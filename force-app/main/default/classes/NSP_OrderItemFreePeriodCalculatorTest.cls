/**
 * @description       :
 * @author            : Manikandan M
 * @group             :
 * @last modified on  : 01-24-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
@isTest
private class NSP_OrderItemFreePeriodCalculatorTest{
    @testSetup
    private static void testSetup(){

        Order_Settings__c sett = new Order_Settings__c();
        sett.EffectiveDateStartOfMonth__c = true;
        insert sett;

       NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;

        Account objaccount = NSP_TestHelper.createAccount(true);

        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c = 'YES';
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
        objproduct.NSP_Free_Periods_Applicable__c = true;
        update objproduct;

        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', true);

        PriceBookEntry objPbe = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 200.0, true);

        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpprtunity.Id, true);

        List<SBQQ__QuoteLine__c> qlList = NSP_TestHelper.createCPQQuotelines(objQuote, new List<Product2>{ objproduct }, new List<PriceBookEntry>{ objPbe }, true);
        qlList[0].NSP_Free_Months__c = 1;
        Update qlList;

        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        objQuote.NSP_Free_Month__c = '1';
        update objQuote;

        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        Test.startTest();
        List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                            FROM Order
                            WHERE SBQQ__Quote__c = :objQuote.Id];
        ords[0].blng__BillingDayOfMonth__c = '1';
        ords[0].Status = 'Reviewed';
        update ords;

        ords[0].Status = 'Activated';
        update ords;
    }

    @isTest
    private static void testNSPOrderItemFreePeriodCalculator(){

        Test.startTest();

        Account objaccount = [Select Id, Name
                              from Account
                              WHERE Name = :NSP_TestHelper.DEFAULT_COMPANY_NAME
                              LIMIT 1];
        List<Order> ordList = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                               FROM Order
                               WHERE Status = 'Activated'];
        List<OrderItem> orderItemList = [Select Id, NSP_Free_Periods_Available__c, NSP_Matching_Id__c
                                         From OrderItem WHERE OrderId IN:ordList LIMIT 10];
        orderItemList[0].NSP_Free_Periods_Available__c = 1;
        orderItemList[0].NSP_Total_Free_Periods__c = 1;
        Update orderItemList;
        ordList[0].blng__BillNow__c = TRUE;
        update ordList;

        List<blng__Invoice__c> invoiceList = [Select id, blng__InvoiceStatus__c
                                              From blng__Invoice__c WHERE Id!= null LIMIT 10];
        invoiceList[0].blng__InvoiceStatus__c = 'Posted';
        Update invoiceList;
        List<Blng__InvoiceLine__c> invLineList = [Select Id, blng__BillingFrequency__c, blng__ChargeType__c, blng__OrderProduct__c, blng__OrderProduct__r.NSP_Total_Free_Periods__c, blng__OrderProduct__r.NSP_Free_Periods_Available__c,blng__Invoice__c
                                                  From Blng__InvoiceLine__c WHERE Id!= null  LIMIT 10];
        NSP_OrderItemFreePeriodCalculator.updateFreePeriodFlow(new List<String>{ invLineList[0]?.blng__Invoice__c });

        blng__UsageSummary__c usageSummaryRecord  = new blng__UsageSummary__c(blng__Account__c = objaccount.Id,blng__OrderProduct__c = orderItemList[0].Id,blng__MatchingId__c = '123',blng__MatchingAttribute__c = 'Each',blng__UnitOfMeasure__c = 'None',blng__Status__c = 'New',blng__Source__c = 'External',blng__SummaryStartDate__c = Date.today().addDays(-15),blng__SummaryEndDate__c = Date.today().addDays(15),blng__Order__c = ordList[0].Id );
        insert usageSummaryRecord;
        NSP_OrderItemFreePeriodCalculator.applyZeroUnitPriceToUsageRecords(new Set<String>{ orderItemList[0]?.Id });
        Test.stopTest();
        System.assert(invoiceList.size()==1,true);
        // Asserts
    }

}