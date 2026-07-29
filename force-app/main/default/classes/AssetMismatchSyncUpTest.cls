@isTest
public with sharing class AssetMismatchSyncUpTest {

    @testSetup
    private static void setupTestData() {

        Account acc1 = NSP_TestHelper.createAccount(true);

        Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(acc1.Id, 'New Product', false);
        insert objOpportunity;

        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test BR';
        brObj.blng__GenerateInvoices__c = 'Yes';
        brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        brObj.blng__PartialPeriodTreatment__c = 'Combine';
        insert brObj;

        blng__RevenueRecognitionRule__c recognitionRule = NSP_TestHelper.createRevrecRule('recoRule');

        blng__TaxRule__c objTaxRule = NSP_TestHelper.createRevTaxRule();


        Product2 product1 = NSP_TestHelper.createProduct('Test Product1',false);
        product1.SBQQ__ChargeType__c = 'Recurring';
        product1.SBQQ__BillingType__c = 'Arrears';
        product1.SBQQ__BillingFrequency__c = 'Monthly';
        product1.blng__BillingRule__c = brObj.Id;
        product1.blng__RevenueRecognitionRule__c = recognitionRule.Id;
        product1.blng__TaxRule__c = objTaxRule.Id;
        insert product1;

        PriceBookEntry pe1std = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,false);
        insert pe1std;

        Test.StartTest();
        Order ord1 = new Order (AccountId=acc1.Id,Status='Draft',EffectiveDate=Date.today(),Pricebook2Id=Test.getStandardPricebookId());
        insert ord1;

        List<OrderItem> oiList = new List<OrderItem>();
        OrderItem ordpr1 = new OrderItem (OrderId = ord1.Id, Product2Id=product1.Id, UnitPrice=10.0,Quantity=5,PricebookEntryId=pe1std.Id);
        OrderItem ordpr2 = new OrderItem (OrderId = ord1.Id, Product2Id=product1.Id, UnitPrice=10.0,Quantity=5,PricebookEntryId=pe1std.Id);
        oiList.add(ordpr1);
        oiList.add(ordpr2);
        insert oiList;



        Asset objAsset = new Asset();

        objAsset.Name = 'OrderHelper Test';
        objAsset.AccountId = acc1.Id;
        objAsset.Status = 'Onboarding';
        objAsset.Product2Id = product1.Id;
        objAsset.Opportunity__c = objOpportunity.Id;
        objAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING).getRecordTypeId();
        //SBQQ.TriggerControl.disable();
        insert objAsset;
        //SBQQ.TriggerControl.enable();
        Test.StopTest();
    }

    @isTest
    private static void OrdMismatchTest() {
        //NSP_AssetTriggerHandler.TriggerDisabled = true;
        Account objaccount  = [Select Id, Name from Account LIMIT 1];
        Opportunity objOpp = [SELECT Id,Name FROM Opportunity LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 LIMIT 1];
        Asset objAsset = [Select Id, Name from Asset LIMIT 1];

        List<OrderItem> orderItemList = [SELECT Id,NSP_ServiceAsset__c,NSP_UsageUpperBound__c,NSP_TotalUsageQuantity__c, OrderItemNumber, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c,SBQQ__Activated__c
                                         FROM OrderItem LIMIT 10];

        orderItemList[0].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[0].NSP_ServiceAssetCategory__c = 'Time Wage Import';
        orderItemList[0].SBQQ__Asset__c = objAsset.Id;
        orderItemList[0].Mismatch_AssetId__c = objAsset.Id;
        orderItemList[0].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[1].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[0].NSP_UsageUpperBound__c = 7;

        Test.startTest();
        update orderItemList;

        Map<Id, OrderItem> orderItemNewMap = new Map<Id, OrderItem>();
        Map<Id, String> orderItemNewStringMap = new Map<Id, String>();
        List<String> lstOrdIds = new List<String>();

        for(OrderItem oi : orderItemList){
            OrderItemNewMap.put(oi.Id,oi);
            lstordIds.add(oi.OrderId);
            orderItemNewStringMap.put(oi.Id,String.valueOf(oi));
        }
        List<Order> OrderLst = new List<Order>();

        for(Order ord:[SELECT Id,Mismatch_Asset__c FROM Order WHERE Id IN:lstordIds])
        {
            ord.Mismatch_Asset__c = false;
            ord.NSP_Rev_Rec_Rules_Reviewed__c = true;
            ord.status = NSP_CPQConstants.ORDER_REVIEWED;
            OrderLst.add(ord);
        }

        database.update(OrderLst);

        AssetMismatchSyncUp.assetOrderProductLinkUp(lstordIds);
        Test.stopTest();
        NSP_OrderItemTriggerHelper.testHandleException( null , null );
    }

    @isTest
    private static void AssetMismatchTest() {
        //NSP_AssetTriggerHandler.TriggerDisabled = true;
        Account objaccount  = [Select Id, Name from Account LIMIT 1];
        Opportunity objOpp = [SELECT Id,Name FROM Opportunity LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 LIMIT 1];
        Asset objAsset = [Select Id, Name from Asset LIMIT 1];


        List<OrderItem> orderItemList = [SELECT Id,NSP_ServiceAsset__c,NSP_UsageUpperBound__c,NSP_TotalUsageQuantity__c, OrderItemNumber, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c,SBQQ__Activated__c
                                         FROM OrderItem LIMIT 1];


        Test.startTest();
        orderItemList[0].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[0].NSP_ServiceAssetCategory__c = 'Time Wage Import';
        orderItemList[0].SBQQ__Asset__c = objAsset.Id;
        orderItemList[0].Mismatch_AssetId__c = objAsset.Id;
        orderItemList[0].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[0].NSP_UsageUpperBound__c = 7;


        update orderItemList;

        Map<Id, OrderItem> orderItemNewMap = new Map<Id, OrderItem>();
        Map<Id, String> orderItemNewStringMap = new Map<Id, String>();
        List<String> lstOrdIds = new List<String>();

        for(OrderItem oi : orderItemList){
            OrderItemNewMap.put(oi.Id,oi);
            lstordIds.add(oi.OrderId);
            orderItemNewStringMap.put(oi.Id,String.valueOf(oi));
        }
        List<Order> OrderLst = new List<Order>();

        for(Order ord:[SELECT Id,Mismatch_Asset__c FROM Order WHERE Id IN:lstordIds])
        {
            ord.Mismatch_Asset__c = true;
            OrderLst.add(ord);
        }
        database.update(OrderLst);

        AssetMismatchSyncUp.assetOrderProductLinkUp(lstordIds);
        Test.stopTest();
        NSP_OrderItemTriggerHelper.testHandleException( null , null );
    }

}
//