/**************************************************************************************************
Version              :  1.0
Created Date         :  September 05, 2022
Function             :  Represents Test class for the NSP_InvoiceTriggerHelper.
Story                :
Modification Log     :

***************************************************************************************************/
@isTest private class NSP_InvoiceTriggerHelperTest {
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';

    @testSetup private static void setupTestData(){

        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        upsert orderSetting;

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
        objcontact.RecordTypeId = '0124x0000019l9CAAQ';
        update objcontact;

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
        objproduct.ProductCode = 'IWXSU';
        objproduct.blng__TaxRule__c=tRule.Id;

        insert objproduct;
        Product2 obj2product = NSP_TestHelper.createProduct('Test2 Product',false);
        obj2product.SBQQ__ChargeType__c = 'Recurring';
        obj2product.SBQQ__BillingType__c = 'Arrears';
        obj2product.SBQQ__BillingFrequency__c = 'Monthly';
        obj2product.NSP_IsScholarshipPrice_Applicable__c ='YES';
        obj2product.blng__BillingRule__c=bRule.Id;
        obj2product.blng__RevenueRecognitionRule__c=rRule.Id;
        obj2product.ProductCode = 'IWXSU';
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
        objproduct1.ProductCode = 'IWXSU';
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

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        oProject.pse__Is_Template__c = true;
        oProject.NSP_Asset_Type__c = 'Time_Attendance';
        oProject.pse__Start_Date__c = System.today();
        insert oProject;

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
        objQuote.SBQQ__Type__c = 'Renewal';

        test.starttest();
        update objQuote;

        list<contact> cntList = [select id from contact limit 2];
        list<pse__Proj__c> prjList = [select id from pse__Proj__c limit 2];

        //project creation
        list<OrderItem> orderItemList = new list<OrderItem>([select id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        orderList[0].ShipToContactId = cntList[0].id;
        orderList[0].NSP_Down_Payment_Required__c = 'yes';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c='Pending Billing';
        orderItemList[0].NSP_Project__c = prjList[0].id;
        update orderItemList;
        orderList[0].Status='Activated';
        update orderList;
        orderList[0].blng__BillNow__c=true;
        update orderList;
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c,blng__Balance__c,NSP_Ship_To_City__c,blng__PaymentStatus__c,blng__TotalAmount__c,(select id,NSP_Product_Code__c from blng__InvoiceInvoiceLines__r ) from blng__Invoice__c WHERE Id!=null LIMIT 10];
        for(blng__Invoice__c invo:inv)
        {
             for(blng__InvoiceLine__c invl:invo.blng__InvoiceInvoiceLines__r)
            {
                system.debug(invl.NSP_Product_Code__c);
            }
        }

        inv[0].blng__InvoiceStatus__c='Posted';
        inv[0].NSP_Invoice_External_ID__c = null;
        system.debug(inv);
        system.debug(inv[0].blng__PaymentStatus__c);
        update inv[0];

        blng__Payment__c currPayment = new blng__Payment__c();
        currPayment.blng__Account__c = objaccount.id;
        currPayment.blng__Amount__c = inv[0].blng__TotalAmount__c;
        currPayment.blng__Status__c = 'Posted';
        currPayment.blng__PaymentDate__c = system.today();
        currPayment.blng__PaymentType__c = 'Check';
        insert currPayment;
        blng__PaymentAllocationInvoice__c paymentAlloc = new blng__PaymentAllocationInvoice__c();
        paymentAlloc.blng__Payment__c = currPayment.id ;
        paymentAlloc.blng__Amount__c = currPayment.blng__Amount__c;
        paymentAlloc.blng__Invoice__c = inv[0].Id;
        paymentAlloc.blng__Type__c = 'Allocation';
        insert paymentAlloc;

        set<id> invoiceIdset = (new map<id,blng__Invoice__c>(inv)).keyset();
        Set<String> invIdset = (Set<String>)JSON.deserialize(JSON.serialize(invoiceIdset), Set<String>.class);

        NSP_InvoiceTriggerHelper.setDownPaymentDetailsOnProject(invIdset);
        test.stoptest();

        // NSP_InvoiceTriggerHelper.setInvoiceToEmail(new Set<String>{inv[0].Id}); // correcting compliation errors ~ NSP_InvoiceTriggerHelperTest: line 124, column 34: Method does not exist or incorrect signature: void setInvoiceToEmail(Set<String>) from the type NSP_InvoiceTriggerHelper
        //System.assert(orderList.size()==1,true);
    }

    @isTest private static void testDunningCase() {
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        NSP_InvoiceTriggerHelper.checkAndCloseDunningCase(new set<Id>{objaccount.Id});
        System.Assert(objaccount.Id!=null);
    }

    @isTest private static void testUnsetDownPaymentOnProject(){
        List<Account> objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        list<Product2> objproductlist  = [Select Id, Name from Product2 WHERE Name != null];
        List<PriceBookEntry> pblist = new List<PriceBookEntry>();
        for(Product2 objproduct : objproductlist){
            pblist.add(NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,false));
        }
        insert pblist;

        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount[0].Id,'New Product',true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount[0].Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,objproductlist,pblist,true);
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        test.starttest();
        update objQuote;

        list<contact> cntList = [select id from contact limit 2];
        list<pse__Proj__c> prjList = [select id from pse__Proj__c limit 2];

        list<OrderItem> orderItemList = new list<OrderItem>([select id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c = system.today();
        orderList[0].Status = 'Reviewed';
        orderList[0].ShipToContactId = cntList[0].id;
        orderList[0].NSP_Down_Payment_Required__c = 'yes';
        update orderList;
        orderItemList[0].blng__InvoiceRunProcessingStatus__c = 'Pending Billing';
        orderItemList[0].NSP_Project__c = prjList[0].id;
        update orderItemList;
        orderList[0].Status = 'Activated';
        update orderList;
        orderList[0].blng__BillNow__c = true;
        update orderList;

        List<blng__Invoice__c> inv = [Select Id,blng__InvoiceStatus__c,blng__Balance__c,blng__PaymentStatus__c,blng__TotalAmount__c from blng__Invoice__c WHERE Id!=null LIMIT 10];
        inv[0].blng__InvoiceStatus__c = 'Posted';
        update inv[0];

        // Pay the invoice so Project_Down_Payment_Received__c gets set to true
        blng__Payment__c currPayment = new blng__Payment__c();
        currPayment.blng__Account__c = objaccount[0].id;
        currPayment.blng__Amount__c = inv[0].blng__TotalAmount__c;
        currPayment.blng__Status__c = 'Posted';
        currPayment.blng__PaymentDate__c = system.today();
        currPayment.blng__PaymentType__c = 'Check';
        insert currPayment;
        blng__PaymentAllocationInvoice__c paymentAlloc = new blng__PaymentAllocationInvoice__c();
        paymentAlloc.blng__Payment__c = currPayment.id;
        paymentAlloc.blng__Amount__c = currPayment.blng__Amount__c;
        paymentAlloc.blng__Invoice__c = inv[0].Id;
        paymentAlloc.blng__Type__c = 'Allocation';
        insert paymentAlloc;

        // Manually set the project checkbox to true to simulate the paid state
        pse__Proj__c proj = prjList[0];
        proj.Project_Down_Payment_Received__c = true;
        update proj;

        // Now directly call unsetDownPaymentOnProject — simulates Paid -> Unpaid transition
        NSP_InvoiceTriggerHelper.unsetDownPaymentOnProject(new Set<String>{ inv[0].Id });
        test.stoptest();

        List<pse__Proj__c> updatedProj = [SELECT Id, Project_Down_Payment_Received__c FROM pse__Proj__c WHERE Id = :prjList[0].Id];
        System.assertEquals(false, updatedProj[0].Project_Down_Payment_Received__c, 'Project_Down_Payment_Received__c should be unchecked after invoice moves to Unpaid');
    }

    @isTest private static void invoiceLineUnpaidTest(){
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
        test.starttest();
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
//