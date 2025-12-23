@isTest
private class NSP_ContractRenewal_Scheduler_Test {

    @isTest
    private static void testCallRenewalBatchScheduler() {
        Test.startTest();
        NSP_ContractRenewal_Scheduler contractschedule = new NSP_ContractRenewal_Scheduler();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Contract Batch', sch, contractschedule);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
   }

}
//