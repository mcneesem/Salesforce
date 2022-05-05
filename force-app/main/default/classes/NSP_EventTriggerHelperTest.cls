@isTest
public without sharing class NSP_EventTriggerHelperTest {
    
    @testSetup
    public static void setupTestData(){
        Account acnt=NSP_TestHelper.createAccount(true);
        Opportunity opp=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp.StageName = 'Discovery';
        opp.NSP_Number_of_Employees__c=12;
        opp.NSP_BidNumber__c='123';
        opp.NSP_PrimaryProduct__c = 'WO';
        opp.NSP_Partner__c=acnt.Id;
        insert opp; 
        Lead leadObject = new Lead();
        leadObject.firstname='Test';
        leadObject.lastname='Lead';
        leadObject.Company = 'TestClass';
        leadObject.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        leadObject.NumberOfEmployees =150;
        leadObject.Email = 'testlead1@testlead1.com';
        leadObject.PostalCode = '10001';
        leadObject.NSP_Lead_Stage__c  =null; 
        leadObject.DNBoptimizer__DNB_D_U_N_S_Number__c = '123';
        insert leadObject;
 
    }
    
    @isTest
    public static void insertAndUpdateEvents(){
        
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE NSP_PrimaryProduct__c = 'WO' LIMIT 1];
        Lead getLead = [SELECT Id, Name FROM Lead WHERE firstname = 'Test' LIMIT 1];
        List<Event> eventList = new List<Event>();
        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
        Event eventRec = new Event(
            Subject = 'Discovery Call',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        eventList.add(eventRec);
        Event eventRec1 = new Event(
            Subject = 'Discovery Call',
            whoId = getLead.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        eventList.add(eventRec1);

        insert eventList;
        
        update eventList;
        System.assertEquals(eventList[0].NSP_Task_Type__c, 'BPS');
    }
}