@isTest
private with sharing class OrderTriggerActivateOrderProductTest {

    @testSetup
    private static void setupTestData() {
        //PriceBook
        Id stdPriceBookId = Test.getStandardPricebookId();

        //Billing Rule
        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test InsBR';
        brObj.blng__GenerateInvoices__c = NSP_CPQConstants.YES;
        brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        brObj.blng__PartialPeriodTreatment__c = 'Combine';
        brObj.blng__PeriodTreatmentForBTDO__c = 'Combine';
        insert brObj;

        //Finance Book
        blng__FinanceBook__c blngFinanceRec = new blng__FinanceBook__c();
        blngFinanceRec.blng__Active__c = true;
        blngFinanceRec.blng__FinancePeriodDuration__c = NSP_CPQConstants.MONTHLY;
        blngFinanceRec.Name = 'Insperity Salesforce Finance Book';
        blngFinanceRec.blng__PeriodType__c = 'Accounting';
        insert blngFinanceRec;

        //Invoice Plan
        blng__InvoicePlan__c invPlanRecord = new blng__InvoicePlan__c();
        invPlanRecord.blng__Active__c = true;
        invPlanRecord.blng__BillingScheduleCreation__c = 'Order Product Activation';
        invPlanRecord.Name = NSP_CPQConstants.INVOICE_PLAN;
        insert invPlanRecord;

        //Insert Invoice Plan Line
        List<blng__InvoicePlan__c> invPlanRec = [Select Id from blng__InvoicePlan__c WHERE Id!=Null];
        blng__InvoicePlanLine__c planLineObj = new blng__InvoicePlanLine__c();
        planLineObj.Name = 'Invoiced at Project Completion';
        planLineObj.blng__Type__c = 'Percent';
        planLineObj.blng__Percentage__c = 100;
        planLineObj.blng__CommencementDate__c = 'Order Product Activation';
        planLineObj.blng__CommencementDateOffsetUnits__c = 'Days';
        planLineObj.NSP_Billing_Commencement_Trigger__c = 'Project Completion';
        planLineObj.blng__ProcessingOrder__c = 1.0;
        planLineObj.blng__InvoicePlan__c = invPlanRec[0].Id;
        insert planLineObj;

        //Billing Treatment
        blng__BillingTreatment__c blngTreatmentRecord = new blng__BillingTreatment__c();
        blngTreatmentRecord.blng__Active__c = true;
        blngTreatmentRecord.blng__BillingRule__c = brObj.Id;
        blngTreatmentRecord.blng__BillingFinanceBook__c = blngFinanceRec.Id;
        blngTreatmentRecord.blng__InvoicePlan__c = invPlanRecord.Id;
        insert blngTreatmentRecord;

        //Billing Revenue Recognition
        blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
        rrObj.blng__Active__c = true;
        rrObj.blng__CreateRevenueSchedule__c = 'No';
        insert rrObj;

        //Billing Tax Rule
        blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
        taxRuleObj.blng__Active__c = true;
        taxRuleObj.blng__TaxableYesNo__c = 'No';
        insert taxRuleObj;

        //Billing GLRule
        blng__GLRule__c taxGLRule = new blng__GLRule__c(
            blng__Active__c = true,
            blng__Notes__c = 'Created to record: Sales Tax Allocation',
            Name = 'Test GLRule'
        );
        insert taxGLRule;

        // Create a test Product
        Product2 testProduct = NSP_TestHelper.createProduct('Test Product', false);
        testProduct.ProductCode = 'IWXBundleW2';
        testProduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        testProduct.SBQQ__BillingType__c = 'Arrears';
        testProduct.NSP_Priority_Amendment__c = 11.0;
        testProduct.SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        testProduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJ_GO_LIVE;
        testProduct.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        testProduct.blng__BillingRule__c = brObj.Id;
        testProduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        testProduct.blng__TaxRule__c = taxRuleObj.Id;
        insert testProduct;

        List<Product2> productList = new List<Product2>();
        productList.add(testProduct);

        // Create a test PricebookEntry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true,
            Pricebook2Id = stdPriceBookId
        );
        insert testPricebookEntry;

        List<PriceBookEntry> priceBookEntList = new List<PriceBookEntry>();
        priceBookEntList.add(testPricebookEntry);

        //Account
        Account objaccount = NSP_TestHelper.createAccount(false);
        objaccount.Name = 'Insperity WO Billing Account';
        insert objaccount;

        //Opportunity
        Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(
            objaccount.Id,
            'New Product',
            false
        );
        insert objOpportunity;

        // Create a test Contract
        Contract testContract = new Contract(
            AccountId = objaccount.Id,
            Status = 'Draft',
            StartDate = System.today()
        );
        insert testContract;

        //Contact Creation
        Contact objCon = NSP_TestHelper.createContact(objaccount.id, false);
        objCon.NSP_Sales_Tax_Contact_Key__c = '123';
        objCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Sales Tax').getRecordTypeId();
        objCon.NSP_Sales_Tax_Contact_Counter__c = 2;
        insert objCon;

        //Project Creation
        pse__Proj__c hcmProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        hcmProject.Name = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.pse__Start_Date__c = Date.Today();
        hcmProject.pse__Account__c = objaccount.Id;
        hcmProject.TemplateName__c = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.Project_Implementer__c = UserInfo.getUserId();
        insert hcmProject;

        Test.startTest();

        //Quote
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpportunity.Id, false);
        objQuote.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_NEW;
        objQuote.SBQQ__primary__c = true;
        upsert objQuote;

        //Quote Line
        List<SBQQ__QuoteLine__c> objQuoteLine = NSP_TestHelper.createCPQQuotelines(objQuote, productList, priceBookEntList, false);

        insert objQuoteLine;
        // Create a test Order
        Order testOrder = new Order(
            AccountId = objaccount.Id,
            SBQQ__Quote__c = objQuote.Id,
            EffectiveDate = System.today(),
            Status = 'Draft',
            Pricebook2Id =stdPriceBookId
        );
        testOrder.blng__BillingAccount__c = objaccount.Id;
        insert testOrder;

        // Create a test OrderItem
        blng__BillingRule__c billingRule = NSP_TestHelper.createBillingRule();

        OrderItem testOrderItem = new OrderItem();
        testOrderItem.OrderId = testOrder.Id;
        testOrderItem.PricebookEntryId = testPricebookEntry.Id;
        testOrderItem.Quantity = 1;
        testOrderItem.UnitPrice = 100;
        testOrderItem.SBQQ__Status__c = 'Draft';
        testOrderItem.blng__BillingRule__c = brObj.Id;
        testOrderItem.blng__BillingTreatment__c=blngTreatmentRecord.Id;
        testOrderItem.blng__RevenueRecognitionRule__c = rrObj.Id;
        testOrderItem.blng__BillingGLRule__c = taxGLRule.Id;
        testOrderItem.blng__TaxRule__c = taxRuleObj.Id;
        insert testOrderItem;
        Test.stopTest();
    }

    @isTest
    private static void testActivateOrderProduct() {
        // Retrieve the test Order
        Order testOrder = [
            SELECT Id, Project_Status__c, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c
            FROM Order
            LIMIT 1
        ];

        // Retrieve the test OrderItem
        OrderItem testOrderItem = [
            SELECT Id, OrderId, SBQQ__Status__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate
            FROM OrderItem
            LIMIT 1
        ];

        // Set the Order and OrderItem fields as per the conditions in the activateOrderProduct method
        testOrder.NSP_Project_Go_Live_Date__c = System.today();
        testOrder.Type = 'New Product';


        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJ_GO_LIVE;
        testOrderItem.Product2.NSP_Partial_Period_Free_Treatment__c = false;
        testOrderItem.SBQQ__BillingFrequency__c = 'Monthly';
        testOrderItem.NSP_OrderProductStartDate__c = '1st of the month';
        testOrderItem.NSP_AnniversaryBlngApplicable__c = true;
        testOrderItem.NSP_ReCalculation_Status_Internal__c = 'Not Applicable';
        testOrderItem.ServiceDate = System.today();
        testOrderItem.SBQQ__RequiredBy__c = null;
        testOrderItem.EndDate = System.today().toStartOfMonth().addMonths(2);


        Test.startTest();
        update testOrder;
        update testOrderItem;
        // Call the activateOrderProduct method
        OrderTriggerActivateOrderProduct.activateOrderProduct(new List<Order>{testOrder}, new Set<Id>{testOrder.Id});
        Test.stopTest();
    }

    @isTest
    private static void testActivateOrderProduct2() {
        // Retrieve the test Order
        Order testOrder = [
            SELECT Id, Project_Status__c, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c
            FROM Order
            LIMIT 1
        ];

        // Retrieve the test OrderItem
        OrderItem testOrderItem = [
            SELECT Id, OrderId, SBQQ__Status__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate
            FROM OrderItem
            LIMIT 1
        ];

        // Set the Order and OrderItem fields as per the conditions in the activateOrderProduct method
        testOrder.NSP_Project_Go_Live_Date__c = System.today();
        testOrder.Type = 'New Product';
        testOrder.EffectiveDate = System.today().toStartOfMonth();

        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJ_GO_LIVE;
        testOrderItem.Product2.NSP_Partial_Period_Free_Treatment__c = false;
        testOrderItem.SBQQ__BillingFrequency__c = 'Monthly';
        testOrderItem.NSP_OrderProductStartDate__c = '1st of the month';
        testOrderItem.NSP_AnniversaryBlngApplicable__c = true;
        testOrderItem.NSP_ReCalculation_Status_Internal__c = 'Not Applicable';
        testOrderItem.ServiceDate = System.today().toStartOfMonth();
        testOrderItem.SBQQ__RequiredBy__c = null;
        testOrderItem.EndDate = System.today().toStartOfMonth().addMonths(2);

        Test.startTest();
        update testOrder;
        update testOrderItem;
        // Call the activateOrderProduct method
        OrderTriggerActivateOrderProduct.activateOrderProduct(new List<Order>{testOrder}, new Set<Id>{testOrder.Id});
        Test.stopTest();
    }

    @isTest
    private static void testActivateOrderProductAmend() {

        Opportunity opp = [select id,NSP_TransactionType__c from Opportunity LIMIT 1];

        opp.NSP_TransactionType__c = 'Amendment/Supplemental';

        update opp;

        // Retrieve the test Order
        Order testOrder = [
            SELECT Id, Project_Status__c, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c
            FROM Order
            LIMIT 1
        ];

        // Retrieve the test OrderItem
        OrderItem testOrderItem = [
            SELECT Id, OrderId, SBQQ__Status__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate
            FROM OrderItem
            LIMIT 1
        ];

        // Set the Order and OrderItem fields as per the conditions in the activateOrderProduct method
        testOrder.NSP_Project_Go_Live_Date__c = System.today();
        testOrder.Type = 'Amendment';
        testOrder.EffectiveDate = System.today().toStartOfMonth();

        testOrderItem.SBQQ__ProductSubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
        testOrderItem.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
        testOrderItem.Product2.NSP_Partial_Period_Free_Treatment__c = true;
        testOrderItem.SBQQ__BillingFrequency__c = 'Monthly';
        testOrderItem.ServiceDate = System.today().toStartOfMonth();
        testOrderItem.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.PROJ_GO_LIVE;
        testOrderItem.NSP_OrderProductStartDate__c = '1st of the month';

        Test.startTest();
        update testOrder;
        update testOrderItem;
        // Call the activateOrderProduct method
        OrderTriggerActivateOrderProduct.activateOrderProduct(new List<Order>{testOrder}, new Set<Id>{testOrder.Id});
        Test.stopTest();
    }

    @isTest
    private static void testActivateOrderProductAmend2() {

        Opportunity opp = [select id,NSP_TransactionType__c from Opportunity LIMIT 1];
        opp.NSP_TransactionType__c = 'Amendment/Supplemental';
        update opp;

        SBQQ__QuoteLine__c objQl = [
            SELECT id,SBQQ__ProductSubscriptionType__c,SBQQ__Quantity__c ,SBQQ__PriorQuantity__c ,SBQQ__SubscriptionType__c
            FROM SBQQ__QuoteLine__c
        ];
        objQl.SBQQ__ProductSubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
        objQl.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
        objQl.SBQQ__SubscriptionTerm__c =1;


        // Retrieve the test Order
        Order testOrder = [
            SELECT Id, Project_Status__c, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c
            FROM Order
            LIMIT 1
        ];

        // Retrieve the test OrderItem
        OrderItem testOrderItem = [
            SELECT Id, OrderId, SBQQ__Status__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate
            FROM OrderItem
            LIMIT 1
        ];

        // Set the Order and OrderItem fields as per the conditions in the activateOrderProduct method
        testOrder.NSP_Project_Go_Live_Date__c = System.today();
        testOrder.Type = 'Amendment';
        testOrder.EffectiveDate = System.today().toStartOfMonth();

        //testOrderItem.NSP_Order_Activation_Trigger__c = 'Immediate';
        testOrderItem.SBQQ__QuoteLine__c =objQl.Id;
        testOrderItem.SBQQ__ProductSubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
        testOrderItem.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
        testOrderItem.Product2.NSP_Partial_Period_Free_Treatment__c = true;
        testOrderItem.SBQQ__BillingFrequency__c = 'Monthly';
        testOrderItem.ServiceDate = System.today().toStartOfMonth();
        testOrderItem.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.PROJ_GO_LIVE;


        Test.startTest();
        update objQl;
        update testOrder;
        update testOrderItem;
        // Call the activateOrderProduct method
        OrderTriggerActivateOrderProduct.activateOrderProduct(new List<Order>{testOrder}, new Set<Id>{testOrder.Id});
        Test.stopTest();
    }

    @isTest
    private static void testActivateOrderProductAmend3() {
        //Catching the Exception
        Opportunity opp = [select id,NSP_TransactionType__c from Opportunity LIMIT 1];
        opp.NSP_TransactionType__c = 'Amendment/Supplemental';
        update opp;

        SBQQ__QuoteLine__c objQl = [SELECT id,SBQQ__ProductSubscriptionType__c,SBQQ__Quantity__c ,SBQQ__PriorQuantity__c ,SBQQ__SubscriptionType__c from SBQQ__QuoteLine__c];
        objQl.SBQQ__ProductSubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
        objQl.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
        objQl.SBQQ__SubscriptionTerm__c =1;
        objQl.SBQQ__Quantity__c = 30;
        objQl.SBQQ__PriorQuantity__c = 5;

        // Retrieve the test Order
        Order testOrder = [SELECT Id, Project_Status__c, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c FROM Order LIMIT 1];

        // Retrieve the test OrderItem
        OrderItem testOrderItem = [SELECT Id, OrderId, SBQQ__Status__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate FROM OrderItem LIMIT 1];

        // Set the Order and OrderItem fields as per the conditions in the activateOrderProduct method
        testOrder.NSP_Project_Go_Live_Date__c = System.today();
        testOrder.Type = 'Amendment';
        testOrder.EffectiveDate = System.today().toStartOfMonth();

        testOrderItem.SBQQ__QuoteLine__c =objQl.Id;
        testOrderItem.SBQQ__ProductSubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
        testOrderItem.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
        testOrderItem.Product2.NSP_Partial_Period_Free_Treatment__c = true;
        testOrderItem.SBQQ__BillingFrequency__c = 'Monthly';
        testOrderItem.NSP_AnniversaryBlngApplicable__c = true;
        testOrderItem.ServiceDate = System.today().toStartOfMonth();
        testOrderItem.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.PROJ_GO_LIVE;

        Test.startTest();
        update objQl;
        update testOrder;
        update testOrderItem;
        // Call the activateOrderProduct method
        OrderTriggerActivateOrderProduct.activateOrderProduct(new List<Order>{testOrder}, new Set<Id>{testOrder.Id});
        Test.stopTest();
    }

}
//