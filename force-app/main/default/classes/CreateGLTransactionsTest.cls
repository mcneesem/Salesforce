@isTest private class CreateGLTransactionsTest {

    @testSetup private static void createTestData() {
        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        orderSetting.Bypass_Rule_PreventStatusChange__c = true;
        upsert orderSetting;

        GLTransactionsBatchSettings__c batchSetting = new GLTransactionsBatchSettings__c();
        batchSetting.BatchSize__c = 200;
        batchSetting.IsEnabled__c = true;
        insert batchSetting;

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
        insert objproduct;

        blng__FinanceBook__c fb = NSP_TestHelper.createFinBook();

        blng__LegalEntity__c legalentity = new blng__LegalEntity__c();
        legalentity.blng__Active__c=true;
        legalentity.blng__City__c='KINGWOOD';
        legalentity.blng__Country__c='US';
        legalentity.blng__State__c='TX';
        legalentity.blng__Street1__c='19001 CRESCENT SPRINGS DR';
        legalentity.blng__ZipPostalCode__c= '77339-3802';
        legalentity.Name= '10';
        insert legalentity;

        Date firstDayOfMonth = System.today().toStartOfMonth();
        Date lastDayOfMonth = firstDayOfMonth.addDays(Date.daysInMonth(firstDayOfMonth.year(), firstDayOfMonth.month()) - 1);
        blng__FinancePeriod__c finperiod = new blng__FinancePeriod__c();
        finperiod.blng__FinanceBook__c = fb.Id;
        finperiod.blng__LegalEntity__c= legalentity.Id;
        finperiod.blng__PeriodStartDate__c= firstDayOfMonth;
        finperiod.blng__PeriodEndDate__c= lastDayOfMonth;
        finperiod.Name='Nov 2024 Inseperity '+ finperiod.blng__LegalEntity__r.Name;
        finperiod.blng__PeriodStatus__c= 'Open';
        insert finperiod;

        GL_Period__c glPeriod = new GL_Period__c(
            Name = 'Test GL Period',
            Financial_Period_Revenue_10__c = finperiod.id
        );
        insert glPeriod;

    }

    @isTest private static void createGLTransactionsTest() {

        // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        Contact con = [SELECT id FROM Contact LIMIT 1];
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Business',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);

        blng__FinancePeriod__c financePeriod = [Select id from blng__FinancePeriod__c LIMIT 1];
        GL_Period__c glPeriod = [Select id,Financial_Period_Revenue_10__c from GL_Period__c LIMIT 1];
        id periodId = glperiod.id;

        //financeperiodList
        List <Id> financeperiodIds = new List<Id>();
        financeperiodIds.add(financePeriod.Id);

        Test.startTest();
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;

        //creating invoice
        list<OrderItem> orderItemList = new list<OrderItem>(
            [
                SELECT id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c
                FROM OrderItem
                WHERE Order.SBQQ__Quote__c =:objQuote.Id
            ]
        );
        list<Order> orderList = new list<Order>([select id from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        orderList[0].Status='Activated';
        update orderList;
        orderList[0].blng__BillNow__c=true;
        update orderList;
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c,blng__Balance__c from blng__Invoice__c WHERE Id!=null];
        blng__InvoiceRun__c invRunObj = new blng__InvoiceRun__c (Name='TestInvRun',blng__TargetDate__c=System.today());
        insert invRunObj;

        blng__InvoiceLine__c line = [
            SELECT
            id,blng__InvoiceLineStatus__c,blng__Invoice__c,
            blng__InvoiceRun__c,blng__Product__c,blng__OrderProduct__c,
            NSP_Product_Code__c,blng__Subtotal__c,blng__TaxAmount__c,
            blng__TaxGLRule__c,blng__TaxGLTreatment__c,
            blng__TaxRule__c,NSP_Tax_Credit_GL_Account_Number__c,
            NSP_Tax_Debit_GL_Account_Number__c,blng__BillingGLRule__c,
            blng__BillingGLTreatment__c,Processed_GL_Transactions__c
            FROM blng__InvoiceLine__c
            LIMIT 1
        ];
        line.blng__InvoiceRun__c = invRunObj.id;
        line.blng__BillingFinancePeriod__c = financePeriod.id;

        NSP_InvoiceLineTriggerHandler.TriggerDisabled = true;

        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        update line;

        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_EmailMessageTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceLineTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_TaskTriggerHandler.TriggerDisabled = true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;

        SBQQ.TriggerControl.disable();
        inv[0].blng__InvoiceRunCreatedBy__c = invRunObj.Id;
        inv[0].NSP_Bill_To_Email__c = 'abc@def.com';
        inv[0].NSP_Send_Email__c = true;
        inv[0].blng__BillToContact__c = con.Id;
        inv[0].blng__InvoiceStatus__c = 'Posted';
        SBQQ.TriggerControl.disable();
        update inv[0];

        line.blng__InvoiceLineStatus__c = 'Posted';
        update line;

        SBQQ.TriggerControl.enable();
        CreateGLTransactionsController.CreateGLTransactions(periodId);
        Test.stopTest();

    }

}
//