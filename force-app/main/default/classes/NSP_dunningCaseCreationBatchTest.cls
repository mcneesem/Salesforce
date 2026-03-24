@isTest
private class NSP_dunningCaseCreationBatchTest {

    // test setup method
    @testSetup
    private static void setupTestData() {

        Order_Settings__c sett = new Order_Settings__c();
        sett.EffectiveDateStartOfMonth__c = true;
        insert sett;

        DunningCaseCreationBatchSettings__c ccSetting = new DunningCaseCreationBatchSettings__c();
        ccSetting.IsEnabled__c = true;
        ccSetting.BatchSize__c = 200;
        ccSetting.CutOffDate__c = Date.newInstance(2025,7,1);
        insert ccSetting;

        // switch off the triggers
        NSP_TestHelper.switchOffTriggers();
        // create Accounts
        Account objaccount = NSP_TestHelper.createAccount(true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        insert objproduct;
        // create billing rules
        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test BR';
        brObj.blng__GenerateInvoices__c = 'Yes';
        brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        brObj.blng__PartialPeriodTreatment__c = 'Combine';
        insert brObj;
        // create revenue recognition rules
        blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
        rrObj.blng__Active__c = true;
        rrObj.blng__CreateRevenueSchedule__c = 'No';
        insert rrObj;
        // create tax rules
        blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
        taxRuleObj.blng__Active__c = true;
        taxRuleObj.blng__TaxableYesNo__c = 'No';
        insert taxRuleObj;
        // update product
        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct.blng__TaxRule__c = taxRuleObj.Id;
        update objproduct;
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        Test.startTest();
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE SBQQ__Quote__c=:objQuote.Id ];
        ords[0].blng__BillingDayOfMonth__c = '10';
        ords[0].Status = 'Reviewed';
        update ords;
        // update order
        ords[0].Status = 'Activated';
        update ords;
        Test.stopTest();
    }

    @isTest
    private static void dunningCaseCreateTest() {
        Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
        update ords;
        Test.stopTest();
        Contact cc = NSP_TestHelper.createContact(objaccount.id,true);
        // get invoices
        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c,blng__BillToContact__c FROM blng__Invoice__c WHERE Id!=null];
        invc[0].blng__DueDate__c = Date.today() - 50;
        invc[0].blng__BillToContact__c = cc.id;
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        update invc;
        // get invoices
        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;
        // get dinning instances
        NSP_dunningInvoicesListController invListCtrl = new NSP_dunningInvoicesListController();
        String logoUrl = invListCtrl.getLogoUrl();
        invListCtrl.caseAccountId = (String)objaccount.Id;
        List<blng__Invoice__c> pendingInvs = invListCtrl.getdunningInvoicesList();
        NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
        ID batchprocessid = cBatch.run();
        System.assertNotEquals(null, batchprocessid);
        System.assertNotEquals(null, pendingInvs);
    }

    @isTest
    private static void dunningCaseCloseTest() {
        Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
        update ords;

        // get invoices
        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Name != null LIMIT 1];
        invc[0].blng__DueDate__c = Date.today() - 50;
        update invc;
        // update invoices
        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;
        // Execute the batch
        NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
        NSP_DunningCaseCreationBatch.schedule();
        Test.stopTest();
        // insert lock box record
        NSP_Lock_Box__c newlbrec = new NSP_Lock_Box__c();
        newlbrec.NSP_Remitter_Name__c = objaccount.Name;
        newlbrec.NSP_Invoice_Number__c = invc[0].Name;
        newlbrec.NSP_Check_Amount__c = invc[0].blng__Balance__c;
        insert newlbrec;

        newlbrec.NSP_Ready_to_Convert__c = TRUE;
        update newlbrec;
    }

    @isTest
    private static void dunningCaseEmailsTest() {

        Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
        update ords;

        // get invoices
        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Name != null LIMIT 1];
        invc[0].blng__DueDate__c = Date.today() - 50;
        update invc;
        // update invoices
        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;

        Id DUNNING_CASE_RT_ID = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'Dunning' );
        // insert case
        Case dunCase = new Case();
        dunCase.AccountId = objaccount.Id;
        dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
        dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
        dunCase.recordTypeId = DUNNING_CASE_RT_ID;
        dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
        dunCase.Origin = NSP_BillingConstants.DUNNING;
        duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
        insert dunCase;
        // execte batch
        NSP_DunningEmailNotificationsBatch ebatch = new NSP_DunningEmailNotificationsBatch();
        ID ebatchprocessid = Database.executeBatch(ebatch);
        Test.stopTest();

        System.assertNotEquals(null, ebatchprocessid);
    }

}
//