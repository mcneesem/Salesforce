@isTest
private class NSP_AccountRegulatedArea_Scheduler_Test {

    @isTest
    private static void testAccountRegulatedBatchScheduler() {
        Test.startTest();
        String jobId = NSP_AccountRegulatedArea_Scheduler.schedule();
        CronTrigger ct = [
            SELECT Id , CronExpression , TimesTriggered , NextFireTime
            FROM CronTrigger
            WHERE ( Id = :jobId )
        ];
        System.assertNotEquals( null , ct );
        System.assertEquals( 0 , ct.TimesTriggered );
        Test.stopTest();
   }

}
//
