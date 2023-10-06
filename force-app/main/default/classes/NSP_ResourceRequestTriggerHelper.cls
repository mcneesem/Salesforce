/**
* Represents the Resource Request trigger helper which handles all the logic.
* Version - STY           - DESCRIPTION                                      	    - TAG

* V1.0    - STY-02212 	 -	RET - New Project Resource Request					    <STY-02212>
            STY-02255	 -  Retirement Services - Project Assignment Email Alert	<STY-02255>

*/
public class NSP_ResourceRequestTriggerHelper {
    // test w/ NSP_ResourceRequestTriggerHelperTest (98%)

    /***********************************************************************************************
    * MethodName: afterInsertDirector
    * Description : Iterates throught the list of Resource Requests Records and passes the parameters to other methods.
    * Params:       List <pse__Resource_Request__c> newList Map<Id, pse__Resource_Request__c> newMap
    * ********************************************************************************************/  
        
        public void afterInsertDirector(List<pse__Resource_Request__c> newList, Map<Id, pse__Resource_Request__c> newMap){
            for(pse__Resource_Request__c resourceRequest: newList){
                //check if resource role is populated and the linked project is of RET Project RT 
                //and pass the rec and resource role to the SendEmailToResourceRole method.
                if(resourceRequest.pse__Resource_Role__c != NULL && 
                   resourceRequest.NSP_Project_Record_Type__c == NSP_ServiceConstants.PROJECT_RET_RECORDTYPE){
                       sendEmailToResourceRole(resourceRequest, resourceRequest.pse__Resource_Role__c);
                   }
            }
            //Check if resource is populated and the project RT is RET Project RT
            //and pass rec and resource to SendEmailToProjectResource method
            for(pse__Resource_Request__c resourceRequest: newList){
                if(resourceRequest.pse__Staffer_Resource__c != NULL && 
                   resourceRequest.NSP_Project_Record_Type__c == NSP_ServiceConstants.PROJECT_RET_RECORDTYPE){
                    sendEmailToProjectResource(resourceRequest, resourceRequest.pse__Staffer_Resource__c);
                    
                }
            }
        }
        
    /***********************************************************************************************
    * MethodName  : afterInsertDirector
    * Description : Iterates throught the list of new Resource Requests Records and old Resource Requests 
                    Recordsand passes the parameters to other methods.
    * Params:     :  Map<Id, pse__Resource_Request__c> mNewResourceRequests,Map<Id, pse__Resource_Request__c> mOldResourceRequests
    * ********************************************************************************************/  
        
        public void afterUpdateDirector(Map<Id, pse__Resource_Request__c> mNewResourceRequests,Map<Id, pse__Resource_Request__c> mOldResourceRequests){
            for(pse__Resource_Request__c resourceRequest: mNewResourceRequests.values()){
                //check if resource role is updated and not equal to the old value and the linked project is of RET Project RT 
                //and pass the rec and email address to the sendEmailNotification method.
                if(resourceRequest.pse__Resource_Role__c != NULL && 
                   resourceRequest.pse__Resource_Role__c != mOldResourceRequests.get(resourceRequest.Id).pse__Resource_Role__c && 
                   resourceRequest.NSP_Project_Record_Type__c == NSP_ServiceConstants.PROJECT_RET_RECORDTYPE){
                       sendEmailToResourceRole(resourceRequest, resourceRequest.pse__Resource_Role__c);
                   }
            }
            for(pse__Resource_Request__c resourceRequest : mNewResourceRequests.values()){
                //check if the resource is changed
                if(resourceRequest.pse__Staffer_Resource__c != null && 
                   resourceRequest.pse__Staffer_Resource__c != mOldResourceRequests.get(resourceRequest.Id).pse__Staffer_Resource__c && 
                   resourceRequest.NSP_Project_Record_Type__c == NSP_ServiceConstants.PROJECT_RET_RECORDTYPE){
                       sendEmailToProjectResource(resourceRequest, resourceRequest.pse__Staffer_Resource__c);
                   }
            }
        }
        
        /**
    * Send the contact in Resource on Project Task Assignment rec to individual functionality methods
    * @param lProjectTaskAssignments List of New Project Task Assignments
    * @param mProjectTaskAssignments Map of New project Task Assignments.
    * @return void
    */
        
        public void sendEmailToProjectResource(pse__Resource_Request__c resourceRequest, Id resource){
            Set<Id> contactIdSet = new Set<Id>();
            Map<Id, Id> resourceContactMap = new Map<Id, Id>();
            //Iterate throught the list of project task assignments and add the contact id to the set
            //and map the project task assignments to the contact on the resource
            contactIdSet.add(resource);
            resourceContactMap.put(resourceRequest.Id, resource);
            //pass the contactId set and map of project task assignments to sendEmailNotification method
            if(!contactIdSet.isEmpty() && !resourceContactMap.isEmpty()){
                sendEmailNotificationToResource(contactIdSet, resourceContactMap);
            }
        }
        
    /**
    * Send an email to the user of contact in Resource on Project Task Assignment rec 
    * @param contactIdSet Set of Contact
    * @param resourceContactMap Map of  project Task Assignments and its contact present on the resource field.
    * @return void
    */
        
        public static void sendEmailNotificationToResource(Set<Id> contactIdSet, Map<Id,Id> resourceContactMap){
            Map<Id, Id> resourceUserMap = new Map<Id, Id>();
            Map<Id, Contact> mapOfContact = new Map<Id, Contact>([SELECT Id, pse__Salesforce_User__c FROM Contact WHERE Id =: contactIdSet AND pse__Salesforce_User__c != NULL]);
            if(mapOfContact.keySet().size() == 0){
                return;
            }
            //map the project task assignments and the user of the contact
            for(Id resourceRequest: resourceContactMap.keyset()){
                Contact con = mapOfContact.get(resourceContactMap.get(resourceRequest));
                if(con != NULL){
                    resourceUserMap.put(resourceRequest, con.pse__Salesforce_User__c);
                }
            }
            NSP_EmailService.sendEmail(resourceUserMap, NSP_ServiceConstants.PROJECT_ASSIGNMENT);
        }    
        
    }