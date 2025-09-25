@isTest
private class QuoteCalculationForTerminationTest {
    //Covers both QuoteCalculationForTermination.apex and QuoteUpdateQueue.apex

    private class myException extends Exception {}

    @testSetup
    private static void makeData() {

        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        upsert orderSetting;

        Contract_Termination_Settings__c ctSetting = Contract_Termination_Settings__c.getOrgDefaults();
        ctSetting.AdminEmailAddresses__c = 'test@insperity.com';
        ctSetting.AutoTerminationEmailAddresses__c = 'test123@insperity.com';
        ctSetting.IsEnabledAutoTermination__c = true;
        ctSetting.IsEnabledNotificationFlow__c = true;
        upsert ctSetting;

         //Disable unnesessary triggers
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled=true;
        NSP_ContractTriggerHandler.TriggerDisabled=true;

        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule('Project Rev Rec');
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        blng__RevenueDistributionMethod__c dis=NSP_TestHelper.createRevenueDistribution('Project Rev Rec (Invoice)');
        blng__GLRule__c glrule=NSP_TestHelper.createGLRule();
        blng__FinanceBook__c finBook=NSP_TestHelper.createFinBook();
        blng__RevenueRecognitionTreatment__c recTreatment=NSP_TestHelper.createRevRecTreatment();
        recTreatment.blng__RevenueDistributionMethod__c=dis.Id;
        recTreatment.blng__RevenueRecognitionRule__c=rRule.Id;
        insert recTreatment;

        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,'New Product',true);

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.ProductCode = 'IWXBundleW2';
        objproduct.blng__TaxRule__c=tRule.Id;

        insert objproduct;

        PriceBookEntry pe1 = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,true);
        NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{objproduct},new List<PriceBookEntry> {pe1}, true);
        opp1.NSP_PrimaryProduct__c = 'WX';
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        update opp1;
    }

    @IsTest
    private static void testQuoteCalculationForTermination() {
        List<String> quoteIdSet = new List<String>();
        SBQQ__Quote__c objQuote = [select Id from SBQQ__Quote__c LIMIT 1];
        quoteIdSet.add(objQuote.Id);
        Test.startTest();
        QuoteCalculationForTermination.runQuoteCalculationForTermination(quoteIdSet);
        QuoteCalculationForTermination.testHandleException( null , null );
        QuoteCalculationForTermination.sendfailureEmail(null,'Test email');
        QuoteUpdateQueue.testHandleException( null , null );
        Test.stopTest();

        List<SBQQ__Quote__c> quoteResults = [
            SELECT
                Id ,
                Ready_for_Approval__c ,
                Auto_Termination__c ,
                SBQQ__MasterEvergreenContract__c ,
                NSP_TransactionType__c ,
                NSP_TerminationDate__c
            FROM SBQQ__Quote__c
            LIMIT 1
        ];
        Assert.isNotNull( quoteResults );
        Assert.isTrue( !quoteResults.isEmpty() );
        SBQQ__Quote__c quoteResult = quoteResults[0];
        Assert.isNotNull( quoteResult );
        System.assertEquals(true,quoteResult.Ready_for_Approval__c);
        System.assertNotEquals(false,quoteResult.Auto_Termination__c);
    }

}
//