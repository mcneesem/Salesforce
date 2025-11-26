@isTest
private class OrderItemPriceUpdateTest {

    @TestSetup
    private static void createTestData() {
        OrderItemPriceUpdateBatchSettings__c sett = new OrderItemPriceUpdateBatchSettings__c();
        sett.IsEnabled__c = true;
        sett.BatchSize__c = 1;
        sett.MonitorEmailAddresses__c = 'test@invalid.com';
        insert sett;

        NSP_ContactTriggerHandler.TriggerDisabled = true;
        blng__BillingRule__c objBillingRule = NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c objRevRecRule =  NSP_TestHelper.createRevrecRule('1');
        blng__TaxRule__c objTaxRule = NSP_TestHelper.createRevTaxRule();

        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(objaccount.id, true);

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.Id;
        objproduct.blng__RevenueRecognitionRule__c = objRevRecRule.Id;
        objproduct.blng__TaxRule__c = objTaxRule.Id;
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_Convert_to_Asset__c = true;
        objproduct.NSP_ServiceAssetCategory__c = 'WX_WA';
        insert objproduct;

        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Business',false);
        objOpprtunity.StageName = NSP_SalesConstants.ANALYSIS_STAGE;

        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        insert objOpprtunity;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        List<SBQQ__QuoteLine__c> qtLines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);

        ConsumptionSchedule NewSchedule = NSP_TestHelper.createConsumptionSchedule('New Schedule');
        insert NewSchedule;

        NSP_TestHelper.createConsumptionRate(NewSchedule);
        NSP_TestHelper.linkProductToCs(objproduct.id,NewSchedule.id);

        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        objQuote.SBQQ__Status__c = 'Approved';

        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        update objQuote;
        NSP_OrderItemTriggerHandler.TriggerDisabled = false;

        List<OrderItem> op = [SELECT id FROM OrderItem];
        SBQQ__OrderItemConsumptionSchedule__c OPCS = new SBQQ__OrderItemConsumptionSchedule__c();
        OPCS.Name = 'New Schedule';
        OPCS.SBQQ__BillingTerm__c = 1;
        OPCS.SBQQ__BillingTermUnit__c = 'Month';
        OPCS.SBQQ__Category__c = 'Rates';
        OPCS.SBQQ__ConsumptionSchedule__c = NewSchedule.id;
        OPCS.SBQQ__OrderItem__c = op[0].id;
        OPCS.SBQQ__RatingMethod__c = 'Tier';
        OPCS.SBQQ__Type__c = 'Range';
        OPCS.blng__BillingRule__c = objBillingRule.id;
        OPCS.blng__TaxRule__c = objTaxRule.id;
        OPCS.blng__RevenueRecognitionRule__c = objRevRecRule.id;

        try{
            SBQQ.TriggerControl.disable();
            insert OPCS;
        }finally{
            SBQQ.TriggerControl.enable();
        }

        List<SBQQ__OrderItemConsumptionRate__c> OICSList = new List<SBQQ__OrderItemConsumptionRate__c>();

        SBQQ__OrderItemConsumptionRate__c OICR = new SBQQ__OrderItemConsumptionRate__c();
        OICR.Name = 'New Rate per unit';
        OICR.SBQQ__LowerBound__c = 0;
        OICR.SBQQ__Price__c = 10;
        OICR.SBQQ__PricingMethod__c = 'PerUnit';
        OICR.SBQQ__ProcessingOrder__c = 1;
        OICR.SBQQ__OrderItemConsumptionSchedule__c = OPCS.id;
        OICR.SBQQ__UpperBound__c = 10;
        OICSList.add(OICR);

        SBQQ__OrderItemConsumptionRate__c OICR2 = new SBQQ__OrderItemConsumptionRate__c();
        OICR2.Name = 'New Rate';
        OICR2.SBQQ__LowerBound__c = 0;
        OICR2.SBQQ__Price__c = 10;
        OICR2.SBQQ__PricingMethod__c = 'FlatFee';
        OICR2.SBQQ__ProcessingOrder__c = 1;
        OICR2.SBQQ__OrderItemConsumptionSchedule__c = OPCS.id;
        OICR2.SBQQ__UpperBound__c = 10;
        OICSList.add(OICR2);


        try{
            SBQQ.TriggerControl.disable();
            insert OICSList;
        }finally{
            SBQQ.TriggerControl.enable();
        }

        List<Order> orderList = [SELECT id, Status, NSP_Rev_Rec_Rules_Reviewed__c FROM Order LIMIT 1];
        orderList[0].NSP_Rev_Rec_Rules_Reviewed__c = true;
        update orderList;
        orderList[0].Status = 'Activated';
        update orderList;

        Contract con = new Contract();
        con.SBQQ__Order__c = orderList[0].id;
        con.AccountId = objaccount.id;
        insert con;
    }

    @isTest
    private static void test_OrderItemPriceUpdate() {
        Test.startTest();
        List<Account> accList = [SELECT id FROM Account LIMIT 1];
        Asset astObj = new Asset();
        astObj.Name = 'testAsset';
        astObj.AccountId = accList[0].id;
        astObj.Status = 'Active';


        OrderItem op = [
            SELECT
                Id ,
                Monthly_Minimum_Price_Increase_Type__c ,
                Monthly_Minimum_Price_Increase_Value__c ,
                Per_Unit_Price_Increase_Type__c ,
                Per_Unit_Price_Increase_Value__c ,
                Price_Increase_Status__c ,
                Last_Batch_Execution_Date__c,
                SBQQ__QuotedListPrice__c ,
                blng__BillableUnitPrice__c ,
                UnitPrice,
                Price_Update_Records__c ,
                OrderId ,
                SBQQ__QuotedQuantity__c ,
                NSP_ServiceAsset__c
            FROM OrderItem
            LIMIT 1
        ];
        op.Monthly_Minimum_Price_Increase_Type__c = 'Amount';
        op.Monthly_Minimum_Price_Increase_Value__c = 1;
        op.Per_Unit_Price_Increase_Type__c = 'Percentage';
        op.Per_Unit_Price_Increase_Value__c = 1;
        op.Price_Increase_Status__c = 'Pending';
        op.Price_Update_Records__c = 'OrderItem;SBQQ__OrderItemConsumptionRate__c;SBQQ__Subscription__c;SBQQ__SubscriptionConsumptionRate__c';
        op.Pricing_Model__c = 'Lasso';
        astObj.NSP_OrderProduct__c = op.id;
        insert astObj;
        op.NSP_ServiceAsset__c = astObj.id;

        update op;

        SBQQ__Subscription__c sub = new SBQQ__Subscription__c();

        sub.SBQQ__OrderProduct__c = op.id;
        sub.SBQQ__Quantity__c = 5;

        insert sub;


        if(OrderItemBatchController.checkPermission()){
            OrderItemBatchController.startBatchJob();
        }
        Test.stopTest();

        List<SBQQ__OrderItemConsumptionRate__C> opRate = [
            SELECT Id , SBQQ__Price__c
            FROM SBQQ__OrderItemConsumptionRate__c
            WHERE Name = 'New Rate per unit'
        ];
        system.assertEquals(opRate[0].SBQQ__Price__c, 10.1);
    }

}
//