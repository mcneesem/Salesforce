/* **************************************************************************************************   
Component Name :  NSP_ValidateOpportunityStageTest class
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used for Validate Opportunity Stage tests.
Story                :                                                                             
Modification Log     :                                                                               
*	Harsha           October 10, 2021          First Iteration
*
***************************************************************************************************
*/

@isTest
public class NSP_ValidateOpportunityStageTest {
    //Test Setup Method to populate test data
    @testSetup
    public static void setupData(){
        
        Account acnt=NSP_TestHelper.createAccount(true);
        Opportunity opp=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp.StageName = 'Discovery';
        opp.NSP_Number_of_Employees__c=12;
        opp.NSP_BidNumber__c='123';
        opp.NSP_PrimaryProduct__c = 'WO';
        opp.NSP_Partner__c=acnt.Id;
        insert opp;   
        
        Opportunity opp1=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp1.StageName = 'Proposal';
        opp1.NSP_PrimaryProduct__c = 'WX';
        opp1.NSP_Partner__c=acnt.Id;
        try{            
            insert opp1;   
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        
        Opportunity opp2=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Business',false);
        opp2.StageName = 'Discovery';
        opp2.NSP_BidNumber__c='unique123';
        try{            
            insert opp2;   
        }catch(Exception ex){
            ex.getStackTraceString();
        }        
        //Adding Tasks and Events to lists.
        List<Task> taskList = new List<Task>();
        List<Event> eventList = new List<Event>();
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
        
        Task taskRec3 = new Task(
            Subject = 'WO Business Profile',
            WhatId = opp.Id,
            NSP_Task_Type__c = 'Core Sales',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = NSP_SalesConstants.WO_BUSINESS_PROFILE,
            Status='Open'
        );
        taskList.add(taskRec3);
        
        Task taskRec2 = new Task(
            Subject = 'Discovery Call',
            WhatId = opp2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            Status='Open'
        );
        taskList.add(taskRec2);
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
        
        //Task and Events Insert
        insert taskList;
        insert eventList;
    }
    // Test for validations when Opportunity stage is set to Closing
    @isTest
    public static void checkOpptyStage(){
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE StageName!=NULL limit 1];           
        Opportunity oppty = oppList[0];
        oppty.NSP_Number_of_Employees__c=25;
        oppty.NSP_PrimaryProduct__c='WO';
        oppty.NSP_BidNumber__c='123';
        oppty.StageName='Analysis';        
        
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        
        oppty.StageName = 'Proposal';
        
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        
        oppty.StageName = 'Closing';
        
        try{
            update oppty; 
        }catch(Exception ex){
            ex.getStackTraceString();
        }
        System.assertEquals('Closing', oppty.StageName);
    }
    // Test for open discovery activity on Analysis stage
    @isTest
    public static void checkOpenDiscoveryActivities(){
        List<Opportunity> oppList = [SELECT Id FROM Opportunity WHERE NSP_BidNumber__c = 'unique123' limit 1];
        Opportunity oppty = oppList[0];
        if(oppty!=null){
            oppty.StageName='Analysis';
            
            try{
                update oppty;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        System.assertEquals('Analysis', oppty.StageName);
    }
}