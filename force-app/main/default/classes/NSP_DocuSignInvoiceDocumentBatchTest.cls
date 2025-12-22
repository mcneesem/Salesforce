@isTest
private class NSP_DocuSignInvoiceDocumentBatchTest {

    @testSetup
    private static void createTestData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        CLMDocumentTransferSettings__c restSettings = CLMDocumentTransferSettings__c.getOrgDefaults();
        restSettings.IsEnabledClmDocumentReceived__c = true;
        restSettings.IsEnabledRestToken__c = true;
        restSettings.IsEnabledRestTokenLogging__c = true;
        upsert restSettings;

        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        upsert orderSetting;

        DocusignInvoiceDocumentBatchSettings__c settings = DocusignInvoiceDocumentBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 25;
        settings.BccAddresses__c = UserInfo.getUserEmail();
        upsert settings;

        CLMTokenRequest request = new CLMTokenRequest();
        request.Access_Token = 'Access_Token';
        request.Token_Type = 'Token_Type';
        request.Expires_In = 'Expires_In';
        request.ApiBase_Url = 'ApiBase_Url';
        request.Scope = 'Scope';

        //Test Data Setup
        // NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;

        Account objaccount = NSP_TestHelper.createAccount(true);

        NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
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

        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);

        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines

        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);

        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;

        Test.startTest();
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order where SBQQ__Quote__c=:objQuote.Id ];
        ords[0].blng__BillingDayOfMonth__c = '1';
        ords[0].Status = 'Reviewed';
        update ords;

        ords[0].Status = 'Activated';
        update ords;
        Test.stopTest();
    }

    @isTest
    private static void testInvoiceDocGenBatch() {
        Test.setMock(HttpCalloutMock.class, new CLMHttpMockResponseGenerator());
        Test.startTest();
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated'];
        ords[0].blng__BillNow__c = TRUE;
        update ords;
        Test.stopTest();

        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c,blng__InvoiceStatus__c FROM blng__Invoice__c];
        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;

        NSP_DocuSignInvoiceDocumentBatch invBatch = new NSP_DocuSignInvoiceDocumentBatch(new List<String>{invc[0].Id});
        ID ebatchprocessid = Database.executeBatch(invBatch,1);
        NSP_DocuSignInvoiceDocumentBatch.testHandleException(null,null);
        NSP_DocuSignRESTUtility.testHandleException(null,null);
        Integer batchSize = NSP_DocuSignInvoiceDocumentBatch.getBatchSize();
        System.assertNotEquals(null,batchSize);
        System.assertNotEquals(null, ebatchprocessid);
    }

    @isTest
    private static void testInvoiceDocGenTrigger() {
        Test.setMock(HttpCalloutMock.class, new CLMHttpMockResponseGenerator());

        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated'];
        ords[0].blng__BillNow__c = TRUE;
        update ords;

        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c,blng__InvoiceStatus__c FROM blng__Invoice__c LIMIT 1];
        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;
        Test.startTest();
        NSP_TriggerAction.resetAllHasRun();

        Test.stopTest();

    }

    @isTest
    private static void testSchedulable() {
        Test.startTest();
        System.schedule(
            'NSP_DocuSignInvoiceDocumentBatch ~ everyday at 3 AM' + ' ~ TEST' ,
            '0 0 3 * * ? *' ,
            new NSP_DocuSignInvoiceDocumentBatch()
        );
        Test.stopTest();
    }

    @isTest
    private static void testLogAuthenticationAttempts() {
        Test.startTest();
        NSP_DocuSignRESTUtility.logAuthenticationAttempts( JSON.serialize( new Docusign_Log__c() ) );
        Test.stopTest();
    }

}
//