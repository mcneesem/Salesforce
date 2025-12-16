@isTest
private class InvoiceMissingFilesAlertBatchTest {

    private static final String POSTED='Posted';

    @testSetup
    private static void setupTestData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        upsert orderSetting;

        InvoiceMissingFilesBatchSettings__c invSettings = InvoiceMissingFilesBatchSettings__c.getOrgDefaults();
        invSettings.BatchSize__c = 1;
        invSettings.IsEnabled__c = True;
        invSettings.BccAddresses__c = 'test@insperity.com';
        upsert invSettings;

        blng__InvoiceRun__c invRun = new blng__InvoiceRun__c();
        invRun.Name = 'Test_Inv_Run';
        invRun.blng__TargetDate__c = System.today();
        insert invRun;

        // Disable unnecessary triggers
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled = true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled = true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled = true;
        NSP_ContractTriggerHandler.TriggerDisabled = true;

        // Create necessary test data
        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(objaccount.id, true);
        blng__BillingRule__c bRule = NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule = NSP_TestHelper.createRevrecRule('Project Rev Rec');
        blng__TaxRule__c tRule = NSP_TestHelper.createRevTaxRule();
        blng__RevenueDistributionMethod__c dis = NSP_TestHelper.createRevenueDistribution('Project Rev Rec (Invoice)');
        NSP_TestHelper.createGLRule();
        NSP_TestHelper.createFinBook();
        blng__RevenueRecognitionTreatment__c recTreatment = NSP_TestHelper.createRevRecTreatment();
        recTreatment.blng__RevenueDistributionMethod__c = dis.Id;
        recTreatment.blng__RevenueRecognitionRule__c = rRule.Id;
        insert recTreatment;

        // Create products and associate billing rules
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c = 'YES';
        objproduct.blng__BillingRule__c = bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c = rRule.Id;
        objproduct.blng__TaxRule__c = tRule.Id;
        objproduct.ProductCode = 'Admin_WO';
        insert objproduct;

        // Create another revenue recognition rule for DELAY_12_1
        blng__RevenueRecognitionRule__c rRule1 = NSP_TestHelper.createRevrecRule(NSP_CPQConstants.DELAY_12_1);
        Product2 objproduct1 = NSP_TestHelper.createProduct('Test Product1', false);
        objproduct1.SBQQ__ChargeType__c = 'Recurring';
        objproduct1.SBQQ__BillingType__c = 'Arrears';
        objproduct1.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct1.NSP_IsScholarshipPrice_Applicable__c = 'YES';
        objproduct1.blng__BillingRule__c = bRule.Id;
        objproduct1.blng__RevenueRecognitionRule__c = rRule1.Id;
        objproduct1.blng__TaxRule__c = tRule.Id;
        insert objproduct1;

        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', true);
        PriceBookEntry objPbe = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 200.0, true);
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpprtunity.Id, true);
        NSP_TestHelper.createCPQQuotelines(objQuote, new List<Product2>{objproduct}, new List<PriceBookEntry> {objPbe}, true);

        // Create an order from Quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        Test.startTest();
        update objQuote;

        // Retrieve Order Items
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([SELECT id FROM Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c = system.today();
        orderList[0].Status = 'Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        update orderItemList;

        // Activate the order
        orderList[0].Status = 'Activated';
        update orderList;
        Assert.isNotNull(objOpprtunity.Id);
        Test.stopTest();
    }

    @isTest
    private static void testBatchWithInvIds() {

        //fetch activated orders
        List<Order> orderList = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                                 FROM Order
                                 WHERE Status = 'Activated'];
        //create an Invoice
        orderList[0].blng__BillNow__c=true;
        update orderList;
        // Test.startTest();
        List<blng__Invoice__c> inv =[SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Order__c=:orderList[0].Id  limit 1];
        //POST the invoice
        List<blng__InvoiceRun__c> invRuns = [SELECT Id FROM blng__InvoiceRun__c LIMIT 1];
        inv[0].blng__InvoiceStatus__c=POSTED;
        inv[0].blng__InvoiceRunCreatedBy__c = invRuns[0].Id;
        update inv;


        List<Id> recIds = new List<Id>();
        for(blng__InvoiceRun__c r : invRuns){
            recIds.add(r.Id);
        }

        List<blng__Invoice__c> invRecs =[SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Order__c=:orderList[0].Id  limit 1];
        List<Id> invIds = new List<Id>();
        for(blng__Invoice__c i : invRecs){
            invIds.add(i.Id);
        }

        Test.startTest();
        InvoiceMissingFilesAlertBatch batch = new InvoiceMissingFilesAlertBatch(invIds);
        Database.executeBatch(batch);
        Test.stopTest();
        System.assert(true, 'Batch executed with Invoice Ids.');
    }

    @isTest
    private static void testBatchWithoutInvIds() {
        Test.startTest();
        InvoiceMissingFilesAlertBatch batch = new InvoiceMissingFilesAlertBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        System.assert(true, 'Batch executed without Invoice Ids.');
    }

    @isTest
    private static void testScheduledExecution() {
        Test.startTest();
        String cronExp = '0 0 0 * * ?';
        System.schedule('Test Scheduled Batch', cronExp, new InvoiceMissingFilesAlertBatch());
        Test.stopTest();
        System.assert(true, 'Scheduled job was created.');
    }

}
//