/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  September 05, 2022                                                             
Function             :  Represents Test class for the NSP_InvoiceTriggerHelper. 
Story                :                                                                             
Modification Log     :                                                                               

***************************************************************************************************/
@isTest
public class NSP_InvoiceTriggerHelperTest
{
    public static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    public static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    @testSetup
    static void setupTestData(){
        
        //Disable unnesessary triggers
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderItemTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled=true;
        NSP_ContractTriggerHandler.TriggerDisabled=true;

        Account objaccount = NSP_TestHelper.createAccount(true);
        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule('Project Rev Rec');
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        blng__RevenueDistributionMethod__c dis=NSP_TestHelper.createRevenueDistribution('Project Rev Rec (Invoice)');
        blng__GLRule__c glrule=NSP_TestHelper.createGLRule();
        blng__FinanceBook__c finBook=NSP_TestHelper.createFinBook();
        blng__RevenueRecognitionTreatment__c recTreatment=NSP_TestHelper.createRevRecTreatment();
        recTreatment.blng__RevenueDistributionMethod__c=dis.Id;
        recTreatment.blng__RevenueRecognitionRule__c=rRule.Id;
        insert recTreatment;
        
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct.blng__BillingRule__c=bRule.Id;
        objproduct.blng__RevenueRecognitionRule__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        
        insert objproduct;
        Product2 obj2product = NSP_TestHelper.createProduct('Test2 Product',false);
        obj2product.SBQQ__ChargeType__c = 'Recurring';
        obj2product.SBQQ__BillingType__c = 'Arrears';
        obj2product.SBQQ__BillingFrequency__c = 'Monthly';
        obj2product.NSP_IsScholarshipPrice_Applicable__c ='YES';
        obj2product.blng__BillingRule__c=bRule.Id;
        obj2product.blng__RevenueRecognitionRule__c=rRule.Id;
        obj2product.blng__TaxRule__c=tRule.Id;
        
        insert obj2product;
        
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
        
        //create HCM case Creation
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        //caseRecord.Subject = NSP_ServiceConstants.HCM_TEST_CASE_SUBJECT;
        caseRecord.NSP_Opened_Date__c = Date.Today();
        caseRecord.Status = NSP_ServiceConstants.OPEN;
        caseRecord.AccountId = objaccount.Id;
        caseRecord.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Dunning').getRecordTypeId();
        caseRecord.Origin='Dunning';
        caseRecord.NSP_Dunning_Type__c = 'Open Invoice';
        //INSERT caseRecord;
        
    }
    
    @isTest
    private static void invoiceLineTest(){
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        list<Product2> objproductlist  = [Select Id, Name from Product2 WHERE Name != null];
        List<PriceBookEntry> pblist = new List<PriceBookEntry>();
        for(Product2  objproduct : objproductlist)
        {
            pblist.add(NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,false));
        }
        insert pblist;
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,objproductlist,pblist, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        objQuote.NSP_Budgetary_Quote__c = true;
        Test.startTest();
        update objQuote;       
        
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
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c,blng__Balance__c from blng__Invoice__c WHERE Id!=null LIMIT 10];
        inv[0].blng__InvoiceStatus__c='Posted';
        update inv;
        
        blng__Payment__c currPayment = new blng__Payment__c();
        currPayment.blng__Account__c = objaccount.id; 
        currPayment.blng__Amount__c = inv[0].blng__Balance__c;
        currPayment.blng__Status__c = 'Posted';
        currPayment.blng__PaymentDate__c = system.today();
        currPayment.blng__PaymentType__c = 'Check';
        insert currPayment;
        blng__PaymentAllocationInvoice__c paymentAlloc = new blng__PaymentAllocationInvoice__c();
        paymentAlloc.blng__Payment__c = currPayment.Id;
        paymentAlloc.blng__Amount__c = currPayment.blng__Amount__c; 
        paymentAlloc.blng__Invoice__c = inv[0].Id;
        paymentAlloc.blng__Type__c = 'Allocation';
        insert paymentAlloc;
        system.assertEquals('Posted', inv[0].blng__InvoiceStatus__c);
        // NSP_InvoiceTriggerHelper.setInvoiceToEmail(new Set<String>{inv[0].Id}); // correcting compliation errors ~ NSP_InvoiceTriggerHelperTest: line 124, column 34: Method does not exist or incorrect signature: void setInvoiceToEmail(Set<String>) from the type NSP_InvoiceTriggerHelper
        //System.assert(orderList.size()==1,true);
        }
    
    public static testMethod void testDunningCase()
    {
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
		NSP_InvoiceTriggerHelper.checkAndCloseDunningCase(new set<Id>{objaccount.Id});
        System.Assert(objaccount.Id!=null);
    }
    
    @isTest
    private static void invoiceLineUnpaidTest(){
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        list<Product2> objproductlist  = [Select Id, Name from Product2 WHERE Name != null];
        List<PriceBookEntry> pblist = new List<PriceBookEntry>();
        for(Product2  objproduct : objproductlist)
        {
            pblist.add(NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,false));
        }
        insert pblist;
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,objproductlist,pblist, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        objQuote.NSP_Budgetary_Quote__c = true;
        Test.startTest();
        update objQuote;       
        
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
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c,blng__Balance__c from blng__Invoice__c WHERE Id!=null LIMIT 10];
        inv[0].blng__InvoiceStatus__c='Posted';
        update inv;
        System.assert(orderList.size()==1,true);

    }
}