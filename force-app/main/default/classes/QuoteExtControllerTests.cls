/**************************************************************************************************   
Apex Controller Name :  QuoteExtControllerTests
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used as controller  class for QuoteExtControllerTests.
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	Sumit                  October 10, 2021          First Iteration
***************************************************************************************************/
@isTest
private class QuoteExtControllerTests {
    
    /**********************************************************************************************
* Method Name:testSubmit
* Purpose: This method will get quote record
***********************************************************************************************/
    testMethod static void testSubmit() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        //Create Quote
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals(null, quote.ApprovalStatus__c);
    }
    
    /**********************************************************************************************
* Method Name:testRecall
* Purpose: This method will get recall record
***********************************************************************************************/
    testMethod static void testRecall() {
        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        System.assertEquals('Recalled', quote.ApprovalStatus__c);
    }
    
    /**********************************************************************************************
* Method Name:validateApprovalTest
* Purpose: This method will get validate approval record
***********************************************************************************************/
    static testMethod void validateApprovalTest(){
        Account objAccount = NSP_TestHelper.createAccount(true);
        Account woAccount = NSP_TestHelper.createAccount(false);
        woAccount.Name = 'WO Account';
        insert woAccount;
        Contact contactObj = NSP_TestHelper.createContact(objAccount.id, true);
        String productName = 'Test Product Name';
        String vehicleTracking = 'Vehicle Tracking Unit';
        String clientForLife = 'WO/WS';
          //Create Product
        Product2 testProduct = NSP_TestHelper.createProduct('Test Parent Product Name',false);
        testProduct.Name = productName;
        testProduct.Family = vehicleTracking;
        testProduct.ProductCode = NSP_CPQConstants.RECRUITING_BUNDLE;
        insert testProduct;
        //Create Child Product
        Product2 testChildProduct = NSP_TestHelper.createProduct('Test Child Product Name',false);
        testChildProduct.Name = productName;
        testChildProduct.Family = vehicleTracking;
        testChildProduct.ProductCode = 'IRSOSourcing';
        insert testChildProduct;
        //Create Product Option
        SBQQ__ProductOption__c productGroup = new SBQQ__ProductOption__c();
        productGroup.SBQQ__Number__c =10;
        //productGroup.SBQQ__Feature__c = featureUpshell.id;
        productGroup.SBQQ__ConfiguredSKU__c = testProduct.id;
        productGroup.SBQQ__OptionalSKU__c   = testChildProduct.id;    
        insert productGroup;
        test.startTest();
        NSP_TestHelper.createPriceBookEntry(testProduct.Id,1,true);
        //Create Opportunity
          Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(objAccount.Id,'New Business',false);
             objOpportunity.NSP_PrimaryProduct__c = 'Employment Screening';
             objOpportunity.NSP_Client_For_Life__c = clientForLife;
             objOpportunity.NSP_Number_of_Employees__c = 110;
             objOpportunity.NSP_TransactionType__c = NSP_CPQConstants.QUOTE_TYPE_TERMINATION;
             insert objOpportunity;
             //Create Quote
             SBQQ__Quote__c obj1quote = NSP_TestHelper.createCPQQuote(objAccount.id,objOpportunity.Id,false);
        	 obj1quote.NSP_Opportunity_Primary_Product__c = 'Time & Attendance';
        	 obj1quote.NSP_Client_For_Life__c = clientForLife;
             obj1quote.NSP_Requested_First_Check_Date__c = system.today() -1;
        	 obj1quote.SBQQ__ExpirationDate__c = system.today() -1;
             obj1quote.NSP_Has_WA_product__c = true;
             obj1quote.NSP_Billing_Account__c = woAccount.Id;
             obj1quote.NSP_OnDemand_Notes__c = 'test notes';
             obj1quote.NSP_Billing_Account__c = woAccount.Id;
             obj1quote.NSP_Customer_Stakeholder__c = contactObj.Id;
             obj1quote.NSP_Authorized_Purchaser_1__c = contactObj.Id;
             obj1quote.NSP_Customer_Role__c = contactObj.Id;
             obj1quote.SBQQ__PrimaryContact__c = contactObj.Id;
             insert obj1quote;
         //Create QuoteLine    
         SBQQ__QuoteLine__c parentqli =  new SBQQ__QuoteLine__c(SBQQ__Product__c = testProduct.id,SBQQ__Quote__c = obj1quote.id);
        insert parentqli;
        SBQQ__QuoteLine__c childqli = new SBQQ__QuoteLine__c(SBQQ__Product__c = testChildProduct.id,SBQQ__Quote__c = obj1quote.id,SBQQ__ProductOption__c = productGroup.Id,SBQQ__RequiredBy__c=parentqli.Id	);
        insert childqli;
        
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(obj1quote));
        con.onSubmit();
        test.stopTest();
        system.assert(parentqli != null);
    }
    
      /**********************************************************************************************
* Method Name:validateApprovalPassTest
* Purpose: This method will get validate approval pass record
***********************************************************************************************/
    static testMethod void validateApprovalPassTest(){
        //Create Account
          Account objAccount = NSP_TestHelper.createAccount(false);
          objAccount.ShippingStreet = 'test street';
          objAccount.ShippingCity = 'test City';
          objAccount.ShippingState = 'Alabama';
          objAccount.ShippingCountry = 'United States';
          objAccount.ShippingPostalCode = '12345';
          objAccount.BillingStreet = 'test street';
          objAccount.BillingCity = 'test City';
          objAccount.BillingState = 'Alabama';
          objAccount.BillingCountry = 'United States';
          objAccount.BillingPostalCode = '12345';
          insert objAccount;
          //Create Contact
         Contact con1 = NSP_TestHelper.createContact(objAccount.id, true);
         String clientForLife = 'WO/WS';
        //Create Opportunity
          Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(objAccount.Id,'New Business',false);
             objOpportunity.NSP_PrimaryProduct__c = 'Employment Screening';
             objOpportunity.NSP_Client_For_Life__c = clientForLife;
             objOpportunity.NSP_Number_of_Employees__c = 110;
             objOpportunity.NSP_TransactionType__c = NSP_CPQConstants.QUOTE_TYPE_TERMINATION;
             insert objOpportunity;
             //Create Quote
             SBQQ__Quote__c obj1quote = NSP_TestHelper.createCPQQuote(objAccount.id,objOpportunity.Id,false);
        	 obj1quote.NSP_Opportunity_Primary_Product__c = 'Time & Attendance';
        	 obj1quote.NSP_Client_For_Life__c = clientForLife;
             obj1quote.NSP_Requested_First_Check_Date__c = system.today() +1;
        	 obj1quote.SBQQ__ExpirationDate__c = system.today() +1;
             obj1quote.NSP_Has_WA_product__c = false;
             obj1quote.NSP_Invoice_To_Email__c = con1.Id;
             insert obj1quote;
       
        test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(obj1quote));
        con.onCancel();
        test.stopTest();
        system.assert(obj1quote!=null);
    }
    
    /**********************************************************************************************
* Method Name:validateApprovalNewQuoteTest
* Purpose: This method will get validate approval record for new Quote
***********************************************************************************************/
    static testMethod void validateApprovalNewQuoteTest(){
        //Create Account
        Account objAccount = NSP_TestHelper.createAccount(true);
        Account woAccount = NSP_TestHelper.createAccount(false);
        woAccount.Name = 'WO Account';
        insert woAccount;
        String productName = 'Test Product Name';
        String vehicleTracking = 'Vehicle Tracking Unit';
        String clientForLife = 'WO/WS';
          //Create Product
        Product2 testProduct = NSP_TestHelper.createProduct('Test Parent Product Name',false);
        testProduct.Name = productName;
        testProduct.Family = vehicleTracking;
        testProduct.ProductCode = NSP_CPQConstants.RECRUITING_BUNDLE;
        insert testProduct;
        //Create Child Product
        Product2 testChildProduct = NSP_TestHelper.createProduct('Test Child Product Name',false);
        testChildProduct.Name = productName;
        testChildProduct.Family = vehicleTracking;
        testChildProduct.ProductCode = 'IRSOSourcing';
        insert testChildProduct;
        //Create Product Option
        SBQQ__ProductOption__c productGroup = new SBQQ__ProductOption__c();
        productGroup.SBQQ__Number__c =10;
        //productGroup.SBQQ__Feature__c = featureUpshell.id;
        productGroup.SBQQ__ConfiguredSKU__c = testProduct.id;
        productGroup.SBQQ__OptionalSKU__c   = testChildProduct.id;    
        insert productGroup;
        test.startTest();
        //Create Pricebook Entry
        NSP_TestHelper.createPriceBookEntry(testProduct.Id,1,true);
        //Create Opportunity
          Opportunity objOpportunity = NSP_TestHelper.createOpenOpportunity(objAccount.Id,'New Business',false);
             objOpportunity.NSP_PrimaryProduct__c = 'Employment Screening';
             objOpportunity.NSP_Client_For_Life__c = clientForLife;
             objOpportunity.NSP_Number_of_Employees__c = 110;
             insert objOpportunity;
             //Create Quote
             SBQQ__Quote__c obj1quote = NSP_TestHelper.createCPQQuote(objAccount.id,objOpportunity.Id,false);
        	 obj1quote.NSP_Opportunity_Primary_Product__c = 'Time & Attendance';
        	 obj1quote.NSP_Client_For_Life__c = clientForLife;
             obj1quote.NSP_Requested_First_Check_Date__c = system.today() -1;
        	 obj1quote.SBQQ__ExpirationDate__c = system.today() -1;
             obj1quote.NSP_Has_WA_product__c = true;
             obj1quote.NSP_Billing_Account__c = woAccount.Id;
             obj1quote.NSP_OnDemand_Notes__c = 'test notes';
             obj1quote.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_NEW;
             obj1quote.NSP_Benchmark_Job_End_Date__c = system.today() -1;
        	 obj1quote.NSP_Benchmark_Job_Start_Date__c = system.today();
        	 obj1quote.NSP_Implementation_Start_Date__c = system.today() -1;
             obj1quote.NSP_Talent_Connect_Subscription_End_Date__c = system.today() -1;
        	 obj1quote.NSP_Talent_Connect_Subscription_Date__c = system.today() -1;
        	 obj1quote.NSP_RPO_Start_Date__c = system.today() -1;
             obj1quote.NSP_RPO_End_Date__c = system.today() -1;
        	 obj1quote.NSP_ProjRec_Start_Date__c = system.today() -1;
        	 obj1quote.NSP_ProjRec_End_Date__c = system.today() -1;
        	 obj1quote.NSP_Target_Date__c = system.today() -1;
             insert obj1quote;
            //Create Quote Line
             SBQQ__QuoteLine__c parentqli =  new SBQQ__QuoteLine__c(SBQQ__Product__c = testProduct.id,SBQQ__Quote__c = obj1quote.id);
             insert parentqli;
             SBQQ__QuoteLine__c childqli = new SBQQ__QuoteLine__c(SBQQ__Product__c = testChildProduct.id,SBQQ__Quote__c = obj1quote.id,SBQQ__ProductOption__c = productGroup.Id,SBQQ__RequiredBy__c=parentqli.Id	);
             insert childqli;
        	 
             
            
            QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(obj1quote));
            con.onSubmit();
            test.stopTest();
            system.assert(parentqli != null);
    }
    
    
    
}