@isTest
private class CancelCoreSalesEventsTasks_SchedulerTest {

    @isTest
    private static void testCancelCoreSalesEventsTasks_schedule() {
        Test.startTest();
        String jobId = CancelCoreSalesEventsTasks_Scheduler.schedule();
        CronTrigger ct = [
            SELECT Id , CronExpression , TimesTriggered , NextFireTime
            FROM CronTrigger
            WHERE ( Id = :jobId )
        ];
        System.assertEquals( 0 , ct.TimesTriggered );
        Test.stopTest();
    }

}
//