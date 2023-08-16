/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  7/2/2023                                                             
Function             :   Test class for NSP_SubscriptionTriggerHelper
Test class           :  NSP_SubscriptionTriggerHelperTest
Story                :                                                                             
Modification Log     :  
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	CPQ           7/2/2023           First Iteration
*
***************************************************************************************************/
@isTest
public class NSP_SubscriptionTriggerHelperTest {
    
    public static final String OPP_TYPE_NEW_PRODUCT = 'New Product';
    public static final String TEST_PRODUCT = 'Test Product';
    public static final String goLiveDate = 'Project go-live date';
    public static final String serialIds = '1234';
    public static final String testAssetName = 'Test Asset';
    Static final Id assetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','Hardware_Asset');
    //Defautl Constructor
    public NSP_SubscriptionTriggerHelperTest() {
        
    }
    /**
* Method Name : setupTestData 
* Description : Method to create test data
* Author : CPQ      
* @return void  
*/
    @testSetup
    static void setupTestData(){
        // NSP_TestHelpser th = new NSP_TestHelper();
        Account objaccount = NSP_TestHelper.createAccount(true);
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        
        Product2 objproduct = NSP_TestHelper.createBillingProduct(TEST_PRODUCT,rRule,tRule,bRule,'Monthly');
        
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, OPP_TYPE_NEW_PRODUCT, true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c= OPP_TYPE_NEW_PRODUCT;
        objQuote.SBQQ__Ordered__c = true;
        
        Test.startTest();
        update objQuote; 
        //create an asset
        Asset newAsset = new Asset();
        newAsset.AccountId = objaccount.Id;
        newAsset.Name = testAssetName;
        newAsset.SerialNumber = '12345';
        insert newAsset;
        
        Product2 product1 = [Select Id, Name FROM Product2 WHERE Name = :TEST_PRODUCT LIMIT 1]; //Added WHERE Condition as part of code fix
        product1.ProductCode = 'PerformSmart Traditional';
        product1.NSP_Product_Type__c = 'Time & Attendance Hardware';
        //product1.SBQQ__SubscriptionType__c = 'Evergreen';
        product1.SBQQ__SubscriptionPricing__c = 'Fixed Price';
        update product1;
        
        Id stdPriceBookId = Test.getStandardPricebookId();
        //create an order
        Order order = new Order();
        order.NSP_Project_Go_Live_Date__c = System.today().addDays(30);
        order.OpportunityId = objOpprtunity.Id;
        order.AccountId = objaccount.Id;
        order.Status = 'Draft';
        order.EffectiveDate = Date.Today();
        order.Pricebook2Id = stdPriceBookId;
        insert order;
        
        list<Order> orderList = new list<Order>([SELECT Id,NSP_Project_Name__c,Type FROM Order WHERE SBQQ__Quote__c =:objQuote.Id]);
        orderList[0].EffectiveDate = Date.Today();
        orderList[0].NSP_Project_Go_Live_Date__c = Date.Today();
        update orderList;
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type FROM OrderItem WHERE Order.SBQQ__Quote__c =:objQuote.Id AND Product2Id=:objproduct.Id]);
        orderItemList[0].SBQQ__BillingFrequency__c='Annual';
        update orderItemList; 
        List<SBQQ__Quoteline__c> quoteLine1 = [SELECT Id, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__c FROM SBQQ__Quoteline__c WHERE Id != null LIMIT 1];
        //Create Contract
        Contract ct = new Contract();
        ct.AccountId = objaccount.Id;
        ct.SBQQ__Opportunity__c = objOpprtunity.Id;
        ct.SBQQ__Quote__c = objQuote.Id;
        ct.ContractTerm = 12;
        Date dt = Date.today();
        ct.StartDate = dt;
        ct.Status = 'Draft';
        ct.SBQQ__Order__c = orderList[0].Id;
        insert ct;
        //Creates subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = objaccount.Id;
        subscription.SBQQ__Quantity__c = 1;
        subscription.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription.SBQQ__Product__c = product1.Id;
        subscription.NSP_Create_Entitlement__c = true;
        subscription.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subscription.SBQQ__Contract__c=ct.Id;
        insert subscription;
        
        update subscription;
        Test.stopTest();       
    }
    /**
* Method Name : testSubscription 
* Description :
* Author : CPQ      
* @return void  
*/
    @isTest
    static void testSubscription(){
        
        //List<SBQQ__Subscription__c> subscription = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = :TEST_PRODUCT LIMIT 1]; //Added WHERE Condition as part of code fix
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        
        List<SBQQ__Quote__c> quote = [SELECT Id FROM SBQQ__Quote__c WHERE Id != null LIMIT 1]; 
        quote[0].SBQQ__Type__c= NSP_CPQConstants.QUOTE_TYPE_RENEWAL;
        test.startTest();
        update quote;
        List<SBQQ__Quoteline__c> quoteLine1 = [SELECT Id, SBQQ__Quote__r.SBQQ__Type__c, SBQQ__Quote__c FROM SBQQ__Quoteline__c WHERE Id != null  LIMIT 1];
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type FROM OrderItem WHERE Order.SBQQ__Quote__c =:quote[0].Id AND Product2Id=:product1.Id]);
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        //creates subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = accounts[0].Id;
        subscription.SBQQ__Quantity__c = 1;
        subscription.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription.SBQQ__Product__c = product1.Id;
        subscription.NSP_Create_Entitlement__c = true;
        subscription.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subList.add(subscription);
        //creates subscription
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c();
        subscription1.SBQQ__Account__c = accounts[0].Id;
        subscription1.SBQQ__Quantity__c = 1;
        subscription1.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription1.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription1.SBQQ__Product__c = product1.Id;
        subscription1.NSP_Create_Entitlement__c = true;
        subscription1.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subscription1.NSP_Serial_Ids__c = serialIds;
        subList.add(subscription1);
        
        insert subList;
        
        quote[0].SBQQ__Type__c= NSP_CPQConstants.ACTION_DOWNGRADE;
        update quote[0];
        //creates subscription
        SBQQ__Subscription__c subscription2 = new SBQQ__Subscription__c();
        subscription2.SBQQ__Account__c = accounts[0].Id;
        subscription2.SBQQ__Quantity__c = 1;
        subscription2.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription2.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription2.SBQQ__Product__c = product1.Id;
        subscription2.NSP_Create_Entitlement__c = true;
        subscription2.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subList.add(subscription2);
        //creates subscription
        SBQQ__Subscription__c subscription3 = new SBQQ__Subscription__c();
        subscription3.SBQQ__Account__c = accounts[0].Id;
        subscription3.SBQQ__Quantity__c = 1;
        subscription3.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription3.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription3.SBQQ__Product__c = product1.Id;
        subscription3.NSP_Create_Entitlement__c = true;
        subscription3.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subscription3.NSP_Serial_Ids__c = serialIds;
        subList.add(subscription3);
        
        upsert subList;
        test.stopTest();
        List<NSP_Support_Entitlement__c> entitlementsCreated = [SELECT Id FROM NSP_Support_Entitlement__c WHERE NSP_Account_Id__c != null LIMIT 1];
        System.assertNotEquals(Null, entitlementsCreated.size());
    }
    /**
* Method Name : testSubscriptionInsert 
* Description :
* Author : CPQ      
* @return void  
*/
    @isTest
    static void testSubscriptionInsert(){
        
        //List<SBQQ__Subscription__c> subscription = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        Product2 product1 = [SELECT Id, Name FROM Product2 WHERE Name = :TEST_PRODUCT LIMIT 1]; //Added WHERE Condition as part of code fix
        List<Account> accounts = [SELECT Id, Name FROM Account  WHERE Name != null LIMIT 1];
        
        List<SBQQ__Quote__c> quote = [SELECT Id FROM SBQQ__Quote__c WHERE Id != null  LIMIT 1]; 
        quote[0].SBQQ__Type__c= NSP_CPQConstants.ACTION_DOWNGRADE;
        test.startTest();
        update quote;
        //creates an asset
        Asset newAsset = new Asset();
        newAsset.AccountId = accounts[0].Id;
        newAsset.Name = testAssetName;
        newAsset.SerialNumber = serialIds;
        newAsset.Status = NSP_CPQConstants.TERMINATED;
        newAsset.RecordTypeId = assetRecordTypeId;
        insert newAsset;
        
        PriceBookEntry pe1 = [SELECT Id FROM PriceBookEntry WHERE Id != null  LIMIT 1];
        //create Quote Lines
        List<SBQQ__Quoteline__c> quoteLine2 = NSP_TestHelper.createCPQQuotelines(quote[0],new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        quoteLine2[0].NSP_Lock_On_QLI__c = true;
        quoteLine2[0].NSP_Previous_Quantity__c = 5;
        quoteLine2[0].NSP_Quoted_Quantity__c = 7;
        insert quoteLine2[0];
        //create Quote Lines
        List<SBQQ__Quoteline__c> quoteLine1 = NSP_TestHelper.createCPQQuotelines(quote[0],new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        quoteLine1[0].NSP_Lock_On_QLI__c = true;
        quoteLine1[0].NSP_Previous_Quantity__c = 5;
        quoteLine1[0].NSP_Quoted_Quantity__c = 7;
        quoteLine1[0].SBQQ__Source__c = quoteLine2[0].Id;
        insert quoteLine1[0];
        
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type FROM OrderItem WHERE Order.SBQQ__Quote__c =:quote[0].Id AND Product2Id=:product1.Id]);
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        //creates subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = accounts[0].Id;
        subscription.SBQQ__Quantity__c = 1;
        subscription.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription.SBQQ__Product__c = product1.Id;
        subscription.NSP_Create_Entitlement__c = true;
        subscription.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subList.add(subscription);
        //creates subscription
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c();
        subscription1.SBQQ__Account__c = accounts[0].Id;
        subscription1.SBQQ__Quantity__c = 1;
        subscription1.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription1.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription1.SBQQ__Product__c = product1.Id;
        subscription1.NSP_Create_Entitlement__c = true;
        subscription1.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subscription1.NSP_Serial_Ids__c = serialIds;
        subList.add(subscription1);
        
        insert subList;
        test.stopTest(); 
        List<Asset> assets = [SELECT Id, Status FROM Asset WHERE Status = :NSP_CPQConstants.ACTIVE];
        System.assertNotEquals(Null, assets.size());
    }
    /**
* Method Name : testSubscriptionInsert2 
* Description :
* Author : CPQ      
* @return void  
*/
    @isTest
    static void testSubscriptionInsert2(){
        
        //List<SBQQ__Subscription__c> subscription = [SELECT Id FROM SBQQ__Subscription__c LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = :TEST_PRODUCT LIMIT 1]; //Added WHERE Condition as part of code fix
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        
        List<SBQQ__Quote__c> quote = [SELECT Id FROM SBQQ__Quote__c WHERE Id != null LIMIT 1]; 
        quote[0].SBQQ__Type__c= NSP_CPQConstants.ACTION_DOWNGRADE;
        test.startTest();
        update quote;
        PriceBookEntry pe1 = [SELECT Id FROM PriceBookEntry WHERE Id != null LIMIT 1];
        //create Quote Lines
        List<SBQQ__Quoteline__c> quoteLine2 = NSP_TestHelper.createCPQQuotelines(quote[0],new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        quoteLine2[0].NSP_Lock_On_QLI__c = true;
        quoteLine2[0].NSP_Previous_Quantity__c = 7;
        quoteLine2[0].NSP_Quoted_Quantity__c = 5;
        insert quoteLine2[0];
        //create Quote Lines
        List<SBQQ__Quoteline__c> quoteLine1 = NSP_TestHelper.createCPQQuotelines(quote[0],new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        quoteLine1[0].NSP_Lock_On_QLI__c = true;
        quoteLine1[0].NSP_Previous_Quantity__c = 7;
        quoteLine1[0].NSP_Quoted_Quantity__c = 5;
        quoteLine1[0].SBQQ__Source__c = quoteLine2[0].Id;
        
        insert quoteLine1[0];
        //creates an asset
        Asset newAsset = new Asset();
        newAsset.AccountId = accounts[0].Id;
        newAsset.Name = testAssetName;
        newAsset.SerialNumber = serialIds;
        newAsset.Status = NSP_CPQConstants.ACTIVE;
        newAsset.NSP_Early_Termination_Notice__c=true;
        newAsset.RecordTypeId = assetRecordTypeId;
        insert newAsset;
        
        list<OrderItem> orderItemList = new list<OrderItem>([SELECT Id,SBQQ__BillingFrequency__c,blng__RevenueRecognitionRule__r.NSP_Rev_Rec_Model__c,Order.Type FROM OrderItem WHERE Order.SBQQ__Quote__c =:quote[0].Id AND Product2Id=:product1.Id]);
        List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        //creates subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = accounts[0].Id;
        subscription.SBQQ__Quantity__c = 1;
        subscription.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription.SBQQ__Product__c = product1.Id;
        subscription.NSP_Create_Entitlement__c = true;
        subscription.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subList.add(subscription);
        //creates subscription
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c();
        subscription1.SBQQ__Account__c = accounts[0].Id;
        subscription1.SBQQ__Quantity__c = 1;
        subscription1.NSP_SubscriptionStartDate__c = goLiveDate;
        subscription1.SBQQ__OrderProduct__c = orderItemList[0].Id;
        subscription1.SBQQ__Product__c = product1.Id;
        subscription1.NSP_Create_Entitlement__c = true;
        subscription1.SBQQ__QuoteLine__c = quoteLine1[0].Id;
        subscription1.NSP_Serial_Ids__c = serialIds;
        subscription1.SBQQ__SubscriptionStartDate__c=system.today();
        subList.add(subscription1);
        
        insert subList;
        test.stopTest(); 
        List<Asset> assets = [SELECT Id, Status FROM Asset WHERE Status = :NSP_CPQConstants.TERMINATED];
        System.assertNotEquals(Null, assets.size());
    }
}