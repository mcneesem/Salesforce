/**
 * Apex class Name : NSP_FLSACaseCreationBatch_SchedulerTest
 * Author: Simran
 * Represents test class for NSP_FLSACaseCreationBatch_Scheduler class
 */
@isTest
public class NSP_FLSACaseCreationBatch_SchedulerTest{
    // Method Name: schedulerTest
    static testmethod void schedulerTest() {
        String CRON_EXP = '0 0 0 15 3 ? *';
        Test.startTest();

            String jobId = System.schedule('ScheduleApexClassTest',  CRON_EXP, new NSP_FLSACaseCreationBatch_Scheduler());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }
}