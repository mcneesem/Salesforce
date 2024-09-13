@isTest
public class PostInvoicesControllerTest {
    
    @TestSetup
    public static void CreateTestData(){
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
    private static void PostInvoices_Test(){
        
        // Query account and product
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        Contact con = [SELECT id FROM Contact LIMIT 1];
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
        blng__InvoiceRun__c invRunObj = new blng__InvoiceRun__c (Name='TestInvRun',blng__TargetDate__c=System.today());
        insert invRunObj;
        id invoiceid = inv[0].id;
        id invoiceRunId = invRunObj.id;
        blng__InvoiceLine__c line = [SELECT id,blng__InvoiceLineStatus__c,blng__Invoice__c,blng__InvoiceRun__c FROM blng__InvoiceLine__c LIMIT 1];
        
        line.blng__InvoiceRun__c = invRunObj.id;
        
        NSP_InvoiceLineTriggerHandler.TriggerDisabled = true;
        //update line;
        system.debug(line.blng__InvoiceLineStatus__c+'_'+line.blng__Invoice__c+'_'+line.blng__InvoiceRun__c);
        
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        update line;
        //update inv;
        system.debug(line.blng__InvoiceLineStatus__c);
        
        NSP_InvoiceTriggerHandler.TriggerDisabled = true; 
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        NSP_EmailMessageTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceLineTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_TaskTriggerHandler.TriggerDisabled = true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        
        system.debug(inv[0]);
        SBQQ.TriggerControl.disable();
        inv[0].blng__InvoiceRunCreatedBy__c = invRunObj.Id;
        inv[0].NSP_Bill_To_Email__c = 'abc@def.com';      
        inv[0].NSP_Send_Email__c = true;
        inv[0].blng__BillToContact__c = con.Id;
        inv[0].NSP_CLM_Document_Received__c = true;
        inv[0].blng__InvoiceStatus__c = 'Posted';
        SBQQ.TriggerControl.disable();
        update inv[0];
        
        line.blng__InvoiceLineStatus__c = 'Draft';
        update line;
        
        SBQQ.TriggerControl.enable();
        
       
        PostInvoicesController.PostInvoices(invRunObj.id);
        
        Test.stopTest();
        blng__Invoice__c invFinal = [SELECt id,blng__InvoiceStatus__c FROM blng__Invoice__c LIMIT 1];
        system.assertEquals(invFinal.blng__InvoiceStatus__c, 'Draft');
        
    }
}