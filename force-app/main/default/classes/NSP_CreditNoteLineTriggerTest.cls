@isTest
public class NSP_CreditNoteLineTriggerTest {
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
        Map<Id,Id> producRevRuleMap= new Map<Id,Id>();
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(objaccount.id, true);
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        blng__RevenueDistributionMethod__c dis=NSP_TestHelper.createRevenueDistribution(NSP_CPQConstants.PROJ_REV_REC_CRED_DIST);
        NSP_TestHelper.createGLRule();
        NSP_TestHelper.createFinBook();
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
        objproduct.NSP_Revenue_Recognition_Rule_Credit__c=rRule.Id;
        objproduct.blng__TaxRule__c=tRule.Id;
        insert objproduct;
        producRevRuleMap.put(objproduct.Id,rRule.Id);
        
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
        producRevRuleMap.put(objproduct1.Id,rRule1.Id);
        
        blng__RevenueRecognitionRule__c rRule2=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.IMMEDIATE_REV);
        Product2 objproduct2 = NSP_TestHelper.createProduct('Test Product2',false);
        objproduct2.SBQQ__ChargeType__c = 'Recurring';
        objproduct2.SBQQ__BillingType__c = 'Arrears';
        objproduct2.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct2.NSP_IsScholarshipPrice_Applicable__c ='YES';
        objproduct2.blng__BillingRule__c=bRule.Id;
        objproduct2.blng__RevenueRecognitionRule__c=rRule2.Id;
        objproduct2.blng__TaxRule__c=tRule.Id;
        insert objproduct2;
        producRevRuleMap.put(objproduct2.Id,rRule2.Id);
        
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        PriceBookEntry objPbe1     = NSP_TestHelper.createPriceBookEntry(objproduct1.Id,200.0,true);
        PriceBookEntry objPbe2     = NSP_TestHelper.createPriceBookEntry(objproduct2.Id,200.0,true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct,objproduct1,objproduct2},new List<PriceBookEntry> {objPbe,objPbe1,objPbe2}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        Test.startTest();
        update objQuote; 
        list<OrderItem> orderItemList = new list<OrderItem>([select id,Product2Id,blng__NextBillingDate__c,blng__InvoiceRunProcessingStatus__c,NSP_Revenue_Recognition_Rule_Credit__c from OrderItem where Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id from Order where SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        orderList[0].Status='Reviewed';
        update orderList;
        for(OrderItem oitem:orderItemList){
            oitem.blng__InvoiceRunProcessingStatus__c='Pending Billing';
            oitem.NSP_Revenue_Recognition_Rule_Credit__c=producRevRuleMap.get(oitem.Product2Id);
        }
        update orderItemList;
        orderList[0].Status='Activated';
        update orderList;
        Assert.isNotNull(objOpprtunity.Id);
        Test.stopTest();
    }
    @isTest
    private static void creditLineTest(){
        String name='Test RevRec Rule '+NSP_CPQConstants.PROJ_REV_REC;
        List<blng__CreditNoteLine__c> credLineList= new List<blng__CreditNoteLine__c>();
        Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        List<Order> orderList = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c,Status
                                 FROM Order
                                 WHERE Status = 'Activated'];
        orderList[0].blng__BillNow__c=true;
        update orderList;
        // Test.startTest();
        List<blng__Invoice__c> inv =[Select Id,blng__InvoiceStatus__c from blng__Invoice__c LIMIT 10];
        inv[0].blng__InvoiceStatus__c='Posted';
        update inv;
        blng__CreditNote__c cred= new blng__CreditNote__c(blng__Account__c=objaccount.Id,blng__CreditNoteDate__c=system.today());
        insert cred;
        //Test.stopTest();  
        List<blng__InvoiceLine__c> invLines=[SELECT Id,Name,blng__Product__c,NSP_Project_Go_Live_Date__c FROM blng__InvoiceLine__c LIMIT 10];
        for(blng__InvoiceLine__c invLine:invLines){
            blng__CreditNoteLine__c credLine= new blng__CreditNoteLine__c();
            credLine.blng__Product__c=invLine.blng__Product__c;
            credLine.blng__CreditNote__c=cred.Id;
            credLine.blng__Subtotal__c=10;
            credLine.blng__InvoiceLine__c=invLine.Id;
            credLine.blng__StartDate__c=system.today();
            credLineList.add(credLine);
        }
        insert credLineList;
        cred.blng__Status__c='Posted';
        List<blng__CreditNoteLine__c> credLine=[SELECT Id,blng__Status__c,NSP_Revenue_Recognition_Rule_Credit__r.Name,NSP_Project_Go_Live_Date__c FROM blng__CreditNoteLine__c LIMIT 10];
        for(blng__CreditNoteLine__c cLine:credLine){
            cLine.blng__Status__c='Posted';
        }
        update cred;
        update credLine;
        blng__RevenueSchedule__c sch=new blng__RevenueSchedule__c();
        sch.blng__TotalRevenueAmount__c=25;
        sch.blng__FullRecognitionDate__c=system.today()-1;
        sch.blng__RevenueDistributionMethod__c=[SELECT Id,Name FROM blng__RevenueDistributionMethod__c limit 1]?.Id;
        sch.blng__RevenueRecognitionTreatment__c=[SELECT Id,Name FROM blng__RevenueRecognitionTreatment__c limit 1]?.Id;
        sch.blng__CreditNoteLine__c=credLine.size()>0?credLine[0].Id:null;
        insert sch;
        for(blng__CreditNoteLine__c cLine:credLine){
            cLine.NSP_Project_Go_Live_Date__c=system.today()+1;
        }
        update credLine;
        system.assertEquals('Activated', orderList[0].Status);
        Test.stopTest();  
    }
    @isTest
    private static void standaloneCreditNoteLineTest(){
        Map<String,Date> projectGoLiveDateMap= new Map<String,Date>();
        Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        
        pse__Proj__c hcmProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        hcmProject.Name = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.pse__Start_Date__c = Date.Today();
        hcmProject.pse__Account__c = objaccount.Id;
        hcmProject.TemplateName__c = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.Project_Implementer__c = UserInfo.getUserId();
        hcmProject.Go_Live_Date__c=system.today();
        insert hcmProject;
        
        blng__CreditNote__c cred= new blng__CreditNote__c(blng__Account__c=objaccount.Id,blng__CreditNoteDate__c=system.today());
        insert cred;
        
        blng__CreditNoteLine__c credLine= new blng__CreditNoteLine__c();
        credLine.blng__Product__c=objproduct.Id;
        credLine.blng__CreditNote__c=cred.Id;
        credLine.blng__Subtotal__c=10;
        credLine.NSP_Project_Go_Live_Date__c=system.today();
        insert credLine;

        projectGoLiveDateMap.put(hcmProject.Id,system.today());
        NSP_RevRecService.updateGoLiveDatesOnInvLineAndCredLines(projectGoLiveDateMap);//invoking explicitly as this will called by platform event

        Test.stopTest(); 
    }
}