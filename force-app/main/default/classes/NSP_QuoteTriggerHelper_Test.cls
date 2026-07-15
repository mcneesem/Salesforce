@isTest
private with sharing class NSP_QuoteTriggerHelper_Test {
    private static final String OPP_TYPE_NEW_PRODUCT = 'New Product'; // Added as part of code fix

    @testSetup
    private static void setupTestData() {
        // NSP_TestHelpser th = new NSP_TestHelper();
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        NSP_TestHelper.createProduct('Test Product',true);
    }

    @isTest
    private static void pricebookmappingTest() {
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;

        Account acc1 = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
        product1.ProductCode = 'PerformSmart Traditional';
        update product1;

        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id, OPP_TYPE_NEW_PRODUCT ,true);
        PriceBookEntry pe1 = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        insert quote1;
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
       	qlines[0].NSP_Lock_On_QLI__c = true;
        qLines[0].Product_Description_Template__c = 'Test';
        insert qlines;
        Test.startTest();
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_APPROVED;
        quote1.SBQQ__Primary__c = true;
        quote1.NSP_Budgetary_Quote__c = true;
        update quote1;
        System.assertEquals(quote1.ApprovalStatus__c, NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED);
        NSP_BudgetaryQuoteTaxController.stampTaxFieldsToQuote(new List<String> {opp1.Id});
        Test.stopTest();
    }

    @isTest
    private static void pricebookmappingTestwithClone() {
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;

        Account acc1 = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
        product1.ProductCode = 'PerformSmart Traditional';
        update product1;

        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id, OPP_TYPE_NEW_PRODUCT ,true);
        PriceBookEntry pe1 = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        insert quote1;
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
       	qlines[0].NSP_Lock_On_QLI__c = true;
        insert qlines;
        Test.startTest();
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_APPROVED;
        quote1.SBQQ__Primary__c = true;
        quote1.NSP_Budgetary_Quote__c = true;
        update quote1;
        SBQQ__Quote__c quote2 = quote1.clone();
        insert quote2;
        System.assertEquals(quote1.ApprovalStatus__c, NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED);
       Test.stopTest();
    }

    @isTest
    private static void partnerPriceBookTest() {
        Account acc1 = [SELECT Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Product2 product1 = [SELECT Id, Name FROM Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
        Account partnerAcc = new Account();
        partnerAcc.Name = 'TestPartner';
        partnerAcc.Type = 'Partner';
        insert partnerAcc;

        Test.startTest();
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id, OPP_TYPE_NEW_PRODUCT ,false);
        opp1.NSP_Partner__c = partnerAcc.Id;
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        System.assertEquals(opp1.NSP_Partner__c, partnerAcc.Id);
        Test.stopTest();
    }

    @isTest
    private static void talentConnectValidationTest() {
        Account acc1 = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Test.startTest();
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id, OPP_TYPE_NEW_PRODUCT ,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,true);

        quote1.NSP_TC_Implementation_Plan_Selected__c = 'Custom';
        quote1.NSP_Talent_Connect_Subscription_Date__c = Date.TODAY();

        update quote1;
        Test.stopTest();
        System.assertEquals(quote1.NSP_TC_Implementation_Plan_Selected__c, 'Custom');
    }

    @isTest
    private static void recrutingPricebookmappingTest() {
        Account acc1 = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Test.startTest();
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id, OPP_TYPE_NEW_PRODUCT ,false);
        opp1.NSP_PrimaryProduct__c = 'Recruiting Services';
        insert opp1;

        Test.stopTest();
        System.assertEquals(opp1.NSP_PrimaryProduct__c, 'Recruiting Services');
    }

}
//