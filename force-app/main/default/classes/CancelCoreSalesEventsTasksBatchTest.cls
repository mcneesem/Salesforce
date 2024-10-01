@isTest(SeeAllData=false)

private class CancelCoreSalesEventsTasksBatchTest {
    private static Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
    private static Id evtRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();

    @testSetup
    private static void setupData() {

        List<Task> taskList = new List<Task>();
        List<Event> eventList = new List<Event>();

        Account acnt = NSP_TestHelper.createAccount(true);

        Task taskRec1 = new Task(
            RecordTypeId = taskRecTypeId,
            ActivityDate = system.today()-46,
            Status = 'Open'
        );
        taskList.add(taskRec1);

        Event evtRec1 = new Event(
            RecordTypeId = evtRecTypeId,
            FSL__Event_Type__c = null,
            IsAllDayEvent = true,
            ActivityDate = system.today()-32,
            EndDateTime = system.today()-31,
            NSP_Status__c = 'Open'
        );
        eventList.add(evtRec1);

        Task taskRec2 = new Task(
            RecordTypeId = taskRecTypeId,
            ActivityDate = system.today(),
            Status = 'Open',
            WhatId = acnt.Id
        );
        taskList.add(taskRec2);

        Event evtRec2 = new Event(
            RecordTypeId = evtRecTypeId,
            FSL__Event_Type__c = null,
            IsAllDayEvent = true,
            ActivityDate = system.today(),
            EndDateTime = system.today(),
            NSP_Status__c = 'Open',
            WhatId = acnt.Id
        );
        eventList.add(evtRec2);

        try{
            insert taskList;
            insert eventList;
        }catch(Exception ex) {
            ex.getStackTraceString();
        }
    }

    @isTest 
    private static void testCancelCoreSalesEventsTasks1() {
        Test.startTest();
        Database.executeBatch(new CancelCoreSalesEventsTasksBatch(null));
        Test.stopTest();
        List<Task> taskList = [SELECT Id, RecordTypeId, Status, ActivityDate, CreatedDate, NSP_Status__c
                        FROM Task WHERE RecordTypeId = :taskRecTypeId
                        AND (Status = null OR Status = 'Open') AND (ActivityDate < N_DAYS_AGO:45
                        OR (ActivityDate = null AND CreatedDate < N_DAYS_AGO:45))];
        List<Event> eventList = [SELECT Id, RecordTypeId, EndDateTime, CreatedDate, NSP_Status__c
                         FROM Event WHERE RecordTypeId = :evtRecTypeId
                         AND IsRecurrence2 = false AND FSL__Event_Type__c = null
                         AND (NSP_Status__c = null OR NSP_Status__c = 'Open') AND (EndDateTime < N_DAYS_AGO:30
                         OR (EndDateTime = null AND CreatedDate < N_DAYS_AGO:30))];
        System.assertEquals(0, taskList.size());
        System.assertEquals(0, eventList.size());
   }

    @isTest 
    private static void testCancelCoreSalesEventsTasks2() {
        Test.startTest();
        List<Id> parentIds = new List<Id>{[SELECT Id FROM Account WHERE Name = :NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1].Id};
        Database.executeBatch(new CancelCoreSalesEventsTasksBatch(parentIds));
        Test.stopTest();
        List<Task> taskList = [SELECT Id, RecordTypeId, Status, ActivityDate, CreatedDate, NSP_Status__c
                        FROM Task WHERE RecordTypeId = :taskRecTypeId
                        AND (Status = null OR Status = 'Open') AND WhatId = :parentIds[0]];
        List<Event> eventList = [SELECT Id, RecordTypeId, EndDateTime, CreatedDate, NSP_Status__c
                         FROM Event WHERE RecordTypeId = :evtRecTypeId
                         AND IsRecurrence2 = false AND FSL__Event_Type__c = null
                         AND (NSP_Status__c = null OR NSP_Status__c = 'Open') AND WhatId = :parentIds[0]];
        System.assertEquals(0, taskList.size());
        System.assertEquals(0, eventList.size());
   }
}