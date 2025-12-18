@isTest
private class NSP_ProcessOrderCancellationBatchTest {
    private static final Id CHOICECLIENTSUBPLANRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'NSP_Client_Sub_Plan_History__c' , 'Choice' );
    private static final Id RETSERVICESASSETRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'RET_Choice' );

    @testSetup
    private static void setupTestData() {
        ProcessOrderCancellationBatchSettings__c settings = ProcessOrderCancellationBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 1;
        upsert settings;

        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        Pricebook2 priceBookRec = NSP_TestHelper.getStandardPriceBook2();

        Id stdPriceBookId = Test.getStandardPricebookId();
        Account objaccount = NSP_TestHelper.createAccount(false);
        objaccount.Name = 'Insperity WO Billing Account';
        insert objaccount;

        Contact objCon = NSP_TestHelper.createContact(objaccount.id, false);
        objCon.NSP_Sales_Tax_Contact_Key__c = '123';
        objCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Sales Tax').getRecordTypeId();
        objCon.NSP_Sales_Tax_Contact_Counter__c = 2;
        insert objCon;

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
        blngFinanceRec.blng__FinancePeriodDuration__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        blngFinanceRec.Name = 'Insperity Salesforce Finance Book';
        blngFinanceRec.blng__PeriodType__c = 'Accounting';
        insert blngFinanceRec;
        blng__InvoicePlan__c invPlanRecord = new blng__InvoicePlan__c();
        invPlanRecord.blng__Active__c = true;
        invPlanRecord.blng__BillingScheduleCreation__c = 'Order Product Activation';
        invPlanRecord.Name = NSP_CPQConstants.INVOICE_PLAN;
        insert invPlanRecord;

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
        objproduct.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objproduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objproduct.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct.blng__TaxRule__c = taxRuleObj.Id;
        objproduct.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct);

        Product2 objInvproduct = NSP_TestHelper.createProduct('Test Product', false);
        objInvproduct.ProductCode = 'IWXBundle';
        objInvproduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objInvproduct.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objInvproduct.NSP_Priority_Amendment__c = 12.0;
        objInvproduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
        objInvproduct.SBQQ__BillingFrequency__c = NSP_CPQConstants.INVOICE_PLAN;
        objInvproduct.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objInvproduct.blng__BillingRule__c = brObj.Id;
        objInvproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objInvproduct.blng__TaxRule__c = taxRuleObj.Id;
        objInvproduct.SBQQ__SubscriptionType__c = 'Renewable';
        objproduct.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        productList.add(objInvproduct);

        Product2 objproduct1 = NSP_TestHelper.createProduct('Test Product1', false);
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
        objproduct1.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct1);

        Product2 objproduct2 = NSP_TestHelper.createProduct('Test Product2', false);
        objproduct2.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct2.SBQQ__BillingType__c = 'Arrears';
        objproduct2.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objproduct2.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        objproduct2.NSP_Priority_Amendment__c = 14.0;
        objproduct2.NSP_Preferred_Payment_Method__c = 'ACH';
        objproduct2.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objproduct2.blng__BillingRule__c = brObj.Id;
        objproduct2.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct2.NSP_ApplicableProduct_AmendUpsell__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        objproduct2.blng__TaxRule__c = taxRuleObj.Id;
        objproduct2.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct2);

        Product2 objproduct3 = NSP_TestHelper.createProduct('Test Product3', false);
        objproduct3.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct3.SBQQ__BillingType__c = 'Arrears';
        objproduct3.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objproduct3.NSP_Priority_Amendment__c = 15.0;
        objproduct3.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        objproduct3.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.IMMEDIATE;
        objproduct3.blng__BillingRule__c = brObj.Id;
        objproduct3.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct3.blng__TaxRule__c = taxRuleObj.Id;
        objproduct3.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct3);

        Product2 objproduct4 = NSP_TestHelper.createProduct('Test Product4', false);
        objproduct4.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct4.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct4.SBQQ__BillingFrequency__c = 'Annual';
        objproduct4.NSP_Priority_Amendment__c = 16.0;
        objproduct4.NSP_AnniversaryBlngApplicable__c = true;
        objproduct4.NSP_SubscriptionStartDate__c = NSP_CPQConstants.SUBS_PROJGOLIVE;
        objproduct4.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.MILESTONEBASED;
        objproduct4.NSP_Preferred_Payment_Method__c = null;
        objproduct4.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct4.blng__BillingRule__c = brObj.Id;
        objproduct4.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct4.blng__TaxRule__c = taxRuleObj.Id;
        objproduct4.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct4);

        Product2 objproduct5 = NSP_TestHelper.createProduct('Test Product5', false);
        objproduct5.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct5.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct5.SBQQ__BillingFrequency__c = NSP_CPQConstants.INVOICE_PLAN;
        objproduct5.NSP_AnniversaryBlngApplicable__c = true;
        objproduct5.NSP_Priority_Amendment__c = 17.0;
        objproduct5.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct5.blng__BillingRule__c = brObj.Id;
        objproduct5.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct5.blng__TaxRule__c = taxRuleObj.Id;
        objproduct5.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.MILESTONEBASED;
        objproduct5.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct5);

        Product2 objproduct6 = NSP_TestHelper.createProduct('Test Product6', false);
        objproduct6.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct6.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct6.SBQQ__BillingFrequency__c = NSP_CPQConstants.INVOICE_PLAN;
        objproduct6.NSP_Preferred_Payment_Method__c = null;
        objproduct6.NSP_Priority_Amendment__c = 18.0;
        objproduct6.NSP_AnniversaryBlngApplicable__c = true;
        objproduct6.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct6.blng__BillingRule__c = brObj.Id;
        objproduct6.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct6.blng__TaxRule__c = taxRuleObj.Id;
        objproduct6.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objproduct6.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct6);

        Product2 objproduct7 = NSP_TestHelper.createProduct('Test Product7', false);
        objproduct7.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct7.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct7.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objproduct7.NSP_Priority_Amendment__c = 19.0;
        objproduct7.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct7.SBQQ__HasConsumptionSchedule__c = false;
        objproduct7.blng__BillingRule__c = brObj.Id;
        objproduct7.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objproduct7.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct7.blng__TaxRule__c = taxRuleObj.Id;
        objproduct7.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct7);

        Product2 objproduct8 = NSP_TestHelper.createProduct('Test Product8', false);
        objproduct8.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct8.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct8.SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objproduct8.NSP_Priority_Amendment__c = 20.0;
        objproduct8.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objproduct8.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct8.blng__BillingRule__c = brObj.Id;
        objproduct8.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct8.blng__TaxRule__c = taxRuleObj.Id;
        objproduct8.SBQQ__SubscriptionType__c = 'Renewable';
        productList.add(objproduct8);

        insert productList;

        List<Contract> allContract = new List<Contract>();
        Contract ct = new Contract();
        ct.AccountId = objaccount.Id;
        ct.SBQQ__Opportunity__c = objOpportunity.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = 'Performance Management';
        Date dt = Date.today();
        ct.StartDate = dt;
        ct.Status = 'Draft';
        ct.NSP_Number_of_Employees__c = 86;
        allContract.add(ct);

        Contract ct2 = new Contract();
        ct2.AccountId = objaccount.Id;
        ct2.SBQQ__Opportunity__c = objOpportunity.Id;
        ct2.ContractTerm = 12;
        ct2.NSP_Product_Type__c = 'Performance Management';
        ct2.StartDate = Date.today();
        ct2.Status = 'Draft';
        ct2.NSP_Number_of_Employees__c = 50;
        allContract.add(ct2);

        insert allContract;

        List<PriceBookEntry> priceBookEntList = new List<PriceBookEntry>();
        PriceBookEntry objPriceBookEntry = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 100, false);
        PriceBookEntry objPriceBookEntry1 = NSP_TestHelper.createPriceBookEntry(objInvproduct.Id, 100, false);
        PriceBookEntry objPriceBookEntry2 = NSP_TestHelper.createPriceBookEntry(objproduct1.Id, 100, false);
        PriceBookEntry objPriceBookEntry3 = NSP_TestHelper.createPriceBookEntry(objproduct2.Id, 100, false);
        PriceBookEntry objPriceBookEntry4 = NSP_TestHelper.createPriceBookEntry(objproduct3.Id, 100, false);
        PriceBookEntry objPriceBookEntry5 = NSP_TestHelper.createPriceBookEntry(objproduct4.Id, 100, false);
        PriceBookEntry objPriceBookEntry6 = NSP_TestHelper.createPriceBookEntry(objproduct5.Id, 100, false);
        PriceBookEntry objPriceBookEntry7 = NSP_TestHelper.createPriceBookEntry(objproduct6.Id, 100, false);
        PriceBookEntry objPriceBookEntry8 = NSP_TestHelper.createPriceBookEntry(objproduct7.Id, 100, false);
        PriceBookEntry objPriceBookEntry9 = NSP_TestHelper.createPriceBookEntry(objproduct8.Id, 100, false);
        priceBookEntList.add(objPriceBookEntry);
        priceBookEntList.add(objPriceBookEntry1);
        priceBookEntList.add(objPriceBookEntry2);
        priceBookEntList.add(objPriceBookEntry3);
        priceBookEntList.add(objPriceBookEntry4);
        priceBookEntList.add(objPriceBookEntry5);
        priceBookEntList.add(objPriceBookEntry6);
        priceBookEntList.add(objPriceBookEntry7);
        priceBookEntList.add(objPriceBookEntry8);
        priceBookEntList.add(objPriceBookEntry9);
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
        objQuoteLine[0].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objQuoteLine[0].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[8].SBQQ__StartDate__c = System.today().toStartOfMonth().addMonths(-2);
        objQuoteLine[8].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objQuoteLine[8].SBQQ__HasConsumptionSchedule__c = false;
        objQuoteLine[9].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objQuoteLine[9].SBQQ__HasConsumptionSchedule__c = false;
        objQuoteLine[9].SBQQ__StartDate__c = System.today().toStartOfMonth().addMonths(-2);
        objQuoteLine[1].NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        objQuoteLine[1].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
        objQuoteLine[2].NSP_ApplicableProduct_AmendDowngrade__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        objQuoteLine[3].NSP_ApplicableProduct_AmendUpsell__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        objQuoteLine[1].NSP_Action_Type__c = NSP_CPQConstants.ACTION_NEW;
        objQuoteLine[2].NSP_Action_Type__c = NSP_CPQConstants.ACTION_DOWNGRADE;
        objQuoteLine[2].NSP_Quoted_Quantity__c = 22;
        objQuoteLine[2].NSP_Previous_Quantity__c = 25;
        objQuoteLine[3].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
        objQuoteLine[3].NSP_Quoted_Quantity__c = 25;
        objQuoteLine[3].NSP_Previous_Quantity__c = 22;
        objQuoteLine[0].NSP_Priority_Amendment__c = 11.0;
        objQuoteLine[1].NSP_Priority_Amendment__c = 12.0;
        objQuoteLine[2].NSP_Priority_Amendment__c = 13.0;
        objQuoteLine[3].NSP_Priority_Amendment__c = 14.0;
        objQuoteLine[4].NSP_Priority_Amendment__c = 15.0;
        objQuoteLine[5].NSP_Priority_Amendment__c = 16.0;
        objQuoteLine[6].NSP_Priority_Amendment__c = 17.0;
        objQuoteLine[7].NSP_Priority_Amendment__c = 18.0;
        objQuoteLine[8].NSP_Priority_Amendment__c = 19.0;
        objQuoteLine[9].NSP_Priority_Amendment__c = 20.0;
        objQuoteLine[0].SBQQ__RequiredBy__c = objQuoteLine[0].Id;
        objQuoteLine[1].SBQQ__RequiredBy__c = objQuoteLine[0].Id;
        objQuoteLine[2].NSP_AnniversaryBlngApplicable__c = true;
        objQuoteLine[2].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[2].NSP_SubscriptionStartDate__c = NSP_CPQConstants.SUBS_PROJGOLIVE;
        objQuoteLine[3].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objQuoteLine[3].NSP_Preferred_Payment_Method__c = 'ACH';
        objQuoteLine[3].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[4].NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.IMMEDIATE;
        objQuoteLine[4].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[5].NSP_SubscriptionStartDate__c = NSP_CPQConstants.SUBS_PROJGOLIVE;
        objQuoteLine[5].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[6].SBQQ__BillingFrequency__c = NSP_CPQConstants.INVOICE_PLAN;
        objQuoteLine[6].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.MILESTONEBASED;
        objQuoteLine[7].NSP_Preferred_Payment_Method__c = null;
        objQuoteLine[7].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objQuoteLine[8].SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objQuoteLine[9].SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        objQuoteLine[6].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[7].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[8].SBQQ__HasConsumptionSchedule__c = true;
        objQuoteLine[9].SBQQ__HasConsumptionSchedule__c = true;
        insert objQuoteLine;

        objQuoteLine[1].SBQQ__RequiredBy__c = objQuoteLine[0].Id;
        objQuoteLine[2].SBQQ__RequiredBy__c = objQuoteLine[1].Id;
        objQuoteLine[2].SBQQ__Source__c = objQuoteLine[1].Id;
        objQuoteLine[3].SBQQ__RequiredBy__c = objQuoteLine[2].Id;
        objQuoteLine[3].SBQQ__Source__c = objQuoteLine[2].Id;
        update objQuoteLine;

        objQuote.SBQQ__Ordered__c = true;
        Update objQuote;

        blng__PaymentMethod__c objPaymntMethod = new blng__PaymentMethod__c();
        objPaymntMethod.blng__Account__c = objaccount.Id;
        objPaymntMethod.blng__Active__c = true;
        objPaymntMethod.blng__BankAccountName__c = 'saving';
        objPaymntMethod.blng__BankAccountNumber__c = '1238388';
        objPaymntMethod.blng__BankAccountType__c = 'Savings';
        objPaymntMethod.blng__BankName__c = 'CITI';
        objPaymntMethod.blng__BankRoutingCode__c = '9874';
        objPaymntMethod.NSP_Active_Custom__c = true;
        objPaymntMethod.NSP_ACH_method__c = 'BoFA';
        objPaymntMethod.blng__PaymentType__c = 'ACH';
        objPaymntMethod.Payment_Method_Type__c = 'ACH';
        insert objPaymntMethod;

        stdPriceBookId = Test.getStandardPricebookId();

        Order testOrder2 = new Order();
        testOrder2.Pricebook2Id = stdPriceBookId;
        testOrder2.AccountId = objQuote.SBQQ__Account__c;
        testOrder2.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder2.NSP_First_usage_upload__c = true;
        testOrder2.Type = NSP_CPQConstants.ORDER_TYPE_NEW;
        testOrder2.NSP_Project_Name__c = Null;
        testOrder2.NSP_Shipping_Address__c = addressShipToRecord.Id;
        testOrder2.SBQQ__Quote__c = objQuote.Id;
        testOrder2.EffectiveDate = Date.Today();
        testOrder2.blng__InvoiceBatch__c = 'Standalone Order';
        testOrder2.NSP_Project_Key__c = 'Test Project Key2';
        testOrder2.NSP_Project_Name__c = 'Test Project Name2';
        SBQQ.TriggerControl.disable();
        insert testOrder2;

        OrderItem ordpr1 = new OrderItem (OrderId = testOrder2.Id, Product2Id=objproduct.Id, UnitPrice=10.0,Quantity=5,PricebookEntryId=objPriceBookEntry.Id);
        ordpr1.blng__BillingRule__c=brObj.Id;
        ordpr1.blng__TaxRule__c=taxRuleObj.Id;
        ordpr1.blng__RevenueRecognitionRule__c=rrObj.Id;
        List<OrderItem> allorderprods = new List<OrderItem>{ordpr1};
        insert allorderprods;

        List<SBQQ__Subscription__c> allSubscription = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(SBQQ__Product__c=objproduct.Id,SBQQ__Contract__c=ct.Id,SBQQ__Quantity__c=5,SBQQ__OrderProduct__c=ordpr1.Id);
        allSubscription.add(sub1);

        insert allSubscription;
        SBQQ.TriggerControl.enable();

        test.stopTest();
    }

    @isTest
    private static void testProcessCancellation() {
        list<Order> orderList = [SELECT Id from Order where EffectiveDate != null];
        OrderItem ordProd = [SELECT Id, OrderId, Product2Id FROM OrderItem WHERE OrderId !=null LIMIT 1];

        Test.startTest();
        //Creat a new Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newAsset.NSP_Client_is_Lead_Parent__c = true;
        newAsset.NSP_Price_Level__c= 'RET - Bundled Plus #2';
        Database.insert(newAsset);

        Asset newMemberAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newMemberAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newMemberAsset.NSP_Process_Order_Change__c = true;
        newMemberAsset.NSP_RET_lead_parent__c = newAsset.Id;
        newMemberAsset.NSP_ReAssigned_Order_Id__c = orderList[0].id;
        newMemberAsset.NSP_OrderProduct__c =ordProd.Id;
        newMemberAsset.NSP_Change_Order_Process_Contract_Status__c = 'Ready To Close';
        Database.insert(newMemberAsset);

        DateTime oneMinuteInTheFuture = System.now().addMinutes( 1 );
        String strSchedule = ''
            + '0 '
            + oneMinuteInTheFuture.minute() + ' '
            + oneMinuteInTheFuture.hour() + ' '
            + oneMinuteInTheFuture.day() + ' '
            + oneMinuteInTheFuture.month() + ' '
            + '? '
            + oneMinuteInTheFuture.year()
            ;
        System.schedule('Sample Job', strSchedule, new NSP_ProcessOrderCancellationBatch());

        Test.stopTest();
        Asset newAsset1=[SELECT Id,NSP_Change_Order_Process_Contract_Status__c FROM Asset WHERE Id=:newMemberAsset.Id limit 1];
    }

    @isTest
    private static void testCodeCoverage() {
        Test.startTest();
        NSP_ProcessOrderCancellationBatch.testHandleException( null , null );
        NSP_ProcessOrderCancellationBatch.schedule();
        Test.stopTest();
    }

}
//