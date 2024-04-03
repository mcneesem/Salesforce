@isTest
public class NSP_ProjBlngTriggerHelperTest {
    public NSP_ProjBlngTriggerHelperTest() {

    }

    public static String accountDefaults = 'NSP_TestDataFactory.AccountDefaults';
    public static String accountName = 'Account Test1';
    public static user u1;

    @isTest
    public static void testTriggerHelper(){
        
        
        u1 = [select id from user where name =: NSP_ServiceConstants.DEPLOYMENT_MANAGER LIMIT 1];
        
        System.runas(u1)
        {
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
            
            Product2 objproduct = NSP_TestHelper.createBillingProduct('Test Product',rRule,tRule,bRule,'Monthly');
            
            
            //Creating Project Templates 
            List<pse__proj__c> projList = new List<pse__proj__c>();
            pse__proj__c oProj = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj.Name = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
            oProj.pse__Is_Template__c = True;
            oProj.pse__Is_Active__c = True;
            oProj.pse__Start_Date__c = System.today();
            oProj.Go_Live_Date__c = System.today().addDays(-1);
            oProj.Invoice_Ready__c = false;
            projList.add(oProj);
            pse__proj__c oProj1 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj1.Name = NSP_ServiceConstants.PROJECT_CORE_TEMPLATE;
            oProj1.pse__Is_Template__c = True;
            oProj1.pse__Is_Active__c = True;
            oProj1.pse__Start_Date__c = System.today();
            projList.add(oProj1);
             //Creating Project Templates 
            pse__proj__c oProj2 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj2.Name = NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE;
            oProj2.pse__Is_Template__c = True;
            oProj2.pse__Is_Active__c = True;
            oProj2.pse__Start_Date__c = System.today();
            projList.add(oProj2);
            if(!projList.isEmpty()){
                Database.insert(projList);
            }
            Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
            product1.ProductCode = 'PerformSmart Traditional';
            product1.NSP_Product_Type__c = 'iSolved Hardware';
            //product1.SBQQ__SubscriptionType__c = 'Evergreen';
            product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            update product1;
            Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(oAccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
            PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
            
            Id stdPriceBookId = Test.getStandardPricebookId();
            SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(oAccount.Id,objOpprtunity.Id,true);
            List<SBQQ__Quoteline__c> quoteLines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{product1},new List<PriceBookEntry> {objPbe}, true);
            // create order from quote
            objQuote.SBQQ__Primary__c = true;
            objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
            objQuote.SBQQ__Ordered__c = true;
            
            Test.startTest();
            update objQuote;
            Order order = new Order();
            order.NSP_Project_Go_Live_Date__c = System.today().addDays(30);
            order.NSP_Project__c = oProj.Id;
            order.OpportunityId = objOpprtunity.Id;
            order.AccountId = oAccount.Id;
            order.Status = NSP_CPQConstants.ORDER_DRAFT;
            order.EffectiveDate = Date.Today();
            order.Pricebook2Id = stdPriceBookId;
            insert order;
            list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
            orderList[0].EffectiveDate = Date.Today();
            update orderList;
            list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:product1.Id]);
            orderItemList[0].NSP_Project__c= oProj.Id;
            update orderItemList;
            oProj.Invoice_Ready__c = true;
            oProj.pse__Project_Status__c = 'Close/Lost';
            oProj.NSP_Rating__c = 'Unfavorable';
            oProj.Go_Live_Date__c = System.today();
            update oProj;
            oProj1.Invoice_Ready__c = true;
            oProj1.pse__Project_Status__c = 'Complete';
            oProj1.NSP_Rating__c = 'Unfavorable';
            oProj1.Go_Live_Date__c = System.today();
            update oProj1;
            test.stopTest();
            //System.assert(orderList.size()==1,true);           
        }


    }

    @isTest
    public static void testProjectUpdate() {
        
        u1 = [select id from user where name =: NSP_ServiceConstants.DEPLOYMENT_MANAGER  LIMIT 1];
        System.runas(u1)
        {
            List<pse__proj__c> projectList = [SELECT Id FROM pse__proj__c WHERE Id!=null LIMIT 2];

            List<pse__proj__c> projList = new List<pse__proj__c>();
            pse__proj__c oProj = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj.Name = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
            oProj.pse__Is_Template__c = True;
            oProj.pse__Is_Active__c = True;
            oProj.pse__Start_Date__c = System.today();
            oProj.Go_Live_Date__c = System.today().addDays(-1);
            oProj.Invoice_Ready__c = false;
            projList.add(oProj);
            pse__proj__c oProj1 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj1.Name = NSP_ServiceConstants.PROJECT_CORE_TEMPLATE;
            oProj1.pse__Is_Template__c = True;
            oProj1.pse__Is_Active__c = True;
            oProj1.pse__Start_Date__c = System.today();
            projList.add(oProj1);
             //Creating Project Templates 
            pse__proj__c oProj2 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj2.Name = NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE;
            oProj2.pse__Is_Template__c = True;
            oProj2.pse__Is_Active__c = True;
            oProj2.pse__Start_Date__c = System.today();
            projList.add(oProj2);
            if(!projList.isEmpty()){
                Database.insert(projList);
            }
            oProj1.pse__Project_Status__c = 'Complete';
            oProj1.NSP_Rating__c = 'Unfavorable';
            oProj1.Go_Live_Date__c = System.today();
            update oProj1;
            oProj1.Invoice_Ready__c = true;
            update oProj1;
            //System.assert(oProj1.Invoice_Ready__c == true,true);
        }
        

    }

    @isTest
    public static void testProjectUpdate2() {
        
        u1 = [select id from user where name =: NSP_ServiceConstants.DEPLOYMENT_MANAGER  LIMIT 1];
        
        System.runas(u1)
        {
             Id assert_WORTId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
           
            //Creating Account
            List<Account> accList = new List<Account>();
            Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount.Name = accountName;
            accList.add(oAccount);
            //Creating Account
            Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount1.Name = 'Account Test2';
            accList.add(oAccount1);
            Account oAccount2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount2.Name = 'Account Test3';
            accList.add(oAccount2);
            if(!accList.isEmpty()){
                Database.insert(accList);
            }
    
            blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
            blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
            blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
            
    
            Product2 objproduct = NSP_TestHelper.createBillingProduct('Test Product',rRule,tRule,bRule,'Monthly');
           
            List<pse__proj__c> projectList = [SELECT Id FROM pse__proj__c WHERE Id!=null LIMIT 2];
    
            List<pse__proj__c> projList = new List<pse__proj__c>();
            pse__proj__c oProj = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj.Name = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
            oProj.pse__Is_Template__c = True;
            oProj.pse__Is_Active__c = True;
            oProj.pse__Start_Date__c = System.today();
            oProj.Go_Live_Date__c = System.today().addDays(-1);
            oProj.Invoice_Ready__c = false;
            projList.add(oProj);
            pse__proj__c oProj1 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj1.Name = NSP_ServiceConstants.PROJECT_CORE_TEMPLATE;
            oProj1.pse__Is_Template__c = True;
            oProj1.pse__Is_Active__c = True;
            oProj1.pse__Start_Date__c = System.today();
            oProj1.Go_Live_Date__c = System.today().addDays(-1);
            oProj1.Invoice_Ready__c = false;
            projList.add(oProj1);
             //Creating Project Templates 
            pse__proj__c oProj2 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj2.Name = NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE;
            oProj2.pse__Is_Template__c = True;
            oProj2.pse__Is_Active__c = True;
            oProj2.pse__Start_Date__c = System.today();
            projList.add(oProj2);
            if(!projList.isEmpty()){
                Database.insert(projList);
            }
            
            Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
            product1.ProductCode = 'PerformSmart Traditional';
            product1.NSP_Product_Type__c = 'iSolved Hardware';
            //product1.SBQQ__SubscriptionType__c = 'Evergreen';
            product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            update product1;
            Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(oAccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
            PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
            
            Id stdPriceBookId = Test.getStandardPricebookId();
            SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(oAccount.Id,objOpprtunity.Id,true);
            List<SBQQ__Quoteline__c> quoteLines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{product1},new List<PriceBookEntry> {objPbe}, true);
            // create order from quote
            objQuote.SBQQ__Primary__c = true;
            objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
            objQuote.SBQQ__Ordered__c = true;
            
            Test.startTest();
            update objQuote; 
            
            Order order = new Order();
            order.NSP_Project_Go_Live_Date__c = System.today().addDays(30);
            order.NSP_Project__c = oProj.Id;
            order.OpportunityId = objOpprtunity.Id;
            order.AccountId = oAccount.Id;
            order.Status = NSP_CPQConstants.ORDER_DRAFT;
            order.EffectiveDate = Date.Today();
            order.Pricebook2Id = stdPriceBookId;
            insert order;
            list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
            orderList[0].EffectiveDate = Date.Today();
            update orderList;
            list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:product1.Id]);
            orderItemList[0].NSP_Project__c= oProj.Id;
            update orderItemList; 
            
            orderItemList[0].NSP_Project__c= oProj1.Id;
            update orderItemList; 
            oProj1.pse__Project_Status__c = 'Complete';
            oProj1.NSP_Rating__c = 'Unfavorable';
            oProj1.Go_Live_Date__c = System.today();
            update oProj1;
            
            //System.assert(orderItemList.size()==1,true);            
        }
        

    }
    
    @isTest
    public static void testTriggerUpdate(){
        
        u1 = [select id from user where name =: NSP_ServiceConstants.DEPLOYMENT_MANAGER LIMIT 1];
        System.runas(u1)
        {
             Id assert_WORTId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
           
            //Creating Account
            List<Account> accList = new List<Account>();
            Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount.Name = accountName;
            accList.add(oAccount);
            //Creating Account
            Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount1.Name = 'Account Test2';
            accList.add(oAccount1);
            Account oAccount2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), accountDefaults, false);
            oAccount2.Name = 'Account Test3';
            accList.add(oAccount2);
            if(!accList.isEmpty()){
                Database.insert(accList);
            }
            
            List<NSP_Account_Team__c> accTeamList = new List<NSP_Account_Team__c>();
            //Creating Account Team for the account
            NSP_Account_Team__c oAccountTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
            oAccountTeam.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
            oAccountTeam.NSP_Account__c = oAccount.Id;
            accTeamList.add(oAccountTeam);
            //Creating Account Team for the account
            NSP_Account_Team__c oAccountTeam1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
            oAccountTeam1.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
            oAccountTeam1.NSP_Account__c = oAccount1.Id;
            accTeamList.add(oAccountTeam1);
            NSP_Account_Team__c oAccountTeam2 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
            oAccountTeam2.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
            oAccountTeam2.NSP_Account__c = oAccount2.Id;
            accTeamList.add(oAccountTeam2);
            if(!accTeamList.isEmpty()){
                Database.insert(accTeamList);
            }
    
            blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
            blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
            blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
            
            Product2 objproduct = NSP_TestHelper.createBillingProduct('Test Product',rRule,tRule,bRule,'Monthly');
            
            
            //Creating Project Templates 
            List<pse__proj__c> projList = new List<pse__proj__c>();
            pse__proj__c oProj = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj.Name = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
            oProj.pse__Is_Template__c = True;
            oProj.pse__Is_Active__c = True;
            oProj.pse__Start_Date__c = System.today();
            oProj.Go_Live_Date__c = System.today().addDays(-1);
            oProj.Invoice_Ready__c = false;
            projList.add(oProj);
            pse__proj__c oProj1 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj1.Name = NSP_ServiceConstants.PROJECT_CORE_TEMPLATE;
            oProj1.pse__Is_Template__c = True;
            oProj1.pse__Is_Active__c = True;
            oProj1.pse__Start_Date__c = System.today();
            projList.add(oProj1);
             //Creating Project Templates 
            pse__proj__c oProj2 = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), NSP_CPQConstants.PROJECTDEFAULTS, false);
            oProj2.Name = NSP_ServiceConstants.PROJECT_MM_FOUNDATIONAL_TEMPLATE;
            oProj2.pse__Is_Template__c = True;
            oProj2.pse__Is_Active__c = True;
            oProj2.pse__Start_Date__c = System.today();
            projList.add(oProj2);
            if(!projList.isEmpty()){
                Database.insert(projList);
            }
            Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
            product1.ProductCode = 'PerformSmart Traditional';
            product1.NSP_Product_Type__c = 'iSolved Hardware';
            //product1.SBQQ__SubscriptionType__c = 'Evergreen';
            product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
            update product1;
            Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(oAccount.Id,NSP_CPQConstants.OPPORTUNITY_TYPE_NEW_BUSINESS,true);
            PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
            
            Id stdPriceBookId = Test.getStandardPricebookId();
            SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(oAccount.Id,objOpprtunity.Id,true);
            List<SBQQ__Quoteline__c> quoteLines = NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{product1},new List<PriceBookEntry> {objPbe}, true);
            // create order from quote
            objQuote.SBQQ__Primary__c = true;
            objQuote.SBQQ__Type__c=NSP_CPQConstants.QUOTE_TYPE_NEW;
            objQuote.SBQQ__Ordered__c = true;
            
            Test.startTest();
            update objQuote;
            Order order = new Order();
            order.NSP_Project_Go_Live_Date__c = System.today().addDays(30);
            order.NSP_Project__c = oProj.Id;
            order.OpportunityId = objOpprtunity.Id;
            order.AccountId = oAccount.Id;
            order.Status = NSP_CPQConstants.ORDER_DRAFT;
            order.EffectiveDate = Date.Today();
            order.Pricebook2Id = stdPriceBookId;
            insert order;
            list<Order> orderList = new list<Order>([select Id,NSP_Project_Name__c,Type from Order WHERE SBQQ__Quote__c =:objQuote.Id]);
            orderList[0].EffectiveDate = Date.Today();
            update orderList;
            list<OrderItem> orderItemList = new list<OrderItem>([select Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type from OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:product1.Id]);
            orderItemList[0].NSP_Project__c= oProj.Id;
            update orderItemList;      
            oProj.Invoice_Ready__c = true;
            oProj.pse__Project_Status__c = 'Close/Lost';
            oProj.NSP_Rating__c = 'Unfavorable';
            update oProj;   
            test.stopTest();
            //System.assert(orderList.size()==1,true);           
        }
    }
        
    
}