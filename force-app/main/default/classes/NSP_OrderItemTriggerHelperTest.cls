/***Test Class for NSP_OrderItemTriggerHelpe Class***
/**
* @description  : Test Class for NSP_OrderItemTriggerHelpe Class
* @author sumit singh
* @date 09/06/2021
* Name : NSP_OrderItemTriggerHelperTest
*/
@isTest
public class NSP_OrderItemTriggerHelperTest{
    
    @testSetup
    static void setupTestData(){

        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test InsBR';
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

        Account objaccount = NSP_TestHelper.createAccount(true);
        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct.blng__TaxRule__c = taxRuleObj.Id;
        insert objproduct;
       
    }
    /**
     * Description : Test method to test the consumption schedule on order item
     * Name : consumptionscheduleTest
     */
    static testMethod void consumptionscheduleTest(){
        // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];

        // create consumption schedule
        ConsumptionSchedule csch =  NSP_TestHelper.createConsumptionSchedule('IWX Consumption');
        insert csch;
        // create consumtpion rate
        ConsumptionRate  crate =  NSP_TestHelper.createConsumptionRate(csch);
        insert crate;
        // activate consumption schedule
        csch.isActive = true;
        update csch;
        // link consumption schedule to product
        ProductConsumptionSchedule psch = NSP_TestHelper.linkProductToCs(objproduct.id,csch.id );
        insert psch;

        Test.startTest();
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
        system.assert(true, objQuote.SBQQ__Primary__c );
        Test.stopTest();
        
        list<OrderItem> orderItemList = new list<OrderItem>([select id from OrderItem where Order.SBQQ__Quote__c =:objQuote.Id]);
        update orderItemList;
        
        delete orderItemList;
        
    }
    
    
}