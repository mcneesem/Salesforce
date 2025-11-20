@isTest
public class BudgetaryQuoteTaxControllerQueueTest {
    
    @testSetup
    private static void testData() {

        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;

        Account objaccount = NSP_TestHelper.createAccount(true);

        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objProduct.NSP_ServiceAssetCategory__c = 'WX_WA';
        objProduct.NSP_Convert_to_Asset__c = true;
        objProduct.ProductCode = 'IWXBundleW2';
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
        objOpprtunity.NSP_PrimaryProduct__c = 'WX';
        objOpprtunity.NSP_Client_For_Life__c = 'WX';
        objOpprtunity.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
        objOpprtunity.CloseDate = date.today();
        objOpprtunity.CurrencyIsoCode = 'USD';
        objOpprtunity.AVA_SFCLOUD__Sales_Tax__c = 10;
        objOpprtunity.NSP_Number_of_Employees__c = 100;
        objOpprtunity.NSP_WS_Number_Of_Employees__c = 123;
        objOpprtunity.NSP_WO_Number_Of_Employees__c = 123;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        update objOpprtunity;
        NSP_OpportunityTriggerHandler.TriggerDisabled = false;

        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);

        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);

        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        List<SBQQ__QuoteLine__c> ql = [select Id,NSP_Quoted_Quantity__c from SBQQ__QuoteLine__c where SBQQ__Quote__c =: objQuote.Id ];
        ql[0].NSP_Quoted_Quantity__c = 10;
        update ql;

        // Approve quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.NSP_Budgetary_Quote__c = true;
        objQuote.SBQQ__Type__c = 'New Product';
        objQuote.SBQQ__Status__c = 'Approved';
        objQuote.NSP_Sales_Tax__c = 0;
        update objQuote;
    }

    @isTest
    private static void testBudgetaryQuoteTaxCalculation() {
        
        Test.startTest();
        List<Opportunity> opportunityList = [Select Id from Opportunity LIMIT 1];
        opportunityList[0].StageName = 'Closed Won';
        update opportunityList;

        BudgetaryQuoteTaxControllerQueue.enqueueJob(new List<String>{opportunityList[0].Id});
        BudgetaryQuoteTaxControllerQueue.testHandleException(null,null);

        Test.stopTest();
        
        List<SBQQ__Quote__c>  quoteList = [Select Id,NSP_Sales_Tax__c from SBQQ__Quote__c where SBQQ__Opportunity2__c =: opportunityList[0].Id LIMIT 1];
        System.assertEquals(10,quoteList[0].NSP_Sales_Tax__c,'The Sales Tax should be updated on the quote.');

    }
}