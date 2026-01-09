@isTest
private class OrderItemConsumptionRateUpdaterTest {
    //covers OrderItemConsumptionRateFieldsUpdater.cls

    @testSetup
    private static void setupTestData(){
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
        NSP_UsageSummaryTriggerHandler.TriggerDisabled=true;

        Account objaccount = NSP_TestHelper.createAccount(true);//create an account
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule(); //creates billing rule
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule('Test');//creates revenue recogintion rule
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule(); //creates tax rule

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);  //Product Creation
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        insert objproduct;

        // create consumption schedule
        ConsumptionSchedule csch =  NSP_TestHelper.createConsumptionSchedule('IWX Consumption');
        insert csch;
        // create FlatFee consumtpion rate
        ConsumptionRate  crate =  NSP_TestHelper.createConsumptionRate(csch);
        insert crate;
        crate.UpperBound = 11;
        update crate;

        //create PerUnit Consumption rate
        ConsumptionRate perUnitCrate = new ConsumptionRate();
        perUnitCrate.LowerBound = 11;
        perUnitCrate.UpperBound = 9999;
        perUnitCrate.Price = 25;
        perUnitCrate.PricingMethod = 'PerUnit';
        perUnitCrate.ProcessingOrder = 2;
        perUnitCrate.ConsumptionScheduleId = csch.id;
        insert perUnitCrate;

        // activate consumption schedule
        csch.isActive = true;
        update csch;
        // link consumption schedule to product
        ProductConsumptionSchedule psch = NSP_TestHelper.linkProductToCs(objproduct.id,csch.id );
        insert psch;
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;

        System.assertEquals(true, csch.IsActive, 'Consumption schedule must be active');
        System.assertNotEquals(null, crate.Id, 'Flat rate must persist');
        System.assertEquals('PerUnit', perUnitCrate.PricingMethod, 'Per-unit rate must persist');
    }

    @IsTest
    private static void updatesOrderItemRates_whenRatesExist() {
        List<Order> theOrder = [
            SELECT Id, NSP_Rev_Rec_Rules_Reviewed__c, AccountId
            FROM Order
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, theOrder[0], 'Expected an Order created from the Quote');

        List<OrderItem> items = [
            SELECT Id, OrderId, blng__BillingAccount__c,
                   NSP_Consumption_Rate_Flat_Price__c,
                   NSP_Consumption_Rate_Per_Unit__c
            FROM OrderItem
            WHERE OrderId = :theOrder[0].Id
        ];
        System.assert(items.size() > 0, 'Expected at least one OrderItem for the Order');

        List<ConsumptionSchedule> csch = [
            SELECT Id FROM ConsumptionSchedule WHERE IsActive = true LIMIT 1
        ];
        SBQQ__OrderItemConsumptionSchedule__c oics = NSP_TestHelper.createOItemConsumptionSchdeule(items, csch[0]);

        SBQQ__OrderItemConsumptionRate__c flat = NSP_TestHelper.createOtemConsumptionRate(oics);
        flat.SBQQ__UpperBound__c = 11;
        update flat;

        SBQQ__OrderItemConsumptionRate__c perUnit = new SBQQ__OrderItemConsumptionRate__c(
            SBQQ__LowerBound__c = 11,
            SBQQ__UpperBound__c = 9999,
            SBQQ__ProcessingOrder__c = 2,
            SBQQ__PricingMethod__c = 'PerUnit',
            SBQQ__Price__c = 25,
            SBQQ__OrderItemConsumptionSchedule__c = oics.Id
        );
        insert perUnit;

        List<SBQQ__OrderItemConsumptionRate__c> rates = [
            SELECT Id, SBQQ__PricingMethod__c, SBQQ__Price__c, SBQQ__LowerBound__c, SBQQ__UpperBound__c
            FROM SBQQ__OrderItemConsumptionRate__c
            WHERE SBQQ__OrderItemConsumptionSchedule__c = :oics.Id
            ORDER BY SBQQ__ProcessingOrder__c
        ];
        System.assertEquals(2, rates.size(), 'Expected flat and per-unit rates');

        Test.startTest();
        OrderItemConsumptionRateFieldsUpdater.updateOrderItems(new List<Id>{ theOrder[0].Id });
        OrderItemConsumptionRateFieldsUpdater.testHandleException(null,null);
        Test.stopTest();

        List<OrderItem> updated = [
            SELECT Id, NSP_Consumption_Rate_Flat_Price__c, NSP_Consumption_Rate_Per_Unit__c
            FROM OrderItem WHERE Id = :items[0].Id
        ];
        System.assertNotEquals(null, updated[0].NSP_Consumption_Rate_Flat_Price__c, 'Flat price should be populated');
        System.assertEquals(25, updated[0].NSP_Consumption_Rate_Per_Unit__c, 'Per-unit price should be 25');
    }

    @IsTest
    private static void doesNotChangeRates_whenNoScheduleLinked() {
        List<Order> theOrder = [
            SELECT Id FROM Order ORDER BY CreatedDate DESC LIMIT 1
        ];
        List<OrderItem> oi = [
            SELECT Id, NSP_Consumption_Rate_Flat_Price__c, NSP_Consumption_Rate_Per_Unit__c
            FROM OrderItem
            WHERE OrderId = :theOrder[0].Id
            LIMIT 1
        ];
        Decimal beforeFlat = oi[0].NSP_Consumption_Rate_Flat_Price__c;
        Decimal beforePerUnit = oi[0].NSP_Consumption_Rate_Per_Unit__c;

        Test.startTest();
        OrderItemConsumptionRateFieldsUpdater.updateOrderItems(new List<Id>{ theOrder[0].Id });
        Test.stopTest();

        List<OrderItem> after = [
            SELECT Id, NSP_Consumption_Rate_Flat_Price__c, NSP_Consumption_Rate_Per_Unit__c
            FROM OrderItem WHERE Id = :oi[0].Id
        ];
        System.assertEquals(beforeFlat, after[0].NSP_Consumption_Rate_Flat_Price__c, 'Flat price should remain unchanged without OICS');
        System.assertEquals(beforePerUnit, after[0].NSP_Consumption_Rate_Per_Unit__c, 'Per-unit price should remain unchanged without OICS');
    }
}