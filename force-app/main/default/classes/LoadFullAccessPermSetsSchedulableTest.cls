@isTest(SeeAllData=false)
private class LoadFullAccessPermSetsSchedulableTest {
    private static final String sch = '0 00 05 ? * 2';

    @isTest private static void testLoadFullAccessPermSetsSchedulable() {  
        Test.startTest();
        String jobId = LoadFullAccessPermSetsSchedulable.schedule();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
   }
}