//***Test Class for Quote Trigger***
/**
* @description  : Test Class for Quote Trigger
* @author Rakesh Das
* @date 11/05/2021
* Name : NSP_QuoteTriggerTest
*
*
*/
@IsTest
public class NSP_QuoteTriggerTest {
    public static final string NEW_PRODUCT = 'New Product';
    public static final string STAND_ALONE = 'Stand Alone';
    public static final string ORG_PLANNING = 'Organizational Planning';
    
    //***setupTestData Method***
    /**
* @description  : Test Data Test Class for Quote Trigger
* @author Rakesh Das
* @date 11/05/2021
* Name : setupTestData
*
*/
    @testSetup
    static void setupTestData(){
        // NSP_TestHelper th = new NSP_TestHelper();
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        NSP_TestHelper.createProduct('Test Product',true);
        
    }
    
    //***pricingModelTest Method***
    /**
* @description  : pricingModel method test positive
* @author Rakesh Das
* @date 11/05/2021
* Name : pricingModelTest
*
*/
    static testMethod void pricingModelTest(){
        
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE NAME != Null LIMIT 1];
        
        Test.startTest();
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = NSP_CPQConstants.CLIENT_WOWS;
        opp1.NSP_PrimaryProduct__c = 'Recruiting Services';
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('Recruiting Services Pricebook');
        insert recpb;
        NSP_TestHelper.createCustomPriceBookEntry(product1.Id,200.0,recpb.Id,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = 'Recruiting Services';
        quote1.NSP_Client_For_Life__c = NSP_CPQConstants.CLIENT_WOWS;
        insert quote1;
        // List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, true);
        
        Test.stopTest();
        
        SBQQ__Quote__c quote2 = [select Id, Name, NSP_Product_Type__c,NSP_Pricing_Model__c from SBQQ__Quote__c WHERE id=:quote1.id ];    
        System.assertEquals(quote2.NSP_Pricing_Model__c, 'WO');
        
    }
    
    //***altulaTest Method***
    /**
* @description  : altulaTest method test positive
* @author Rakesh Das
* @date 11/05/2021
* Name : altulaTest
*
*/
    static testMethod void altulaTest(){
        
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name != null LIMIT 1];
        Account acc2 = new Account(Name='Altula International');
        insert acc2;
        Test.startTest();
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
        opp1.NSP_PrimaryProduct__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        opp1.NSP_Partner__c = acc2.id;
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('Altula Pricebook');
        insert recpb;
        NSP_TestHelper.createCustomPriceBookEntry(product1.Id,200.0,recpb.Id,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        quote1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
        insert quote1;
        // List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, true);
        quote1.ApprovalStatus__c = 'Pending';
        quote1.SBQQ__Primary__c = false;
        update quote1;
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_APPROVED;
        quote1.SBQQ__Primary__c = true;
        quote1.NSP_Select_Payroll_Frequency__c = 'Weekly;Monthly';
        update quote1;
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_REJECTED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_REJECTED;
        update quote1;
        
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_RECALLED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_RECALLED;
        update quote1;
        Test.stopTest();
        
        SBQQ__Quote__c quote2 = [select Id, Name, NSP_Product_Type__c,NSP_Pricing_Model__c from SBQQ__Quote__c WHERE id=:quote1.id ];    
        System.assertEquals(quote2.NSP_Product_Type__c, NSP_QuoteTriggerTest.ORG_PLANNING);
        
    }
    
    //***renewalquotetest Method***
    /**
* @description  : renewalquotetest method test positive
* @author Rakesh Das
* @date 11/05/2021
* Name : renewalquotetest
*
*/
    static testMethod void renewalquotetest(){
        
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name != null LIMIT 1];
        
        
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
        opp1.NSP_PrimaryProduct__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        quote1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
        insert quote1;
        // List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, true);
        Contract ct = new Contract();
        ct.AccountId = acc1.Id;
        ct.SBQQ__Opportunity__c = opp1.Id;
        ct.SBQQ__Quote__c = quote1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        Date dt = Date.today();
        ct.StartDate = dt;
        ct.Status = 'Draft';
        
        insert ct;
        
        Test.startTest();
        Opportunity opp2 = NSP_TestHelper.createOpenOpportunity(acc1.Id,'Existing Product',false);
        opp2.SBQQ__RenewedContract__c = ct.Id;
        insert opp2;
        SBQQ__Quote__c quote2 = NSP_TestHelper.createCPQQuote(acc1.Id,opp2.Id,false);
        quote2.SBQQ__Type__c = 'Renewal';
        insert quote2;
        Test.stopTest();
        
        SBQQ__Quote__c quote3 = [select Id, Name, NSP_Product_Type__c,NSP_Pricing_Model__c from SBQQ__Quote__c WHERE id=:quote1.id ];    
        System.assertEquals(quote3.NSP_Pricing_Model__c, 'List Price');
        
    }
    
    //***terminatequotetest Method***
    /**
* @description  : terminatequotetest method test positive
* @author Rakesh Das
* @date 11/05/2021
* Name : terminatequotetest
*
*/
    static testMethod void terminatequotetest(){
        
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name != null LIMIT 1];
        
        
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
        opp1.NSP_PrimaryProduct__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        quote1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
        insert quote1;
        // List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, true);
        Contract ct = new Contract();
        ct.AccountId = acc1.Id;
        ct.SBQQ__Opportunity__c = opp1.Id;
        ct.SBQQ__Quote__c = quote1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = NSP_QuoteTriggerTest.ORG_PLANNING;
        Date dt = Date.today();
        ct.StartDate = dt;
        ct.Status = 'Draft';
        
        insert ct;
        
        Test.startTest();
        Opportunity opp2 = NSP_TestHelper.createOpenOpportunity(acc1.Id,'Existing Product',false);
        opp2.SBQQ__AmendedContract__c = ct.Id;
        opp2.NSP_TransactionType__c = 'Termination';
        insert opp2;
        SBQQ__Quote__c quote2 = NSP_TestHelper.createCPQQuote(acc1.Id,opp2.Id,false);
        
        insert quote2;
        Test.stopTest();
        
        SBQQ__Quote__c quote3 = [select Id, Name, NSP_Product_Type__c,NSP_Pricing_Model__c from SBQQ__Quote__c WHERE id=:quote1.id ];    
        System.assertEquals(quote3.NSP_Pricing_Model__c, 'List Price');
        
    }
    
    //***supplementAndShowDiscountCoverage Method***
    /**
* @description  : supplementAndShowDiscountCoverage method test positive
* @author Rakesh Das
* @date 11/05/2021
* Name : supplementAndShowDiscountCoverage
*/
    static testMethod void supplementAndShowDiscountCoverage(){
        
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name != null  LIMIT 1];
       // User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole role = [SELECT Id FROM UserRole WHERE Name='CEO'];
        User userobj = new User(alias = 'jsmith', email='jsmith@insperity.com', 
                          emailencodingkey='UTF-8', lastname='Smith', 
                          languagelocalekey='en_US', 
                          localesidkey='en_US', profileid = profileobj.Id, userroleid = role.Id,
                          timezonesidkey='America/Los_Angeles', 
                          username='insperitytestadminuser@insperity.com',
                          IsActive=true);
        insert userobj;
        Id gpid =  [Select Id from Group WHERE Group.DeveloperName =  'NSP_CSS' LIMIT 1].Id;
        GroupMember gm = new GroupMember (UserOrGroupId = userobj.Id, GroupId = gpid);
        insert gm;
        System.runAs (userobj) {
            Test.startTest();
            Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
            opp1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
            opp1.NSP_PrimaryProduct__c = NSP_QuoteTriggerTest.ORG_PLANNING;
            insert opp1;
            NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
            
            SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
            quote1.NSP_Opportunity_Primary_Product__c = NSP_QuoteTriggerTest.ORG_PLANNING;
            quote1.NSP_Client_For_Life__c = NSP_QuoteTriggerTest.STAND_ALONE;
            insert quote1;
            
            // List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, true);
            quote1.NSP_Show_Discounts__c = true;
            quote1.SBQQ__Type__c = 'Amendment';
            quote1.SBQQ__Primary__c = true;
            
            update quote1;
            
            quote1.SBQQ__Type__c = 'Supplemental';
            quote1.NSP_SupplementBPS__c = true;
            quote1.NSP_Supplement__c = true;
            update quote1;
            
            Test.stopTest();
            
            SBQQ__Quote__c quote2 = [select Id, Name, NSP_Product_Type__c,NSP_Pricing_Model__c from SBQQ__Quote__c WHERE id=:quote1.id ];    
            System.assertEquals(quote2.NSP_Product_Type__c, 'Organizational Planning');
        }
    }
    
    static testMethod void addressUpdateTest(){
        Account objAccount = [SELECT Id, Name FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1]; //Added WHERE Condition as part of code fix
        Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(objAccount.Id, NSP_QuoteTriggerTest.NEW_PRODUCT ,true);
        NSP_Address__c objBillingAddress = NSP_TestHelper.createCustomAddress();
        objBillingAddress.NSP_Related_Site__c = objAccount.id;
        objBillingAddress.NSP_Address_Type__c = 'Bill To';
        objBillingAddress.NSP_Source__c = 'AIMS';
        insert objBillingAddress;
        
        NSP_Address__c objshippingAddress = NSP_TestHelper.createCustomAddress();
        objshippingAddress.NSP_Address_Type__c = 'Ship To';
        objshippingAddress.NSP_Source__c = 'AIMS';
        objshippingAddress.NSP_Related_Site__c = objAccount.id;
        insert objshippingAddress;
        
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objAccount.Id,objOpportunity.Id,false);
        objQuote.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_NEW;
        insert objQuote;
        Test.startTest();
        objQuote.NSP_Billing_Address__c = objBillingAddress.Id;
        objQuote.NSP_Shipping_Address__c = objshippingAddress.Id;
        objQuote.NSP_Customer_Billing_Address__c = objBillingAddress.Id;
        objQuote.NSP_Customer_Shipping_Address__c = objshippingAddress.Id;
        objQuote.NSP_Product_Type__c = NSP_CPQConstants.QUOTE_PRODUCT_TYPE_WX;
        objQuote.NSP_Client_For_Life__c = 'WX';
        //objQuote.NSP_TransactionType__c = NSP_CPQConstants.SUPPLEMENTAL_ONLY_TRANSACTION_TYPE;
        objQuote.NSP_Opportunity_Primary_Product__c = 'WX';

        update objQuote;
        test.stopTest();
        System.assertEquals(objQuote.NSP_Client_For_Life__c, 'WX');
    }
    
    static testMethod void woToWXQuoteTest(){
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE NAME != Null LIMIT 1];
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = NSP_CPQConstants.CLIENT_WOWS;
        opp1.NSP_PrimaryProduct__c = 'WO';
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('WX Pricebook');
        insert recpb;
        
        Test.startTest();
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = 'WO';
        quote1.NSP_Client_For_Life__c = NSP_CPQConstants.CLIENT_WOWS;
        quote1.SBQQ__PriceBook__c = recpb.id;
        quote1.SBQQ__PricebookId__c = recpb.id;
        insert quote1;
        quote1.SBQQ__Primary__c = true;
        update quote1;
        Test.stopTest();
        System.assertEquals(quote1.NSP_Client_For_Life__c, NSP_CPQConstants.CLIENT_WOWS);
    }
    
    static testMethod void woToWAQuoteTest(){
        Account acc1 = [Select Id, Name from Account WHERE Name != null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE NAME != Null LIMIT 1];
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = NSP_CPQConstants.CLIENT_WOWS;
        opp1.NSP_PrimaryProduct__c = 'WO';
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('WA Pricebook');
        insert recpb;
        
        Test.startTest();
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = 'WO';
        quote1.NSP_Client_For_Life__c = NSP_CPQConstants.CLIENT_WOWS;
        quote1.SBQQ__PriceBook__c = recpb.id;
        quote1.SBQQ__PricebookId__c = recpb.id;
        insert quote1;
        quote1.SBQQ__Primary__c = true;
        update quote1;
        Test.stopTest();
        System.assertEquals(quote1.NSP_Client_For_Life__c, NSP_CPQConstants.CLIENT_WOWS);
        
    }
    static testMethod void enrollmentTest(){
        Account acc1 = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        Product2 product1 = [SELECT  Id, Name FROM Product2 WHERE NAME != Null LIMIT 1];
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = 'WX';
        opp1.NSP_PrimaryProduct__c = 'WX';
        //Inserting Opportunity
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('WX Pricebook');
        insert recpb;
        Test.startTest();
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = 'WX';
        quote1.NSP_Client_For_Life__c = 'WX';
        quote1.SBQQ__PriceBook__c = recpb.id;
        quote1.SBQQ__PricebookId__c = recpb.id;
        quote1.SBQQ__Primary__c = true;
        quote1.SBQQ__Type__c=NSP_QuoteTriggerTest.NEW_PRODUCT;
        //Inserting Quote
        insert quote1;
        //Updating Quote
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_APPROVED;
        update quote1;
        List<NSP_Enrollment_Fee_Payment__c> createdList= [Select Id,NSP_Opportunity__c FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c=:opp1.Id];
        system.Assert(createdList.size()==1);
        Test.stopTest();
    }
    @isTest
    private static void existingEnrollmentTest(){
         Account acc1 = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        Product2 product1 = [SELECT  Id, Name FROM Product2 WHERE NAME != Null LIMIT 1];
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,NSP_QuoteTriggerTest.NEW_PRODUCT,false);
        opp1.NSP_Client_For_Life__c = 'WX';
        opp1.NSP_PrimaryProduct__c = 'WX';
        //Inserting Opportunity
        insert opp1;
        NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        PriceBook2 recpb = NSP_TestHelper.createPriceBook2('WX Pricebook');
        insert recpb;
        NSP_Enrollment_Fee_Payment__c enrollmentFee= new NSP_Enrollment_Fee_Payment__c();
        enrollmentFee.NSP_Opportunity__c=opp1.Id;
        insert enrollmentFee;
        Test.startTest();
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = 'WX';
        quote1.NSP_Client_For_Life__c = 'WX';
        quote1.SBQQ__PriceBook__c = recpb.id;
        quote1.SBQQ__PricebookId__c = recpb.id;
        quote1.SBQQ__Primary__c = true;
        quote1.SBQQ__Type__c=NSP_QuoteTriggerTest.NEW_PRODUCT;
        //Inserting Quote
        insert quote1;
        //Updating Quote
        quote1.ApprovalStatus__c = NSP_CPQConstants.QUOTE_APPROVAL_STATUS_APPROVED;
        quote1.SBQQ__Status__c = NSP_CPQConstants.QUOTE_STATUS_APPROVED;
        quote1.NSP_WX_WA_Enrollment_Fee__c=0;
        update quote1;
        List<NSP_Enrollment_Fee_Payment__c> createdList= [Select Id,NSP_Opportunity__c FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c=:opp1.Id];
        system.Assert(createdList.size()==1);
        Test.stopTest();
    }
    
}