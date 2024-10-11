@isTest(SeeAllData=false)
private class CancelCoreSalesEventsTasks_SchedulerTest {
    private static final String sch = '0 0 3 * * ? *';
    
    //Static Test Method to Call the Scheduler Class
    @isTest private static void testCancelCoreSalesEventsTasks_schedule() {
        Test.startTest();
        String jobId = CancelCoreSalesEventsTasks_Scheduler.schedule();
        CronTrigger ct = [
            SELECT Id , CronExpression , TimesTriggered , NextFireTime
            FROM CronTrigger
            WHERE id = :jobId
        ];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
   }

}
//