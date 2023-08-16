/**
* 
Apex Class Name      :  NSP_UsageTriggerHelperTest
Version              :  1.0                                                                          
Created Date         :                                                                       
Description    :        This is the test class Usage Trigger                                                                      
*--------------------------------------------------------------------------------------------------  
*  Developer                   Date                   Description                                    
* ------------------------------------------------------------------------------------------------- 
   CPQ Team                    06-06-2023
*/
@isTest
public class NSP_UsageTriggerHelperTest {
    @testSetup
    static void setupTestData(){
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled=true;
        NSP_ContractTriggerHandler.TriggerDisabled=true;
        NSP_UsageSummaryTriggerHandler.TriggerDisabled=true;
        
        Account objaccount = NSP_TestHelper.createAccount(true);//create an account
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule(); //creates billing rule
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule('Test');//creates revenue recogintion rule
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule(); //creates tax rule
        
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);  //Product Creation
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id; 
        insert objproduct;
        
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
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        Test.startTest();
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        Test.stopTest();
    }
    @isTest
    private static void usageratingTest(){
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        ConsumptionSchedule csch=[SELECT Id FROM ConsumptionSchedule WHERE Id!=null limit 1];
        list<OrderItem> orderItemList = new list<OrderItem>([select id,ServiceDate from OrderItem WHERE Id!=null]);
        system.debug('orderItemList '+orderItemList);
        Test.startTest();
        SBQQ__OrderItemConsumptionSchedule__c ocsh=NSP_TestHelper.createOItemConsumptionSchdeule(orderItemList,csch);
        SBQQ__OrderItemConsumptionRate__c ocshrate=NSP_TestHelper.createOtemConsumptionRate(ocsh);
        blng__UsageSummary__c uSummary=NSP_TestHelper.createUsageSummary(orderItemList,objaccount);
        blng__UsageSummary__c uSummary1=[SELECT Id,blng__MatchingId__c FROM blng__UsageSummary__c WHERE Id!=null limit 1];
        blng__Usage__c usage=NSP_TestHelper.createUsages(uSummary1,orderItemList);
        usage.blng__Status__c='Processed';
        update usage;
        system.assertEquals(usage.blng__Status__c, 'Processed');
        Test.stopTest();
    }
    
}