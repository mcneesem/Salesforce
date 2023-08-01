/**
Apex Class Name      :  NSP_AssignFSLUserPermissions
Version              :  1.0                                                                          
Created Date         :  2/15/2023  
Author               :  Dhawal Saiya
Function             :  This class is used to assign and remove permissions sets for FSL.
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Dhawal Saiya               2/15/2023              First Iteration
*/
public with sharing class NSP_AssignFSLUserPermissions implements Queueable  {
    private List<User> lstUserToProcess{get;set;}
    private Map<String, Id> mapPermissionSetNameId = new Map<String, Id>();
    private Map<String, Id> mapTerritory = new Map<String, Id>();
    private Boolean isUpdate{get;set;}

    public NSP_AssignFSLUserPermissions(List<User> lstUser, Boolean isUpdate){
        this.lstUserToProcess = lstUser;
        this.isUpdate = isUpdate;

        //generate permission set map.
        Set<String> setPermissionSetName = new Set<String>{ NSP_ServiceConstants.FSL_DISPATCHER_LICENSE_PS, NSP_ServiceConstants.FSL_EDIT_FIELDS_PS,
                    NSP_ServiceConstants.FSL_DISPATCHER_PERMISSIONS_READ_ONLY_PS, NSP_ServiceConstants.FSL_RESOURCE_PERMISSIONS_PS,
                    NSP_ServiceConstants.FSL_RESOURCE_LICENSE_PS, NSP_ServiceConstants.EINSTEIN_ACTIVITY_CAPTURE_INCLUDED_PS,
                    NSP_ServiceConstants.FSL_READ_ONLY_PS, NSP_ServiceConstants.FSL_DISPATCHER_PERMISSIONS_PS};
        
        //create a map of PermissionSetName and PermissionSetId
        for(PermissionSet ps: [SELECT Id, Name FROM PermissionSet WHERE Name IN :setPermissionSetName]){
            mapPermissionSetNameId.put(ps.Name, ps.Id);
        }
    }

    public void execute(QueueableContext context) {
        List<PermissionSetAssignment> lstPSA = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> lstPSAToDelete = new List<PermissionSetAssignment>();
        List<User> lstUserToUpdate = new List<User>();
        Set<Id> setUserId = new Set<Id>();

        //Iterate on list of users and generate list of permission set assignment and FSL records
        if(lstUserToProcess != null && !lstUserToProcess.isEmpty()){
            //Generate set of dispatch region
            for(User usr: lstUserToProcess){
                setUserId.add(usr.Id);
                lstUserToUpdate.add(New User(Id = usr.Id, NSP_IsFSLPermissionAssigned__c = true));
            }

            if(isUpdate == null || isUpdate){
                for(PermissionSetAssignment psa: [SELECT Id FROM PermissionSetAssignment 
                                    WHERE AssigneeId IN :setUserId AND PermissionSetId IN :mapPermissionSetNameId.values() ]){
                    lstPSAToDelete.add(psa);
                }
            }

            if(lstPSAToDelete != null && !lstPSAToDelete.isEmpty()){
                Database.DeleteResult[] DeleteResults = Database.Delete(lstPSAToDelete, false);
            }

            for(User usr: lstUserToProcess){
                //When Salesforce Field Service is Dispatcher
                if(String.isNotBlank(usr.NSP_Salesforce_Field_Service__c) && 
                        (usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER ||
                         usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE)){
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_DISPATCHER_LICENSE_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_DISPATCHER_PERMISSIONS_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_EDIT_FIELDS_PS, usr.Id));
                }
                
                //When Salesforce Field Service is Resource
                if(String.isNotBlank(usr.NSP_Salesforce_Field_Service__c) && 
                        (usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_RESOURCE ||
                         usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE)){
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_RESOURCE_PERMISSIONS_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_RESOURCE_LICENSE_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.EINSTEIN_ACTIVITY_CAPTURE_INCLUDED_PS, usr.Id));
                }

                //When Salesforce Field Service is Readonly
                if(String.isNotBlank(usr.NSP_Salesforce_Field_Service__c) && usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_SFS_READONLY){
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_DISPATCHER_LICENSE_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_DISPATCHER_PERMISSIONS_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_DISPATCHER_PERMISSIONS_READ_ONLY_PS, usr.Id));
                    lstPSA.add(createPermissionSetAssignment(NSP_ServiceConstants.FSL_READ_ONLY_PS, usr.Id));
                }
            }

            if(!lstPSA.isEmpty()){
                Database.SaveResult[] result =  Database.insert(lstPSA,false);
            }

            if(lstUserToUpdate != null && !lstUserToUpdate.isEmpty()){
                Database.SaveResult[] result =  Database.update(lstUserToUpdate, false);
            }
        }    
    }

    /**
     * @description: private method to create permission set assignment record 
     * @parameters: permission set name, user Id
     * @return: PermissionSetAssignment
    */
    private PermissionSetAssignment createPermissionSetAssignment(String permSetName, Id userId){
        PermissionSetAssignment psa = new PermissionSetAssignment(
                    PermissionSetId = mapPermissionSetNameId.get(permSetName), 
                    AssigneeId = userId);
        return psa;
    }
}