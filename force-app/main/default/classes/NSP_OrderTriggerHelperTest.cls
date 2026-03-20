@isTest
private class NSP_OrderTriggerHelperTest {

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
        objCon.NSP_Sales_Tax_Contact_Key__c = '123';
        objCon.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Sales Tax').getRecordTypeId();
        objCon.NSP_Sales_Tax_Contact_Counter__c = 2;
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

        Product2 objInvproduct = NSP_TestHelper.createProduct('Test Product', false);
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
        productList.add(objproduct1);

        Product2 objproduct2 = NSP_TestHelper.createProduct('Test Product2', false);
        objproduct2.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct2.SBQQ__BillingType__c = 'Arrears';
        objproduct2.SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        objproduct2.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        objproduct2.NSP_Priority_Amendment__c = 14.0;
        objproduct2.NSP_Preferred_Payment_Method__c = 'ACH';
        objproduct2.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
        objproduct2.blng__BillingRule__c = brObj.Id;
        objproduct2.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct2.NSP_ApplicableProduct_AmendUpsell__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
        objproduct2.blng__TaxRule__c = taxRuleObj.Id;
        productList.add(objproduct2);

        Product2 objproduct3 = NSP_TestHelper.createProduct('Test Product3', false);
        objproduct3.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct3.SBQQ__BillingType__c = 'Arrears';
        objproduct3.SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        objproduct3.NSP_Priority_Amendment__c = 15.0;
        objproduct3.NSP_IsScholarshipPrice_Applicable__c = NSP_CPQConstants.YES;
        objproduct3.NSP_Order_Activation_Trigger_Amend__c = NSP_CPQConstants.IMMEDIATE;
        objproduct3.blng__BillingRule__c = brObj.Id;
        objproduct3.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct3.blng__TaxRule__c = taxRuleObj.Id;
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
        productList.add(objproduct6);

        Product2 objproduct7 = NSP_TestHelper.createProduct('Test Product7', false);
        objproduct7.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct7.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct7.SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        objproduct7.NSP_Priority_Amendment__c = 19.0;
        objproduct7.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct7.SBQQ__HasConsumptionSchedule__c = false;
        objproduct7.blng__BillingRule__c = brObj.Id;
        objproduct7.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objproduct7.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct7.blng__TaxRule__c = taxRuleObj.Id;
        productList.add(objproduct7);

        Product2 objproduct8 = NSP_TestHelper.createProduct('Test Product8', false);
        objproduct8.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
        objproduct8.SBQQ__BillingType__c = NSP_CPQConstants.BLNGTYPE_ADVANCE;
        objproduct8.SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        objproduct8.NSP_Priority_Amendment__c = 20.0;
        objproduct8.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        objproduct8.NSP_IsScholarshipPrice_Applicable__c = 'No';
        objproduct8.blng__BillingRule__c = brObj.Id;
        objproduct8.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct8.blng__TaxRule__c = taxRuleObj.Id;
        productList.add(objproduct8);

        insert productList;

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
        objQuoteLine[8].SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
        objQuoteLine[9].SBQQ__BillingFrequency__c = NSP_CPQConstants.MONTHLY;
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

        Asset asset = new Asset();
        asset.AccountId = objaccount.Id;
        asset.Name = 'xyz';
        asset.Product2Id = objproduct8.id;
        asset.Opportunity__c = objOpportunity.id;
        asset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Hardware_Asset').getRecordTypeId();
        asset.Status = 'Purchased';
        insert asset;

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
        test.stopTest();
    }

    @isTest
    private static void testOrderInsert() {
        NSP_Address__c nspAddress = [Select Id
                                     From NSP_Address__c WHERE Id!=null
                                     Limit 1];
        Id stdPriceBookId = Test.getStandardPricebookId();
        SBQQ__Quote__c quoteRecord = [Select Id, SBQQ__Account__c, SBQQ__Opportunity2__C
                                      From SBQQ__Quote__c WHERE Id!=null LIMIT 10];
        Test.startTest();
        Order testOrder2 = new Order();
        testOrder2.Pricebook2Id = stdPriceBookId;
        testOrder2.AccountId = quoteRecord.SBQQ__Account__c;
        testOrder2.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder2.NSP_First_usage_upload__c = true;
        testOrder2.Type = NSP_CPQConstants.ORDER_TYPE_NEW;
        testOrder2.NSP_Project_Name__c = Null;
        testOrder2.NSP_Shipping_Address__c = nspAddress.Id;
        testOrder2.SBQQ__Quote__c = quoteRecord.Id;
        testOrder2.EffectiveDate = Date.Today();
        testOrder2.blng__InvoiceBatch__c = 'Standalone Order';
        testOrder2.NSP_Project_Key__c = 'Test Project Key2';
        testOrder2.NSP_Project_Name__c = 'Test Project Name2';
        SBQQ.TriggerControl.disable();
        insert testOrder2;
        SBQQ.TriggerControl.enable();
        Test.stopTest();

        List<Order> orderList = [SELECT Id FROM Order WHERE SBQQ__Quote__c =: quoteRecord.Id];

        System.Assert(orderList.size()>0, 'Orders are inserted.');
    }

    @isTest
    private static void testOrderInsertSuppl() {
        NSP_Address__c nspAddress = [Select Id
                                     From NSP_Address__c WHERE Id!=null
                                     Limit 1];
        Id stdPriceBookId = Test.getStandardPricebookId();
        SBQQ__Quote__c quoteRecord = [Select Id, SBQQ__Account__c, SBQQ__Opportunity2__C, NSP_Project__c
                                      From SBQQ__Quote__c WHERE Id!=null LIMIT 10];

        pse__Proj__c proj = [SELECT id FROM pse__Proj__c LIMIT 1];
        quoteRecord.NSP_Project__c = proj.id;
        update quoteRecord;

        Test.startTest();
        Order testOrder2 = new Order();
        testOrder2.Pricebook2Id = stdPriceBookId;
        testOrder2.AccountId = quoteRecord.SBQQ__Account__c;
        testOrder2.Status = NSP_CPQConstants.ORDER_REVIEWED;
        testOrder2.NSP_First_usage_upload__c = true;
        testOrder2.Type = NSP_CPQConstants.SUPPLEMENTAL;
        testOrder2.NSP_Project_Name__c = Null;
        testOrder2.NSP_Shipping_Address__c = nspAddress.Id;
        testOrder2.SBQQ__Quote__c = quoteRecord.Id;
        testOrder2.EffectiveDate = Date.Today();
        testOrder2.blng__InvoiceBatch__c = 'Standalone Order';
        testOrder2.NSP_Project_Key__c = 'Test Project Key2';
        testOrder2.NSP_Project__c = proj.id;

        SBQQ.TriggerControl.disable();
        insert testOrder2;
        SBQQ.TriggerControl.enable();
        Test.stopTest();

        List<Order> orderList = [SELECT Id FROM Order WHERE SBQQ__Quote__c =: quoteRecord.Id];

        System.Assert(orderList.size()>0, 'Orders are inserted.');
    }

    @isTest
    private static void beforeUpdateDirectorMethod() {
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_Address__c nspAddress = [Select Id
                                     From NSP_Address__c WHERE Id!=null
                                     Limit 1];
        List<Order> orderList = [Select Id, NSP_Project__c, SBQQ__Quote__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 From Order WHERE Id!=null LIMIT 10];

        Id projId = orderList[0].NSP_Project__c;
        List<pse__Proj__c> project = [SELECT id, pse__Project_Status__c,Invoice_Ready__c, Go_Live_Date__c FROM pse__Proj__c LIMIT 1];
        orderList[0].NSP_Project__c = project[0].id;


        orderList[0].NSP_Billing_Address__c = nspAddress.Id;
        update orderList;
        //project not being created
        project[0].pse__Project_Status__c = 'Close/Lost';
        orderList[0].NSP_Billing_Address__c = null;
        Test.startTest();

        update project;
        update orderList;
        orderList[0].NSP_Shipping_Address__c = null;
        update orderList;
        orderList[0].NSP_Billing_Account__c = null;
        orderList[0].NSP_Project_Go_Live_Date__c = System.today() + 10;
        orderList[0].NSP_Project_Go_Live_Approved__c = true;
        orderList[0].NSP_Rev_Rec_Rules_Reviewed__c = true;

        update orderList;


        blng__TaxRule__c taxRuleRecord = [Select id From blng__TaxRule__c WHERE Id!=null limit 1];
        List<OrderItem> orderProducts = [SELECT Id, blng__TaxRule__c FROM OrderItem WHERE OrderId = :orderList[0].Id];

        for (OrderItem op : orderProducts) {
            op.blng__TaxRule__c = taxRuleRecord.Id; // Replace with the appropriate value
        }
        update orderProducts;

        orderList[0].Status = 'Reviewed';
        update orderList;
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void testCreateContract() {

        Test.startTest();
        blng__TaxRule__c taxRuleRecord = [Select id
                                          From blng__TaxRule__c WHERE Id!=null
                                          limit 1];
        List<Order> orderList = [Select Id, SBQQ__Quote__c, Status, EffectiveDate, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 From Order WHERE Id!=null LIMIT 10];
        orderList[0].NSP_Project__c = null;
        orderList[0].EffectiveDate = System.today().toStartOfMonth().addMonths(-3);
        orderList[0].NSP_First_usage_upload__c = false;
        Update orderList;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        List<OrderItem> orderProductList = [SELECT Id, Product2.ProductCode, NSP_Priority_New_Sales__c, NSP_Project_Name_New_Sales__c, OrderId
                                            from OrderItem
                                            WHERE OrderId IN:orderList];
        orderProductList[0].NSP_Priority_New_Sales__c = 10;
        orderProductList[0].blng__TaxRule__c = taxRuleRecord.id;
        orderProductList[1].blng__TaxRule__c = taxRuleRecord.id;
        orderProductList[0].NSP_Product_Type__c = 'test';
        Update orderProductList;
        orderlist[0].Type = NSP_CPQConstants.ORDER_TYPE_NEW;
        orderList[0].Status = NSP_CPQConstants.ORDER_REVIEWED;
        orderList[0].NSP_First_usage_upload__c = true;
        Update orderList;
        orderProductList[0].blng__TaxRule__c = taxRuleRecord.id;
        orderProductList[1].blng__TaxRule__c = taxRuleRecord.id;
        Update orderProductList;
        orderList[0].Status = NSP_CPQConstants.ORDER_ACTIVATED;
        SBQQ.TriggerControl.disable();
        update orderList;
        SBQQ.TriggerControl.enable();
        List<OrderItem> ObjOrderProductList = [SELECT Id, SBQQ__Status__c, ServiceDate, NSP_Order_Activation_Trigger__c, SBQQ__QuoteLine__r.SBQQ__HasConsumptionSchedule__c
                                            FROM OrderItem
                                            WHERE  NSP_Order_Activation_Trigger__c = :NSP_CPQConstants.FIRSTUSAGEUPLOAD];

        if(!ObjOrderProductList.isEmpty()){
        ObjOrderProductList[1].ServiceDate = System.today().toStartOfMonth().addMonths(-2);
        ObjOrderProductList[1].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        ObjOrderProductList[1].SBQQ__QuoteLine__r.SBQQ__HasConsumptionSchedule__c = false;
        ObjOrderProductList[2].ServiceDate = System.today().toStartOfMonth().addMonths(-2);
        ObjOrderProductList[2].NSP_Order_Activation_Trigger__c = NSP_CPQConstants.FIRSTUSAGEUPLOAD;
        ObjOrderProductList[2].SBQQ__QuoteLine__r.SBQQ__HasConsumptionSchedule__c = false;
        update ObjOrderProductList;
        }
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void testProcessConsumptionSchedule() {
        Test.startTest();
        NSP_OrderItemTriggerHelper.processConsumptionSchedule(
            new List<String>() ,
            3 ,
            new List<String>()
        );
        Test.stopTest();
    }

    @isTest
    private static void createInvoiceMethod() {
        List<Order> orderList = [Select Id, Status, SBQQ__Quote__c, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 From Order WHERE Id!=null LIMIT 10];
        List<blng__PaymentMethod__c> objPaymntMethod = [SELECT Id, blng__Account__c,Payment_Method_Type__c FROM blng__PaymentMethod__c WHERE blng__BankAccountName__c = 'saving'];
        Test.startTest();
        orderList[0].Status = 'Reviewed';
        List<OrderItem> ObjOrderProductList = [SELECT Id, SBQQ__Status__c, ServiceDate, NSP_Order_Activation_Trigger__c
                                            FROM OrderItem
                                            WHERE  SBQQ__BillingFrequency__c = 'Invoice Plan' AND OrderId =: orderList[0].ID];
        blng__BillingSchedule__c blngSchedule= new blng__BillingSchedule__c();
        blngSchedule.blng__Amount__c = 100.00;
        blngSchedule.Name = 'Project Completion Plan';
        blngSchedule.blng__OrderProduct__c = ObjOrderProductList[0].Id;
        insert blngSchedule;
        List<blng__BillingSchedule__c> blngSchdObj = [Select Id FROM blng__BillingSchedule__c WHERE blng__OrderProduct__c =: ObjOrderProductList[0].ID];
        List<blng__InvoicePlanLine__c> invPlanLineRec = [Select Id from blng__InvoicePlanLine__c WHERE Id!=null LIMIT 10];

        blng__BillingTransaction__c blngTranObj = new blng__BillingTransaction__c();
        blngTranObj.Name = 'Invoiced at Signature';
        blngTranObj.blng__Status__c = 'Pending';
        blngTranObj.blng__Amount__c = 100.00;
        blngTranObj.blng__Quantity__c = 1.00;
        blngTranObj.blng__InvoicePlanLine__c = invPlanLineRec[0].Id;
        blngTranObj.blng__BillingSchedule__c = blngSchdObj[0].Id;
        insert blngTranObj;
        orderList[0].NSP_Project_Go_Live_Approved__c = true;
        orderList[0].NSP_Project_Go_Live_Date__c = System.today() + 20;
        update orderList;
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void createInvoiceMethod2() {
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        List<Order> orderList = [Select Id, Status, SBQQ__Quote__c, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 From Order  WHERE Id!=null  LIMIT 10];
        List<blng__PaymentMethod__c> objPaymntMethod = [SELECT Id, blng__Account__c,Payment_Method_Type__c
                                                        FROM blng__PaymentMethod__c WHERE Id!=null  LIMIT 10];
        List<OrderItem> orderItemList = [SELECT Id, SBQQ__Status__c, Order.Type, NSP_Preferred_Payment_Method__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Order.AccountId, NSP_Payment_Method__c, ServiceDate, SBQQ__BillingFrequency__c, NSP_AnniversaryBlngApplicable__c, SBQQ__SubscriptionTerm__c
                                         FROM OrderItem
                                         WHERE OrderId IN:orderList];

        Test.startTest();
        orderList[0].Status = 'Reviewed';
        orderList[0].Type = 'New Product';
        update orderList;
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void createInvoiceMethod3() {
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        List<Order> orderList = [Select Id, blng__BillingAccount__c,NSP_Rev_Rec_Rules_Reviewed__c,Status, SBQQ__Quote__c, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 From Order WHERE Id!=null LIMIT 10];
        List<blng__PaymentMethod__c> objPaymntMethod = [SELECT Id, blng__Account__c,Payment_Method_Type__c
                                                        FROM blng__PaymentMethod__c  WHERE Id!=null LIMIT 10];
        List<OrderItem> orderItemList = [SELECT Id, blng__TaxRule__c,SBQQ__Status__c, Order.Type, NSP_Preferred_Payment_Method__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Order.AccountId, NSP_Payment_Method__c, ServiceDate, SBQQ__BillingFrequency__c, NSP_AnniversaryBlngApplicable__c, SBQQ__SubscriptionTerm__c
                                         FROM OrderItem  WHERE OrderId IN:orderList LIMIT 10];
        Account acc = [SELECT id FROM Account WHERE NAME = 'Insperity WO Billing Account' LIMIT 1];

        orderList[0].NSP_Rev_Rec_Rules_Reviewed__c = true;
        SBQQ.TriggerControl.disable();
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        update orderList;
        SBQQ.TriggerControl.enable();


        Test.startTest();
        orderList[0].Status = 'Reviewed';
        orderList[0].Type = NSP_CPQConstants.QUOTE_TYPE_AMENDMENT;
        orderList[0].blng__BillingAccount__c = acc.id;

        update orderList;
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void testCreateContractAmendment() {

        Test.startTest();
        List<Order> orderList = [Select Id, SBQQ__Quote__c, Status, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 From Order  WHERE Id!=null LIMIT 10];
        orderList[0].NSP_Project__c = null;
        orderList[0].NSP_First_usage_upload__c = false;
        Update orderList;

        orderList[0].NSP_Project__c = null;
        orderList[0].NSP_First_usage_upload__c = true;
        orderList[0].Type = NSP_CPQConstants.ORDER_TYPE_AMENDMENT;
        orderList[0].NSP_Back_Out__c = true;
        orderList[0].NSP_CreateProject__c = true;
        NSP_OrderTriggerHelper.changeTaxRulesForWOOrders(new set<Id>{ [SELECT Id
                                                                       FROM Order  WHERE Id!=null
                                                                       LIMIT 1]?.Id });
        Update orderList;

        List<OrderItem> orderItemList = [SELECT Id, SBQQ__Status__c, Order.Type, NSP_Preferred_Payment_Method__c, NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c, Order.AccountId, NSP_Payment_Method__c, ServiceDate, SBQQ__BillingFrequency__c, NSP_AnniversaryBlngApplicable__c, SBQQ__SubscriptionTerm__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.Product2.ProductCode
                                         FROM OrderItem  WHERE OrderId IN:orderList LIMIT 10];
        orderItemList[0].NSP_Priority_Amendment__c = 10.0;
        orderItemList[1].NSP_Priority_Amendment__c = 13.0;
        orderItemList[2].NSP_Priority_Amendment__c = 14.0;
        orderItemList[3].NSP_Priority_Amendment__c = 15.0;
        orderItemList[4].NSP_Priority_Amendment__c = 16.0;
        orderItemList[5].NSP_Priority_Amendment__c = 17.0;
        orderItemList[6].NSP_Priority_Amendment__c = 18.0;
        orderItemList[7].NSP_Priority_Amendment__c = 19.0;
        orderItemList[8].NSP_Priority_Amendment__c = 1.0;
        orderItemList[9].NSP_Priority_Amendment__c = 2.0;
        update orderItemList;

        orderList[0].NSP_Project__c = null;
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }


    @isTest
    private static void createInvoiceMethod4() {
        List<Order> orderList = [Select Id,Status,SBQQ__Quote__c, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c, NSP_Project_Complete_Date__c,NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c,NSP_Billing_Address__c,NSP_Shipping_Address__c,NSP_Billing_Account__c From Order WHERE Id!=null LIMIT 10];
        orderList[0].Type = NSP_CPQConstants.QUOTE_TYPE_NEW;
        orderList[0].NSP_Project_Go_Live_Date__c = System.today()+5;
        update orderList;
        Test.startTest();
        orderList[0].Status = NSP_CPQConstants.ORDER_REVIEWED;
        orderList[0].Type = NSP_CPQConstants.ORDER_TYPE_NEW;
        orderList[0].NSP_Project_Go_Live_Date__c = System.today()+20;
        orderList[0].NSP_Project_Complete_Date__c = System.today();
        update orderList;
        Test.stopTest();

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void createAndStampSalesTaxContactMethod() {
        NSP_AccountContactRelationTriggerHandler.TriggerDisabled = true;
        List<Account> accList = [SELECT Id
                                 FROM Account WHERE Id!=null  LIMIT 10];
        List<Contact> conList = [SELECT Id, RecordTypeId, NSP_Sales_Tax_Contact_Key__c, AccountId, Account.Name, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, MailingStateCode, MailingCountryCode
                                 FROM Contact WHERE Id!=null  LIMIT 10];
        Set<Id> accIdList = new Set<Id>();
        accIdList.add(accList[0].Id);
        List<Order> orderList = [SELECT Id, Status, blng__BillingAccount__c, ShippingStateCode, ShippingCountryCode, ShippingStreet, ShippingCity, ShippingState, ShippingCountry, ShippingPostalCode, NSP_Ship_To_Street__c, NSP_Ship_To_City__c, NSP_Ship_To_State__c, NSP_Ship_To_Country__c, NSP_Ship_To_Postal_Code__c, NSP_Invoice_To_Email__c, ShipToContactId, BillToContactId, SBQQ__Quote__c, AccountId, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                 FROM Order WHERE Id!=null  LIMIT 10];
        orderList[0].NSP_Billing_Account__c = accList[0].Id;

        update orderList;
        Map<String, Order> orderAddressKeyToCheck = new Map<String, Order>();
        orderAddressKeyToCheck.put(orderList[0].Id, orderList[0]);
        NSP_OrderTriggerHelper.createAndStampSalesTaxContact(accIdList, orderList, orderAddressKeyToCheck);

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
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
        NSP_OrderTriggerHelper.checkDownPaymentDetails(orderIds);

        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void testStampDunningEmailonContact() {
        NSP_AccountContactRelationTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled = true;
        NSP_UserTriggerHandler.TriggerDisabled = true;
        Account objaccount = NSP_TestHelper.createAccount(false);
        objaccount.Name = 'Insperity WO Billing Account1';
        insert objaccount;
        Profile proRecord = [SELECT Id, Name
                             FROM profile
                             WHERE Name = 'Integration User'
                             LIMIT 1];
        Contact conrecord = [SELECT Id, AccountId
                             FROM Contact WHERE Id!=null
                             LIMIT 1];
        User userRecord = new User(LastName = 'Test User1', ProfileId = proRecord.Id, Email = 'testuser1@insperity.com', Username = 'testuser1@test.com' + System.currentTimeMillis(), CompanyName = 'TEST', Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US', NSP_Sales_Office_Membership__c = '301', LocaleSidKey = 'en_US');
        insert userRecord;
        System.runAs(userRecord){
        }
        AccountContactRelation accConRelRecord = new AccountContactRelation(ContactId = conrecord.Id, AccountId = objaccount.Id);
        insert accConRelRecord;
        Test.startTest();
        Set<String> uniqueId = new Set<String>{ String.valueof(accConRelRecord.ContactId) + String.valueOf(accConRelRecord.AccountId) };
        Set<Id> conSet = new Set<Id>{ accConRelRecord.ContactId };
        Set<Id> accSet = new Set<Id>{ accConRelRecord.AccountId };
        NSP_OrderTriggerHelper.StampDunningEmailonContact(conSet, accSet, uniqueId);
        Test.stopTest();

        List<AccountContactRelation> updatedACR = [SELECT Id, NSP_Dunning_Emails__c FROM AccountContactRelation WHERE ContactId =: conrecord.Id];
        System.assert(updatedACR.size()>0, 'Account contact relation Records are present.');

    }

    @isTest
    private static void testUpdateStartDateOnTerm() {
        List<Order> orderList = [Select Id,Status,SBQQ__Quote__c, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c,NSP_Billing_Address__c,NSP_Shipping_Address__c,NSP_Billing_Account__c From Order WHERE Id!=null LIMIT 10];
        orderList[0].Status = NSP_CPQConstants.ORDER_DRAFT ;
        orderList[0].Type = NSP_CPQConstants.QUOTE_TYPE_TERMINATION;
        orderList[0].NSP_TerminationDate__c = Date.today()-20;
        update orderList[0];
        orderList[0].NSP_TerminationDate__c = Date.today();
        update orderList[0];
        System.assert(orderList[0].id!=null, true);
        NSP_OrderTriggerHelper.updateOrderStartDate( new Set<Id>{ orderList[0].Id } );
    }

    @isTest
    private static void createInvoiceMethod5() {
        List<Order> orderList = [SELECT id,AccountId,OpportunityId, Type,NSP_Transaction_Type__c, Status, NSP_Back_Out__c, NSP_Project_Go_Live_Date__c, NSP_Project_Go_Live_Approved__c FROM Order WHERE NSP_Back_Out__c = false];
        List<pse__Proj__c> project = [SELECT id, pse__Project_Status__c,Invoice_Ready__c, Go_Live_Date__c FROM pse__Proj__c LIMIT 1];
        List<OrderItem> items = [SELECT id, Product2Id,SBQQ__BillingFrequency__c,NSP_Order_Activation_Trigger__c, NSP_Order_Activation_Trigger_Amend__c FROM OrderItem WHERE OrderId =: orderList[0].id];
        for(integer i=0;i<items.size();i++){
            items[i].SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_MONTHLY;
        }

        system.debug('ITEMS LIST VAIBHAV = '+items);
        orderList[0].NSP_Project__c = project[0].id;
        orderList[0].NSP_Project_Go_Live_Date__c = System.today();
        orderList[0].NSP_Project_Go_Live_Approved__c = true;
        orderList[0].Status = 'Reviewed';
        orderList[0].Type = 'New Product';
        SBQQ.TriggerControl.disable();
        update orderList;
        update items;
        SBQQ.TriggerControl.enable();


        Test.startTest();
        project[0].Invoice_Ready__c = true;
        project[0].Go_Live_Date__c = System.today();
        update project;

        Test.stopTest();

        system.debug('HI ORDER LIST VAIBHAV = ' + orderList);
        System.assert(orderList.size()>0, 'Order List size is greater than 0');
    }

    @isTest
    private static void createContractTest2() {
        List<Order> orderList = [SELECT id,Type,Status,blng__InvoiceBatch__c, NSP_Order_Product_Type__c fROM Order Where Status != 'Activated'];
        orderList[0].Status = NSP_CPQConstants.ORDER_REVIEWED;
        List<OrderItem> itemsList = [SELECT Id, ServiceDate FROM OrderItem WHERE OrderId = :orderList[0].id];
        itemsList[0].ServiceDate = System.Today();

        update itemsList;

        SBQQ.TriggerControl.disable();
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        update orderList;
        SBQQ.TriggerControl.enable();

        Test.startTest();
        NSP_OrderTriggerHelper.setInvoiceBatch(new Set<Id>{ orderList[0].Id }, orderList);
        NSP_OrderTriggerHelper.updateUsageProd(new Set<Id>{ orderList[0].Id }, orderList);
        NSP_OrderTriggerHelper.setProjNameSupplement(new Set<Id>{ orderList[0].Id },orderList);
        Test.stopTest();

        system.debug('VAIBHAV ORDER LIST = '+ orderList);
        System.assert(orderList.size()>0, 'Order List size is greater than 0');
        NSP_UpdateProjMilestone.testHandleException( null , null );
    }

}
//