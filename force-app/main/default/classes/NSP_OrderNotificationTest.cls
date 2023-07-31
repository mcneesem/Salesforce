/**
* @description  : test  class for Order Notification visualforce component to display order products
* @date 21/09/2021
* Name : NSP_OrderNotificationTest
*/
@isTest(SeeAllData=false)
public class NSP_OrderNotificationTest {
    /*
    *Test setup Data
    */
    @testSetup
    static void setupTestData(){

        
        Account objaccount = NSP_TestHelper.createAccount(true);
        blng__BillingRule__c objBillingRule = NSP_TestHelper.createBillingRule(); 
        blng__RevenueRecognitionRule__c objRevRecRule =  NSP_TestHelper.createRevrecRule('1');
        blng__TaxRule__c objTaxRule = NSP_TestHelper.createRevTaxRule();
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.Id;
        objproduct.blng__RevenueRecognitionRule__c = objRevRecRule.Id;
        objproduct.blng__TaxRule__c = objTaxRule.Id;
        objproduct.SBQQ__ChargeType__c = 'One-Time';
        insert objproduct;
        
    }
    
    /*
    *Test Method : testGetContractRecord
    *@Utpal Utkalit
    */
     @isTest
    private static void testGetContractRecord(){
        
        
        // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Business',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        Test.startTest();
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        Order orderitemlist = [select id FROM Order WHERE Id!=null];
        NSP_OrderNotification orderNotification = new NSP_OrderNotification();
        orderNotification.orderIdstr = String.valueOf(orderitemlist.Id);
        List<String> orderItem=orderNotification.getProductBundleList();
        Test.stopTest();
        System.assert(orderItem.size() == 0);
        
    }
}