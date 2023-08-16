/**
* 
Apex Class Name      :  NSP_InvoiceLineTriggerTest
Version              :  1.0                                                                          
Created Date         :                                                                       
Description    :        This is the test class Invoice Line Trigger                                                                      
*--------------------------------------------------------------------------------------------------  
*  Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest
public class NSP_InvoiceLineTriggerTest {
    private static final String POSTED='Posted';
    //Set up method to create test data
    @testSetup
    static void setupTestData(){
        //Disable unnesessary triggers
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
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(objaccount.id, true);
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule('Project Rev Rec');
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        blng__RevenueDistributionMethod__c dis=NSP_TestHelper.createRevenueDistribution('Project Rev Rec (Invoice)');
        NSP_TestHelper.createGLRule();
        NSP_TestHelper.createFinBook();
        blng__RevenueRecognitionTreatment__c recTreatment=NSP_TestHelper.createRevRecTreatment();
        recTreatment.blng__RevenueDistributionMethod__c=dis.Id;
        recTreatment.blng__RevenueRecognitionRule__c=rRule.Id;
        insert recTreatment;
        //create products and assoicate Billing rules
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        objproduct.ProductCode = 'Admin_WO';
        insert objproduct;
        blng__RevenueRecognitionRule__c rRule1=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.DELAY_12_1);
        Product2 objproduct1 = NSP_TestHelper.createProduct('Test Product1',false);
        objproduct1.SBQQ__ChargeType__c = 'Recurring';
        objproduct1.SBQQ__BillingType__c = 'Arrears';
        objproduct1.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct1.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct1.blng__BillingRule__c=bRule.Id;
        objproduct1.blng__RevenueRecognitionRule__c=rRule1.Id;
        objproduct1.blng__TaxRule__c=tRule.Id;
        
        insert objproduct1;
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true); //creates Opportunity
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);          //creates Pricebook entries
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);     //creates Quote
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true); //creates Quote Lines
        //create an order from Quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        Test.startTest();
        update objQuote;
        //Retrieve Order Items
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([SELECT id FROM Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        //activate the order
        orderList[0].Status='Activated';
        update orderList;  
        Assert.isNotNull(objOpprtunity.Id);
        Test.stopTest();
    }
    /*Below test method covers Project Rev Rec 
and Project Rev Rec 12 models*/
    @isTest
    private static void invoiceLineTest(){
        Test.startTest();
        //fetch activated orders
        List<Order> orderList = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                                 FROM Order
                                 WHERE Status = 'Activated'];
        //create an Invoice
        orderList[0].blng__BillNow__c=true;
        update orderList;
        // Test.startTest();
        List<blng__Invoice__c> inv =[SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Order__c=:orderList[0].Id  limit 1];
        //POST the invoice
        inv[0].blng__InvoiceStatus__c=POSTED;
        update inv;
        //create revenue schedules and associate an invoice line
        blng__RevenueSchedule__c sch=new blng__RevenueSchedule__c();
        sch.blng__TotalRevenueAmount__c=25;
        sch.blng__FullRecognitionDate__c=system.today()-1;
        sch.blng__RevenueDistributionMethod__c=[SELECT Id,Name FROM blng__RevenueDistributionMethod__c WHERE Id!=null limit 1]?.Id;
        sch.blng__RevenueRecognitionTreatment__c=[SELECT Id,Name FROM blng__RevenueRecognitionTreatment__c WHERE Id!=null limit 1]?.Id;
        blng__InvoiceLine__c invLine=[SELECT Id,Name,NSP_Go_Live_Date__c FROM blng__InvoiceLine__c  WHERE blng__Invoice__c=:inv[0].Id  limit 1];
        //sch.blng__InvoiceLine__c=[SELECT Id,Name FROM blng__InvoiceLine__c limit 1]?.Id;
        sch.blng__InvoiceLine__c=invLine.Id;
        insert sch;
        //orderList[0].NSP_Project_Go_Live_Date__c=system.today()+1;
        // update orderList; // this will invoke recreate rev shedules
        invLine.NSP_Go_Live_Date__c=system.today()+1;
        update invLine;
        system.assertEquals(POSTED, inv[0].blng__InvoiceStatus__c);
        Test.stopTest();  
    }
    /*Below test method covers 12 Delay1 rev rec model*/
    @isTest
    private static void invoiceLine12DelayTest(){
        Account objaccount  = [Select Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name FROM Product2 WHERE Name = 'Test Product1' LIMIT 1];
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        Test.startTest();
        update objQuote;       
        
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([SELECT id FROM Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;
        //activate the order
        orderList[0].Status='Activated';
        update orderList;
        //create an invoice
        orderList[0].blng__BillNow__c=true;
        update orderList;
        List<blng__Invoice__c> inv =[SELECT Id,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__Account__c=:objaccount.Id limit 1];
        //Post the invoice
        inv[0].blng__InvoiceStatus__c=POSTED;
        update inv;
        system.assertEquals(POSTED, inv[0].blng__InvoiceStatus__c);
        
    }
}