@isTest
public class NSP_ReviewRevRecRulesTest {
    public static final String TEST_RULE='Test RevRec Rule ';
    @testSetup
    static void setupTestData(){
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled=true;
        NSP_ContractTriggerHandler.TriggerDisabled=true;
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
        blng__RevenueRecognitionRule__c rRule1=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC12);
        blng__RevenueRecognitionRule__c rRule2=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.DELAY_12_1);
        blng__RevenueRecognitionRule__c rRule3=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.IMMEDIATE_REV);
        blng__RevenueRecognitionRule__c rRule4=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.MONTH_12);
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        
        Product2 objproduct = NSP_TestHelper.createBillingProduct('Test Product',rRule,tRule,bRule,NSP_CPQConstants.BLNGFREQ_MONTHLY);
        Product2 objproduct1 = NSP_TestHelper.createBillingProduct('Test Product1',rRule,tRule,bRule,NSP_CPQConstants.BLNGFREQ_MONTHLY);
        Product2 objproduct2 = NSP_TestHelper.createBillingProduct('Test Product2',rRule3,tRule,bRule,NSP_CPQConstants.BLNGFREQ_MONTHLY);
        Product2 objproduct3 = NSP_TestHelper.createBillingProduct('Test Product3',rRule3,tRule,bRule,NSP_CPQConstants.BLNGFREQ_MONTHLY);
        Product2 objproduct4 = NSP_TestHelper.createBillingProduct('Test Product4',rRule1,tRule,bRule,NSP_CPQConstants.BLNGFREQ_ANNUAL);
        Product2 objproduct5 = NSP_TestHelper.createBillingProduct('Test Product5',rRule4,tRule,bRule,NSP_CPQConstants.BLNGFREQ_ANNUAL);
        Product2 objproduct6 = NSP_TestHelper.createBillingProduct('Test Product6',rRule2,tRule,bRule,NSP_CPQConstants.BLNGFREQ_ANNUAL);
        
    }
    @isTest
    private static void reviewProjectRevRecTest(){
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        Product2 objproduct1  = [Select Id, Name from Product2 WHERE Name = 'Test Product1' LIMIT 1];
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        PriceBookEntry objPbe1     = NSP_TestHelper.createPriceBookEntry(objproduct1.Id,200.0,true);        
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct,objproduct1},new List<PriceBookEntry> {objPbe,objPbe1}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
        objQuote.SBQQ__Ordered__c = true;
        
        Test.startTest();
        update objQuote; 
        //revenue distribution scenario
        NSP_Revenue_Distribution_Scenario__c revscenrio= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Project Rev Rec' limit 1]?.Id;
        revscenrio.NSP_Product__c=objproduct.Id;
        revscenrio.NSP_Project_Rev_Rec_Rule12_Inv__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12;
        revscenrio.NSP_Project_Rev_Rec_Rule12_Cred__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12;
        insert revscenrio;
        
        NSP_Revenue_Distribution_Scenario__c revscenrio1= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio1.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name,NSP_Rev_Rec_Model__c FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Project Rev Rec' limit 1]?.Id;
        revscenrio1.NSP_Product__c=objproduct1.Id;
        revscenrio1.NSP_Immediate_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV;
        revscenrio1.NSP_Immediate_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV;
        insert revscenrio1;
        
        list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id]);
        orderItemList[0].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_ANNUAL;
        update orderItemList;      
        NSP_ReviewRevRecRules.overrideRevRecRules(new List<String>{orderList[0].Id});// explicitly calling method as this method will invoke after 2 mins of delay
        String updatedRuleName=[select Id,blng__RevenueRecognitionRule__r.Name FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id limit 1]?.blng__RevenueRecognitionRule__r.Name;
        system.assertEquals(TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12,updatedRuleName);
        Test.stopTest();
    }
    @isTest
    private static void reviewImmediateRevRecTest(){
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product2' LIMIT 1];
        Product2 objproduct1  = [Select Id, Name from Product2 WHERE Name = 'Test Product3' LIMIT 1];
        objproduct1.NSP_Project_Name_New_Sales__c = 'ISolved HCM';
        objproduct1.NSP_Priority_New_Sales__c = 1;
        update objproduct1;
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        PriceBookEntry objPbe1     = NSP_TestHelper.createPriceBookEntry(objproduct1.Id,200.0,true);        
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct,objproduct1},new List<PriceBookEntry> {objPbe,objPbe1}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
        objQuote.SBQQ__Ordered__c = true;
        
        Test.startTest();
        update objQuote;
        //revenue distribution scenario
        NSP_Revenue_Distribution_Scenario__c revscenrio= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Immediate' limit 1]?.Id;
        revscenrio.NSP_Product__c=objproduct.Id;
        revscenrio.NSP_Project_Rev_Rec_Rule12_Inv__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12;
        revscenrio.NSP_Project_Rev_Rec_Rule12_Cred__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12;
        insert revscenrio;
        
        NSP_Revenue_Distribution_Scenario__c revscenrio1= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio1.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name,NSP_Rev_Rec_Model__c FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Immediate' limit 1]?.Id;
        revscenrio1.NSP_Product__c=objproduct1.Id;
        revscenrio1.NSP_Project_Rev_Rec_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC;
        revscenrio1.NSP_Project_Rev_Rec_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC;
        insert revscenrio1;
        
        list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id]);
        orderItemList[0].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_ANNUAL;
        update orderItemList;
        orderList[0].NSP_Project_Name__c='ISolved HCM';
        update orderList;
        NSP_ReviewRevRecRules.overrideRevRecRules(new List<String>{orderList[0].Id});// explicitly calling method as this method will invoke after 2 mins of delay
        String updatedRuleName=[select Id,blng__RevenueRecognitionRule__r.Name FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id limit 1]?.blng__RevenueRecognitionRule__r.Name;
        system.assertEquals(TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12,updatedRuleName);
        Test.stopTest();
    }
    @isTest
    private static void reviewProjRevRec12Test(){
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product4' LIMIT 1];
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);       
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
        objQuote.SBQQ__Ordered__c = true;
        
        Test.startTest();
        update objQuote; 
        list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id]);
        orderItemList[0].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_MONTHLY;
        update orderItemList;
        //revenue distribution scenario
        NSP_Revenue_Distribution_Scenario__c revscenrio= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Project Rev Rec 12' limit 1]?.Id;
        revscenrio.NSP_Product__c=objproduct.Id;
        revscenrio.NSP_Immediate_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV;
        revscenrio.NSP_Immediate_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV;
        insert revscenrio;
        
        NSP_ReviewRevRecRules.overrideRevRecRules(new List<String>{orderList[0].Id});// explicitly calling method as this method will invoke after 2 mins of delay
        String updatedRuleName=[select Id,blng__RevenueRecognitionRule__r.Name FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id limit 1]?.blng__RevenueRecognitionRule__r.Name;
        system.assertEquals(TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV,updatedRuleName);
        Test.stopTest();
    }
    @isTest
    private static void review12MonthTest(){        
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product5' LIMIT 1];
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);       
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
        objQuote.SBQQ__Ordered__c = true;
        
        Test.startTest();
        update objQuote; 
        list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id]);
        orderItemList[0].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_MONTHLY;
        update orderItemList;
        //revenue distribution scenario
        NSP_Revenue_Distribution_Scenario__c revscenrio= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='12 Month' limit 1]?.Id;
        revscenrio.NSP_Product__c=objproduct.Id;
        revscenrio.NSP_Immediate_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV;
        revscenrio.NSP_Immediate_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV;
        insert revscenrio;
        
        NSP_ReviewRevRecRules.overrideRevRecRules(new List<String>{orderList[0].Id});// explicitly calling method as this method will invoke after 2 mins of delay
        String updatedRuleName=[select Id,blng__RevenueRecognitionRule__r.Name FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id limit 1]?.blng__RevenueRecognitionRule__r.Name;
        system.assertEquals(TEST_RULE+NSP_CPQConstants.IMMEDIATE_REV,updatedRuleName);
        Test.stopTest();
    }
        @isTest
    private static void renewaltest(){
        NSP_InvoiceTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OrderTriggerHandler.TriggerDisabled = true;
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_ContactTriggerHandler.TriggerDisabled=true;
        NSP_QuoteLineTriggerHandler.TriggerDisabled=true;
        NSP_SubscriptionTriggerHandler.TriggerDisabled=true;
        NSP_ContractTriggerHandler.TriggerDisabled=true;
        
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
        Product2 objproduct1  = [Select Id, Name from Product2 WHERE Name = 'Test Product6' LIMIT 1];
        Product2 objproduct2  = [Select Id, Name from Product2 WHERE Name = 'Test Product3' LIMIT 1];
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        PriceBookEntry objPbe1     = NSP_TestHelper.createPriceBookEntry(objproduct1.Id,200.0,true);  
        PriceBookEntry objPbe2     = NSP_TestHelper.createPriceBookEntry(objproduct2.Id,200.0,true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        Contract ct = new Contract();
        ct.AccountId = objaccount.Id;
        ct.SBQQ__Opportunity__c = objOpprtunity.Id;
        ct.SBQQ__Quote__c = objQuote.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        Date dt = Date.today();
        ct.StartDate = dt;
        ct.Status = 'Draft';
        insert ct;
        
        Opportunity opp2 = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'Existing Product',false);
        opp2.SBQQ__RenewedContract__c = ct.Id;
        insert opp2;
        SBQQ__Quote__c quote2 = NSP_TestHelper.createCPQQuote(objaccount.Id,opp2.Id,false);
        quote2.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_RENEWAL;
        insert quote2;
        NSP_TestHelper.createCPQQuotelines(quote2,new List<Product2>{objproduct,objproduct1,objproduct2},new List<PriceBookEntry> {objPbe,objPbe1,objPbe2}, true);
        // create order from quote
        quote2.SBQQ__Primary__c = true;
        quote2.SBQQ__Ordered__c = true;     
        Test.startTest();
        update quote2; 
        //revenue distribution scenario
        
        NSP_Revenue_Distribution_Scenario__c revscenrio= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Project Rev Rec' limit 1]?.Id;
        revscenrio.NSP_Product__c=objproduct.Id;
        revscenrio.NSP_Project_Rev_Rec_Rule12_Inv__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12;
        revscenrio.NSP_Project_Rev_Rec_Rule12_Cred__c=TEST_RULE+NSP_CPQConstants.PROJ_REV_REC12;
        revscenrio.NSP_X12_Month_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.MONTH_12;
        revscenrio.NSP_X12_Month_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.MONTH_12;
        insert revscenrio;
        
        NSP_Revenue_Distribution_Scenario__c revscenrio1= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio1.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='12 Delay 1' limit 1]?.Id;
        revscenrio1.NSP_Product__c=objproduct1.Id;
        revscenrio1.NSP_X12_Month_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.MONTH_12;
        revscenrio1.NSP_X12_Month_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.MONTH_12;
        insert revscenrio1;
        
        NSP_Revenue_Distribution_Scenario__c revscenrio2= new NSP_Revenue_Distribution_Scenario__c();
        revscenrio2.NSP_Primary_Rev_Rec_Rule__c=[SELECT Id,Name FROM blng__RevenueRecognitionRule__c WHERE NSP_Rev_Rec_Model__c='Immediate' limit 1]?.Id;
        revscenrio2.NSP_Product__c=objproduct2.Id;
        revscenrio2.NSP_X12_Month_Rule_Inv__c=TEST_RULE+NSP_CPQConstants.MONTH_12;
        revscenrio2.NSP_X12_Month_Rule_Cred__c=TEST_RULE+NSP_CPQConstants.MONTH_12;
        insert revscenrio2;
        
        list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:quote2.Id]);
        list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:quote2.Id]);
        orderItemList[0].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_ANNUAL;
        orderItemList[1].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_ANNUAL;
        orderItemList[0].NSP_Action_Type__c=NSP_CPQConstants.QUOTE_TYPE_RENEWAL;
        orderItemList[1].NSP_Action_Type__c=NSP_CPQConstants.QUOTE_TYPE_RENEWAL;
        orderItemList[2].SBQQ__BillingFrequency__c=NSP_CPQConstants.BLNGFREQ_ANNUAL;
        orderItemList[2].NSP_Action_Type__c=NSP_CPQConstants.QUOTE_TYPE_RENEWAL;
        update orderItemList;
        NSP_ReviewRevRecRules.overrideRevRecRules(new List<String>{orderList[0].Id});
        String updatedRuleName=[select Id,blng__RevenueRecognitionRule__r.Name FROM OrderItem WHERE Order.SBQQ__Quote__c =:quote2.Id AND Product2Id=:objproduct.Id limit 1]?.blng__RevenueRecognitionRule__r.Name;
        system.assertEquals(TEST_RULE+NSP_CPQConstants.MONTH_12,updatedRuleName);
        Test.stopTest();
    }
}