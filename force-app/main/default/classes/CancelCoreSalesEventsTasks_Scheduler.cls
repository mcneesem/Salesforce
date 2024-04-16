public without sharing class CancelCoreSalesEventsTasks_Scheduler implements Schedulable {
    // test w/ CancelCoreSalesEventsTasks_SchedulerTest (87%)

    public void execute( SchedulableContext context ) {
        CancelCoreSalesEventsTasks();
    }

    public static void CancelCoreSalesEventsTasks() {
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Id evtRecTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('Core_Sales_Event_RT').getRecordTypeId();

        List<sObject> cancelList = new List<sObject>();
        for(Task tsk : [
                    SELECT Id, RecordTypeId, Status, ActivityDate, CreatedDate, NSP_Status__c
                    FROM Task
                    WHERE (
                        RecordTypeId = :taskRecTypeId
                        AND (
                            Status = null
                            OR Status = 'Open'
                        )
                        AND (
                            ActivityDate < N_DAYS_AGO:45
                            OR (
                                ActivityDate = null
                                AND CreatedDate < N_DAYS_AGO:45
                            )
                        )
                    )
                ]
            )
        {
            tsk.Status = 'Cancelled';
            tsk.NSP_Status__c = 'Cancelled';
            cancelList.add(tsk);
        }
        for(Event evt : [
                    SELECT Id, RecordTypeId, EndDateTime, CreatedDate, NSP_Status__c
                    FROM Event
                    WHERE (
                        RecordTypeId = :evtRecTypeId
                        AND IsRecurrence2 = false
                        AND FSL__Event_Type__c = null
                        AND (
                            NSP_Status__c = null
                            OR NSP_Status__c = 'Open'
                        )
                        AND (
                            EndDateTime < N_DAYS_AGO:30
                            OR (
                                EndDateTime = null
                                AND CreatedDate < N_DAYS_AGO:30
                            )
                        )
                    )
                ]
            )
        {
            evt.NSP_Status__c = 'Cancelled';
            cancelList.add(evt);
        }
        try {
            if (!cancelList.isEmpty()) {
                database.update(cancelList);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logSaveException(
                'CancelCoreSalesEventsTasks_Scheduler', 'execute',
                e.getMessage() + ' ~ ' + e.getStackTraceString()
            );
        }
    }

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'CancelCoreSalesEventsTasks_Scheduler ~ everyday at 3 AM' + suffix ,
            '0 0 3 * * ? *' ,
            new CancelCoreSalesEventsTasks_Scheduler()
        );
    }

}