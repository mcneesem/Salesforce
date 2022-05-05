/* **************************************************************************************************   
Component Name :  NSP_DisplayQliController class
Version              :  1.0                                                                          
Created Date         :  05/07/2021                                                            
Function             :  This is the test class for DisplayQli visualforce component which is used to display quote line date
Story                :  STY-00450                                                                           
Modification Log     :                                                                               
*	Raksha           05/07/2021          First Iteration
*
***************************************************************************************************
*/
@isTest
public without sharing class NSP_DisplayQliControllerTest {
    
    @testSetup
    public static void setUpData(){
        Product2 product = NSP_TestHelper.createProduct('TESTPRODUCT123', false);
        product.IsActive = true;
        product.NSP_Include_In_PEPM__c = true;
        product.NSP_Show_On_Approval_Email__c = true;
        product.NSP_Show_On_Recruitment_Template__c = true;
        //Product creation
        insert product;
        //Pricebook entry creation
        PriceBookEntry pbEntry = NSP_TestHelper.createPriceBookEntry(product.Id, 299.29, false);
        insert pbEntry;
        //Account Creation
        Account acc = NSP_TestHelper.createAccount(false);
        acc.Name = 'TEST_DISPLAY_QLI_CONT';
        insert acc;
        //Opportunity Creation
        Opportunity oppty = NSP_TestHelper.createOpenOpportunity(acc.Id, 'New Product', false);
        oppty.NSP_Number_of_Employees__c = 120;
        oppty.NSP_PrimaryProduct__c = 'WX';
        
        insert oppty;
        
        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
        Event eventRec = new Event(
            Subject = 'Discovery Call',
            WhatId = oppty.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Completed'
        );
        
        insert eventRec;
        
        oppty.StageName = 'Analysis';
        update oppty;
        //Create Quote
        SBQQ__Quote__c quote = NSP_TestHelper.createCPQQuote(acc.Id, oppty.Id, false);
        quote.SBQQ__Primary__c = true;
        insert quote;
        //Create Product and Pricebook
        List<Product2> productList = new List<Product2>();        
        List<PricebookEntry> priceBook = new List<PricebookEntry>();
        
        productList.add(product);
        priceBook.add(pbEntry);
        //Create QuoteLine
        List<SBQQ__Quoteline__c> quoteLine = NSP_TestHelper.createCPQQuotelines(quote,productList,priceBook,false);
        for(Integer quoteItem=0; quoteItem<quoteLine.size(); quoteItem++){
            if(math.mod(quoteItem, 2) == 0){
                quoteLine[quoteItem].SBQQ__Discount__c = 12.5;
                quoteLine[quoteItem].NSP_Is_Bundle__c = true;
            }else{
                quoteLine[quoteItem].NSP_Max_Quantity__c = 12;
                quoteLine[quoteItem].NSP_Quoted_Quantity__c = 2;            
            }
        }
       insert quoteLine;
     }
    @isTest
    public static void getQliListTest(){
        List<NSP_DisplayQliController.QuotLinewrap> qliWrapperList = new List<NSP_DisplayQliController.QuotLinewrap>();
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Name!=NULL LIMIT 1];
        
        NSP_DisplayQliController displayQLIController = new NSP_DisplayQliController();
        displayQLIController.quoteIdstr = quote.Id;
        qliWrapperList = displayQLIController.getQliList();
        
        system.assertEquals(true, qliWrapperList.size()>0);
    } 
    
    @isTest
    public static void getQliPEPMListTest(){
        List<NSP_DisplayQliController.QuotLinewrap> qliWrapperList = new List<NSP_DisplayQliController.QuotLinewrap>();
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Name!=NULL LIMIT 1];
        NSP_DisplayQliController displayQLIController = new NSP_DisplayQliController();
        displayQLIController.quoteIdstr = quote.Id;
        qliWrapperList = displayQLIController.getQliPEPMList();
        system.assertEquals(true, qliWrapperList.size()>0);
    } 

    @isTest
    public static void getLastLine(){
        List<NSP_DisplayQliController.QuotLinewrap> qliWrapperList = new List<NSP_DisplayQliController.QuotLinewrap>();
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Name!=NULL LIMIT 1];
        NSP_DisplayQliController displayQLIController = new NSP_DisplayQliController();
        displayQLIController.quoteIdstr = quote.Id;
        qliWrapperList = displayQLIController.getLastLine();
        system.assertEquals(true, qliWrapperList.size()>0);
    }
    
    @isTest
    public static void getQliRecruitingListTest(){
        List<NSP_DisplayQliController.QuotLinewrap> qliWrapperList = new List<NSP_DisplayQliController.QuotLinewrap>();
        NSP_DisplayQliController displayQLIController = new NSP_DisplayQliController();
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Name!=NULL LIMIT 1];
        displayQLIController.quoteIdstr = quote.Id;
        qliWrapperList = displayQLIController.getQliRecruitingList();
        system.assertEquals(true, qliWrapperList.size()>0);
    } 
    
    @isTest
    public static void getApproversCommentTest(){
        List<NSP_DisplayQliController.QuotLinewrap> qliWrapperList = new List<NSP_DisplayQliController.QuotLinewrap>();
        NSP_DisplayQliController displayQLIController = new NSP_DisplayQliController();
        qliWrapperList = displayQLIController.getApproversComment();
        system.assertEquals(false, qliWrapperList.size()>0);
    } 
    
    @isTest
    public static void getProductBundleListTest(){
        List<NSP_DisplayQliController.QuotLinewrap> qliWrapperList = new List<NSP_DisplayQliController.QuotLinewrap>();
        NSP_DisplayQliController displayQLIController = new NSP_DisplayQliController();
        SBQQ__Quote__c quote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Name!=NULL LIMIT 1];
        displayQLIController.quoteIdstr = quote.Id;
        qliWrapperList = displayQLIController.getProductBundleList();
        system.assertEquals(true, qliWrapperList.size()>0);
    } 
}