/**
Apex Class Name      :  NSP_AssignFSLPermissionsBatch
Version              :  1.0                                                                          
Created Date         :  2/15/2023  
Author               :  Dhawal Saiya
Function             :  This Batch is used to assign and remove permissions sets for FSL to users.
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Dhawal Saiya               2/15/2023              First Iteration
*/
public with sharing class NSP_AssignFSLPermissionsBatch implements Database.Batchable<sObject>, Database.Stateful{
    private Set<Id> setUserId {get;set;}

    public NSP_AssignFSLPermissionsBatch(){
        setUserId = new set<Id>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        List<String> setUserFields = new List<String>{'NSP_Salesforce_Field_service__c', 'NSP_Dispatch_Region__c', 'Id', 'FirstName', 'LastName'};
        List<String> lstProfileName = new List<String> {'System Administrator', NSP_ServiceConstants.PEOSERVICE, NSP_ServiceConstants.CONTACTCENTER, NSP_ServiceConstants.BPSSERVICE, NSP_ServiceConstants.RT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.USER_OBJECT, setUserFields)
                                        .addFilter('Profile.Name', lstProfileName, NSP_QueryBuilder.Operator.INCLUDES)
                                        .addFilter('NSP_isFSLPermissionAssigned__c', false)
                                        .setSecurityEnforce(false)
                                        .build();
        query += ' AND ( NSP_Salesforce_Field_service__c != \'\' OR NSP_Dispatch_Region__c != \'\')';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<User> lstUser){
        NSP_UserTriggerHelper userHelper = new NSP_UserTriggerHelper();
        userHelper.processUserPermissions(lstUser, null);
    }

    public void finish(Database.BatchableContext bc){
    }

}