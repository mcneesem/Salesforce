@isTest
private class WingspanCreateUserActionTest {

    @testSetup
    private static void createTestData() {
        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        orderSetting.Bypass_Rule_PreventStatusChange__c = true;
        upsert orderSetting;

        Wingspan_Settings__c wSett = new Wingspan_Settings__c();
        wSett.BaseUrl__c = 'https://stagingapi.wingspan.app';
        wSett.IsEnabled__c = true;
        wSett.PrivateKey__c = 'testPrivateKey';
        wSett.XWingspanUserId__c = 'testXWingspanUserId';
        wSett.ParentUserId__c = 'testParentUserId';
        wSett.Name = 'TESTING';
        wSett.Hr360ParentUserId__c = 'testKey';
        wSett.HrScaleParentUserId__c = 'testKey';
        wSett.SsoPrivateKey__c = 'testKey';
        wSett.RestrictedCharacters__c = '!';
        wSett.RestrictedProducts__c = 'test';
        insert wSett;

        NSP_ContactTriggerHandler.TriggerDisabled = true;
        blng__BillingRule__c objBillingRule = NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c objRevRecRule =  NSP_TestHelper.createRevrecRule('1');
        blng__TaxRule__c objTaxRule = NSP_TestHelper.createRevTaxRule();

        Account objaccount = NSP_TestHelper.createAccount(true);
        Contact cc = NSP_TestHelper.createContact(objaccount.id, true);

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.Id;
        objproduct.blng__RevenueRecognitionRule__c = objRevRecRule.Id;
        objproduct.blng__TaxRule__c = objTaxRule.Id;
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        insert objproduct;

        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Business',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        objQuote.SBQQ__Ordered__c = true;
        objQuote.SBQQ__primary__c = true;
        objQuote.NSP_Customer_Stakeholder__c = cc.id;
        update objQuote;
        objOpprtunity.StageName = 'Closed Won';
        objOpprtunity.NSP_Number_of_Employees__c = 100;
        update objOpprtunity;

        OrderItem ordItem = [SELECT id FROM OrderItem LIMIT 1];

        NSP_AssetTriggerHandler.TriggerDisabled = true;
        Asset asset = new Asset();
        asset.NSP_Client__c = 'asset3';
        asset.opportunity__c = objOpprtunity.Id;
        asset.name = 'asset3';
        asset.AccountId = objaccount.id;
        asset.ContactId = cc.id;
        asset.Platform__c = WingspanRestService.NON_SSO;
        asset.NSP_AccountName__c = 'test!';

        insert asset;

        asset.NSP_OrderProduct__c = ordItem.id;
        update asset;
    }

    @isTest
    private static void createWingspanUserTest() {
        Asset asset = [SELECT id, NSP_OrderProduct__c FROM Asset LIMIT 1];
        Contact cc = [SELECT id FROM Contact LIMIT 1];
        WingspanCreateUserAction.Input input = new WingspanCreateUserAction.Input();
        input.contactId = cc.id;
        input.recordId = asset.id;
        input.isCheckOnly = false;
        Test.setMock(HttpCalloutMock.class, new WingspanHttpCalloutMock());
        Test.startTest();
        List<WingspanCreateUserAction.Output> outputList = WingspanCreateUserAction.createWingspanUser(new List<WingspanCreateUserAction.Input>{input});
        WingspanCreateUserAction.testHandleException( null , null );
        WingspanRestService.testHandleException( null , null );
        Test.stopTest();
    }

    @isTest
    private static void createHrUserTest() {
        List<Asset> assetList = [SELECT id, NSP_OrderProduct__c, Platform__c FROM Asset LIMIT 1];
        assetList[0].Platform__c = WingspanRestService.HR360;
        update assetList[0];
        List<Contact> ccList = [SELECT id FROM Contact LIMIT 1];
        WingspanCreateUserAction.Input input = new WingspanCreateUserAction.Input();
        input.contactId = ccList[0].id;
        input.recordId = assetList[0].id;
        input.isCheckOnly = false;
        Test.setMock(HttpCalloutMock.class, new WingspanHttpCalloutMock());
        Test.startTest();
        List<WingspanCreateUserAction.Output> outputList = WingspanCreateUserAction.createWingspanUser(new List<WingspanCreateUserAction.Input>{input});
        WingspanCreateUserAction.testHandleException( null , null );
        WingspanRestService.testHandleException( null , null );
        Test.stopTest();
    }

    @isTest
    private static void createWingspanUserNegativeTest() {
        Asset asset = [SELECT id, NSP_OrderProduct__c FROM Asset LIMIT 1];
        Contact cc = [SELECT id FROM Contact LIMIT 1];
        WingspanCreateUserAction.Input input = new WingspanCreateUserAction.Input();
        input.contactId = cc.id;
        input.recordId = asset.id;
        input.isCheckOnly = null;
        Test.setMock(HttpCalloutMock.class, new WingspanHttpCalloutMock());
        Test.startTest();
        List<WingspanCreateUserAction.Output> outputList = WingspanCreateUserAction.createWingspanUser(new List<WingspanCreateUserAction.Input>{input});
        Test.stopTest();
    }

}
//