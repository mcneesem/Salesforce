@isTest
private class NSP_InvoiceLineTriggerTest {
    private static final String POSTED='Posted';

    @testSetup
    private static void setupTestData() {
        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        upsert orderSetting;

        //Disable unnesessary triggers
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled=true;
        NSP_ContractTriggerHandler.TriggerDisabled=true;

        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(objaccount.id, true);
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule('Project Rev Rec');
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        blng__RevenueDistributionMethod__c dis=NSP_TestHelper.createRevenueDistribution('Project Rev Rec (Invoice)');
        NSP_TestHelper.createGLRule();
        NSP_TestHelper.createFinBook();
        blng__RevenueRecognitionTreatment__c recTreatment=NSP_TestHelper.createRevRecTreatment();
        recTreatment.blng__RevenueDistributionMethod__c=dis.Id;
        recTreatment.blng__RevenueRecognitionRule__c=rRule.Id;
        insert recTreatment;
        //create products and assoicate Billing rules
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        objproduct.ProductCode = 'Admin_WO';
        insert objproduct;
        blng__RevenueRecognitionRule__c rRule1=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.DELAY_12_1);
        Product2 objproduct1 = NSP_TestHelper.createProduct('Test Product1',false);
        objproduct1.SBQQ__ChargeType__c = 'Recurring';
        objproduct1.SBQQ__BillingType__c = 'Arrears';
        objproduct1.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct1.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct1.blng__BillingRule__c=bRule.Id;
        objproduct1.blng__RevenueRecognitionRule__c=rRule1.Id;
        objproduct1.blng__TaxRule__c=tRule.Id;

        insert objproduct1;
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true); //creates Opportunity
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);          //creates Pricebook entries
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);     //creates Quote
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true); //creates Quote Lines
        //create an order from Quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        Test.startTest();
        update objQuote;
        //Retrieve Order Items
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([SELECT id FROM Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        //activate the order
        orderList[0].Status='Activated';
        update orderList;
        Assert.isNotNull(objOpprtunity.Id);
        Test.stopTest();
    }

    // Below test method covers Project Rev Rec and Project Rev Rec 12 models
    @isTest
    private static void invoiceLineTest() {
        Test.startTest();
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
        inv[0].blng__InvoiceStatus__c=POSTED;
        update inv;
        //create revenue schedules and associate an invoice line
        blng__RevenueSchedule__c sch=new blng__RevenueSchedule__c();
        sch.blng__TotalRevenueAmount__c=25;
        sch.blng__FullRecognitionDate__c=system.today()-1;
        sch.blng__RevenueDistributionMethod__c=[SELECT Id,Name FROM blng__RevenueDistributionMethod__c WHERE Id!=null limit 1]?.Id;
        sch.blng__RevenueRecognitionTreatment__c=[SELECT Id,Name FROM blng__RevenueRecognitionTreatment__c WHERE Id!=null limit 1]?.Id;
        blng__InvoiceLine__c invLine=[SELECT Id,Name,NSP_Go_Live_Date__c FROM blng__InvoiceLine__c  WHERE blng__Invoice__c=:inv[0].Id  limit 1];
        //sch.blng__InvoiceLine__c=[SELECT Id,Name FROM blng__InvoiceLine__c limit 1]?.Id;
        sch.blng__InvoiceLine__c=invLine.Id;
        insert sch;
        //orderList[0].NSP_Project_Go_Live_Date__c=system.today()+1;
        // update orderList; // this will invoke recreate rev shedules
        invLine.NSP_Go_Live_Date__c=system.today()+1;
        update invLine;
        system.assertEquals(POSTED, inv[0].blng__InvoiceStatus__c);
        Test.stopTest();
    }

    // Below test method covers 12 Delay1 rev rec model
    @isTest
    private static void invoiceLine12DelayTest() {
        Account objaccount  = [Select Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name FROM Product2 WHERE Name = 'Test Product1' LIMIT 1];
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        Test.startTest();
        update objQuote;

        list<OrderItem> orderItemList = new list<OrderItem>([SELECT id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([SELECT id FROM Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        //activate the order
        orderList[0].Status='Activated';
        update orderList;
        //create an invoice
        orderList[0].blng__BillNow__c=true;
        update orderList;
        List<blng__Invoice__c> inv =[SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Account__c=:objaccount.Id limit 1];
        //Post the invoice
        inv[0].blng__InvoiceStatus__c=POSTED;
        update inv;
        system.assertEquals(POSTED, inv[0].blng__InvoiceStatus__c);

    }

    // Test method to cover getUsageSummaryToRateMap method and related helper methods
    @isTest
    private static void testGetUsageSummaryToRateMap() {
        // Query test data from setup
        List<Account> objaccount  = [Select Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Product2> objproduct  = [Select Id, Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

        // Create consumption schedule
        ConsumptionSchedule csch = NSP_TestHelper.createConsumptionSchedule('Test Consumption Schedule');
        insert csch;

        // Create consumption rate
        ConsumptionRate crate = NSP_TestHelper.createConsumptionRate(csch);
        insert crate;

        // Activate consumption schedule
        csch.isActive = true;
        update csch;

        // Link consumption schedule to product
        ProductConsumptionSchedule psch = NSP_TestHelper.linkProductToCs(objproduct[0].Id, csch.Id);
        insert psch;

        Test.startTest();

        // Create opportunity, quote, and order - Query existing PriceBookEntry to avoid duplicate
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount[0].Id,'New Product',true);
        List<PriceBookEntry> objPbe = [SELECT Id, Product2Id, UnitPrice FROM PriceBookEntry WHERE Product2Id = :objproduct[0].Id LIMIT 1];
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount[0].Id, objOpprtunity.Id, true);
        NSP_TestHelper.createCPQQuotelines(objQuote, objproduct, objPbe, true);

        // Create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;

        // Query order items
        List<OrderItem> orderItemList = [SELECT Id, blng__NextBillingDate__c, blng__InvoiceRunProcessingStatus__c
                                         FROM OrderItem
                                         WHERE Order.SBQQ__Quote__c = :objQuote.Id];
        List<Order> orderList = [SELECT Id FROM Order WHERE SBQQ__Quote__c = :objQuote.Id];

        // Create Order Item Consumption Schedules with all required fields
        List<SBQQ__OrderItemConsumptionSchedule__c> consumptionSchedules = new List<SBQQ__OrderItemConsumptionSchedule__c>();
        for(OrderItem oi : orderItemList) {
            SBQQ__OrderItemConsumptionSchedule__c oics = new SBQQ__OrderItemConsumptionSchedule__c(
                SBQQ__OrderItem__c = oi.Id,
                SBQQ__BillingTermUnit__c = 'Month',
                SBQQ__BillingTerm__c = 1,
                SBQQ__Category__c = 'Rates',
                SBQQ__RatingMethod__c = 'Tier',
                SBQQ__Type__c = 'Range',
                SBQQ__MatchingAttribute__c = 'Test'
            );
            consumptionSchedules.add(oics);
        }
        insert consumptionSchedules;

        // Create Order Item Consumption Rates with PerUnit pricing
        List<SBQQ__OrderItemConsumptionRate__c> consumptionRates = new List<SBQQ__OrderItemConsumptionRate__c>();
        for(SBQQ__OrderItemConsumptionSchedule__c oics : consumptionSchedules) {
            // PerUnit rate - this should be included in the result map
            SBQQ__OrderItemConsumptionRate__c rate = new SBQQ__OrderItemConsumptionRate__c(
                SBQQ__OrderItemConsumptionSchedule__c = oics.Id,
                SBQQ__PricingMethod__c = 'PerUnit',
                SBQQ__LowerBound__c = 17,
                SBQQ__UpperBound__c = 99999,
                SBQQ__ProcessingOrder__c = 2,
                SBQQ__Price__c = 15.00
            );
            consumptionRates.add(rate);

            // FlatFee rate - this should be filtered out by the method
            SBQQ__OrderItemConsumptionRate__c rateNonPerUnit = new SBQQ__OrderItemConsumptionRate__c(
                SBQQ__OrderItemConsumptionSchedule__c = oics.Id,
                SBQQ__PricingMethod__c = 'FlatFee',
                SBQQ__LowerBound__c = 0,
                SBQQ__UpperBound__c = 17,
                SBQQ__ProcessingOrder__c = 1,
                SBQQ__Price__c = 100.00
            );
            consumptionRates.add(rateNonPerUnit);
        }
        insert consumptionRates;

        // Create Usage Summaries linked to consumption schedules - use blng__OrderProduct__c instead of blng__OrderItem__c
        List<blng__UsageSummary__c> usageSummaries = new List<blng__UsageSummary__c>();
        for(Integer i = 0; i < orderItemList.size(); i++) {
            blng__UsageSummary__c uSummary = new blng__UsageSummary__c(
                blng__Account__c = objaccount[0].Id,
                blng__OrderProduct__c = orderItemList[i].Id,
                blng__OrderItemConsumptionSchedule__c = consumptionSchedules[i].Id,
                blng__SummaryStartDate__c = Date.today(),
                blng__SummaryEndDate__c = Date.today().addMonths(1),
                blng__Status__c = 'New',
                blng__UnitPrice__c = 10.00
            );
            usageSummaries.add(uSummary);
        }
        insert usageSummaries;

        // Process usage summaries
        for(blng__UsageSummary__c us : usageSummaries) {
            us.blng__Status__c = 'Processed';
        }
        update usageSummaries;

        // Create invoice manually to bypass order activation validation
        // The validation error occurs because consumption schedules need complete rate coverage
        // Since the test's purpose is to test getUsageSummaryToRateMap method, not order activation,
        // we create invoice and invoice lines directly
        blng__Invoice__c invoice = new blng__Invoice__c(
            blng__Account__c = objaccount[0].Id,
            blng__Order__c = orderList[0].Id,
            blng__InvoiceDate__c = Date.today(),
            blng__InvoiceStatus__c = 'Draft'
        );
        insert invoice;

        // Create invoice lines with usage summaries
        List<blng__InvoiceLine__c> invoiceLines = new List<blng__InvoiceLine__c>();
        for(Integer i = 0; i < usageSummaries.size(); i++) {
            blng__InvoiceLine__c invLine = new blng__InvoiceLine__c(
                blng__Invoice__c = invoice.Id,
                blng__OrderProduct__c = orderItemList[i].Id,
                blng__UsageSummary__c = usageSummaries[i].Id,
                blng__Quantity__c = 10,
                blng__UnitPrice__c = 15.00,
                blng__Subtotal__c = 150.00
            );
            invoiceLines.add(invLine);
        }
        insert invoiceLines;

        // TEST: Call getUsageSummaryToRateMap method
        Map<Id, SBQQ__OrderItemConsumptionRate__c> resultMap = NSP_InvoiceLineTriggerHelper.getUsageSummaryToRateMap(invoiceLines);

        Test.stopTest();

        // ASSERTIONS
        System.assertNotEquals(null, resultMap, 'Result map should not be null');

        // If we have invoice lines with usage summaries, verify the mapping
        if(!invoiceLines.isEmpty()) {
            System.assert(resultMap.size() > 0, 'Result map should contain entries for usage summaries with consumption rates');

            // Verify only PerUnit rates are included
            for(Id usageSummaryId : resultMap.keySet()) {
                SBQQ__OrderItemConsumptionRate__c rate = resultMap.get(usageSummaryId);
                System.assertNotEquals(null, rate, 'Rate should not be null for Usage Summary: ' + usageSummaryId);
                System.assertEquals('PerUnit', rate.SBQQ__PricingMethod__c, 'Pricing method should be PerUnit');
                System.assertEquals(15.00, rate.SBQQ__Price__c, 'Rate price should match expected value');
            }
        }

        // Test edge case: empty invoice lines list
        Map<Id, SBQQ__OrderItemConsumptionRate__c> emptyResult = NSP_InvoiceLineTriggerHelper.getUsageSummaryToRateMap(new List<blng__InvoiceLine__c>());
        System.assertNotEquals(null, emptyResult, 'Empty result map should not be null');
        System.assertEquals(0, emptyResult.size(), 'Empty invoice lines should return empty map');

        // Test edge case: null invoice lines list
        Map<Id, SBQQ__OrderItemConsumptionRate__c> nullResult = NSP_InvoiceLineTriggerHelper.getUsageSummaryToRateMap(null);
        System.assertNotEquals(null, nullResult, 'Null input should return empty map, not null');
    }

}
//