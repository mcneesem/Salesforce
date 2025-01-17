@isTest private class CreateSeparateProjectOrderItemTest {

    private static String accountDefaults = 'NSP_TestDataFactory.AccountDefaults';
    private static String accountName = 'Account Test1';

    @testSetup private static void setupTestData() {
        Order_Settings__c orderSetting = Order_Settings__c.getOrgDefaults();
        orderSetting.EffectiveDateStartOfMonth__c = true;
        orderSetting.Bypass_Rule_PreventStatusChange__c = true;
        upsert orderSetting;
    }

    @isTest private static void testSeperateProject() {
        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) {
             //Creating Account
            List<Account> accList = new List<Account>();
            Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount.Name = accountName;
            accList.add(oAccount);
            //Creating Account
            
            if(!accList.isEmpty()){
                Database.insert(accList);
            }
           
            blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
            blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
            blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
            
            Product2 objproduct = NSP_TestHelper.createSeparateBillingProduct('Test Product',rRule,tRule,bRule,'Monthly');
            Product2 objproduct1 = NSP_TestHelper.createSeparateBillingProduct('Test Product1',rRule,tRule,bRule,'Monthly');
            
            
            //Creating Project Templates 
            List<pse__proj__c> projList = new List<pse__proj__c>();
            pse__proj__c oProj2 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj2.Name = NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE;
            oProj2.pse__Is_Template__c = True;
            oProj2.pse__Is_Active__c = True;
            oProj2.pse__Start_Date__c = System.today();
            projList.add(oProj2);
            pse__proj__c oProj3 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj3.Name = NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE;
            oProj3.pse__Is_Template__c = True;
            oProj3.pse__Is_Active__c = True;
            oProj3.pse__Start_Date__c = System.today();
            oProj3.Go_Live_Date__c = System.today().addDays(-1);
            oProj3.Invoice_Ready__c = false;
            projList.add(oProj3);
            if(!projList.isEmpty()){
                Database.insert(projList);
            }
            projList.clear();
            list<string> trProdNames = new list<string>();
            list<Product2> productlist = new list<Product2>();
            trProdNames.add('Test Product');
            trProdNames.add('Test Product1');
            list<Product2> productlst = [Select Id, Name,ProductCode,NSP_Product_Type__c,SBQQ__SubscriptionPricing__c,Separate_Project__c	 from Product2 WHERE Name IN:trProdNames LIMIT 2]; //Added WHERE Condition as part of code fix

            productlst[0].ProductCode = 'HCMRETIntegration';
            productlst[0].NSP_Product_Type__c = 'IWX Bundle';
            //product1.SBQQ__SubscriptionType__c = 'Evergreen';
            productlst[0].SBQQ__SubscriptionPricing__c = 'Fixed Price';
            productlist.add(productlst[0]);
            productlst[1].ProductCode = 'HCMRETIntegration';
            productlst[1].NSP_Product_Type__c = 'IWX Bundle';
            //product1.SBQQ__SubscriptionType__c = 'Evergreen';
            productlst[1].SBQQ__SubscriptionPricing__c = 'Fixed Price';
            productlist.add(productlst[1]);
            
            update productlist;

            Opportunity objOpprtunity1 = NSP_TestHelper.createOpenOpportunity(oAccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
            Opportunity objOpprtunity2 = NSP_TestHelper.createOpenOpportunity(oAccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
            PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(productlst[0].Id,200.0,true);
            PriceBookEntry objPbe1     = NSP_TestHelper.createPriceBookEntry(productlst[1].Id,200.0,true);
            
            Id stdPriceBookId = Test.getStandardPricebookId();
            SBQQ__Quote__c objQuote1   = NSP_TestHelper.createCPQQuote(oAccount.Id,objOpprtunity1.Id,true);
            SBQQ__Quote__c objQuote2   = NSP_TestHelper.createCPQQuote(oAccount.Id,objOpprtunity2.Id,true);

            List<SBQQ__Quoteline__c> quoteLines1 = NSP_TestHelper.createCPQQuotelinesSeperateProject(objQuote1,productlist,new List<PriceBookEntry> {objPbe,objPbe1}, true);
            List<SBQQ__Quoteline__c> quoteLines2 = NSP_TestHelper.createCPQQuotelinesSeperateProject(objQuote2,productlist,new List<PriceBookEntry> {objPbe,objPbe1}, true);
            

            // create order from quote separate project
            objQuote1.SBQQ__Primary__c = true;
            objQuote1.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
            objQuote1.SBQQ__Ordered__c = true;
             // create order from quote separate project
            objQuote2.SBQQ__Primary__c = true;
            objQuote2.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_AMENDMENT;
            objQuote2.SBQQ__Ordered__c = true;
            
            list<order> orderlist = new list<order>();
            list<OrderItem> orderitemUpdlist = new list<OrderItem>();
            list<SBQQ__Quote__c> quotelist = new list<SBQQ__Quote__c>();
            set<id> quoteids=  new set<id>();
            set<id> productids=  new set<id>();

            quoteids.add(objQuote1.id);
            quoteids.add(objQuote2.id);

            quotelist.add(objQuote1);
            quotelist.add(objQuote2);
            
            productids.add(productlst[0].id);

            Test.startTest();
            update quotelist;
            
            Order order1 = new Order();
            order1.NSP_Project_Go_Live_Date__c = System.today().addDays(30);
            order1.OpportunityId = objOpprtunity2.Id;
            order1.AccountId = oAccount.Id;
            order1.Status = NSP_CPQConstants.ORDER_DRAFT;
            order1.EffectiveDate = Date.Today();
            order1.Pricebook2Id = stdPriceBookId;
            orderlist.add(order1);
            Order order2 = new Order();
            order2.NSP_Project_Go_Live_Date__c = System.today().addDays(30);
            order2.OpportunityId = objOpprtunity2.Id;
            order2.AccountId = oAccount.Id;
            order2.Status = NSP_CPQConstants.ORDER_DRAFT;
            order2.EffectiveDate = Date.Today();
            order2.Pricebook2Id = stdPriceBookId;
            orderlist.add(order2);
            insert orderList;
            
            orderList.clear();
            
            list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,NSP_Project__c,NSP_Project_Name_New_Sales__c,Separate_Project__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c IN:quoteids]);
            integer nTwice=0;
            for ( OrderItem oi : orderItemList ) {
                 if(oi.Separate_Project__c == true) {
                    if(nTwice <=1) {
                        oi.NSP_Project__c = oProj3.id;
                        nTwice++;
                    }
                    oi.NSP_Project_Name_New_Sales__c = 'iSolved - Other';
                } else {
                    oi.NSP_Project__c= oProj2.Id;
                }
                orderitemUpdlist.add(oi);
            }

            update orderitemUpdlist;
            
            list<Order> orderList1 = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c IN:quoteids]);
            orderList1[0].EffectiveDate = Date.Today();
            orderList1[0].Status = NSP_CPQConstants.ORDER_REVIEWED;
            orderList.add(orderList1[0]);
            orderList1[1].Status = NSP_CPQConstants.ORDER_REVIEWED;
            orderList.add(orderList1[1]);
            update orderList; 
            list<string> strlst = new list<string>();
            for ( order ord:orderList ) {
                strlst.add(ord.id);
            }
            CreateSeparateProjectOrderItem.createSeparateProject(strlst);
        }
    }

}
//