/*
*Test class for NSP_CreateQuote
*This test class for NSP_CreateQuote controller
*@Utpal Utkalit
*Since Oct 2021
*/
@isTest(SeeAllData=false)
public class NSP_CreateQuoteTest {
    
    public static final String OPP_TYPE_NEW_PRODUCT = 'New Product';
    public static final String OPP_STAGE_NAME_DISCOVERY = 'Discovery';
    public static final String OPP_STAGE_NAME_ANALYSIS = 'Analysis';
    @testSetup
    public static void setupData(){
         Account acnt=NSP_TestHelper.createAccount(true);
         Opportunity opp=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',false);
         opp.StageName = 'Discovery';
         opp.NSP_Client_For_Life__c = 'WA';
         opp.NSP_PrimaryProduct__c = 'WA';
         opp.NSP_Partner__c=acnt.Id;
        insert opp;
        
        List<Task> taskList = new List<Task>();
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Task taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            Status='Completed'
        );
        taskList.add(taskRec);
        insert taskList;
        
        opp.StageName='Analysis';
        update opp;
        

    }
    
    /*
    *Test method for checkQuoteCreationfromOppTest
    *This test method to  NSP_CreateQuote controller
    *@Utpal Utkalit
    */    
    static testmethod void checkQuoteCreationfromOppTest() {
        test.startTest();
        List<Opportunity> oppList = [SELECT Id,Type FROM Opportunity WHERE Type =: OPP_TYPE_NEW_PRODUCT LIMIT 1]; //Added Where Condition as part of Code fix
        NSP_CreateQuote.ResponseWrapper rw=new NSP_CreateQuote.ResponseWrapper(); 
        rw= NSP_CreateQuote.validateQuoteCreationfromOpp(oppList[0].Id);
        System.assert(rw.isSuccess);
        test.stopTest();
    }
    
    /*
    *Test method for checkQuoteCreationinDiscoveryTest
    *This test method to  NSP_CreateQuote controller
    *@Utpal Utkalit
    */
     static testmethod void checkQuoteCreationinDiscoveryTest() {
        test.startTest();
        List<Opportunity> oppList = [SELECT Id,StageName FROM Opportunity WHERE StageName !=: OPP_TYPE_NEW_PRODUCT LIMIT 1]; //Added Where Condition as part of Code fix
        NSP_CreateQuote.ResponseWrapper rw=new NSP_CreateQuote.ResponseWrapper();
         User newUser = new User(Id= UserInfo.getUserId());
         system.runAs(newUser){
             if(oppList.size() > 0){
            Opportunity opp=oppList[0];
            opp.StageName='Discovery';
            update opp;
            rw= NSP_CreateQuote.validateQuoteCreationfromOpp(opp.Id);
            }
            System.assert(! rw.isSuccess);
            test.stopTest();
         }
        
    }
     
    /*
    *Test method for checkQuoteCreationinClientForLifeTest
    *This test method for  NSP_CreateQuote controller
    *@Utpal Utkalit
    */
     static testmethod void checkQuoteCreationinClientForLifeTest() {
        test.startTest();
        List<Opportunity> oppList = [SELECT Id,StageName FROM Opportunity WHERE StageName =: OPP_STAGE_NAME_ANALYSIS LIMIT 1]; //Added Where Condition as part of Code fix 
        NSP_CreateQuote.ResponseWrapper rw=new NSP_CreateQuote.ResponseWrapper();
        if(oppList.size() > 0){
            Opportunity opp=oppList[0];
            opp.NSP_Client_For_Life__c= null;
            update opp;
            rw= NSP_CreateQuote.validateQuoteCreationfromOpp(opp.Id);
        }
        System.assert( rw.isSuccess);
        test.stopTest();
    }
    
    /*
    *Test method for checkQuoteCreationinClientForLifeTest
    *This test method for  NSP_CreateQuote controller
    *@Utpal Utkalit
    */
     static testmethod void checkQuoteCreationinPrimaryProductTest() {
        test.startTest();
        List<Opportunity> oppList = [SELECT Id,StageName FROM Opportunity WHERE StageName =: OPP_STAGE_NAME_ANALYSIS LIMIT 1]; //Added Where Condition as part of Code fix 
        NSP_CreateQuote.ResponseWrapper rw=new NSP_CreateQuote.ResponseWrapper();
        if(oppList.size() > 0){
            Opportunity opp=oppList[0];
            opp.NSP_PrimaryProduct__c = null;
            update opp;
            rw= NSP_CreateQuote.validateQuoteCreationfromOpp(opp.Id);
        }
        System.assert( !rw.isSuccess);
        test.stopTest();
    }
}