@isTest
private class PurchasedProductsCreateBatchTest {

    @testSetup
    private static void testData() {
        PurchasedProductBatchSettings__c settings = PurchasedProductBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        upsert settings;

        NSP_AssetTriggerHandler.TriggerDisabled = true;

        Account objaccount = NSP_TestHelper.createAccount(true);

        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objProduct.Purchased_Asset_Record_Type__c = 'NSP_Asset_Product';
        objProduct.NSP_ServiceAssetCategory__c = 'WX_WA';
        objProduct.NSP_Convert_to_Asset__c = true;
        objProduct.ProductCode = 'IWXBundleW2';
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

        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        objOpprtunity.NSP_PrimaryProduct__c = 'WX';
        objOpprtunity.NSP_Client_For_Life__c = 'WX';
        objOpprtunity.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
        objOpprtunity.CloseDate = date.today();
        objOpprtunity.CurrencyIsoCode = 'USD';
        objOpprtunity.NSP_Number_of_Employees__c = 100;
        objOpprtunity.NSP_WS_Number_Of_Employees__c = 123;
        objOpprtunity.NSP_WO_Number_Of_Employees__c = 123;
        update objOpprtunity;

        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);

        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);

        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        List<SBQQ__QuoteLine__c> ql = [select Id,NSP_Quoted_Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: objQuote.Id ];
        ql[0].NSP_Quoted_Quantity__c = 10;
        update ql;

        // Approve quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c = 'New Product';
        objQuote.SBQQ__Status__c = 'Approved';
        update objQuote;

        Asset ast = new Asset();
        ast.Name = 'Test-Account';
        ast.AccountId = objaccount.Id;
        ast.Product2Id = objproduct.Id;
        ast.Status = 'Active';
        ast.Opportunity__c = objOpprtunity.Id;
        ast.RecordTypeId = '0124x000000yRuxAAE';
        insert ast;

        NSP_Pricing_Table__c pt = new NSP_Pricing_Table__c();
        pt.Name = 'Test';
        pt.NSP_Product__c = objproduct.Id;
        pt.NSP_Lower_Bound__c = 1;
        pt.NSP_Upper_Bound__c = 20;
        pt.NSP_List_Price__c = 50;
        pt.NSP_Pricing_Model__c = 'WX';
        pt.NSP_Start_Date__c= Date.valueOf('2023-07-01');
        pt.NSP_End_Date__c = Date.valueOf('2100-12-31');
        pt.Seasonal_Pricing__c = 'Not Applicable';
        insert pt;
    }

    @isTest
    private static void PurchasedProductCreateTest(){
        Test.startTest();
        List<Opportunity> opportunityList = [Select Id from Opportunity LIMIT 1];
        opportunityList[0].StageName = 'Closed Won';
        update opportunityList;
        Test.stopTest();
        List<Asset> ast = [Select Id from Asset];
        List<Purchased_Product__c> pp = [Select Id,Purchase_Status__c,Asset__c from Purchased_Product__c where Asset__c =: ast[0].Id];

        System.assertNotEquals(0, pp.size(), 'Purchased Product should exist.');
        System.assertEquals(ast[0].Id, pp[0].Asset__c, 'Asset ID should match.');
        System.assertEquals('Purchased', pp[0].Purchase_Status__c, 'Status should match expected status after purchase.');
    }

    @isTest
    private static void PurchasedProductsUpdateTest(){
        Test.startTest();

        List<Opportunity> opportunityList = [Select Id from Opportunity LIMIT 1];
        List<OpportunityLineItem> ol = [Select Id,Product2Id,NSP_ProductBundle__c from OpportunityLineItem where OpportunityId =: opportunityList[0].Id];
        List<Asset> ast = [Select Id from Asset];
        Purchased_Product__c pp = new Purchased_Product__c();
        pp.Asset__c = ast[0].Id;
        pp.Product__c = ol[0].Product2Id;
        pp.Original_Opportunity_Product__c = ol[0].Id;
        pp.Purchase_Status__c = 'Canceled';
        insert pp;

        opportunityList[0].Type = 'Existing Product';
        opportunityList[0].StageName = 'Closed Won';
        update opportunityList;
        Test.stopTest();

        List<Opportunity> updatedOpportunity = [Select Id, StageName, Type from Opportunity where Id =: opportunityList[0].Id LIMIT 1];
        System.assertEquals('Closed Won', updatedOpportunity[0].StageName, 'Opportunity Stage should be Closed Won.');
        System.assertEquals('Existing Product', updatedOpportunity[0].Type, 'Opportunity Type should be Existing Product.');

        List<Purchased_Product__c> updatedPP = [Select Id, Purchase_Status__c from Purchased_Product__c where Id =: pp.Id];
        System.assertEquals('Purchased', updatedPP[0].Purchase_Status__c, 'Purchased Product status should change from Canceled to Purchased');
    }

}
//