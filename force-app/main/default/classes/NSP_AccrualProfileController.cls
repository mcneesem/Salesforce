/**
Apex Class Name      :  NSP_AccrualProfileController
Version              :  1.0                                                                          
Function             :  It handles all the operations related to Accrual Profile. 
Modification Log     :                                                                              
**/

public with sharing class NSP_AccrualProfileController {
    public static String recId;
    public static void setrecId (String recordId) {
        recId = recordId;
    }
     public static String getrecId() {
        return recId;
    }
     /***********************************************************************************************
    * MethodName: linkFilesToRecord
    * Description : It links uploaded files to given record
    * Params: String recordId, List<String> contentDocumentIds
    * ********************************************************************************************/ 

    @AuraEnabled
    public static void linkFilesToRecord(String recordId, List<String> contentDocumentIds){
        try {
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            for (String cd : contentDocumentIds) {
                cdlList.add(new ContentDocumentLink(ContentDocumentId=cd, LinkedEntityId=recordId));
            }

            if (Schema.sObjectType.ContentDocumentLink.isCreateable()) {
                // This insert operation should run in all or none mode so that on failure of one record it should revert the entire operation.
                insert cdlList;
             }

        } catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
    }

    
	/***********************************************************************************************
    * MethodName: getPlanOptions
    * Description : This method returns list of Service Plan options related to the given accounts.
    * Params: List<String> accountIds
    * ********************************************************************************************/ 
    
    @AuraEnabled(cacheable=true)
    public static List<NSP_LookupOption> getPlanOptions(List<String> subClientIds){
        try {
            List<NSP_LookupOption> options = new List<NSP_LookupOption>();
            for (NSP_Accrual_Profile__c plan : getAccrualPlans(subClientIds)) {
                options.add(new NSP_LookupOption(plan.NSP_Accrual_Profile_Plan_Name__c, plan.Id, null, null, null));
            }
            options.add(new NSP_LookupOption('Other', 'other', null, null, null));
            return options;
        } catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
    }

    @testvisible
    private static List<NSP_Accrual_Profile__c> getAccrualPlans(List<String> subClientIds){
        List<String> status = new List<String>{ 'Active','Inactive' };
        return [
            SELECT Id, NSP_Accrual_Profile_Plan_Name__c 
                    FROM NSP_Accrual_Profile__c 
                WHERE Id IN (SELECT NSP_Accrual_Profile__c FROM NSP_Accrual_Profile_Subclient_Relation__c WHERE NSP_Sub_Client__c IN : subClientIds )
                    AND NSP_Status__c IN: Status
                    AND NSP_Accrual_Profile_Plan_Name__c != NULL
        ];
    }
    public static String accrualProfilePlanName {
        get {
            if(recId != null){
                List<String> ACC_PROFILE_FIELDS = new List<String>{
                    'Id', 
                    'NSP_Accrual_Profile_Plan_Name__c'
                }; 
                String query = new NSP_QueryBuilder('NSP_Accrual_Profile__c', ACC_PROFILE_FIELDS).addFilter('Id', recId).addLimit(1).build();
                NSP_Accrual_Profile__c aprofile = Database.query(query);
                return aprofile.NSP_Accrual_Profile_Plan_Name__c;
            } 
            return null;
        } set;
        
    }
    public static String accrualProfileAccountNames {
        get {
            List<String> lstAccountNames = new list<String>();
            if(recId != null){
                for(NSP_Accrual_Profile_Account_Relationship__c apAR: [SELECT Id, NSP_Account__r.Name 
                                                                       FROM NSP_Accrual_Profile_Account_Relationship__c 
                                                                       WHERE NSP_Accrual_Profile__c=:recId]){
                    lstAccountNames.add(apAR.NSP_Account__r.Name);
                }
            } 
            return String.join(lstAccountNames, ', ');
        } set;
        
    }
}