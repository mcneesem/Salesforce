/**
* @description  : Batch Class to generate invoice documents using DocuSIgn CLM API
* @author Rakesh Das
* @date 02/16/2023
* Name : NSP_DocuSignInvoiceDocumentBatch
*/
public class NSP_DocuSignInvoiceDocumentBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts, Schedulable {
    // test w/ NSP_DocuSignInvoiceDocumentBatchTest (80%)

    public Integer recordsProcessed = 0;
    public String query;
    public List<String> invcIdList;
    public List<String> processedInvcNumbers = new List<String>();
    //parameterized constructor
    public NSP_DocuSignInvoiceDocumentBatch(List<String> sfInvIds) {
        invcIdList = sfInvIds; 
        query='SELECT Id, Name, blng__InvoiceStatus__c, NSP_CLM_Document_Received__c FROM blng__Invoice__c WHERE Id IN:invcIdList AND blng__InvoiceStatus__c = \'Posted\' AND NSP_CLM_Document_Received__c=FALSE AND NSP_Invoice_External_ID__c = null LIMIT 10000';
    }
    //default constructor
    public NSP_DocuSignInvoiceDocumentBatch() {
       query='SELECT Id, Name, blng__InvoiceStatus__c, NSP_CLM_Document_Received__c FROM blng__Invoice__c WHERE Id blng__InvoiceStatus__c = \'Posted\' AND NSP_CLM_Document_Received__c=FALSE AND NSP_Invoice_Email_Sent__c=FALSE AND NSP_Invoice_External_ID__c = null LIMIT 10000'; 
    }
    
    //start method of batch class
    public Database.QueryLocator start(Database.BatchableContext bc){
      //returns QueryLocator to execute method.
      return Database.getQueryLocator(query);
	}
    
     //Execute Method of Batch Class.
	public void execute(Database.BatchableContext bc, List<blng__Invoice__c> scope){
        try {
        List<String> invIdsToGenerateDocs = new List<String> ();
        for (blng__Invoice__c inv : scope) {
            invIdsToGenerateDocs.add(inv.id);
            recordsProcessed = recordsProcessed + 1;
            processedInvcNumbers.add(inv.Name);
        }
        // method to call DocuSign CLM API to invoke workflowss
        if(invIdsToGenerateDocs.size()>0) {
            NSP_DocuSignRESTUtility.startInvoiceWorkflow(invIdsToGenerateDocs);
        }
    	}catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_DocuSignInvoiceDocumentBatch','execute',ex.getMessage());
        }
    }
    
    public void finish(Database.BatchableContext bc){
        
        System.debug('Total Records : '+recordsProcessed);
       //THIS COMMENT IS INTENTIONAL. DO NOT DELETE.
      // This sends an email to Operations team DL. 
       // Get the ID of the AsyncApexJob representing this batch job
       // from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
       AsyncApexJob async = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
          TotalJobItems, CreatedBy.Email
          FROM AsyncApexJob WHERE Id =
          :bc.getJobId()];
       // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       //String opsEmail = Label.NSP_Operations_Team_DL;
       String[] toAddresses = new String[] {async.CreatedBy.Email};
       mail.setToAddresses(toAddresses);
       mail.setSubject('DocuSign Invoice Generation Batch ' + async.Status);
       mail.setPlainTextBody
       ('The batch Apex job processed ' + async.TotalJobItems +
       ' batches with '+ async.NumberOfErrors + ' failures.' +
       'Total Records :'+recordsProcessed + '\n'+
       'Invoice Numbers : \n'+ String.join(processedInvcNumbers,','));
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
 
    }
    
    public void execute(SchedulableContext ctx) {
        NSP_DocuSignInvoiceDocumentBatch batchObject = new NSP_DocuSignInvoiceDocumentBatch();
          Database.executeBatch(batchObject, Integer.valueOf(Label.NSP_BATCH_SIZE) );   
      }
}