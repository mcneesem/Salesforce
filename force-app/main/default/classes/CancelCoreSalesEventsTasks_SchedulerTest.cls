@isTest(SeeAllData=false)

private class CancelCoreSalesEventsTasks_SchedulerTest {
    private static final String sch = '0 0 3 * * ? *';
    private static Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
    private static Id evtRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();

    @testSetup
    public static void setupData() {

        Task taskRec = new Task(
            RecordTypeId = taskRecTypeId,
            ActivityDate = system.today()-46,
            Status = 'Open'
        );
        try{
            insert taskRec;
        }catch(Exception ex) {
            ex.getStackTraceString();
        }

        Event evtRec = new Event(
            RecordTypeId = evtRecTypeId,
            FSL__Event_Type__c = null,
            IsAllDayEvent = true,
            ActivityDate = system.today()-32,
            EndDateTime = system.today()-31,
            NSP_Status__c = 'Open'
        );
        try{
            insert evtRec;
        }catch(Exception ex) {
            ex.getStackTraceString();
        }
    }

    @isTest 
    private static void testCancelCoreSalesEventsTasks() {
        Test.startTest();
        CancelCoreSalesEventsTasks_Scheduler.CancelCoreSalesEventsTasks();
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
        Test.stopTest();
   }

    //Static Test Method to Call the Scheduler Class
    @isTest 
    private static void testCancelCoreSalesEventsTasks_schedule() {
        Test.startTest();
        String jobId = CancelCoreSalesEventsTasks_Scheduler.schedule();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
   }
}