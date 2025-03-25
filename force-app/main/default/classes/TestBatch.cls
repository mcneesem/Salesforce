@isTest
global class TestBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account LIMIT 1');
    }
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
    }
    global void finish(Database.BatchableContext bc) {
    }    
}