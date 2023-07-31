/**
* @description  : Batch Class to process lock box records
* @author Rakesh Das
* @date 08/17/2022
* Name : NSP_processLockBoxFiles
*/

public class NSP_processLockBoxFiles implements Database.Batchable<sObject>, Database.Stateful {
    public String query {get;set;}
    public Integer totalRecords {get;set;}
    public Integer successRecords {get;set;}
    public Integer failedRecords {get;set;}

    public NSP_processLockBoxFiles() {
        query = 'SELECT Id, NSP_Account__c, NSP_Bank_Number__c, NSP_Category__c, NSP_Check_Number__c, NSP_Customer_Batch_Number__c, NSP_Deposit_Date__c, NSP_Invoice_Number__c,NSP_Check_Amount__c,';
        query+='NSP_LockBox_Number__c, NSP_Ready_to_Convert__c, NSP_Sequence_Number__c, NSP_Remitter_Name__c, NSP_Status__c, NSP_Transaction_Type__c FROM NSP_Lock_Box__c WHERE NSP_Ready_to_Convert__c=TRUE AND NSP_Status__c = \'Pending\' AND NSP_Payment__c=null';
        totalRecords = 0;
        successRecords= 0;
        failedRecords=0;
    }

    public Database.QueryLocator start (Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute (Database.BatchableContext BC, List<NSP_Lock_Box__c> scope) {
        
		totalRecords+=scope.size();
        List<String> lockboxIds = new List<String>();
        for(NSP_Lock_Box__c lb : scope){
            lockboxIds.add(lb.Id);
        }
		List<NSP_LockBox_Controller.lockboxWrapper> resArr = NSP_LockBox_Controller.processLockBoxRecords(lockboxIds);
        for(NSP_LockBox_Controller.lockboxWrapper lbwrap : resArr) {
            if(lbwrap.success) {
                successRecords+=1;
            }
            else {
                failedRecords+=1;
            }
        }
    }

    public void finish(Database.BatchableContext BC){


          //THIS COMMENT IS INTENTIONAL. DO NOT DELETE.
      // This sends an email to Operations team DL. Will be used in Phase 2 when batch is scheduled in system.
      /* Get the ID of the AsyncApexJob representing this batch job
       // from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
       AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
          TotalJobItems, CreatedBy.Email
          FROM AsyncApexJob WHERE Id =
          :BC.getJobId()];
        // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       String opsEmail = Label.NSP_Operations_Team_DL;
       String[] toAddresses = new String[] {opsEmail};
       mail.setToAddresses(toAddresses);
       mail.setSubject('Error Logs Deletion Batch ' + a.Status);
       mail.setPlainTextBody
       ('The batch Apex job processed ' + totalRecords +
       ' batches with '+ successRecords + ' successes and 'failedRecords + ' failures.' +
       'Total Records :'+totalRecords);
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
       */

    }
    
}