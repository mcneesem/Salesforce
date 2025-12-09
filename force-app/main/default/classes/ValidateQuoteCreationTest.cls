@IsTest
private class ValidateQuoteCreationTest {
	@testSetup
    private static void setupTestData(){
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        NSP_TestHelper.createProduct('Test Product',true);
    }
    @isTest
    private static void validateQuoteTest(){
        Account acc1 = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        Product2 product1 = [SELECT  Id, Name FROM Product2 WHERE NAME != Null LIMIT 1];
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = 'WX';
        opp1.NSP_PrimaryProduct__c = 'WX';
        //Inserting Opportunity
        insert opp1;
        Asset ast = new Asset();
        ast.AccountId = acc1.Id;
        ast.Name = 'asset1';
        ast.Status = 'Active';
        ast.NSP_Product_Line__c = 'Workforce Acceleration';
        ast.NSP_ProductBundle__c = 'WX';
        ast.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WX_WA_RECORD_TYPE).getRecordTypeId();
        insert ast;

        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('WX Pricebook');
        insert recpb;

        Test.startTest();
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = 'WX';
        quote1.NSP_Client_For_Life__c = 'WX';
        quote1.SBQQ__PriceBook__c = recpb.id;
        quote1.SBQQ__PricebookId__c = recpb.id;
        quote1.SBQQ__Primary__c = true;
        quote1.SBQQ__Type__c=NSP_QuoteTriggerTest.NEW_PRODUCT;
        //Inserting Quote
        insert quote1;

        List<SBQQ__Quote__c> createdQuotesList = [Select Id from SBQQ__Quote__c where SBQQ__Opportunity2__c =: opp1.Id ];
        system.Assert(createdQuotesList.size()==1);
        Test.stopTest();
    }
}