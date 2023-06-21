/***Test Class for NSP_OrderTriggerHelper Class***
/**
* @description  : Test Class for NSP_OrderTriggerHelper Class
* @author sumit singh
* @date 11/08/2021
* Name :  NSP_OrderTriggerHelperTest
*/
@isTest
public class NSP_OrderTriggerHelperTest{
    
    @testSetup
    static void setupTestData(){
        blng__BillingRule__c objBillingRule = NSP_TestHelper.createBillingRule();

        Account objaccount = NSP_TestHelper.createAccount(true);
		NSP_Address__c addressBillToRecord = NSP_TestHelper.createCustomAddress();
        addressBillToRecord.NSP_Related_Site__c = objaccount.Id;
		addressBillToRecord.NSP_Address_Type__c = 'Bill To';
		insert addressBillToRecord;
		NSP_Address__c addressShipToRecord = NSP_TestHelper.createCustomAddress();
        addressShipToRecord.NSP_Related_Site__c = objaccount.Id;
		addressShipToRecord.NSP_Address_Type__c = 'Ship To';
		insert addressShipToRecord;
         NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.id;
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        insert objproduct;
       
    }
    /**
     * Description : Test method to test the consumption schedule on order item
     * Name : consumptionscheduleTest
     */
    static testMethod void orderUpdateTest(){
        // Query account and product
        Account objaccount  = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Product2 objproduct  = [SELECT Id, Name FROM Product2  WHERE SBQQ__ChargeType__c = 'Recurring' LIMIT 1]; //Added WHERE Condition as part of code fix
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
		objQuote.NSP_Billing_Address__c   = [SELECT id FROM NSP_Address__c WHERE NSP_Address_Type__c = 'Bill To' AND NSP_Related_Site__c =: objaccount.Id ].Id;
		update objQuote;
        System.assertEquals(objQuote.SBQQ__Ordered__c, true);
        Test.stopTest();
		
		order objOrder = [SELECT id,NSP_Billing_Address__c,NSP_Shipping_Address__c FROM order WHERE SBQQ__Quote__c =:objQuote.Id];
		objOrder.NSP_Shipping_Address__c  = [SELECT id FROM NSP_Address__c WHERE NSP_Address_Type__c = 'Bill To' AND NSP_Related_Site__c =: objaccount.Id ].Id;
        update objOrder;
        
        objOrder.NSP_Billing_Account__c  = objaccount.Id;
        update objOrder;
        
		/*objOrder.NSP_Billing_Account__c  = Null;
        objOrder.NSP_Shipping_Address__c = null;
        objOrder.NSP_Billing_Address__c = null;
        update objOrder; */

    }
    
    
}