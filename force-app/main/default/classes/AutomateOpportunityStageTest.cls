@isTest
public with sharing class AutomateOpportunityStageTest {

    @testSetup
    private static void setupData(){
        Account acnt=NSP_TestHelper.createAccount(true);
        Contact cntct=NSP_TestHelper.createContact(true);

        Opportunity opp1=NSP_TestHelper.createOpenOpportunity(acnt.Id,'Existing Product',false);
        opp1.StageName = 'Prospecting';
        opp1.NSP_Number_of_Employees__c=12;
        opp1.NSP_BidNumber__c='MM123';
        opp1.NSP_PrimaryProduct__c = 'WS';
        opp1.NSP_Partner__c=acnt.Id;
        insert opp1;

        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = opp1.Id,
            ContactId = cntct.Id
        );
        insert ocr;
    }

    @isTest
    private static void automateOpportunityStage(){
        test.startTest();
        OpportunityStageSettings__c setting = new OpportunityStageSettings__c();
        setting.Is_Enabled_WO_WS_Stage_Entry__c = true;
        insert setting;

        Id eventRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();
		List<SObject> sOList = new List<SObject>();
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c = 'MM123' limit 1];
        Opportunity oppty = oppList[0];        

        Event eventRec = new Event(
            Subject = 'Discovery Call',
            WhatId = oppty.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = eventRecTypeId,
            StartDateTime=system.now(),
            EndDateTime=system.now()+( 15/1440),
            NSP_Event_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            NSP_Status__c='Open'
        );
        sOList.add(eventRec);
        insert sOList;
        test.stopTest();
    }
}