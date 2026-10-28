@isTest
public class CheckDownPaymentDetailsActionTest {

    @testSetup
    private static void setupTestData() {
        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        upsert orderSetting;

        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        Pricebook2 priceBookRec = NSP_TestHelper.getStandardPriceBook2();

        Id stdPriceBookId = Test.getStandardPricebookId();
        Account objaccount = NSP_TestHelper.createAccount(false);
        objaccount.Name = 'Insperity WO Billing Account';
        insert objaccount;

        Contact objCon = NSP_TestHelper.createContact(objaccount.id, false);
        insert objCon;

        pse__Proj__c hcmProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        hcmProject.Name = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.pse__Start_Date__c = Date.Today();
        hcmProject.pse__Account__c = objaccount.Id;
        hcmProject.TemplateName__c = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.Project_Implementer__c = UserInfo.getUserId();
        insert hcmProject;

        Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', false);
        insert objOpportunity;

        NSP_Address__c addressBillToRecord = NSP_TestHelper.createCustomAddress();
        addressBillToRecord.NSP_Related_Site__c = objaccount.Id;
        addressBillToRecord.NSP_Address_Type__c = 'Bill To';
        addressBillToRecord.CurrencyIsoCode = 'USD';
        addressBillToRecord.NSP_Source__c = 'AIMS';
        insert addressBillToRecord;
        NSP_Address__c addressShipToRecord = NSP_TestHelper.createCustomAddress();
        addressShipToRecord.NSP_Related_Site__c = objaccount.Id;
        addressShipToRecord.NSP_Address_Type__c = 'Ship To';
        addressShipToRecord.CurrencyIsoCode = 'USD';
        addressShipToRecord.NSP_Source__c = 'AIMS';
        insert addressShipToRecord;

        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test InsBR';
        brObj.blng__GenerateInvoices__c = NSP_CPQConstants.YES;
        brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        brObj.blng__PartialPeriodTreatment__c = 'Combine';
        insert brObj;

        blng__FinanceBook__c blngFinanceRec = new blng__FinanceBook__c();
        blngFinanceRec.blng__Active__c = true;
        blngFinanceRec.blng__FinancePeriodDuration__c = NSP_CPQConstants.MONTHLY;
        blngFinanceRec.Name = 'Insperity Salesforce Finance Book';
        blngFinanceRec.blng__PeriodType__c = 'Accounting';
        insert blngFinanceRec;
        blng__InvoicePlan__c invPlanRecord = new blng__InvoicePlan__c();
        invPlanRecord.blng__Active__c = true;
        invPlanRecord.blng__BillingScheduleCreation__c = 'Order Product Activation';
        invPlanRecord.Name = NSP_CPQConstants.INVOICE_PLAN;
        insert invPlanRecord;

        //Insert Invoice Plan Line
        List<blng__InvoicePlan__c> invPlanRec = [Select Id from blng__InvoicePlan__c WHERE Id!=Null];
        blng__InvoicePlanLine__c planLineObj = new blng__InvoicePlanLine__c();
        planLineObj.Name = 'Invoiced at Project Completion';
        planLineObj.blng__Type__c = 'Percent';
        planLineObj.blng__Percentage__c = 100;
        planLineObj.blng__CommencementDate__c = 'Order Product Activation';
        planLineObj.blng__CommencementDateOffsetUnits__c = 'Days';
        planLineObj.NSP_Billing_Commencement_Trigger__c = 'Project Completion';
        planLineObj.blng__ProcessingOrder__c = 1.0;
        planLineObj.blng__InvoicePlan__c = invPlanRec[0].Id;
        insert planLineObj;

        blng__BillingTreatment__c blngTreatmentRecord = new blng__BillingTreatment__c();
        blngTreatmentRecord.blng__Active__c = true;
        blngTreatmentRecord.blng__BillingRule__c = brObj.Id;
        blngTreatmentRecord.blng__BillingFinanceBook__c = blngFinanceRec.Id;
        blngTreatmentRecord.blng__InvoicePlan__c = invPlanRecord.Id;
        insert blngTreatmentRecord;

        blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
        rrObj.blng__Active__c = true;
        rrObj.blng__CreateRevenueSchedule__c = 'No';
        insert rrObj;

        blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
        taxRuleObj.blng__Active__c = true;
        taxRuleObj.blng__TaxableYesNo__c = 'No';
        insert taxRuleObj;

        blng__GLRule__c taxGLRule = new blng__GLRule__c(blng__Active__c = true, blng__Notes__c = 'Created to record: Sales Tax Allocation', Name = 'Test GLRule');
        insert taxGLRule;

        List<Product2> productList = new List<Product2>();
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
        objproduct.ProductCode = 'IWXBundleW2';
        objproduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.NSP_Priority_Amendment__c = 11.0;
        objproduct.SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        objproduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objproduct.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct.blng__TaxRule__c = taxRuleObj.Id;
        productList.add(objproduct);

        Product2 objInvproduct = NSP_TestHelper.createProduct('Test Product 1', false);
        objInvproduct.ProductCode = 'IWXBundle';
        objInvproduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objInvproduct.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objInvproduct.NSP_Priority_Amendment__c = 12.0;
        objInvproduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
        objInvproduct.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.PROJGOLIVEDATE;
        objInvproduct.SBQQ__BillingFrequency__c = NSP_CPQConstants.INVOICE_PLAN;
        objInvproduct.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objInvproduct.blng__BillingRule__c = brObj.Id;
        objInvproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objInvproduct.blng__TaxRule__c = taxRuleObj.Id;
        objproduct.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        productList.add(objInvproduct);

        Product2 objproduct1 = NSP_TestHelper.createProduct('Test Product 2', false);
        objproduct1.ProductCode = 'IWXBundleW2';
        objproduct1.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct1.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct1.SBQQ__BillingFrequency__c = 'Annual';
        objproduct1.NSP_Priority_Amendment__c = 13.0;
        objproduct1.NSP_AnniversaryBlngApplicable__c = true;
        objproduct1.NSP_SubscriptionStartDate__c = NSP_CPQConstants.SUBS_PROJGOLIVE;
        objproduct1.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objproduct1.NSP_Preferred_Payment_Method__c = null;
        objproduct1.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct1.blng__BillingRule__c = brObj.Id;
        objproduct1.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct1.NSP_ApplicableProduct_AmendDowngrade__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        objproduct1.blng__TaxRule__c = taxRuleObj.Id;
        productList.add(objproduct1);

        insert productList;

        List<PriceBookEntry> priceBookEntList = new List<PriceBookEntry>();
        PriceBookEntry objPriceBookEntry = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 100, false);
        PriceBookEntry objPriceBookEntry1 = NSP_TestHelper.createPriceBookEntry(objInvproduct.Id, 100, false);
        PriceBookEntry objPriceBookEntry2 = NSP_TestHelper.createPriceBookEntry(objproduct1.Id, 100, false);

        priceBookEntList.add(objPriceBookEntry);
        priceBookEntList.add(objPriceBookEntry1);
        priceBookEntList.add(objPriceBookEntry2);

        insert priceBookEntList;

         NSP_Address__c nspAddress = NSP_TestHelper.createCustomAddress();
        nspAddress.NSP_Related_Site__c = objaccount.Id;
        nspAddress.NSP_Source__c = 'AIMS';
        insert nspAddress;

        test.startTest();
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpportunity.Id, false);
        objQuote.SBQQ__primary__c = true;
        objQuote.NSP_Billing_Address__c = nspAddress.Id;
        objQuote.SBQQ__ShippingStreet__c = 'Alondra Boulevard';
        objQuote.SBQQ__ShippingCity__c = 'San Francisco';
        objQuote.SBQQ__StartDate__c = System.today().toStartOfMonth().addMonths(-3);
        objQuote.SBQQ__ShippingState__c = 'California';
        objQuote.SBQQ__ShippingCountry__c = 'United States';
        objQuote.SBQQ__ShippingPostalCode__c = '94103';
        objQuote.NSP_Shipping_Address__c = nspAddress.Id;
        objQuote.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_AMENDMENT;
        objQuote.SBQQ__PrimaryContact__c = objCon.Id;
        objQuote.NSP_Billing_Account__c = objaccount.Id;
        objQuote.SBQQ__Account__c = objaccount.Id;
        objQuote.SBQQ__PriceBook__c = priceBookRec.Id;
        objQuote.NSP_Change_Order_Process_Quote__c = true;
        insert objQuote;

        List<SBQQ__QuoteLine__c> objQuoteLine = NSP_TestHelper.createCPQQuotelines(objQuote, productList, priceBookEntList, false);
        insert objQuoteLine;

        objQuote.SBQQ__Ordered__c = true;
        Update objQuote;

        List<Order> orderList = [SELECT Id, NSP_Project__c FROM Order];
        orderList[0].NSP_Project__c = hcmProject.Id;
        update orderList;
        test.stopTest();
    }

    @isTest
    private static void checkDownPaymentDetailsMethod() {
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        List<Order> orderList = [Select Id, NSP_Down_Payment_Required__c, NSP_Project__c, NSP_Project__r.Project_Complete_Date__c, Status, SBQQ__Quote__c,
                        AccountId, NSP_Project_Go_Live_Date__c, (SELECT ID, SBQQ__BillingFrequency__c, NSP_Project__c, NSP_Project__r.Project_Complete_Date__c
                        FROM ORDERITEMS WHERE SBQQ__BillingFrequency__c IN ('Monthly', 'Annual', 'Invoice Plan'))NSP_Project_Go_Live_Approved__c,
                        NSP_Project_Complete_Date__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c
                        From Order];
        List<ID> orderIds = new List<ID>();
        orderIds.add(orderList[0].Id);
        CheckDownPaymentDetailsAction.checkDownPaymentDetails(orderIds);

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void checkDownPaymentDetailsMethodInvoicePlan() {
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        String invPlanId = '';
        List<Order> orderList = [Select Id, NSP_Down_Payment_Required__c, NSP_Project__c, NSP_Project__r.Project_Complete_Date__c, Status, SBQQ__Quote__c,
                        AccountId, NSP_Project_Go_Live_Date__c, (SELECT ID, SBQQ__BillingFrequency__c, NSP_Project__c, NSP_Project__r.Project_Complete_Date__c
                        FROM ORDERITEMS WHERE SBQQ__BillingFrequency__c IN ('Monthly', 'Annual', 'Invoice Plan'))NSP_Project_Go_Live_Approved__c,
                        NSP_Project_Complete_Date__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c
                        From Order];
        List<OrderItem> itemList = new List<OrderItem>();
        if( orderList != null && !orderList.isEmpty() ) {
            for(Order ord: orderList){
                if( ord.OrderItems != null && !ord.OrderItems.isEmpty() ) {
                    for(OrderItem item: ord.OrderItems){
                        if( item.SBQQ__BillingFrequency__c != 'Invoice Plan' ){
                            itemList.add(item);
                        }else {
                            invPlanId = item.Id;
                        }
                    }
                }
            }
        }
        if( itemList!= null && !itemList.isEmpty() ){
            delete itemList;
        }

        blng__InvoicePlan__c invPlanRecord = new blng__InvoicePlan__c();
        invPlanRecord.blng__Active__c = true;
        invPlanRecord.blng__BillingScheduleCreation__c = 'Order Product Activation';
        invPlanRecord.Name = NSP_CPQConstants.INVOICE_PLAN;
        insert invPlanRecord;

        //Insert Invoice Plan Line
        List<blng__InvoicePlan__c> invPlanRec = [Select Id from blng__InvoicePlan__c WHERE Id!=Null];
        blng__InvoicePlanLine__c planLineObj = new blng__InvoicePlanLine__c();
        planLineObj.Name = 'Invoiced at Project Completion';
        planLineObj.blng__Type__c = 'Percent';
        planLineObj.blng__Percentage__c = 0;
        planLineObj.blng__CommencementDate__c = 'Order Product Activation';
        planLineObj.blng__CommencementDateOffsetUnits__c = 'Days';
        planLineObj.NSP_Billing_Commencement_Trigger__c = 'Order Activation';
        planLineObj.blng__ProcessingOrder__c = 1.0;
        planLineObj.blng__InvoicePlan__c = invPlanRec[0].Id;
        insert planLineObj;

        blng__BillingSchedule__c blngSchedule= new blng__BillingSchedule__c();
        blngSchedule.blng__Amount__c = 100.00;
        blngSchedule.Name = 'Project Completion Plan';
        blngSchedule.blng__OrderProduct__c = invPlanId;
        insert blngSchedule;

        blng__BillingTransaction__c blngTranObj = new blng__BillingTransaction__c();
        blngTranObj.Name = 'Invoiced at Signature';
        blngTranObj.blng__Status__c = 'Pending';
        blngTranObj.blng__Amount__c = 100.00;
        blngTranObj.blng__Quantity__c = 1.00;
        blngTranObj.blng__InvoicePlanLine__c = planLineObj.Id;
        blngTranObj.blng__BillingSchedule__c = blngSchedule.Id;
        insert blngTranObj;

        List<ID> orderIds = new List<ID>();
        orderIds.add(orderList[0].Id);
        CheckDownPaymentDetailsAction.checkDownPaymentDetails(orderIds);

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

}
//
