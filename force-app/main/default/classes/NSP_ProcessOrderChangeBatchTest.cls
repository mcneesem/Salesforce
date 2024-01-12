@isTest
public class NSP_ProcessOrderChangeBatchTest {
    
    public static final Id CHOICECLIENTSUBPLANRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
    public static final Id RETSERVICESASSETRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
    
    @testSetup
    static void setupTestData(){
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_AccountGroupTriggerHandler.TriggerDisabled = true;
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u2 = new User(Alias = 'newUser', Email='newuser@insperity.com',
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                           LocaleSidKey='en_US', ProfileId = adminProfile.Id,
                           TimeZoneSidKey='America/Los_Angeles', UserName='newuser@insperity.com.test');
        System.runAs(u2) {
            
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
            
            blng__TaxIntegration__c taxIntegrationRec = new blng__TaxIntegration__c(AVA_BLNG__AvaTaxAccountNumber__c = '1100126607', AVA_BLNG__AvaTaxLicenseKey__c = '0FE211624F764D08', AVA_BLNG__DocCode__c = 'Id', AVA_BLNG__CustomerCode__c = 'Id', blng__Active__c = true, AVA_BLNG__Validate_Address__c = true, AVA_BLNG__TestMode__c = true, AVA_BLNG__Save_transactions_to_AvaTax__c = true, Name = 'Test TaxIntegration', blng__TaxEngine__c = 'Standard');
            insert taxIntegrationRec;
            
            blng__LegalEntity__c legalEntityRec = new blng__LegalEntity__c(blng__Active__c = true, NSP_Company_Name__c = 'Insperity Business Services', blng__City__c = 'KINGWOOD', blng__State__c = 'TX', blng__County__c = 'US', blng__Street1__c = '19001 CRESCENT SPRINGS DR', blng__ZipPostalCode__c = '77339-3802', Name = 'Test Legal Entity');
            insert legalEntityRec;
            
            blng__TaxTreatment__c texRuleRec = new blng__TaxTreatment__c(blng__TaxCode__c = 'SW052011', blng__TaxGLRule__c = taxTreatmentRec.Id, blng__TaxIntegration__c = taxIntegrationRec.Id, blng__TaxLegalEntity__c = legalEntityRec.Id, Name = 'TestTaxTreatment', blng__TaxRule__c = taxRuleObj.Id);
            insert texRuleRec;
            
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
            // create consumtpion rate
            ConsumptionRate  crate =  NSP_TestHelper.createConsumptionRate(csch);
            insert crate;
            // activate consumption schedule
            csch.isActive = true;
            update csch;
            
            
            List<Product2> productList = new List<Product2>();
            Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
            objproduct.ProductCode = 'IWXBundleW2'; 
            objproduct.SBQQ__ChargeType__c = NSP_CPQConstants.PRODUCT_CHARGETYPE_RECURRING;  
            objproduct.SBQQ__BillingType__c = 'Arrears';
            objproduct.NSP_Priority_Amendment__c = 11.0;
            objproduct.SBQQ__SubscriptionType__c = NSP_CPQConstants.SUBS_RENEWABLE;
            objproduct.SBQQ__BillingFrequency__c = 'Monthly';
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
            
            SBQQ.TriggerControl.disable();
            insert productList;
            SBQQ.TriggerControl.enable();
            
            ProductConsumptionSchedule psch = NSP_TestHelper.linkProductToCs(objproduct3.id,csch.id );
            insert psch;
            
            List<PriceBookEntry> priceBookEntList = new List<PriceBookEntry>();
            PriceBookEntry objPriceBookEntry = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 100, false);
            PriceBookEntry objPriceBookEntry1 = NSP_TestHelper.createPriceBookEntry(objInvproduct.Id, 100, false);
            PriceBookEntry objPriceBookEntry2 = NSP_TestHelper.createPriceBookEntry(objproduct2.Id, 100, false);
            PriceBookEntry objPriceBookEntry3 = NSP_TestHelper.createPriceBookEntry(objproduct3.Id, 100, false);
            priceBookEntList.add(objPriceBookEntry);
            priceBookEntList.add(objPriceBookEntry1);
            priceBookEntList.add(objPriceBookEntry2);
            priceBookEntList.add(objPriceBookEntry3);
            insert priceBookEntList;
            
            NSP_Address__c nspAddress = NSP_TestHelper.createCustomAddress();
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
            insert objQuote;
            
            objOpportunity.StageName = 'Closed Won';
            update objOpportunity;
            
            List<SBQQ__QuoteLine__c> objQuoteLine = NSP_TestHelper.createCPQQuotelines(objQuote, productList, priceBookEntList, true);
            objQuoteLine[0].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
            //  objQuoteLine[1].NSP_Action_Type__c = NSP_CPQConstants.ACTION_UPSELL;
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
            insert objPaymntMethod;
            test.stopTest();
        }
    }
    
    static testMethod void testProcessChange(){
        list<SBQQ__Quote__c> quoteList = [SELECT Id from SBQQ__Quote__c where SBQQ__primary__c = true];
        Test.startTest();
        //Creat a new Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), NSP_CPQConstants.ASSETDEFAULTS, false);
        newAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newAsset.NSP_Client_is_Lead_Parent__c = true;
        newAsset.NSP_Price_Level__c= 'RET - Bundled Plus #2';
        Database.insert(newAsset);
        
        Asset newMemberAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), NSP_CPQConstants.ASSETDEFAULTS, false);
        newMemberAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newMemberAsset.NSP_Process_Order_Change__c = true;
        newMemberAsset.NSP_RET_lead_parent__c = newAsset.Id;
        newMemberAsset.NSP_ReAssigned_Order_Quote_Id__c = quoteList[0].id;
        Database.insert(newMemberAsset);
        
        
        NSP_ProcessOrderChangeBatch bch = new NSP_ProcessOrderChangeBatch();
        Database.executeBatch(bch,Integer.valueof(system.label.NSP_OrderChangeBatchSize)); 
        Test.stopTest();
        Asset newAsset1=[SELECT Id,NSP_Change_Order_Process_Contract_Status__c FROM Asset WHERE Id=:newMemberAsset.Id limit 1];
        system.AssertEquals('Change Order Created',newAsset1.NSP_Change_Order_Process_Contract_Status__c);
    }
    
    static testMethod void testProcessCancellation(){
        list<SBQQ__Quote__c> quoteList = [SELECT Id from SBQQ__Quote__c where SBQQ__primary__c = true];
        Test.startTest();
        //Creat a new Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), NSP_CPQConstants.ASSETDEFAULTS, false);
        newAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newAsset.NSP_Client_is_Lead_Parent__c = true;
        newAsset.NSP_Price_Level__c= 'RET - Bundled Plus #2';
        Database.insert(newAsset);
        
        Asset newMemberAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), NSP_CPQConstants.ASSETDEFAULTS, false);
        newMemberAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newMemberAsset.NSP_Process_Order_Change__c = true;
        newMemberAsset.NSP_RET_lead_parent__c = newAsset.Id;
        newMemberAsset.NSP_ReAssigned_Order_Quote_Id__c = quoteList[0].id;
        newMemberAsset.NSP_Change_Order_Process_Contract_Status__c = 'Ready To Close';
        Database.insert(newMemberAsset);
        
        
        NSP_ProcessOrderChangeBatch bch = new NSP_ProcessOrderChangeBatch();
        Database.executeBatch(bch,Integer.valueof(system.label.NSP_OrderChangeBatchSize)); 
        system.AssertEquals('Ready To Close',newMemberAsset.NSP_Change_Order_Process_Contract_Status__c);
        Test.stopTest();
    }
}