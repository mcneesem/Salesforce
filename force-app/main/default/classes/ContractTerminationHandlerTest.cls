@IsTest
private class ContractTerminationHandlerTest {
    //Covers both ContractTerminationHandler.apex and ContractTerminationQueue.apex classes

    private class myException extends Exception {}

    @testSetup
    private static void makeData() {

        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        orderSetting.Bypass_Rule_PreventStatusChange__c = true;
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

        Contract ct = new Contract();
        ct.AccountId = acc1.Id;
        ct.SBQQ__Opportunity__c = opp1.Id;
        ct.SBQQ__Quote__c = quote1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = 'Workforce Acceleration';
        Date dt = Date.today()-330;
        ct.StartDate = dt;
        ct.EndDate = dt+365;
        ct.Status = 'Draft';
        ct.NSP_Number_of_Employees__c = 86;
        ct.NSP_PrimaryProduct__c = 'WX';
        insert ct;
        //Activating the contract
        ct.NSP_Product_Type__c = 'Workforce Acceleration';
        ct.NSP_TransactionType__c = 'Termination';
        ct.Status = 'Activated';
        update ct;
    }

    @IsTest
    private static void testRunContractTerminationCallOut() {

        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];

        SBQQ__Quote__c objQuote = [select Id from SBQQ__Quote__c LIMIT 1];
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        objQuote.NSP_Budgetary_Quote__c = true;
        update objQuote;


        list<contact> cntList = [select id from contact limit 2];

        list<OrderItem> orderItemList = new list<OrderItem>([select id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        orderList[0].ShipToContactId = cntList[0].id;
        orderList[0].NSP_Down_Payment_Required__c = 'yes';
        update orderList;
        orderList[0].Status='Activated';
        update orderList;

        Contract ct = [SELECT Id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c,Name from Contract WHERE ContractNumber !=null LIMIT 1];
        ct.NSP_Product_Type__c = 'Workforce Acceleration';
        ct.Status = 'Activated';
        update ct;


        // Create test data
        Contract testContract = [Select Id from Contract WHERE Status = 'Activated' LIMIT 1];

        ContractTerminationHandler.ContractTerminationRequest request = new ContractTerminationHandler.ContractTerminationRequest();
        request.ContractId = testContract.Id;
        request.TerminationDate = Date.today();

        // Call the method being tested
        Test.startTest();
        ContractTerminationHandler.runContractTerminationHandler(new List<ContractTerminationHandler.ContractTerminationRequest>{request});
        ContractTerminationHandler.runContractTerminationHandler(testContract.Id,Date.today(),'test@insperity.com');
        ContractTerminationHandler.constructAndSendEmail(null, 'Test email');
        ContractTerminationQueue.testHandleException( null , null );
        ContractTerminationHandler.testHandleException( null , null );
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
            WHERE (
                NSP_TransactionType__c = 'Termination'
                AND SBQQ__Account__c = :objaccount.Id
            )
            LIMIT 1
        ];
        Assert.isNotNull( quoteResults );
        Assert.isTrue( !quoteResults.isEmpty() );
        SBQQ__Quote__c quoteResult = quoteResults[0];
        Assert.isNotNull( quoteResult );
        System.assertEquals(Date.today(),quoteResult.NSP_TerminationDate__c);
    }

}
//