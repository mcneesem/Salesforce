@isTest
private class OpportunityCloseWonTest {

    @TestSetup
    private static void createTestData(){
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
        objproduct.NSP_AssetProductLine__c = 'Workforce Acceleration';
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
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);

        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        objQuote.SBQQ__Status__c = 'Approved';

        update objQuote;

    }

    @isTest
    private static void test_CreateAssetForCloseWonOpp(){

        Test.startTest();
        List<OpportunityLineItem> oppItems = [SELECT id, OpportunityId FROM OpportunityLineItem WHERE Opportunity.StageName != 'Closed Won'];

        Opportunity objOpprtunity = new Opportunity(id = oppItems[0].OpportunityId);

        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_EmailMessageTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceLineTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_TaskTriggerHandler.TriggerDisabled = true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;

        objOpprtunity.StageName = 'Closed Won';
        objOpprtunity.HRCore_Contract_Changes__c = 'Contract Term';
        objOpprtunity.NSP_CountAsSale__c = 'No';
        update objOpprtunity;
        Test.stopTest();

        List<Asset> assetList = [SELECT id FROM Asset];

    }
}
//