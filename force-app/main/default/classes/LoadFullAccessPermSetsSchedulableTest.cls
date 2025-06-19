@isTest
private class LoadFullAccessPermSetsSchedulableTest {

    @isTest
    private static void testLoadFullAccessPermSetsSchedulable() {
        Test.startTest();
        String jobId = LoadFullAccessPermSetsSchedulable.schedule();
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