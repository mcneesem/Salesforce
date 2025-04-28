@isTest
private class InvoiceMissingFilesControllerTest {

    private static final String POSTED='Posted';

    @testSetup
    private static void setupTestData() {
        
        InvoiceMissingFilesBatchSettings__c invSettings = InvoiceMissingFilesBatchSettings__c.getOrgDefaults();
        invSettings.BatchSize__c = 1;
        upsert invSettings;

        blng__InvoiceRun__c invRun = new blng__InvoiceRun__c();
        invRun.Name = 'Test_Inv_Run';
        invRun.blng__TargetDate__c = System.today();
        insert invRun;

    }

    @IsTest static void testInvoiceBatch() {

        List<blng__InvoiceRun__c> invRuns = [SELECT Id FROM blng__InvoiceRun__c LIMIT 1];
       
        List<Id> recIds = new List<Id>();
        for(blng__InvoiceRun__c r : invRuns){
            recIds.add(r.Id);
        }

        Test.startTest();
        InvoiceMissingFilesController.executeBatch(recIds);
        Test.stopTest();
    }
}