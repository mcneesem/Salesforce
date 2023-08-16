/**
* @description  : Batch Class to delete old error logs
* @author Rakesh Das
* @date 08/05/2022
* Name : NSP_deleteErrorLogsBatch
*/

public class NSP_deleteErrorLogsBatch implements Database.Batchable<sObject>, Database.Stateful {
    public String query {get;set;}
    public Integer totalRecords {get;set;}
    public DateTime dt {get;set;}

    public NSP_deleteErrorLogsBatch() {
        Integer daysValue = Integer.valueOf(System.label.NSP_ErrorLogRetentionDays);
		if(Test.isRunningTest()){
			daysValue = -5;
		}
        dt = System.today() - daysValue;
        query = 'Select Id from NSP_Error_Log__c WHERE CreatedDate<='+dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        totalRecords = 0;
    }

    public Database.QueryLocator start (Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
	
    public void execute (Database.BatchableContext BC, List<sObject> scope) {
        
		totalRecords+=scope.size();
		delete scope;
		//Database.emptyRecycleBin(scope);
    }
    
    public void finish(Database.BatchableContext BC){
        
        //System.debug('Total Records :'+totalRecords);
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
       ('The batch Apex job processed ' + a.TotalJobItems +
       ' batches with '+ a.NumberOfErrors + ' failures.' +
       'Total Records :'+totalRecords);
       Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
       */
    }
}