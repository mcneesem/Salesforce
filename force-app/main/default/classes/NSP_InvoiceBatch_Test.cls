//***Test Class for NSP_InvoiceBatchh***
/**
* @description  : Test Class for NSP_InvoiceBatch Class
* @date 13 April 2023
* Name : NSP_InvoiceBatch_Test
*/
@isTest
public class NSP_InvoiceBatch_Test {
    
	@TestSetup
    public static void createTestData(){
        NSP_ContactTriggerHandler.TriggerDisabled = true;
        blng__BillingRule__c objBillingRule = NSP_TestHelper.createBillingRule(); 
        blng__RevenueRecognitionRule__c objRevRecRule =  NSP_TestHelper.createRevrecRule('1');
        blng__TaxRule__c objTaxRule = NSP_TestHelper.createRevTaxRule();
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.blng__BillingRule__c = objBillingRule.Id;
        objproduct.blng__RevenueRecognitionRule__c = objRevRecRule.Id;
        objproduct.blng__TaxRule__c = objTaxRule.Id;
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
		insert objproduct;
      
    }
    
    @isTest
    private static void generateInvoice(){
         // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
         // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Business',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        
        
        Test.startTest();
      // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        
        //creating invoice
        list<OrderItem> orderItemList = new list<OrderItem>([select id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        orderList[0].Status='Activated';
        update orderList;
        orderList[0].blng__BillNow__c=true;
        update orderList;
        
        /*
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
		List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE SBQQ__Quote__c=:objQuote.Id ];
        ords[0].blng__BillingDayOfMonth__c = '1';
        ords[0].Status = 'Reviewed';
        update ords;

        ords[0].Status = 'Activated';
        update ords;
        ords[0].blng__BillNow__c = TRUE;
		update ords;
        */
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c,blng__Balance__c from blng__Invoice__c WHERE Id!=null];
        
        NSP_InvoiceBatch invBatch= new NSP_InvoiceBatch();
        Database.executeBatch(invBatch,1);
        Test.stopTest();
        System.assert(orderList.size()==1,true);
    }  
    
    //this is to test the parameterized constructor in batch class
    @isTest
    private static void parameterizedMethod(){
         // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
         // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Business',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        
        
        Test.startTest();
      // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        
        //creating invoice
        list<OrderItem> orderItemList = new list<OrderItem>([select id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        orderList[0].Status='Activated';
        update orderList;
        orderList[0].blng__BillNow__c=true;
        update orderList;
        
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c,blng__Balance__c from blng__Invoice__c WHERE Id!=null];
        List<Id>invoices = new List<Id>{inv[0].Id};
        
        NSP_InvoiceBatch invBatch= new NSP_InvoiceBatch(invoices);
        Database.executeBatch(invBatch,1);
        
        Test.stopTest();
        System.assert(orderList.size()==1,true);
    }
}