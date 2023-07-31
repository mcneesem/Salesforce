/**
Apex Class Name      :  NSP_InvoiceEmailMessageServiceTest
Version              :  1.0   
Author               :  Rakesh                                                                       
Created Date         :  12/08/2022 
Function             :   Represent test class for NSP_InvoiceEmailMessageServiceTest
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rakesh               12/08/2022          First Iteration
*/

@isTest(isParallel=false)
public with sharing class NSP_InvoiceEmailMessageServiceTest {
    public NSP_InvoiceEmailMessageServiceTest() {

    }

    @TestSetup
    public static void createTestData(){
        //Test Data Setup
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
		NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
		NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
		NSP_QuoteTriggerHandler.TriggerDisabled = true;
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        
        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
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
        
        // Query account and product
        //Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        //Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
     
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
        
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
		Test.startTest();
		List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE SBQQ__Quote__c=:objQuote.Id ];
        ords[0].blng__BillingDayOfMonth__c = '1';
        ords[0].Status = 'Reviewed';
        //ords[0].blng__BillNow__c = TRUE;
		update ords;

        ords[0].Status = 'Activated';
        update ords;
        Test.stopTest(); 
    }


    /**
     * Description : Test method to test the invoice message service methods (negative case)
     * Name : testInvoiceEmailMessageService
     */
    @isTest
    static void testInvoiceEmailMessageServiceNegative(){
        Test.startTest();
        Account objaccount  = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated'];
        ords[0].blng__BillNow__c = TRUE;
		update ords;
        Test.stopTest();
        
		List<blng__Invoice__c> invc = [SELECT Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Id != NULL];
        NSP_InvoiceEmailMessageService.sendInvoiceEmail(new List<String>{invc[0].Id});
        List<blng__Invoice__c> invcheck = [SELECT Id, Name, blng__Account__c,blng__Balance__c,NSP_Send_Email__c,NSP_Invoice_Email_Sent__c FROM blng__Invoice__c WHERE Id=:invc[0].Id];
        System.assertEquals(invcheck[0].NSP_Invoice_Email_Sent__c, false); 
    }

      /**
     * Description : Test method to test the invoice message service methods (positive case)
     * Name : testInvoiceEmailMessageService
     */
    @isTest
    static void testInvoiceEmailMessageServicePositive(){
        Test.startTest();
        Account objaccount  = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Contact conobj = [SELECT Id FROM Contact WHERE Id != NULL LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated'];
        ords[0].blng__BillNow__c = TRUE;
		update ords;
        Test.stopTest();
        
		List<blng__Invoice__c> invc = [SELECT Id, Name, blng__Account__c,blng__Balance__c,NSP_Send_Email__c,blng__InvoiceStatus__c FROM blng__Invoice__c WHERE Id != NULL LIMIT 1];
        invc[0].blng__InvoiceStatus__c = 'Posted';
        invc[0].NSP_Send_Email__c = true;
        invc[0].NSP_CLM_Document_Received__c = true;
        invc[0].blng__BillToContact__c = conobj.Id;
		NSP_InvoiceTriggerHandler.TriggerDisabled = true;        
        update invc;
        NSP_InvoiceEmailMessageService.sendInvoiceEmail(new List<String>{invc[0].Id});
        List<blng__Invoice__c> invcheck = [SELECT Id, Name, blng__Account__c,blng__Balance__c,NSP_Send_Email__c,NSP_Invoice_Email_Sent__c FROM blng__Invoice__c WHERE Id=:invc[0].Id];
        System.assertEquals(invcheck[0].NSP_Invoice_Email_Sent__c, true); 
    }
}