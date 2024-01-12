//***Test Class for NSP_InvoiceNotificationBatch***
/**
* @description  : Test Class for NSP_InvoiceNotificationBatch Class
* @date 12 July 2023
* Name : NSP_InvoiceNotificationBatch_Test
*/
@isTest
public class NSP_InvoiceNotificationBatch_Test{
    
    @TestSetup
    public static void createTestData(){
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        
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
        
        //activate order
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        Test.startTest();
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE SBQQ__Quote__c=:objQuote.Id ];
        List<OrderItem> orderItemList = new list<OrderItem>([select id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c from OrderItem WHERE OrderId=:ords]);
        ords[0].NSP_Project_Go_Live_Date__c=system.today();
        ords[0].blng__BillingDayOfMonth__c = '1';
        ords[0].Status = 'Reviewed';
        update ords;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        update orderItemList;

        ords[0].Status = 'Activated';
        update ords;
        
        
        Test.stopTest();
      
    }
    @isTest
    private static void nonParameterizedMethod(){
        Test.startTest();
        Account objaccount  = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated'];
        ords[0].blng__BillNow__c = TRUE;
        update ords;
        NSP_InvoiceNotificationBatch invNotification = new NSP_InvoiceNotificationBatch();
        Database.executeBatch(invNotification,1);
        Test.stopTest();
        System.assertEquals(ords.size()==1,true);
    }
  
    
    @isTest
    private static void parameterizedMethod(){
        Test.startTest();
        Account objaccount  = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated'];
        
        
        ords[0].blng__BillNow__c = TRUE;
        update ords;
        List<blng__Invoice__c> invList = [SELECT Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE ID!=null];
        if(invList.size()>0){
            invList[0].NSP_CLM_Document_Received__c = true;
            invList[0].NSP_Invoice_Email_Sent__c = false;
            invList[0].blng__InvoiceStatus__c = 'Posted';
            update invList[0];
        }
        NSP_InvoiceNotificationBatch invNotification = new NSP_InvoiceNotificationBatch(invList);
        Database.QueryLocator ql = invNotification.start(null);
        invNotification.execute(null,invList);
        //invNotification.finish(null);
        //Database.executeBatch(invNotification,1);
        Test.stopTest(); 
        System.assertEquals(ords.size()==1,true);

    }
    
}