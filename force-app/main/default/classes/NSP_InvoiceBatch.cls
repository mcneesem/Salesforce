/*
@description: update all draft invoices to posted
@date: 13-April-2023
@name: InvoiceBatch
*/
public class NSP_InvoiceBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    public String stringQuery;
    public Integer processedRecords = 0;
    public List<Id> invoices;
    
    //Constructor declaration
    public NSP_InvoiceBatch(){
        stringQuery = 'SELECT ID from blng__Invoice__c WHERE blng__InvoiceStatus__c = \'Draft\' AND CreatedDate = LAST_90_DAYS AND NSP_Invoice_External_ID__c = null';
    }
    
    public NSP_InvoiceBatch(List<Id> invoiceIds){
        this.invoices = invoiceIds;
        if(invoices!=null){
            stringQuery = 'SELECT ID,blng__InvoiceStatus__c from blng__Invoice__c WHERE blng__InvoiceStatus__c = \'Draft\' AND CreatedDate = LAST_90_DAYS AND ID In:invoices AND NSP_Invoice_External_ID__c = null' ;
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
    	//system.debug(Database.query(stringQuery));
        return Database.getQueryLocator(stringQuery);
    }
    
    public void execute(Database.BatchableContext bc, List<blng__Invoice__c> scope){
        for(blng__Invoice__c invoice: scope){
            invoice.blng__InvoiceStatus__c = 'Posted';
            processedRecords++;
        }
		
        List<Database.SaveResult> invoiceResults = Database.update(scope,false);
        NSP_ErrorLogHandler.logSaveResultsException('NSP_InvoiceBatch','ExecuteMethod',invoiceResults);
        
    }
    
    public void finish (Database.BatchableContext bc){
         AsyncApexJob async = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
         						 TotalJobItems, CreatedBy.Email
         						 FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {async.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Draft Invoice post Batch ' + async.Status);
        mail.setPlainTextBody
        ('The batch Apex job processed ' + async.TotalJobItems +
        ' batches with '+ async.NumberOfErrors + ' failures.' +
        'Total Records :'+processedRecords);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    public void execute(SchedulableContext ctx) {
    	NSP_InvoiceBatch batchObject = new NSP_InvoiceBatch();
        Database.executeBatch(batchObject, Integer.valueOf(Label.NSP_BATCH_SIZE) );   
    }
    
}