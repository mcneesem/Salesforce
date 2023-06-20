/***Test Class for NSP_OpportunityLineItemTriggerHelper Class***
/**
* @description  : Test Class for NSP_OpportunityLineItemTriggerHelper Class
* @author Anil Kumar
* @date 15/12/2021
* Name :  NSP_OpportunityLineItemTriggerHelperTest
*/
@isTest
public class NSP_OpportunityLineItemTriggerHelperTest {
     public static final String PRODUCTNAME ='Test Product'; // Added as part of code scan fix
  @testSetup
    static void setupTestData(){
        blng__BillingRule__c brObj = new blng__BillingRule__c();
        brObj.blng__Active__c = true;
        brObj.Name = 'Test BR';
        brObj.blng__GenerateInvoices__c = 'No';
        brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
        insert brObj;
       
        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_Address__c addressBillToRecord = NSP_TestHelper.createCustomAddress();
        addressBillToRecord.NSP_Related_Site__c = objaccount.Id;
        addressBillToRecord.NSP_Address_Type__c = 'Bill To';
        insert addressBillToRecord;
        NSP_Address__c addressShipToRecord = NSP_TestHelper.createCustomAddress();
        addressShipToRecord.NSP_Related_Site__c = objaccount.Id;
        addressShipToRecord.NSP_Address_Type__c = 'Ship To';
        insert addressShipToRecord;
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.Id;
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
         Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; // Added where condition as part of code fix
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name =:PRODUCTNAME LIMIT 1]; // Added where condition as part of code fix
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
        Test.stopTest();
        system.assertEquals(true, objQuote.SBQQ__Ordered__c); //Added as part of code scan fix
        
        order objOrder = [select id,NSP_Billing_Address__c,NSP_Shipping_Address__c FROM order WHERE SBQQ__Quote__c =:objQuote.Id];
        objOrder.NSP_Shipping_Address__c  = [SELECT id FROM NSP_Address__c WHERE NSP_Address_Type__c = 'Bill To' AND NSP_Related_Site__c =: objaccount.Id ].Id;
        update objOrder;
        
        objOrder.NSP_Billing_Account__c  = objaccount.Id;
        update objOrder;
        
        objOrder.NSP_Billing_Account__c  = Null;
        objOrder.NSP_Shipping_Address__c = null;
        objOrder.NSP_Billing_Address__c = null;
        update objOrder;
        
        delete objOrder;
        
        //insert OpportunityLineItem        
        OpportunityLineItem OLI = new OpportunityLineItem();
        OLI.OpportunityId = objOpprtunity.Id; //Opportunity Id has to be assigned
        OLI.Product2Id = objproduct.Id; //PriceBookEntry Id for that Product should be assigned.
        OLI.Quantity = 1;
        OLI.UnitPrice = 1;
        insert OLI;
        
        OLI.Quantity = 2;
        update OLI;
    }
    
}