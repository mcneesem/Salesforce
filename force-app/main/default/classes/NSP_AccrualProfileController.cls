/**
Apex Class Name      :  NSP_AccrualProfileController
Version              :  1.0                                                                          
Function             :  It handles all the operations related to Accrual Profile. 
Modification Log     :                                                                              
**/

public with sharing class NSP_AccrualProfileController {
    // test w/ NSP_AccrualProfileControllerTest (92%)

    public static String recId;
    public static void setrecId (String recordId) {
        recId = recordId;
    }
     public static String getrecId() {
        return recId;
    }

    //
    // MethodName: getAttachedFiles
    // Description : It gets uploaded files name attched with a given record
    // Params: String recordId
    //
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getAttachedFiles(String recordId){
        List<FileWrapper> lstAttachedFiles=new List<FileWrapper>();
        try {
            for ( ContentDocumentLink cdlink : [
                        SELECT contentDocumentId , contentDocument.Title , contentDocument.FileExtension
                        FROM ContentDocumentLink
                        WHERE ( LinkedEntityId = :recordId )
                    ]
                )
            {
                if ( ( cdlink.contentDocument != null ) && String.isNotBlank( cdlink.contentDocument.Title ) ) {
                    FileWrapper fileWrapper = new FileWrapper();
                    fileWrapper.fileId = cdlink.contentDocumentId;
                    String fileName = cdlink.contentDocument.Title;
                    if ( String.isNotBlank( cdlink.contentDocument.FileExtension ) ) {
                        fileName += '.' + cdlink.contentDocument.FileExtension;
                    }
                    fileWrapper.fileName = fileName;
                    lstAttachedFiles.add( fileWrapper );
                }
            }
        } catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
        return lstAttachedFiles;
    }

    /***********************************************************************************************
    * Class Name: FileWrapper
    * Description : to create wrapper object having properties ContentDocument record Id and its Name.
    * ********************************************************************************************/ 
    public class FileWrapper{
        @AuraEnabled public String fileId{ get; set;}
        @AuraEnabled public String fileName{ get; set;}
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
        List<String> status = new List<String>{ 'Active','Inactive','AP Approved' };
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

    @AuraEnabled(cacheable=true)  
    public static SObject getRecordWithAllFields(Id recordId) {  
        SObject result = null;  
        
        if (recordId != null) {  
            Schema.DescribeSObjectResult accrualDescribe = getAccrualDescribe();  
            if (accrualDescribe != null) {  
                Map<String, Schema.SObjectField> accrualFieldMap = getAccrualFieldMap(accrualDescribe);  
                if (accrualFieldMap != null && !accrualFieldMap.isEmpty()) {  
                    List<String> allFields = getAllFields(accrualFieldMap);  
                    if (allFields != null && !allFields.isEmpty()) {  
                        NSP_sObjectSelector selector = getSelector(allFields);  
                        if (selector != null) {  
                            result = selector.selectById(recordId);  
                        }  
                    }  
                }  
            }  
        }  
        
        return result;  
    }  
    
    private static Schema.DescribeSObjectResult getAccrualDescribe() {  
        return NSP_Accrual_Profile__c.sObjectType.getDescribe();  
    }  
    
    private static Map<String, Schema.SObjectField> getAccrualFieldMap(Schema.DescribeSObjectResult accrualDescribe) {  
        return accrualDescribe.fields.getMap();  
    }  
    
    private static List<String> getAllFields(Map<String, Schema.SObjectField> accrualFieldMap) {  
        return new List<String>(accrualFieldMap.keySet());  
    }  
    
    private static NSP_sObjectSelector getSelector(List<String> allFields) {  
        return new NSP_sObjectSelector('NSP_Accrual_Profile__c', allFields).setSecurityEnforce(false);  
    }
}