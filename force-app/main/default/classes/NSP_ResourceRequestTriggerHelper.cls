/**
* Represents the Resource Request trigger helper which handles all the logic.
* Version - STY           - DESCRIPTION                                      	    - TAG

* V1.0    - STY-02212 	 -	RET - New Project Resource Request					    <STY-02212>
            STY-02255	 -  Retirement Services - Project Assignment Email Alert	<STY-02255>

*/


public class NSP_ResourceRequestTriggerHelper {
	
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
    
    /***********************************************************************************************
    * MethodName: SendEmailToResourceRole
    * Description : Method to send an email based on the resource role selected
    * Params:       List <pse__Resource_Request__c> newList Map<Id, pse__Resource_Request__c> newMap
    * ********************************************************************************************/  
        
        public void sendEmailToResourceRole(pse__Resource_Request__c resourceRequest, String resourceRole){
            sendEmailBasedOnResourceRoleSelected(resourceRequest, resourceRole);
        }
        
    /***********************************************************************************************
    * MethodName  : resourceRole
    * Description : Helper method for SendEmailToResourceRole which Sends emails to shared inbox based on resource role selected.
    * Params:     : pse__Resource_Request__c resourceRequest, String resourceRole
    * ********************************************************************************************/  
        
        public void sendEmailBasedOnResourceRoleSelected(pse__Resource_Request__c resourceRequest, String resourceRole){
            if(resourceRole == NSP_ServiceConstants.RET_COMPLIANCE){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_401KCOMPLIANCE)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_FINANCE){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_FINANCEMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_NBICONVERSION){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_NBICONVERSIONMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_NBIIMPLEMENTATION){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_NBIIMPLEMENTATIONMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_QCANALYST){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_QCANALYSTMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_OPSOMNI){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_OPSOMNIMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RETOPSPROCESSING){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_401KASFPLAN)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_PLANCONSULTING){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_PLANCONSULTINGMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_SALES){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_SALESMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_CSPPROCESSING){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_CSPPROCESSINGMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_CSPIMPLEMENTATION){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_CSPIMPLEMENTATIONMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_CSPCOMPLIANCE){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_CSPCOMPLIANCEMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_CSPCONSULTING){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_CSPCONSULTINGMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_SRP){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_SRPMDT)});
            }
            if(resourceRole == NSP_ServiceConstants.RET_ORK){
                sendEmailNotification(resourceRequest, new List<String>{getEmailAddressFromMDT(NSP_ServiceConstants.RET_ORKMDT)});
            }
        }
        
        
    /***********************************************************************************************
    * MethodName: getEmailAddressFromMDT
    * Description : Helper method for sendEmailBasedOnResourceRoleSelected which Gets emails from metadata record
    * Params:     : String mdtRecord
    * ********************************************************************************************/  
        
        public String getEmailAddressFromMDT(String mdtRecord){
            NSP_Retirement_Services__mdt mdtrec = NSP_Retirement_Services__mdt.getInstance(mdtRecord);
            return mdtrec.NSP_Email_Address__c;
        }
        
        
    /***********************************************************************************************
    * MethodName: sendEmailNotification
    * Description : Sends an email notification to shared inboxes based on the resource role selected
    * Params:       Map<Id, pse__Resource_Request__c> mNewResourceRequests Map<Id, pse__Resource_Request__c> mOldResourceRequests
    * ********************************************************************************************/  
        
        public void sendEmailNotification(pse__Resource_Request__c resourceRequest, List<String> sendToList){
            List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
            List<String> emailTempFields = new List<String>{
                'ID',
                'BrandTemplateId',
                'Subject',
                'HTMLValue',
                'Body',
                'DeveloperName'    
                };      
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, NSP_ServiceConstants.RESOURCE_REQUEST_ROLE);
            if(!sendToList.isEmpty()){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , resourceRequest.pse__Project__c);
                email.setTemplateId(emailTemplate.Id); 
                email.setToAddresses(sendToList);
                email.setWhatId(resourceRequest.pse__Project__c);  
                lstEmailMessages.add(email);
            }
            if(!lstEmailMessages.isEmpty() && !Test.isRunningTest()){
                //send email alert
                Messaging.sendEmail(lstEmailMessages);
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