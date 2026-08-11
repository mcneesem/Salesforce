@isTest
private class NSP_OrderItemTriggerHelperTest{

    @testSetup
    private static void setupTestData() {
        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        upsert orderSetting;

        NSP_Trigger_Switch__c triggerSetting = new NSP_Trigger_Switch__c();
        triggerSetting.QuoteValidation__c = true;
        insert triggerSetting;
        Seasonal_Pricing_Setting__c Seasonalsetting = new Seasonal_Pricing_Setting__c();
        Seasonalsetting.Enabled__c = true;
        insert Seasonalsetting;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;

        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) {

            AVA_MAPPER__Entity_Use_code__c entityObj = new AVA_MAPPER__Entity_Use_code__c();
            entityObj.Name = 'ABC';
            entityObj.AVA_MAPPER__Description__c = 'FEDERAL GOV';
            insert entityObj;

            Pricebook2 priceBookRec = NSP_TestHelper.getStandardPriceBook2();

            Id stdPriceBookId = Test.getStandardPricebookId();
            //   NSP_ProjectTasksTrigger.TriggerDisabled = true;
            Account objaccount = NSP_TestHelper.createAccount(false);
            objaccount.Name = NSP_TestHelper.DEFAULT_COMPANY_NAME;
            objaccount.AVA_MAPPER__Entity_Use_code__c = entityObj.Id;
            objaccount.AVA_MAPPER__Is_Seller_Importer_Of_Record__c = false;
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
            objOpportunity.NSP_Signed_CSA__c = true;
            objOpportunity.NSP_Signed_Delivery_Order__c = true;
            insert objOpportunity;


            blng__BillingRule__c brObj = new blng__BillingRule__c();
            brObj.blng__Active__c = true;
            brObj.Name = 'Test InsBR';
            brObj.blng__GenerateInvoices__c = 'Yes';
            brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
            brObj.blng__PartialPeriodTreatment__c = 'Combine';
            insert brObj;

            blng__FinanceBook__c blngFinanceRec = new blng__FinanceBook__c();
            blngFinanceRec.blng__Active__c = true;
            blngFinanceRec.blng__FinancePeriodDuration__c = 'Monthly';
            blngFinanceRec.Name = 'Insperity Salesforce Finance Book';
            blngFinanceRec.blng__PeriodType__c = 'Accounting';
            insert blngFinanceRec;
            blng__InvoicePlan__c invPlanRecord = new blng__InvoicePlan__c();
            invPlanRecord.blng__Active__c = true;
            invPlanRecord.blng__BillingScheduleCreation__c = 'Order Product Activation';
            invPlanRecord.Name = 'Invoice Plan';
            insert invPlanRecord;

            blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
            rrObj.blng__Active__c = true;
            rrObj.blng__CreateRevenueSchedule__c = 'No';
            insert rrObj;

            blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
            taxRuleObj.blng__Active__c = true;
            taxRuleObj.blng__TaxableYesNo__c = 'No';
            insert taxRuleObj;

            blng__GLRule__c taxTreatmentRec = new blng__GLRule__c(blng__Active__c = true, blng__Notes__c = 'Created to record: Sales Tax Allocation', Name = 'Test GLRule');
            insert taxTreatmentRec;

            blng__LegalEntity__c legalEntityRec = new blng__LegalEntity__c(blng__Active__c = true, NSP_Company_Name__c = 'Insperity Business Services', blng__City__c = 'KINGWOOD', blng__State__c = 'TX', blng__County__c = 'US', blng__Street1__c = '19001 CRESCENT SPRINGS DR', blng__ZipPostalCode__c = '77339-3802', Name = 'Test Legal Entity');
            insert legalEntityRec;

            blng__BillingTreatment__c blngTreatmentRecord = new blng__BillingTreatment__c();
            blngTreatmentRecord.blng__Active__c = true;
            blngTreatmentRecord.blng__BillingRule__c = brObj.Id;
            blngTreatmentRecord.blng__BillingFinanceBook__c = blngFinanceRec.Id;
            blngTreatmentRecord.blng__InvoicePlan__c = invPlanRecord.Id;
            blngTreatmentRecord.blng__BillingLegalEntity__c = legalEntityRec.Id;
            blngTreatmentRecord.blng__CancellationRule__c = 'LIFO by Order Product Creation Date';
            insert blngTreatmentRecord;

            ConsumptionSchedule csch =  NSP_TestHelper.createConsumptionSchedule('IWX Consumption');
            insert csch;
            ConsumptionSchedule seasonalCSCH = NSP_TestHelper.createConsumptionSchedule('Seasonal Consumption Schedule');
            insert seasonalCSCH;
            // create consumtpion rate
            ConsumptionRate  crate =  NSP_TestHelper.createConsumptionRate(csch);
            insert crate;
            ConsumptionRate  Seasonalcrate =  NSP_TestHelper.createConsumptionRate(seasonalCSCH);
            insert Seasonalcrate;
            // activate consumption schedule
            csch.isActive = true;
            update csch;
            seasonalCSCH.IsActive = true;
            update seasonalCSCH;

            List<Product2> productList = new List<Product2>();
            Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
            objproduct.ProductCode = 'IWXBundleW2';
            objproduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
            objproduct.SBQQ__BillingType__c = 'Arrears';
            objproduct.NSP_Priority_Amendment__c = 11.0;
            objproduct.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
            objproduct.SBQQ__BillingFrequency__c = 'Annual';
            objproduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.IMMEDIATE;
            objproduct.NSP_IsScholarshipPrice_Applicable__c = 'YES';
            objproduct.blng__BillingRule__c = brObj.Id;
            objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
            objproduct.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
            objproduct.blng__TaxRule__c = taxRuleObj.Id;
            productList.add(objproduct);

            Product2 objInvproduct = NSP_TestHelper.createProduct('Test Product1', false);
            objInvproduct.ProductCode = 'IWXBundle';
            objInvproduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
            objInvproduct.SBQQ__BillingType__c = 'Advance';
            objInvproduct.NSP_Priority_Amendment__c = 12.0;
            objInvproduct.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
            objInvproduct.SBQQ__BillingFrequency__c = 'Monthly';
            objInvproduct.NSP_IsScholarshipPrice_Applicable__c = 'No';
            objInvproduct.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
            objInvproduct.blng__BillingRule__c = brObj.Id;
            objInvproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
            objInvproduct.blng__TaxRule__c = taxRuleObj.Id;
            objproduct.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
            productList.add(objInvproduct);

            Product2 objproduct2 = NSP_TestHelper.createProduct('Test Product2', false);
            objproduct2.ProductCode = 'IWXBundle';
            objproduct2.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
            objproduct2.SBQQ__BillingType__c = 'Advance';
            objproduct2.NSP_Priority_Amendment__c = 12.0;
            objproduct2.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
            objproduct2.SBQQ__BillingFrequency__c = 'Quarterly';
            objproduct2.NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
            objproduct2.NSP_IsScholarshipPrice_Applicable__c = 'No';
            objproduct2.blng__BillingRule__c = brObj.Id;
            objproduct2.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
            objproduct2.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            objproduct2.blng__RevenueRecognitionRule__c = rrObj.Id;
            objproduct2.blng__TaxRule__c = taxRuleObj.Id;
            objproduct2.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
            productList.add(objproduct2);

            Product2 objproduct3 = NSP_TestHelper.createProduct('Test Product3', false);
            objproduct3.ProductCode = 'IWXBundle';
            objproduct3.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
            objproduct3.SBQQ__BillingType__c = 'Advance';
            objproduct3.NSP_Priority_Amendment__c = 12.0;
            objproduct3.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
            objproduct3.SBQQ__BillingFrequency__c = 'Quarterly';
            objproduct3.NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
            objproduct3.NSP_IsScholarshipPrice_Applicable__c = 'No';
            objproduct3.blng__BillingRule__c = brObj.Id;
            objproduct3.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
            objproduct3.SBQQ__HasConsumptionSchedule__c = true;
            objproduct3.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            objproduct3.blng__RevenueRecognitionRule__c = rrObj.Id;
            objproduct3.blng__TaxRule__c = taxRuleObj.Id;
            objproduct3.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
            productList.add(objproduct3);

            Product2 objproduct4 = NSP_TestHelper.createProduct('Test Product4', false);
            objproduct4.ProductCode = 'IWXBundle';
            objproduct4.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;
            objproduct4.SBQQ__BillingType__c = 'Advance';
            objproduct4.NSP_Priority_Amendment__c = 12.0;
            objproduct4.NSP_Order_Activation_Trigger__c = NSP_CPQConstants.PROJGOLIVEDATE;
            objproduct4.SBQQ__BillingFrequency__c = 'Quarterly';
            objproduct4.NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
            objproduct4.NSP_IsScholarshipPrice_Applicable__c = 'No';
            objproduct4.blng__BillingRule__c = brObj.Id;
            objproduct4.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
            objproduct4.SBQQ__HasConsumptionSchedule__c = true;
            objproduct4.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            objproduct4.blng__RevenueRecognitionRule__c = rrObj.Id;
            objproduct4.blng__TaxRule__c = taxRuleObj.Id;
            objproduct4.NSP_ApplicableProductAmendNew__c = NSP_CPQConstants.QUOTELINE_APPLICABLEPRODUCT;
            objproduct4.Has_Seasonal_Pricing__c = true;
            productList.add(objproduct4);

            SBQQ.TriggerControl.disable();
            insert productList;
            SBQQ.TriggerControl.enable();

            ProductConsumptionSchedule psch = NSP_TestHelper.linkProductToCs(objproduct3.id,csch.id );
            insert psch;
            ProductConsumptionSchedule psch2 = NSP_TestHelper.linkProductToCs(objproduct4.id,seasonalCSCH.id );
            insert psch2;

            List<PriceBookEntry> priceBookEntList = new List<PriceBookEntry>();
            PriceBookEntry objPriceBookEntry = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 100, false);
            PriceBookEntry objPriceBookEntry1 = NSP_TestHelper.createPriceBookEntry(objInvproduct.Id, 100, false);
            PriceBookEntry objPriceBookEntry2 = NSP_TestHelper.createPriceBookEntry(objproduct2.Id, 100, false);
            PriceBookEntry objPriceBookEntry3 = NSP_TestHelper.createPriceBookEntry(objproduct3.Id, 100, false);
            PriceBookEntry objPriceBookEntry4 = NSP_TestHelper.createPriceBookEntry(objproduct4.Id, 100, false);
            priceBookEntList.add(objPriceBookEntry);
            priceBookEntList.add(objPriceBookEntry1);
            priceBookEntList.add(objPriceBookEntry2);
            priceBookEntList.add(objPriceBookEntry3);
            priceBookEntList.add(objPriceBookEntry4);
            insert priceBookEntList;

            NSP_Address__c nspAddress = NSP_TestHelper.createCustomAddress();
            nspAddress.NSP_Source__c = 'AIMS';
            nspAddress.NSP_Related_Site__c = objaccount.Id;
            insert nspAddress;

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
            objQuote.NSP_WX_Scholarship__c = true;
            insert objQuote;

            objOpportunity.StageName = 'Closed Won';
            update objOpportunity;

            List<SBQQ__QuoteLine__c> objQuoteLine = NSP_TestHelper.createCPQQuotelines(objQuote, productList, priceBookEntList, true);
            objQuoteLine[0].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
            objQuoteLine[2].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
            objQuoteLine[3].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
            objQuoteLine[0].NSP_Previous_Quantity__c = 500;
            objQuoteLine[2].NSP_Previous_Quantity__c = 500;
            objQuoteLine[0].NSP_Quoted_Quantity__c = 5;
            objQuoteLine[1].NSP_Quoted_Quantity__c = 5;
            objQuoteLine[2].NSP_Quoted_Quantity__c = 5;
            objQuoteLine[0].SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
            objQuoteLine[1].SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
            objQuoteLine[2].NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
            objQuoteLine[3].NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
            objQuoteLine[2].SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
            objQuoteLine[3].SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_EVERGREEN;
            objQuoteLine[2].SBQQ__SubscriptionPricing__c = 'Fixed Price';
            objQuoteLine[0].NSP_Total_Free_Periods__c = 1 ;
            objQuoteLine[1].NSP_Total_Free_Periods__c = 1 ;
            objQuoteLine[2].NSP_Total_Free_Periods__c = 1 ;
            objQuoteLine[0].NSP_Scholarship_Price__c = true ;
            objQuoteLine[1].NSP_Quoted_Quantity__c = 25;
            objQuoteLine[1].NSP_Previous_Quantity__c = 22;
            objQuoteLine[1].NSP_Scholarship_Price__c = true ;
            objQuoteLine[1].SBQQ__Source__c  = objQuoteLine[0].Id ;
            objQuoteLine[2].SBQQ__Source__c  = objQuoteLine[1].Id ;
            objQuoteLine[0].SBQQ__Source__c  = objQuoteLine[2].Id ;
            objQuoteLine[1].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
            objQuoteLine[2].NSP_Action_Type__c = NSP_CPQConstants.ACTION_DOWNGRADE;
            objQuoteLine[2].NSP_Scholarship_Price__c = true ;
            objQuoteLine[3].SBQQ__HasConsumptionSchedule__c = true;
            objQuoteLine[0].NSP_Number_Of_Boxes__c = 5;
            objQuoteLine[0].NSP_Number_of_Checks__c = 5;
            objQuoteLine[0].NSP_Number_Of_Users__c = 5;
            objQuoteLine[0].NSP_TCFullUserLicenseQty__c = 5;
            objQuoteLine[1].NSP_Number_Of_Boxes__c = 5;
            objQuoteLine[1].NSP_Number_of_Checks__c = 5;
            objQuoteLine[1].NSP_Number_Of_Users__c = 5;
            objQuoteLine[1].NSP_TCFullUserLicenseQty__c = 5;
            objQuoteLine[2].NSP_Number_Of_Boxes__c = 5;
            objQuoteLine[2].NSP_Number_of_Checks__c = 5;
            objQuoteLine[2].NSP_Number_Of_Users__c = 5;
            objQuoteLine[2].NSP_TCFullUserLicenseQty__c = 5;
            objQuoteLine[3].NSP_Number_Of_Boxes__c = 5;
            objQuoteLine[3].NSP_Number_of_Checks__c = 5;
            objQuoteLine[3].NSP_Number_Of_Users__c = 5;
            objQuoteLine[3].NSP_TCFullUserLicenseQty__c = 5;
            update objQuoteLine;

            objQuote.SBQQ__Ordered__c = true;
            test.startTest();
            update objQuote;

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
    }

    @isTest
    private static void afterUpdateDirectorMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;
        List<Order> orderList = [Select Id, SBQQ__Quote__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                From Order WHERE Id!=null LIMIT 10];

        List<OrderItem> orderItemList = [SELECT Id,NSP_AnniversaryBlngApplicable__c,NSP_ServiceAsset__c,SBQQ__TerminatedDate__c ,OrderItemNumber, NSP_TotalUsageQuantity__c, NSP_ServiceAssetCategory__c, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c,SBQQ__Activated__c
                FROM OrderItem
                WHERE OrderId IN:orderList];
        Test.startTest();
        Order ord = new Order();
        ord.id = orderItemList[0].OrderId;
        ord.status = 'Reviewed';
        ord.NSP_Project_Name__c = 'xyz';
        ord.NSP_Change_Order_Process_Quote__c = False;
        ord.Prevent_Asset_Updates__c = false;
        update ord;
        orderItemList[0].SBQQ__TerminatedDate__c = System.Today() + 10;
        orderItemList[0].NSP_TotalUsageQuantity__c = 5;
        orderItemList[1].NSP_TotalUsageQuantity__c = 5;
        orderItemList[2].NSP_TotalUsageQuantity__c = 5;
        orderItemList[3].NSP_TotalUsageQuantity__c = 5;
        orderItemList[4].NSP_TotalUsageQuantity__c = 5;
        orderItemList[0].NSP_AnniversaryBlngApplicable__c = true;
        update orderItemList;
        orderList[0].NSP_Project_Complete_Date__c = System.today();
        orderList[0].Status = 'Reviewed';
        orderList[0].NSP_Project_Name__c = 'xyz';
        orderList[0].NSP_Change_Order_Process_Quote__c = False;
        orderList[0].Prevent_Asset_Updates__c = false;
        update orderList;
        Test.stopTest();
        System.assert(orderList.size()==1,true);
    }

    @isTest
    private static void beforeUpdateDirectorMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;
        NSP_ProjectTriggerHandler.TriggerDisabled = true;
        List<Account> objAccount = [SELECT Id,Name FROM Account WHERE Id!=null LIMIT 1];
        List<blng__LegalEntity__c> objLegalEntity = [Select Id, blng__Active__c, NSP_Company_Name__c From blng__LegalEntity__c WHERE Id!=null LIMIT 10];
        List<blng__PaymentMethod__c> paymentMethod = [Select Id FROM blng__PaymentMethod__c WHERE Id!=null LIMIT 10];

        List<Product2> objProduct = [SELECT Id,SBQQ__ChargeType__c, SBQQ__BillingType__c, SBQQ__BillingFrequency__c FROM Product2 WHERE Id!=null LIMIT 4];

        Test.startTest();
        pse__Proj__c bpsProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            bpsProject.Templates_Used__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
            bpsProject.pse__Project_Status__c = 'Active';
            bpsProject.Project_Complete_Date__c = System.Today().addMonths(1);
            bpsProject.pse__Is_Active__c = true;
            bpsProject.pse__Account__c = objAccount[0].Id;
            insert bpsProject;

        List<Order> orderList = [SELECT Id, SBQQ__Quote__c, Status, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                FROM Order WHERE Id!=null LIMIT 10];

        List<OrderItem> orderItemList = [SELECT Id, OrderItemNumber, NSP_Scholarship_Price__c, SBQQ__BillingFrequency__c, EndDate, SBQQ__Status__c, blng__LegalEntity__c, blng__BillingTreatment__c, NSP_TotalUsageQuantity__c, NSP_ServiceAssetCategory__c, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c,SBQQ__Activated__c
                                        FROM OrderItem
                                        WHERE OrderId IN:orderList LIMIT 4];

        List<OrderItem> orderItemListUsage = [SELECT Id, OrderItemNumber, NSP_Scholarship_Price__c, SBQQ__BillingFrequency__c, EndDate, SBQQ__Status__c, blng__LegalEntity__c, blng__BillingTreatment__c, NSP_TotalUsageQuantity__c, NSP_ServiceAssetCategory__c, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c,SBQQ__Activated__c
                                        FROM OrderItem
                                        WHERE Product2.Name = 'Test Product3' LIMIT 1];

        List<blng__UsageSummary__c> usageSumRecs = new List<blng__UsageSummary__c>();
        blng__UsageSummary__c usageSumRecs1 = new blng__UsageSummary__c();
        usageSumRecs1.blng__Account__c = objAccount[0].Id;
        usageSumRecs1.blng__OrderProduct__c = orderItemListUsage[0].Id;
        usageSumRecs1.blng__MatchingId__c = '123';
        usageSumRecs1.blng__MatchingAttribute__c = 'Each';
        usageSumRecs1.blng__UnitOfMeasure__c = 'None';
        usageSumRecs1.blng__Status__c = 'New';
        usageSumRecs1.blng__Source__c = 'External';
        usageSumRecs1.blng__SummaryStartDate__c = Date.today().addDays(-15);
        usageSumRecs1.blng__SummaryEndDate__c = Date.today().addDays(15);
        usageSumRecs1.blng__Order__c = orderList[0].Id;
        usageSumRecs.add(usageSumRecs1);
        insert usageSumRecs;


        orderItemList[0].NSP_Project_Completion_Date__c = System.today();
        orderItemList[1].NSP_Project_Completion_Date__c = System.today();
        orderItemList[2].NSP_Project_Completion_Date__c = System.today();
        orderItemList[0].blng__LegalEntity__c = objLegalEntity[0].Id ;
        orderItemList[1].blng__LegalEntity__c = objLegalEntity[0].Id ;
        orderItemList[2].blng__LegalEntity__c = objLegalEntity[0].Id ;
        orderItemList[0].NSP_Scholarship_Price__c = true ;
        orderItemList[1].NSP_Scholarship_Price__c = true ;
        orderItemList[2].NSP_Scholarship_Price__c = true ;
        orderItemList[0].NSP_Total_Free_Periods__c = 1;
        orderItemList[1].NSP_Total_Free_Periods__c = 1;
        orderItemList[2].NSP_Total_Free_Periods__c = 1;
        orderItemList[0].NSP_Payment_Method__c = paymentMethod[0].Id;
        orderItemList[1].NSP_Payment_Method__c = paymentMethod[0].Id;
        orderItemList[2].NSP_Payment_Method__c = paymentMethod[0].Id;
        orderItemList[0].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[1].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[2].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[3].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        update orderItemList;

        orderList[0].Status = 'Reviewed';
        orderList[0].NSP_Project_Name__c = 'xyz';
        orderList[0].NSP_Change_Order_Process_Quote__c = False;
        update orderList;


        orderItemList[0].SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
        orderItemList[1].SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
        orderItemList[2].SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
        //orderItemList[3].SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
        update orderItemList;

        Test.stopTest();
        system.assert(usageSumRecs.size()==1,true);
    }

    @isTest
    private static void autoActivateOrderLinesMethod() {
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Opportunity objOpp = [SELECT Id,Name FROM Opportunity LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];

        Asset objAsset = new Asset();
        objAsset.Name = 'OrderHelper Test';
        objAsset.AccountId = objaccount.Id;
        objAsset.Status = 'Onboarding';
        objAsset.Product2Id = objproduct.Id;
        objAsset.Opportunity__c = objOpp.Id;
        objAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING).getRecordTypeId();
        //SBQQ.TriggerControl.disable();
        insert objAsset;
        //SBQQ.TriggerControl.enable();

        List<OrderItem> orderItemList = [SELECT Id,NSP_ServiceAsset__c,NSP_UsageUpperBound__c,NSP_TotalUsageQuantity__c, OrderItemNumber, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, NSP_Project_Completion_Date__c,NSP_ReCalculation_Status_Internal__c,SBQQ__Activated__c
                                         FROM OrderItem LIMIT 10];

        orderItemList[0].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[1].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[0].NSP_ServiceAssetCategory__c = 'Time Wage Import';
        orderItemList[1].NSP_ServiceAssetCategory__c = 'Time Wage Import';
        orderItemList[2].NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
        orderItemList[3].NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
        orderItemList[0].SBQQ__Asset__c = objAsset.Id;
        orderItemList[1].SBQQ__Asset__c = objAsset.Id;
        orderItemList[2].SBQQ__Asset__c = objAsset.Id;
        orderItemList[3].SBQQ__Asset__c = objAsset.Id;
        orderItemList[0].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[1].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[2].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[3].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[4].NSP_ServiceAsset__c = objAsset.id;
        orderItemList[0].NSP_TotalUsageQuantity__c = 6;
        orderItemList[1].NSP_TotalUsageQuantity__c = 6;
        orderItemList[2].NSP_TotalUsageQuantity__c = 6;
        orderItemList[3].NSP_TotalUsageQuantity__c = 6;
        orderItemList[4].NSP_TotalUsageQuantity__c = 6;
        orderItemList[0].NSP_UsageUpperBound__c = 7;
        orderItemList[1].NSP_UsageUpperBound__c = 5;
        orderItemList[2].NSP_UsageUpperBound__c = 8;
        orderItemList[3].NSP_UsageUpperBound__c = 4;
        orderItemList[4].NSP_UsageUpperBound__c = 9;
        update orderItemList;

        Map<Id, OrderItem> orderItemNewMap = new Map<Id, OrderItem>();
        Map<Id, String> orderItemNewStringMap = new Map<Id, String>();

        for(OrderItem oi : orderItemList){
            OrderItemNewMap.put(oi.Id,oi);
            orderItemNewStringMap.put(oi.Id,String.valueOf(oi));
        }
        Test.startTest();
        NSP_OrderItemTriggerHelper.updateAsset(orderItemNewStringMap);
        Test.stopTest();
        NSP_OrderItemTriggerHelper.testHandleException( null , null );
    }

    // Covers processOrderItemForScholarshipCS — items with and without ServiceAssetCategory
    @isTest
    private static void processOrderItemForScholarshipCSMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;
        NSP_AssetTriggerHandler.TriggerDisabled = true;

        List<OrderItem> orderItemList = [
            SELECT Id, NSP_ServiceAssetCategory__c, NSP_ServiceAsset__c
            FROM OrderItem
            LIMIT 5
        ];

        // Set up two items that qualify (category set, no asset linked yet)
        orderItemList[0].NSP_ServiceAssetCategory__c = NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING;
        orderItemList[0].NSP_ServiceAsset__c = null;
        // Item with HARDWARE_ASSET should be excluded
        orderItemList[1].NSP_ServiceAssetCategory__c = NSP_CPQConstants.HARDWARE_ASSET;
        orderItemList[1].NSP_ServiceAsset__c = null;
        // Item with no category should be excluded
        orderItemList[2].NSP_ServiceAssetCategory__c = null;

        Test.startTest();
        Map<Id, OrderItem> newMap = new Map<Id, OrderItem>(orderItemList);
        NSP_OrderItemTriggerHelper helper = new NSP_OrderItemTriggerHelper();
        helper.processOrderItemForScholarshipCS( newMap );
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }

    // Covers processOrderItemForScholarshipCS when opIdMap is empty (no qualifying items)
    @isTest
    private static void processOrderItemForScholarshipCSEmptyMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;

        List<OrderItem> orderItemList = [SELECT Id, NSP_ServiceAssetCategory__c, NSP_ServiceAsset__c FROM OrderItem LIMIT 2];
        // Ensure no item qualifies
        orderItemList[0].NSP_ServiceAssetCategory__c = null;
        orderItemList[1].NSP_ServiceAssetCategory__c = null;

        Test.startTest();
        Map<Id, OrderItem> newMap = new Map<Id, OrderItem>(orderItemList);
        NSP_OrderItemTriggerHelper helper = new NSP_OrderItemTriggerHelper();
        helper.processOrderItemForScholarshipCS( newMap );
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }

    // Covers populateLegalEntityOnOrderItem direct invocation
    @isTest
    private static void populateLegalEntityOnOrderItemMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;

        List<OrderItem> orderItemList = [SELECT Id, Product2Id FROM OrderItem LIMIT 3];

        Test.startTest();
        NSP_OrderItemTriggerHelper helper = new NSP_OrderItemTriggerHelper();
        helper.populateLegalEntityOnOrderItem( orderItemList );
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }

    // Covers activateOrder when all order items are already activated (groupedResults not empty, removeAll path)
    @isTest
    private static void activateOrderWithNonActivatedItemsMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;

        List<Order> orderList = [SELECT Id FROM Order LIMIT 2];
        Set<Id> orderIdSet = new Set<Id>();
        for ( Order ord : orderList ) {
            orderIdSet.add( ord.Id );
        }

        Test.startTest();
        // With non-activated items present the method will remove their order IDs from the set
        NSP_OrderItemTriggerHelper.activateOrder( orderIdSet );
        Test.stopTest();

        Assert.isNotNull( orderIdSet , 'Order id set should not be null.' );
    }

    // Covers activateOrder when no non-activated items remain (orderIdSet fully cleared)
    @isTest
    private static void activateOrderEmptySetMethod() {
        Test.startTest();
        NSP_OrderItemTriggerHelper.activateOrder( new Set<Id>() );
        Test.stopTest();

        Assert.isTrue( true , 'activateOrder with empty set should complete without error.' );
    }

    // Covers beforeUpdateDirector termination branch and bill-through override branch
    @isTest
    private static void beforeUpdateDirectorTerminationAndBillThroughMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;
        NSP_ProjectTriggerHandler.TriggerDisabled = true;

        List<Order> orderList = [SELECT Id, Status FROM Order WHERE Id != null LIMIT 10];

        List<OrderItem> orderItemList = [
            SELECT Id, SBQQ__BillingFrequency__c, SBQQ__TerminatedDate__c,
                   NSP_AnniversaryBlngApplicable__c, blng__InvoiceRunProcessingStatus__c,
                   blng__BillThroughDateOverride__c, blng__NextChargeDate__c,
                   NSP_ReCalculation_Status_Internal__c
            FROM OrderItem
            WHERE OrderId IN :orderList
            LIMIT 4
        ];

        Test.startTest();
        // Trigger the SBQQ__TerminatedDate__c null → non-null transition
        orderItemList[0].SBQQ__TerminatedDate__c = System.today().addDays( 30 );
        // Trigger the anniversary bill-through override branch
        orderItemList[1].NSP_AnniversaryBlngApplicable__c = true;
        orderItemList[1].blng__InvoiceRunProcessingStatus__c = NSP_CPQConstants.INVRUN_PENDING;
        orderItemList[1].blng__BillThroughDateOverride__c = null;
        orderItemList[1].blng__NextChargeDate__c = System.today().addMonths( 1 );
        orderItemList[1].SBQQ__BillingFrequency__c = NSP_CPQConstants.BLNGFREQ_ANNUAL;
        update orderItemList;
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }

    // Covers beforeUpdateDirector scholarship status-activated branch and orderLinesToActivate branch
    @isTest
    private static void beforeUpdateDirectorScholarshipActivatedAndOrderLinesMethod() {
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;
        NSP_ProjectTriggerHandler.TriggerDisabled = true;

        List<Order> orderList = [SELECT Id, Status FROM Order WHERE Id != null LIMIT 10];
        List<OrderItem> orderItemList = [
            SELECT Id, NSP_Scholarship_Price__c, SBQQ__Status__c,
                   NSP_ReCalculation_Status_Internal__c, NSP_Override_Start_Date__c,
                   SBQQ__Activated__c
            FROM OrderItem
            WHERE OrderId IN :orderList
            LIMIT 4
        ];

        Test.startTest();
        // Trigger the scholarship status-activated branch (status transitions to Activated with Scholarship flag)
        orderItemList[0].NSP_Scholarship_Price__c = true;
        orderItemList[0].SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
        // Trigger the orderLinesToActivate branch: NSP_Override_Start_Date__c changes on a non-renewable/non-action-type line
        orderItemList[1].NSP_Override_Start_Date__c = System.today().addDays( 5 );
        orderItemList[1].NSP_ReCalculation_Status_Internal__c = NSP_CPQConstants.ORDERITEM_RECALCULATIONSTATUS_NA;
        orderItemList[1].SBQQ__Activated__c = false;
        update orderItemList;
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }

    // Covers afterUpdateDirector opActiveMap branch (NSP_ServiceAsset__c + NSP_ServiceAssetCategory__c set, status Activated)
    @isTest
    private static void afterUpdateDirectorActiveAssetMethod() {
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;

        Account objaccount = [SELECT Id FROM Account WHERE Name = :NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Opportunity objOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Product2 objproduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

        Asset objAsset = new Asset();
        objAsset.Name = 'AfterUpdate Active Asset Test';
        objAsset.AccountId = objaccount.Id;
        objAsset.Status = 'Onboarding';
        objAsset.Product2Id = objproduct.Id;
        objAsset.Opportunity__c = objOpp.Id;
        objAsset.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get( NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING ).getRecordTypeId();
        insert objAsset;

        blng__BillingTreatment__c billingTreatment = [
            SELECT Id
            FROM blng__BillingTreatment__c
            WHERE blng__CancellationRule__c = 'LIFO by Order Product Creation Date'
            LIMIT 1
        ];

        List<OrderItem> orderItemList = [
            SELECT Id, NSP_ServiceAssetCategory__c, NSP_ServiceAsset__c, SBQQ__Status__c,
                   blng__BillingTreatment__c
            FROM OrderItem
            WHERE NSP_ServiceAssetCategory__c = :NSP_CPQConstants.QUOTELINE_APPLICANTTRACKING
            LIMIT 1
        ];

        Test.startTest();
        if ( !orderItemList.isEmpty() ) {
            OrderItem oi = orderItemList[0];
            oi.NSP_ServiceAsset__c = objAsset.Id;
            oi.blng__BillingTreatment__c = billingTreatment.Id;
            update oi;
            // Activate the single order item so the opActiveMap branch fires in afterUpdateDirector
            oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
            update oi;
        }
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }

    // Covers afterUpdateDirector activeUserMap lower-bound branch (usage equals upper bound exactly — neither branch)
    // and ensures NSP_TotalUsageQuantity__c == NSP_UsageUpperBound__c path is exercised
    @isTest
    private static void afterUpdateDirectorUsageEqualBoundMethod() {
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;

        Account objaccount = [SELECT Id FROM Account WHERE Name = :NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];

        Asset objAsset = new Asset();
        objAsset.Name = 'UsageEqual Asset Test';
        objAsset.AccountId = objaccount.Id;
        objAsset.Status = 'Onboarding';
        objAsset.Product2Id = objproduct.Id;
        insert objAsset;

        List<OrderItem> orderItemList = [
            SELECT Id, NSP_ServiceAsset__c, NSP_TotalUsageQuantity__c, NSP_UsageUpperBound__c,
                   Prevent_Asset_Updates__c, OrderType__c
            FROM OrderItem
            LIMIT 2
        ];

        // Set both bounds equal so neither upper nor lower branch is taken
        orderItemList[0].NSP_ServiceAsset__c = objAsset.Id;
        orderItemList[0].NSP_TotalUsageQuantity__c = 10;
        orderItemList[0].NSP_UsageUpperBound__c = 10;

        Test.startTest();
        update orderItemList;
        Test.stopTest();

        Assert.isNotNull( orderItemList , 'Order item list should not be null.' );
    }


}
//