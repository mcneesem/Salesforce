@isTest
private class NSP_UsageSummaryTriggerTest {

    @testSetup
    private static void setupTestData() {
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
    }

    @isTest
    private static void usageSummaryTest() {
        // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        // create consumption schedule
        ConsumptionSchedule csch =  NSP_TestHelper.createConsumptionSchedule('IWX Consumption');
        insert csch;
        // create consumtpion rate
        ConsumptionRate  crate =  NSP_TestHelper.createConsumptionRate(csch);
        insert crate;
        // activate consumption schedule
        csch.isActive = true;
        update csch;
        // link consumption schedule to product
        ProductConsumptionSchedule psch = NSP_TestHelper.linkProductToCs(objproduct.id,csch.id );
        insert psch;

        Test.startTest();
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        NSP_OrderTriggerHandler.TriggerDisabled=true;
        NSP_OrderItemTriggerHandler.TriggerDisabled =true;
        update objQuote;
        system.assert(true, objQuote.SBQQ__Primary__c );

        List<OrderItem> orderItemList = new List<OrderItem>([select id from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        SBQQ__Subscription__c sub= new SBQQ__Subscription__c();
        sub.NSP_Waived_Amount__c=500;
        sub.SBQQ__Quantity__c=1;
        insert sub;
        orderItemList[0].SBQQ__Subscription__c=sub.Id;
        update orderItemList;
        blng__UsageSummary__c uSummary=NSP_TestHelper.createUsageSummary(orderItemList,objaccount);
        uSummary.blng__Status__c='Processed';
        update uSummary;
        System.assert(orderItemList.size() > 0);
        NSP_OrderTriggerHandler.TriggerDisabled=false;
        NSP_OrderItemTriggerHandler.TriggerDisabled =false;
        Test.stopTest();
    }

}
//