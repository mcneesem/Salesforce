public class NSP_PaperlessBatchDateBatch implements database.Batchable<sObject>, schedulable {
    
    public database.QueryLocator start(Database.BatchableContext Bc){
        String query = 'Select Id, NSP_Paperless_Batch_Date__c, NSP_IsPaperless__c, NSP_Paid_Non_Paid__c, NSP_Employee_Status__c, NSP_Sub_Client__r.NSP_Account_Status__c, NSP_Sub_Client__c, NSP_Sub_Client__r.NSP_Paperless_Batch_Date__c, NSP_Sub_Client__r.NSP_Asset__c, NSP_Sub_Client__r.NSP_Asset__r.Status, NSP_Sub_Client__r.NSP_Asset__r.NSP_Paperless_Batch_Date__c From NSP_Sub_Client_Contact__c Where  NSP_Sub_Client__r.NSP_Asset__r.RecordType.Name = \'WO\' AND (NSP_Paperless_Batch_Date__c = YESTERDAY OR NSP_Sub_Client__r.NSP_Paperless_Batch_Date__c = YESTERDAY OR NSP_Sub_Client__r.NSP_Asset__r.NSP_Paperless_Batch_Date__c = YESTERDAY)';
        return Database.getQueryLocator(Query);
        
    }
    
    public void execute (Database.BatchableContext bc , List<NSP_Sub_Client_Contact__c> subClientContactList){
        NSP_PaperlessBatchDateService.updatePaperlessOnAsset(subClientContactList);
    }
    
    public void finish (Database.BatchableContext bc){
    }
    
    public void execute(SchedulableContext scon) {
        Database.executeBatch(new NSP_PaperlessBatchDateBatch());
    }
}