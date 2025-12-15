@isTest private class InsperityWOBlngAccTransferBatchTest {

    @testSetup private static void dataSetup() {
        Email_Deliverability_Settings__c emailSetting = new Email_Deliverability_Settings__c();
        insert emailSetting;

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
        Account objaccount1 = NSP_TestHelper.createAccount(true);
        objaccount1.Previous_Month_Account__c = objaccount.name;
        objaccount1.name = 'Test';
        update objaccount1;
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
        list<OrderItem> orderItemList = new list<OrderItem>([select id,blng__InvoiceRunProcessingStatus__c,blng__BillingAccount__c from OrderItem where Order.SBQQ__Quote__c =:objQuote.Id]);
        list<Order> orderList = new list<Order>([select id,blng__BillingAccount__c,NSP_Back_Out__c,Prevent_Reassignment__c from Order where SBQQ__Quote__c =:objQuote.Id]);
        //orderList[0].NSP_Project_Go_Live_Date__c=system.today();
        //orderList[0].Status='Reviewed';
        orderList[0].NSP_Back_Out__c = false;
        orderList[0].Prevent_Reassignment__c = false;  
        orderList[0].blng__BillingAccount__c=objaccount.id;
        update orderList;
        for(OrderItem oitem:orderItemList){
            oitem.blng__InvoiceRunProcessingStatus__c='Pending Billing';
            oitem.blng__BillingAccount__c=objaccount.id;
        }
        update orderItemList;
        //orderList[0].Status='Activated';
        update orderList;
        //Assert.isNotNull(objOpprtunity.Id);
        Test.stopTest();
    }

    @isTest private static void testMethod_InsperityWOBillingAccountTransferBatch() {
        List<String> strAccNames = new List<String>();
        String currentMonthId = '';
        list<account> acclist = [select id,Previous_Month_Account__c from account];
        if(acclist[0].Previous_Month_Account__c != '') {
            currentMonthId = acclist[1].id;
            strAccNames.add(acclist[1].Previous_Month_Account__c);
        } else {
            currentMonthId = acclist[0].id;
            strAccNames.add(acclist[0].Previous_Month_Account__c);          
        }
        
         list<order> query = [SELECT Id,blng__BillingAccount__c ,(select id,blng__BillingAccount__c,blng__InvoiceRunProcessingStatus__c,Has_Consumption_Schedule__c from  orderitems) from order];
        list<orderitem> query1 = [select id,OrderId,blng__BillingAccount__c,blng__InvoiceRunProcessingStatus__c,Has_Consumption_Schedule__c from  orderitem];

        // This code runs as the system user
        User u = [select id,email from user where name = 'Deployment Manager'];
        
        System.runAs(u) 
        {  
            test.starttest();
            InsperityWOBillingAccountTransferBatch BatchClass = new InsperityWOBillingAccountTransferBatch(strAccNames[0],currentMonthId);
            Database.executeBatch(BatchClass, 20);
            test.stoptest();
        }
    }
}