public with sharing class UpdateRETClientSubplanHistoryBatch implements ISelfSchedulable, Schedulable, Database.Batchable<sObject> {
    // test w/ UpdateRETClientSubplanHistoryBatchTest (92%)
   
    // Executes the batch job to update client sub-plan history records
    // This method is called by the scheduler to initiate the batch process
    public void execute( SchedulableContext sc ) {
        Database.executeBatch( new UpdateRETClientSubplanHistoryBatch(), 200 );
    }

     public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'UpdateRETClientSubplanHistoryBatch ~ everyday at 1 AM' + suffix ,
            '0 0 1 * * ? *' ,
            new UpdateRETClientSubplanHistoryBatch()
        );
    }

    // Starts the batch process by querying records that need to be updated
    // Finds all NSP_Client_Sub_Plan_History__c records where the end date has passed 
    // and the record is currently marked as the active sub-plan
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
            SELECT 
            Id 
            FROM 
            NSP_Client_Sub_Plan_History__c 
            WHERE 
            NSP_End_Date__c <= TODAY 
            AND 
            NSP_Current_Subplan__c = true
        ]
        );
    }

    // Processes the batch of records by marking them as inactive (not current sub-plan)
    // Updates the NSP_Current_Subplan__c field to false for all retrieved records
    public void execute( Database.BatchableContext bc, List<NSP_Client_Sub_Plan_History__c> historyRecords ) {
        // Prepare list of records to update
        List<NSP_Client_Sub_Plan_History__c> recordsToUpdate = new List<NSP_Client_Sub_Plan_History__c>();
        
        // Loop through each record and mark it as not current
        for( NSP_Client_Sub_Plan_History__c historyRecord : historyRecords ) {
            historyRecord.NSP_Current_Subplan__c = false;
            recordsToUpdate.add(historyRecord);
        }
        
        // Perform the update operation
        try {
            if ( !recordsToUpdate?.isEmpty() ) {
                Database.SaveResult[] results = Database.update( recordsToUpdate, false );
                NSP_ErrorLogHandler.logResults(
                    UpdateRETClientSubplanHistoryBatch.class.getName() , 
                    'execute:NSP_Client_Sub_Plan_History__c' , 
                    results
                );
            }
        } catch ( Exception e ) {
             NSP_ErrorLogHandler.logException(
                UpdateRETClientSubplanHistoryBatch.class.getName() , 
                'execute' , 
                e
            );

        }
    }    

    // Finish method called after all batches have been processed
    // Used for any final cleanup or notifications
    public void finish( Database.BatchableContext bc ) {

    }
}
