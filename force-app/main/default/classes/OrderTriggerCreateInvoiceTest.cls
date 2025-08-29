@IsTest
private class OrderTriggerCreateInvoiceTest {
    @TestSetup
    private static void setupTestData() 
    {
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
        
        system.debug('testing'+brObj);
		
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
        
        system.debug('BillingRuleTreatment'+blngTreatmentRecord.blng__BillingRule__c);
		
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
        blng__GLRule__c taxGLRule = new blng__GLRule__c(blng__Active__c = true, 
                                                        blng__Notes__c = 'Created to record: Sales Tax Allocation',
                                                        Name = 'Test GLRule');
        insert taxGLRule;
        
        // Create a test Product
        Product2 testProduct = NSP_TestHelper.createProduct('Test Product', false);
        testProduct.ProductCode = 'IWXBundleW2';
        testProduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        testProduct.SBQQ__BillingType__c = 'Arrears';
        testProduct.NSP_Priority_Amendment__c = 11.0;
        testProduct.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_ANNUAL;
        testProduct.NSP_AnniversaryBlngApplicable__c =true;
        testProduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        testProduct.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        testProduct.blng__BillingRule__c = brObj.Id;
        testProduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        testProduct.blng__TaxRule__c = taxRuleObj.Id;
        


        
        Product2 testProduct1 = NSP_TestHelper.createProduct('Test Product1', false);
        testProduct1.ProductCode = 'IWXSU';
        testProduct1.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        testProduct1.SBQQ__BillingType__c = 'Arrears';
        testProduct1.NSP_Priority_Amendment__c = 11.0;
        testProduct1.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_ANNUAL;
        testProduct1.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        testProduct1.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        testProduct1.blng__BillingRule__c = brObj.Id;
        testProduct1.blng__RevenueRecognitionRule__c = rrObj.Id;
        testProduct1.blng__TaxRule__c = taxRuleObj.Id;
        

  
        
        List<Product2> productList = new List<Product2>();
        productList.add(testProduct1);
        productList.add(testProduct);
        
        insert productList;
        
        // Create a test PricebookEntry
        PricebookEntry testPricebookEntry = new PricebookEntry(Product2Id = testProduct.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = stdPriceBookId);

        
        PricebookEntry testPricebookEntry1 = new PricebookEntry(Product2Id = testProduct1.Id, UnitPrice = 100, IsActive = true, Pricebook2Id = stdPriceBookId);

        
        List<PriceBookEntry> priceBookEntList = new List<PriceBookEntry>();
        priceBookEntList.add(testPricebookEntry);
        priceBookEntList.add(testPricebookEntry1);
        
        insert priceBookEntList;
        
        
                 
         //Account
         Account objaccount = NSP_TestHelper.createAccount(false);
         objaccount.Name = 'Insperity WO Billing Account';
         insert objaccount;
        
        blng__PaymentMethod__c objPaymntMethod = new blng__PaymentMethod__c();
        objPaymntMethod.blng__Account__c = objaccount.Id;
        objPaymntMethod.blng__Active__c = true;
        objPaymntMethod.blng__BankAccountName__c = 'saving';
        objPaymntMethod.blng__BankAccountNumber__c = '1238388';
        objPaymntMethod.blng__BankAccountType__c = 'Savings';
        objPaymntMethod.blng__BankName__c = 'CITI';
        objPaymntMethod.blng__BankRoutingCode__c = '9874';
        objPaymntMethod.NSP_Active_Custom__c = true;
        objPaymntMethod.NSP_ACH_method__c = 'BoFA';
        objPaymntMethod.blng__PaymentType__c = 'ACH';
        objPaymntMethod.Payment_Method_Type__c = 'ACH';
        insert objPaymntMethod;
        
        
        list<Opportunity> lstOpport = new list<Opportunity>();
        
         //Opportunity
         Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', false);
         lstOpport.add(objOpportunity) ;
        
         //Opportunity
         Opportunity objOpportunity1 = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', false);
         objOpportunity.NSP_TransactionType__c = 'Amendment/Supplemental';
         lstOpport.add(objOpportunity1) ;
        
                 //Opportunity
         Opportunity objOpportunity2 = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', false);
         objOpportunity2.NSP_TransactionType__c = 'Termination';
         lstOpport.add(objOpportunity2) ;
        
         insert lstOpport;
              
        // Create a test Contract
        Contract testContract = new Contract(AccountId = objaccount.Id, Status = 'Draft', StartDate = System.today());
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
        
        
       
        
        //Quote
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpportunity.Id, false);
        objQuote.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_NEW;
        objQuote.SBQQ__primary__c = true;
        insert objQuote;
        
        //Quote Line
        List<SBQQ__QuoteLine__c> objQuoteLine = NSP_TestHelper.createCPQQuotelines(objQuote, productList, priceBookEntList, false);
        
		objQuoteLine[0].NSP_Preferred_Payment_Method__c =  'ACH';
        objQuoteLine[1].NSP_Preferred_Payment_Method__c =  'ACH';
        objQuoteLine[0].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE; 
        objQuoteLine[1].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        
        insert objQuoteLine;
        
        Test.startTest();
        objQuote.SBQQ__Ordered__c = true;
        Update objQuote;
    }
    
    @IsTest
    private static void testCreateInvoice()
    {
         // Retrieve the test Order
        Order testOrder = [SELECT Id, Project_Status__c,Status, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c FROM Order LIMIT 1];
        
        OrderItem testOrderItem = [SELECT Id, OrderId, SBQQ__Status__c,NSP_Preferred_Payment_Method__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate FROM OrderItem where Product2.ProductCode = 'IWXSU'  LIMIT 1];
        
        
        
        testOrder.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder.NSP_Rev_Rec_Rules_Reviewed__c =true;
        testOrder.NSP_Project_Name__c = 'TestProj';
        testOrder.NSP_Change_Order_Process_Quote__c = FALSE;
        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        testOrderItem.NSP_Preferred_Payment_Method__c = null;
        test.starttest();
        update testOrderItem;
        update testOrder;
        test.stoptest();
            

    }
    
    @IsTest
    private static void testCreateInvoice2()
    {
         // Retrieve the test Order
        Order testOrder = [SELECT Id, Project_Status__c,Status, Type,NSP_Change_Order_Process_Quote__c, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c FROM Order LIMIT 1];
        
        OrderItem testOrderItem = [SELECT Id, OrderId, SBQQ__Status__c,NSP_Preferred_Payment_Method__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate FROM OrderItem where Product2.ProductCode = 'IWXBundleW2' LIMIT 1];
        
        testOrder.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder.NSP_Rev_Rec_Rules_Reviewed__c =true;
        testOrder.NSP_Project_Name__c = 'TestProj';
        testOrderItem.NSP_AnniversaryBlngApplicable__c = true;
        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        testOrderItem.NSP_Preferred_Payment_Method__c = 'ACH';
        test.starttest(); 
        update testOrderItem;
        update testOrder;  
        test.stoptest();
            

    }
    
    @IsTest
    private static void testCreateInvoice3()
    {
        

         // Retrieve the test Order
        Order testOrder = [SELECT Id, Project_Status__c,Status, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c FROM Order LIMIT 1];
        
        OrderItem testOrderItem = [SELECT Id, OrderId, SBQQ__Status__c,NSP_Preferred_Payment_Method__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate FROM OrderItem where Product2.ProductCode = 'IWXSU'  LIMIT 1];

        testOrder.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder.NSP_Rev_Rec_Rules_Reviewed__c =true;
        testOrder.NSP_Project_Name__c = 'TestProj';
        testOrder.NSP_Change_Order_Process_Quote__c = FALSE;
        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.MILESTONEBASED;
        testOrderItem.NSP_Preferred_Payment_Method__c = null;
        test.starttest();
        update testOrderItem;
        update testOrder;
        test.stoptest();
            

    }
    
    
    @IsTest
    private static void testCreateInvoice4()
    {
        Opportunity oppObj = [select Id,AccountId from Opportunity where NSP_TransactionType__c = 'Amendment/Supplemental' LIMIT 1 ];   

        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(oppObj.AccountId, oppObj.Id, false);
        
        objQuote.SBQQ__primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        
        test.starttest();
        insert objQuote;
        
        // Retrieve the test Order
        Order testOrder = [SELECT Id, Project_Status__c,Status, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c FROM Order LIMIT 1];
        
        OrderItem testOrderItem = [SELECT Id, OrderId, SBQQ__Status__c,NSP_Preferred_Payment_Method__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate FROM OrderItem where Product2.ProductCode = 'IWXSU'  LIMIT 1];

        testOrder.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder.NSP_Rev_Rec_Rules_Reviewed__c =true;
        testOrder.NSP_Project_Name__c = 'TestProj';
        testOrder.Type = 'Supplemental';
        testOrder.NSP_Change_Order_Process_Quote__c = FALSE;
        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.MILESTONEBASED;
        testOrderItem.NSP_Preferred_Payment_Method__c = null;
        testOrderItem.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.IMMEDIATE;
        testOrder.NSP_Project_Go_Live_Date__c = system.today()+30;
        testOrder.NSP_Project_Go_Live_Approved__c = true;

        
        update testOrderItem;
        update testOrder;
        test.stoptest();
    }
    
    @IsTest
    private static void testCreateInvoice5()
    {

        Opportunity oppObj = [select Id,AccountId from Opportunity where NSP_TransactionType__c = 'Termination' LIMIT 1 ];   

        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(oppObj.AccountId, oppObj.Id, false);
        
        objQuote.SBQQ__primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        
        test.starttest();
        insert objQuote;
        
        // Retrieve the test Order
        Order testOrder = [SELECT Id, Project_Status__c,Status, Type, NSP_Project_Go_Live_Date__c, NSP_Transaction_Type__c, NSP_Usage_Products_Count__c FROM Order LIMIT 1];
        
        OrderItem testOrderItem = [SELECT Id, OrderId, SBQQ__Status__c,NSP_Preferred_Payment_Method__c, Order.Project_Status__c, Order.Type, Order.NSP_Project_Go_Live_Date__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Product2.NSP_Partial_Period_Free_Treatment__c, SBQQ__BillingFrequency__c, Order.EffectiveDate, NSP_OrderProductStartDate__c, SBQQ__SubscriptionType__c, NSP_AnniversaryBlngApplicable__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, NSP_Project_Completion_Date__c, Order.NSP_Usage_Products_Count__c, ServiceDate, SBQQ__RequiredBy__c, EndDate FROM OrderItem where Product2.ProductCode = 'IWXSU'  LIMIT 1];
        
        testOrder.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder.NSP_Rev_Rec_Rules_Reviewed__c =true;
        testOrder.NSP_Project_Name__c = 'TestProj';
        testOrder.Type = 'Termination';
        testOrder.NSP_Change_Order_Process_Quote__c = FALSE;
        testOrderItem.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.MILESTONEBASED;
        testOrderItem.NSP_Preferred_Payment_Method__c = null;
        testOrderItem.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.IMMEDIATE;
        testOrder.NSP_Project_Go_Live_Date__c = system.today()+30;
        testOrder.NSP_Project_Go_Live_Approved__c = true;

        
        update testOrderItem;
        update testOrder;
        test.stoptest();
    }

}