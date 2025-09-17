@isTest
private class UpdateInvoiceLinesControllerTest {

    @testSetup
    private static void createTestData() {
        UpdateInvoiceLinesBatchSettings__c sett = new UpdateInvoiceLinesBatchSettings__c();
        sett.IsEnabled__c = true;
        sett.BatchSize__c = 200;
        insert sett;

        Account objaccount = NSP_TestHelper.createAccount(true);

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        insert objproduct;

        blng__InvoiceRun__c invRun = new blng__InvoiceRun__c();
        SBQQ.TriggerControl.Disable();
        invRun.blng__TargetDate__c = System.Today() + 10;
        insert invRun;

        blng__Invoice__c inv = new blng__Invoice__c();
        inv.blng__Account__c = objaccount.id;
        insert inv;

        blng__UsageSummary__c usg = new blng__UsageSummary__c();
        usg.blng__SummaryStartDate__c = System.Today() - 5;
        usg.blng__SummaryEndDate__c = System.Today() + 10;
        insert usg;

        blng__InvoiceLine__c invLine = new blng__InvoiceLine__c();
        invLine.NSP_Additional_Product_Description__c = '$100 PEPM';
        invLine.blng__UnitPrice__c = 100;
        invLine.blng__UsageSummary__c = usg.id;
        invLine.blng__Subtotal__c = 100;
        invLine.blng__Product__c = objproduct.id;
        invLine.blng__Quantity__c = 10;
        invLine.blng__InvoiceRun__c = invRun.id;
        invLine.blng__Invoice__c = inv.id;
        invLine.NSP_Product_Description__c = 'test123';
        insert invLine;
    }

    @isTest
    private static void createGLTransactionsTest() {
        List<blng__InvoiceRun__c> invRuns = [SELECT id FROM blng__InvoiceRun__c];
        List<Id> idList = new List<Id>{invRuns[0].id};
        Test.startTest();
        UpdateInvoiceLinesController.processInvoiceLines(idList);
        Test.stopTest();
        List<blng__InvoiceLine__c> invLines = [SELECT id, Invoice_Run_Completed__c FROM blng__InvoiceLine__c];
        System.assertEquals(invLines[0].Invoice_Run_Completed__c,true);
    }

    @isTest
    private static void createGLTransactionsNullTest() {
        Test.startTest();
        UpdateInvoiceLinesBatch.executeBatch( null );
        Test.stopTest();
        List<blng__InvoiceLine__c> invLines = [SELECT id, Invoice_Run_Completed__c FROM blng__InvoiceLine__c];
        System.assertEquals(invLines[0].Invoice_Run_Completed__c,false);
    }

}
//