global class UpdateRETClientSubplanHistoryBatch implements Schedulable, Database.Batchable<sObject> {
    // test w/ UpdateRETClientSubplanHistoryBatchTest (93%)
    /*
     * Executes the batch job to update client sub-plan history records
     * This method is called by the scheduler to initiate the batch process
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new UpdateRETClientSubplanHistoryBatch(), 200);
    }

    /*
     * Starts the batch process by querying records that need to be updated
     * Finds all NSP_Client_Sub_Plan_History__c records where the end date has passed 
     * and the record is currently marked as the active sub-plan
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM NSP_Client_Sub_Plan_History__c WHERE NSP_End_Date__c <= TODAY AND NSP_Current_Subplan__c = true';
        return Database.getQueryLocator(query);
    }

    /*
     * Processes the batch of records by marking them as inactive (not current sub-plan)
     * Updates the NSP_Current_Subplan__c field to false for all retrieved records
     */
    global void execute(Database.BatchableContext bc, List<NSP_Client_Sub_Plan_History__c> historyRecords) {
        // Prepare list of records to update
        List<NSP_Client_Sub_Plan_History__c> recordsToUpdate = new List<NSP_Client_Sub_Plan_History__c>();
        
        // Loop through each record and mark it as not current
        for(NSP_Client_Sub_Plan_History__c historyRecord : historyRecords) {
            historyRecord.NSP_Current_Subplan__c = false;
            recordsToUpdate.add(historyRecord);
        }
        
        // Perform the update operation
        try {
            if (!recordsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(recordsToUpdate, false);
                NSP_ErrorLogHandler.logSaveResultsException('UpdateRETClientSubplanHistoryBatch', 'ExecuteMethod', results);
            } else {
                System.debug('No records to update in UpdateRETClientSubplanHistoryBatch');
            }
        } catch (Exception e) {
            System.debug('Error in UpdateRETClientSubplanHistoryBatch: ' + e.getMessage());
            // Log the full exception for better debugging
            System.debug('Error details: ' + e);
        }
    }    

    /*
     * Finish method called after all batches have been processed
     * Used for any final cleanup or notifications
     */
    global void finish(Database.BatchableContext bc) {
        System.debug('Finish method of UpdateRETClientSubplanHistoryBatch');
    }
}