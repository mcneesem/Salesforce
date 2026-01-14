@isTest
private class NSP_RetirementServiceActivationBatchTest {

    @testSetup
    private static void setupTestData() {
        RetirementServiceActivationBatchSettings__c batchSettings = RetirementServiceActivationBatchSettings__c.getOrgDefaults();
        batchSettings.IsEnabled__c = true;
        batchSettings.BatchSize__c = 200;
        upsert batchSettings;

        Order_Settings__c settings = Order_Settings__c.getOrgDefaults();
        upsert settings;
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c = 'YES';
        insert objproduct;

        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test BR';
        brObj.blng__GenerateInvoices__c = 'Yes';
        brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        brObj.blng__PartialPeriodTreatment__c = 'Combine';
        insert brObj;

        blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
        rrObj.blng__Active__c = true;
        rrObj.blng__CreateRevenueSchedule__c = 'No';
        insert rrObj;

        blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
        taxRuleObj.blng__Active__c = true;
        taxRuleObj.blng__TaxableYesNo__c = 'No';
        insert taxRuleObj;

        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct.blng__TaxRule__c = taxRuleObj.Id;
        update objproduct;

        List<Pricebook2> priceBookList = [SELECT Id
                                          FROM Pricebook2
                                          WHERE isStandard = true
                                          LIMIT 1];
        Pricebook2 customPricebook = new Pricebook2(Name = 'Test Price Book', IsActive = true);
        priceBookList.add(customPricebook);
        insert priceBookList;
        Pricebook2 standardPricebook2 = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
        PricebookEntry testPricebookEntry = new PricebookEntry();
        testPricebookEntry.Pricebook2Id = standardPricebook2.Id;
        testPricebookEntry.IsActive = true;
        testPricebookEntry.Product2Id = objproduct.Id;
        testPricebookEntry.UseStandardPrice = false;
        testPricebookEntry.UnitPrice = 0.70;
        insert testPricebookEntry;


        List<blng__GLRule__c> glRuleList = new List<blng__GLRule__c>();
        String note = 'Created to record: Payments';
        blng__GLRule__c glRule1 = new blng__GLRule__c(blng__Active__c = true, blng__Notes__c = note, CurrencyIsoCode = 'USD', Name = 'BPS Cash (Invoice-AR)');
        blng__GLRule__c glRule2 = new blng__GLRule__c(blng__Active__c = true, blng__Notes__c = note, CurrencyIsoCode = 'USD', Name = 'RET Cash (Invoice-AR)');
        blng__GLRule__c glRule3 = new blng__GLRule__c(blng__Active__c = true, blng__Notes__c = note, CurrencyIsoCode = 'USD', Name = 'Recruiting Cash (Invoice-AR)');
        glRuleList.add(glRule1);
        glRuleList.add(glRule2);
        glRuleList.add(glRule3);
        insert glRuleList;

        List<blng__LegalEntity__c> legalEntityList = new List<blng__LegalEntity__c>();
        blng__LegalEntity__c legalEntity1 = new blng__LegalEntity__c(blng__Active__c = true, blng__City__c = 'KINGWOOD', blng__Country__c = 'US', blng__County__c = 'US', blng__State__c = 'TX', blng__Street1__c = '19001 CRESCENT SPRINGS DR', blng__ZipPostalCode__c = '77339-3802', CurrencyIsoCode = 'USD', Name = '29', NSP_Company_Name__c = 'Test Company');
        legalEntityList.add(legalEntity1);
        insert legalEntityList;

        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', true);
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpprtunity.Id, true);
        NSP_TestHelper.createCPQQuotelines(objQuote, new List<Product2>{ objproduct }, new List<PriceBookEntry>{ testPricebookEntry }, true);
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        Test.startTest();
        List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                            FROM Order
                            WHERE SBQQ__Quote__c = :objQuote.Id];
        ords[0].blng__BillingDayOfMonth__c = '10';
        update ords;
        List<OrderItem> orderProductList = new List<OrderItem>();
        OrderItem orderProductRecord = new OrderItem();
        orderProductRecord.PricebookEntryId = testPricebookEntry.Id;
        orderProductRecord.blng__BillingAccount__c = objaccount.Id;
        orderProductRecord.blng__BillingRule__c = brObj.Id;
        orderProductRecord.blng__HoldBilling__c = 'No';
        orderProductRecord.blng__RevenueRecognitionRule__c = rrObj.Id;
        orderProductRecord.blng__TaxStatus__c = 'Warning';
        orderProductRecord.NSP_Action_Type__c = 'Add Product';
        orderProductRecord.NSP_Is_Bundle__c = true;
        orderProductRecord.OrderId = ords[0].Id;
        orderProductRecord.Quantity = 1;
        orderProductRecord.SBQQ__OrderedQuantity__c = 1;
        orderProductRecord.SBQQ__PricingMethod__c = 'List';
        orderProductRecord.SBQQ__ProductSubscriptionType__c = 'Evergreen';
        orderProductRecord.SBQQ__ProrateMultiplier__c = 1;
        orderProductRecord.SBQQ__Status__c = 'Draft';
        orderProductRecord.NSP_Order_Activation_Trigger__c = 'Plan Activation';
        orderProductRecord.SBQQ__SubscriptionTerm__c = 1;
        orderProductRecord.SBQQ__SubscriptionType__c = 'Evergreen';
        orderProductRecord.UnitPrice = 100;
        orderProductList.add(orderProductRecord);
        insert orderProductList;
        Asset assetRecord = new Asset();
        assetRecord.AccountId = objaccount.Id;
        assetRecord.AverageUptimePerDay = 24;
        assetRecord.ConsequenceOfFailure = 'Insignificant';
        assetRecord.Country = 'United States';
        assetRecord.CountryCode = 'US';
        assetRecord.Name = 'Test Asset';
        assetRecord.NSP_Actual_of_Employee_at_Signature__c = 20;
        assetRecord.NSP_All__c = 'All';
        assetRecord.NSP_Product_Line__c = 'Retirement Services';
        assetRecord.NSP_Client_is_Lead_Parent__c = true;
        assetRecord.NSP_Handbook_Status__c = 'New Client';
        assetRecord.NSP_OrderProduct__c = orderProductList[0].Id;
        assetRecord.NSP_Product_Line__c = 'Retirement Services';
        assetRecord.NSP_ProductBundle__c = 'WX';
        assetRecord.Opportunity__c = objOpprtunity.Id;
        assetRecord.Product2Id = objproduct.Id;
        assetRecord.SBQQ__PricingMethod__c = 'List';
        assetRecord.Status = 'Onboarding';
        assetRecord.NSP_Price_Level__c = 'WO';
        insert assetRecord;

        Id planWORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Plan__c' , 'WO' );
        NSP_Plan__c planRecord = new NSP_Plan__c();
        planRecord.RecordTypeId = planWORecordTypeId;
        insert planRecord;
        Id subPlanWORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Plan_SubPlan__c' , 'WO' );
        NSP_Plan_SubPlan__c subplan = new NSP_Plan_SubPlan__c();
        subplan.NSP_Parent_Plan_ID__c = planRecord.Id;
        subplan.NSP_Plan_Type__c = '401K';
        subplan.NSP_Subplan_ID__c = 'Test SP';
        subplan.NSP_Subplan_Name__c = 'Test 1';
        subplan.RecordTypeId = subPlanWORecordTypeId;
        insert subplan;
        Id clientSubPlanWORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Client_Sub_Plan_History__c' , 'WO' );
        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        clientSubPlanHistRec.NSP_Asset__c = assetRecord.Id;
        clientSubPlanHistRec.NSP_End_Date__c = System.today();
        clientSubPlanHistRec.NSP_Start_Date__c = System.today();
        clientSubPlanHistRec.NSP_Current_Subplan__c = true;
        clientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = subplan.Id;
        clientSubPlanHistRec.RecordTypeId = clientSubPlanWORecordTypeId;
        insert clientSubPlanHistRec;
    }

    @isTest
    private static void testBatchMethod() {

        Test.startTest();
        NSP_Client_Sub_Plan_History__c cilentSubPlanRecord = [SELECT Id, NSP_Asset__c, NSP_Asset__r.NSP_OrderProduct__c
                                                              FROM NSP_Client_Sub_Plan_History__c
                                                              WHERE Id != NULL Limit 1];
        NSP_RetirementServiceActivationBatch batchObj = new NSP_RetirementServiceActivationBatch();
        Database.executeBatch(batchObj, 200);
        Test.stopTest();
        List<OrderItem> resultOrderItem = [SELECT Id, SBQQ__Status__c
                                           FROM OrderItem
                                           WHERE Id = :cilentSubPlanRecord.NSP_Asset__r.NSP_OrderProduct__c
                                           Limit 1];
        System.assertEquals(1, resultOrderItem.size());
    }

    @isTest
    private static void testScheduleBatchMethod() {

        Test.startTest();
        String cronExpression = '0 0 2 * * ?';
        String jobId = System.schedule('NSP_RetirementServiceActivationBatch_SCH', cronExpression, new NSP_RetirementServiceActivationBatch_SCH());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger
                          WHERE Id = :jobId];
        Test.stopTest();
        System.assertEquals(cronExpression, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
    }

    @isTest
    private static void testSchedule() {
        Test.startTest();
        NSP_RetirementServiceActivationBatch.schedule();
        Test.stopTest();
    }

}
//