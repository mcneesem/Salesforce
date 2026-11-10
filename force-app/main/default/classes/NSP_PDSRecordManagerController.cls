//@ Apex Class Name: NSP_PDSRecordManagerController
//Created Date:  8/11/2022
//Author: Virendra
public class NSP_PDSRecordManagerController {
    // test w/ NSP_PDSRecordManagerController_Test (82%)
    public Id recordId {get;set;}    
    //@ Method Name: NSP_PDSRecordManagerController
    public NSP_PDSRecordManagerController(ApexPages.StandardSetController sc) {
        recordId  = ApexPages.currentPage().getParameters().get('id');
    }
    //@ Mthod Name:getPDSRecordsForSubClient
    @AuraEnabled
    public static String getPDSRecordsForSubClient(String recordId) {
        try{
        List<NSP_Payroll__c> payrollDetails = [SELECT Id FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c =: recordId];
        //Checking if Payroll Details is empty or not
        if(!payrollDetails.isEmpty()) {
            return 'PDS Exists';
        } 
        return createNewPayrollRecord(recordId); 
        }catch(Exception Ex){
            throw new AuraHandledException( ex.getMessage());
        }
    }
    //@Method Name: createNewPayrollRecord
    private static String createNewPayrollRecord(String recordId) {
        try{
        List<NSP_Sub_Client__c> existingSubClients = [SELECT Id, NSP_Sub_Client__c FROM NSP_Sub_Client__c WHERE Id =:recordId];
        NSP_Sub_Client__c existingSubClient = null;
            if( !existingSubClients.isEmpty() ){
                existingSubClient = existingSubClients[0];
            }
        //Creating new Payroll
        if (Schema.sObjectType.NSP_Payroll__c.isCreateable()) {
            NSP_Payroll__c newPayroll = new NSP_Payroll__c();
            newPayroll.NSP_Sub_Client_Name__c = recordId;
            newPayroll.NSP_Sub_Client__c = existingSubClient.NSP_Sub_Client__c;
            // Inserting New Payroll
            insert newPayroll; 
            return newPayroll.Id;
        }
        return null;
        }catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getUpdatedSubClient(String recordId) {
        return [SELECT Id, LastModifiedBy.Profile.Name FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c =:recordId].LastModifiedBy.Profile.Name;
    }
}