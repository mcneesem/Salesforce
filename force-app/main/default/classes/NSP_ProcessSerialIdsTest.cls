/**
* 
*
*
Apex Class Name      :  NSP_ProcessSerialIdsTest
Version              :  1.0                                                                          
Created Date         :                                                                       
Description    :        This is a test class for Process Serial Ids Class  
*
*

*--------------------------------------------------------------------------------------------------  
*  Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest
public class NSP_ProcessSerialIdsTest {
    public static final String OPP_TYPE_NEW_PRODUCT = 'New Product';
    //Set up method to create test data
    @testSetup
    static void setupTestData(){
        //Disabel unnessasry triggers
        NSP_AccountTriggerHandler.TriggerDisabled = true;
        NSP_OpportunityTriggerHandler.TriggerDisabled = true; 
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        NSP_AssetTriggerHandler.TriggerDisabled=true;
        //Creates Account
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        NSP_TestHelper.createProduct('Test Product',true);
        //create an asset
        Asset newAsset = new Asset();
        newAsset.AccountId = acc1.Id;
        newAsset.Name = 'Test Asset';
        newAsset.SerialNumber = '12345';
        newAsset.NSP_Early_Termination_Notice__c=true;
        insert newAsset;
        //create a subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = acc1.Id;
        subscription.SBQQ__Quantity__c = 1;
        insert subscription;
        //Create support entitelment
        NSP_Support_Entitlement__c entitelment = new NSP_Support_Entitlement__c();
        entitelment.NSP_Covered_Asset__c = newAsset.Id;
        entitelment.NSP_Supported_Subscription__c = subscription.Id;
        entitelment.NSP_Support_Product__c  = 'PerformSmart Traditional';
        insert entitelment;
        
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
        product1.ProductCode = 'PerformSmart Traditional';
        update product1;
        
        List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id!=null LIMIT 1];
        
        Opportunity opp1 = NSP_TestHelper.createOpenOpportunity(accounts[0].Id, OPP_TYPE_NEW_PRODUCT ,true);
        PriceBookEntry pe1 = NSP_TestHelper.createPriceBookEntry(product1.Id,200.0,true);
        Test.startTest();
        SBQQ__Quote__c quote1 = NSP_TestHelper.createCPQQuote(accounts[0].Id,opp1.Id,false);
        quote1.SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_RENEWAL;
        insert quote1;
        Test.stopTest();
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote1,new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        qlines[0].NSP_Lock_On_QLI__c = true;
        qlines[0].NSP_Previous_Quantity__c = 7;
        qlines[0].NSP_Quoted_Quantity__c = 5;
        insert qlines[0];
        
        
    }
    /**
* Method Name : testUpdateSerialIdsOnQuoteLines 
* Description : Test Method to process Serial Ids for New/Amend Quote Lines
* Author : CPQ Team       Date : 
* @return void  
*/ 
    @isTest
    public static void testUpdateSerialIdsOnQuoteLines() {
        List<SBQQ__Quote__c> quote = [SELECT Id FROM SBQQ__Quote__c WHERE Id!=null LIMIT 1];
        List<SBQQ__QuoteLine__c> qline=[SELECT Id,NSP_Serial_Ids__c FROM SBQQ__QuoteLine__c WHERE Id!=null LIMIT 1];
        
        Test.startTest();
        List<NSP_Support_Entitlement__c> entitlements = [SELECT Id, NSP_Support_Product__c, NSP_Serial_ID__c FROM NSP_Support_Entitlement__c WHERE Id!=null LIMIT 1];
        NSP_ProcessSerialIds.InputVariables testInputs = new NSP_ProcessSerialIds.InputVariables();
        testInputs.quoteId = quote[0].Id;
        testInputs.selectedEntitlements = entitlements;
        
        List<NSP_ProcessSerialIds.InputVariables> inputs = new List<NSP_ProcessSerialIds.InputVariables>();
        inputs.add(testInputs);
        //explicitly call the method as it gets called via flow usaully
        NSP_ProcessSerialIds.updateSerialIdsOnQuoteLines(inputs);
        PriceBookEntry pe1 = [SELECT Id FROM PriceBookEntry WHERE Id!=null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
        List<SBQQ__Quoteline__c> qlines2 = NSP_TestHelper.createCPQQuotelines(quote[0],new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        qlines2[0].NSP_Lock_On_QLI__c = true;
        qlines2[0].NSP_Previous_Quantity__c = 7;
        qlines2[0].NSP_Quoted_Quantity__c = 5;
        qlines2[0].SBQQ__Source__c = qline[0].Id;
        insert qlines2;
        quote[0].SBQQ__Type__c = NSP_CPQConstants.QUOTE_TYPE_AMENDMENT;
        update quote[0];
        NSP_ProcessSerialIds.updateSerialIdsOnQuoteLines(inputs);
        system.assertEquals(NSP_CPQConstants.QUOTE_TYPE_AMENDMENT, quote[0].SBQQ__Type__c);
        Test.stopTest();
    }
    /**
* Method Name : testQLines 
* Description : Test Method to process Serial Ids for Renewal Quote Lines
* Author : CPQ Team       Date : 
* @return void  
*/ 
    @isTest
    public static void testQLines(){
        List<SBQQ__Quote__c> quote = [SELECT Id FROM SBQQ__Quote__c WHERE Id!=null LIMIT 1];
        PriceBookEntry pe1 = [SELECT Id FROM PriceBookEntry WHERE Id!=null LIMIT 1];
        SBQQ__Subscription__c sub=[SELECT Id FROM SBQQ__Subscription__c WHERE Id!=null LIMIT 1];
        List<NSP_Support_Entitlement__c> entitlements = [SELECT Id, NSP_Support_Product__c, NSP_Serial_ID__c,NSP_Early_Termination_Notice__c FROM NSP_Support_Entitlement__c WHERE Id!=null LIMIT 1];
        Product2 product1 = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1]; //Added WHERE Condition as part of code fix
        List<SBQQ__Quoteline__c> qlines = NSP_TestHelper.createCPQQuotelines(quote[0],new List<Product2>{product1},new List<PriceBookEntry> {pe1}, false);
        qlines[0].NSP_Lock_On_QLI__c = true;
        qlines[0].NSP_Quoted_Quantity__c = 5;
        qlines[0].NSP_Action_Type__c='Renewal';
        qlines[0].SBQQ__RenewedSubscription__c=sub.Id;
        insert qlines;
        system.assertEquals(true, entitlements[0].NSP_Early_Termination_Notice__c);
    }
}