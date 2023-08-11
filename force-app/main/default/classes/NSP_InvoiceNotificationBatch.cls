//***Class for NSP_InvoiceNotificationBatch***
/**
* @description  : Class for sending notification for invoice
* @date 12 July 2023
* Name : NSP_InvoiceNotificationBatch
*/
public class NSP_InvoiceNotificationBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    // test w/ NSP_InvoiceNotificationBatch_Test (82%)

    public String stringQuery;
    public Integer processedRecords = 0;
    
    //default constructor
    public NSP_InvoiceNotificationBatch(){
        stringQuery = 'SELECT Id FROM blng__Invoice__c WHERE NSP_CLM_Document_Received__c = TRUE AND NSP_Invoice_Email_Sent__c= FALSE AND NSP_InvBatch_Processed_Internal__c= FALSE AND blng__InvoiceStatus__c = \'Posted\'';
    }
    //Constructor where invoice run id as param
    public NSP_InvoiceNotificationBatch(List<Id> invoiceRunIds){
        if(invoiceRunIds!=null){
            stringQuery = 'SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceRunCreatedBy__c IN: invoiceRunIds AND NSP_CLM_Document_Received__c = TRUE AND NSP_Invoice_Email_Sent__c= FALSE AND NSP_InvBatch_Processed_Internal__c= FALSE AND blng__InvoiceStatus__c = \'Posted\'';
        }
    }
    //Constructor where List of invoices as param
    public NSP_InvoiceNotificationBatch(List<blng__Invoice__c> invoices){
        if(invoices!=null){ 
            Set<Id> invIds = new Set<Id> (new Map<Id,SObject>(invoices).keySet());
            String invoicesString = String.format( '(\'\'{0}\'\')', new List<String> { String.join( invIds , '\',\'') });
            stringQuery = 'SELECT Id FROM blng__Invoice__c WHERE Id IN'+invoicesString +' AND NSP_CLM_Document_Received__c = TRUE AND NSP_Invoice_Email_Sent__c= FALSE AND NSP_InvBatch_Processed_Internal__c= FALSE AND blng__InvoiceStatus__c = \'Posted\'';

        }
    }
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(stringQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<blng__Invoice__c> scope){
         List<String> invoiceIds = new List<String>();

         for(blng__Invoice__c invoice: scope){
            invoiceIds.add(invoice.Id);
         }
         if(invoiceIds.size()!=0){
             NSP_InvoiceEmailMessageService.sendInvoiceEmail(invoiceIds);
             processedRecords += invoiceIds.size();
         }
    }
    
    public void finish (Database.BatchableContext bc){
         AsyncApexJob async = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                      TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {async.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Invoice Notification Batch ' + async.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + async.TotalJobItems +
        ' batches with '+ async.NumberOfErrors + ' failures.' +
        'Total Records :'+processedRecords);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public void execute(SchedulableContext ctx) {
      NSP_InvoiceNotificationBatch batchObject = new NSP_InvoiceNotificationBatch();
        Database.executeBatch(batchObject, Integer.valueOf(Label.NSP_BATCH_SIZE) );   
    }
    
}