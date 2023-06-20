//***Test Class for MultipleContractFutureClass***
/**
* @description  : Test Class for MultipleContractFutureClass
* @author Rakesh Das
* @date 11/05/2021
* Name : MultipleContractFutureClassTest
*
*/
@IsTest
public class NSP_MultipleContractFutureClassTest {
    
    public static final String ORGANIZATIONAL_PLANNING = 'Organizational Planning' ; // Added as part of code fix
    
    /**
* @description  : Test Class for MultipleContractFutureClass setupTestData
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
        Product2 product1 = NSP_TestHelper.createProduct('Test Product1',false);
        product1.NSP_Product_Category__c =  ORGANIZATIONAL_PLANNING;
        Product2 product2 = NSP_TestHelper.createProduct('Test Product2',false);
        product2.NSP_Product_Category__c = 'Performance Management';
        Product2 product3 = NSP_TestHelper.createProduct('Test Product3',false);
        product3.NSP_Product_Category__c = ORGANIZATIONAL_PLANNING;
        Product2 product4 = NSP_TestHelper.createProduct('Test Product4',false);
        product4.NSP_Product_Category__c = 'Performance Management';
        List<Product2> allproducts = new List<Product2>{product1,product2,product3,product4};

        List<Product2> allproducts = new List<Product2>{product1,product2,product3,product4};
        for ( Product2 prd : allproducts) {
                prd.SBQQ__ChargeType__c = 'Recurring';
                prd.SBQQ__BillingType__c = 'Arrears';
                prd.SBQQ__BillingFrequency__c = 'Monthly';
                prd.blng__BillingRule__c = brObj.Id;
                prd.blng__RevenueRecognitionRule__c = rrObj.Id;
                prd.blng__TaxRule__c = taxRuleObj.Id;
        }

        insert allproducts;
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(acc1.Id,'New Product',false);
        opp1.NSP_Client_For_Life__c = 'Stand Alone';
        opp1.NSP_PrimaryProduct__c = ORGANIZATIONAL_PLANNING;
        insert opp1;
        
        PriceBookEntry pe1std = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,false);
        PriceBookEntry pe2std = NSP_TestHelper.createPriceBookEntry(product2.Id,200.0,false);
        PriceBookEntry pe3std = NSP_TestHelper.createPriceBookEntry(product3.Id,200.0,false);
        PriceBookEntry pe4std = NSP_TestHelper.createPriceBookEntry(product4.Id,200.0,false);
        List<PriceBookEntry> allprices = new List<PriceBookEntry>{pe1std,pe2std,pe3std,pe4std};
            insert allprices;
        
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(acc1.Id,opp1.Id,false);
        quote1.NSP_Opportunity_Primary_Product__c = ORGANIZATIONAL_PLANNING;
        quote1.NSP_Client_For_Life__c = 'Stand Alone';
        insert quote1;
        
        Order ord1 = new Order (AccountId=acc1.Id,Status='Draft',EffectiveDate=Date.today(),Pricebook2Id=Test.getStandardPricebookId());
        Order ord2 = new Order (AccountId=acc1.Id,Status='Draft',EffectiveDate=Date.today(),Pricebook2Id=Test.getStandardPricebookId());
        List<Order> allorders = new List<Order>{ord1,ord2};
            insert allorders;
        
        OrderItem ordpr1 = new OrderItem (OrderId = ord1.Id, Product2Id=product1.Id, UnitPrice=10.0,Quantity=5,PricebookEntryId=pe1std.Id);
        OrderItem ordpr2 = new OrderItem (OrderId = ord1.Id, Product2Id=product2.Id, UnitPrice=20.0, Quantity=10,PricebookEntryId=pe2std.Id);
        OrderItem ordpr3 = new OrderItem (OrderId = ord2.Id, Product2Id=product3.Id, UnitPrice=30.0,Quantity=15,PricebookEntryId=pe3std.Id);
        OrderItem ordpr4 = new OrderItem (OrderId = ord2.Id, Product2Id=product4.Id, UnitPrice=40.0,Quantity=15,PricebookEntryId=pe4std.Id);
        
        
        List<OrderItem> allorderprods = new List<OrderItem>{ordpr1,ordpr2,ordpr3,ordpr4};
            insert allorderprods;
        
        Contract ct = new Contract();
        ct.AccountId = acc1.Id;
        ct.SBQQ__Opportunity__c = opp1.Id;
        ct.SBQQ__Quote__c = quote1.Id;
        ct.ContractTerm = 12;
        ct.NSP_Product_Type__c = 'Organizational Planning;Performance Management';
        Date dt = Date.today();
        ct.StartDate = dt;
        ct.Status = 'Draft';
        ct.SBQQ__Order__c = ord1.Id;
        
        insert ct;
        
        List<SBQQ__Subscription__c> allSubscription = new List<SBQQ__Subscription__c>();
        SBQQ__Subscription__c sub1 = new SBQQ__Subscription__c(SBQQ__Product__c=product1.Id,SBQQ__Contract__c=ct.Id,SBQQ__Quantity__c=5,SBQQ__OrderProduct__c=ordpr1.Id);
        SBQQ__Subscription__c sub2 = new SBQQ__Subscription__c(SBQQ__Product__c=product2.Id,SBQQ__Contract__c=ct.Id,SBQQ__Quantity__c=10,SBQQ__OrderProduct__c=ordpr2.Id);
        SBQQ__Subscription__c sub3 = new SBQQ__Subscription__c(SBQQ__Product__c=product3.Id,SBQQ__Contract__c=ct.Id,SBQQ__Quantity__c=15,SBQQ__OrderProduct__c=ordpr3.Id);
        SBQQ__Subscription__c sub4 = new SBQQ__Subscription__c(SBQQ__Product__c=product4.Id,SBQQ__Contract__c=ct.Id,SBQQ__Quantity__c=15,SBQQ__OrderProduct__c=ordpr4.Id);
        allSubscription.add(sub1);
        allSubscription.add(sub2);
        allSubscription.add(sub3);
        allSubscription.add(sub4);
        
        insert allSubscription;
        List<SBQQ__Subscription__c> allSubscriptionToUpdate = new List<SBQQ__Subscription__c>();
        sub3.SBQQ__RequiredById__c = (String)sub1.Id;
        sub4.SBQQ__RequiredById__c = (String)sub2.Id;
        allSubscriptionToUpdate.add(sub3);
        allSubscriptionToUpdate.add(sub4);
        update allSubscriptionToUpdate;
    }
    
    /**
* @description  : Test Class for MultipleContractFutureClass multipleContractTest
* @author Rakesh Das
* @date 11/05/2021
*
* Name : multipleContractTest
*/
    static testMethod void multipleContractTest(){
        
        Contract con = [SELECT Id, Name FROM Contract WHERE ContractNumber !=null LIMIT 1];
        Test.startTest();
        NSP_MultipleContractFutureClass.createContractAndReparentSubscriptions(new List<String>{con.Id});
        Test.stopTest();
        
        List<Contract> allCons = [Select Id, Name from Contract WHERE ContractNumber !=null LIMIT 10];
        System.assertEquals(allCons.size(), 2);
    }
    /**
* @description  : Test Class for MultipleContractFutureClass contractControllerTest
* @author Rakesh Das
* @date 11/05/2021
* Name : contractControllerTest
*/
    static testMethod void contractControllerTest(){
        
        Contract con = [Select Id, Name from Contract WHERE ContractNumber !=null LIMIT 1];
        Test.startTest();
        NSP_ContractController.checkValidContractForReProcess(con.Id);
        NSP_ContractController.callReProcessContract(con.Id);
        Test.stopTest();
        
        List<Contract> allCons = [Select Id, Name from Contract WHERE ContractNumber != null LIMIT 10];
        System.assertEquals(allCons.size(), 2);
    }
    
    
}