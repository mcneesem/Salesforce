//***Test Class for Schedulable Apex Class***
/**
* @description  : Test Class for Scheduler Class to schedule Error Logs Deletion Batch job
* @author Rakesh Das
* @date 08/05/2022
* Name : NSP_deleteErrorLogsSchedulerTest
*/
@isTest(SeeAllData=false)
public class NSP_deleteErrorLogsSchedulerTest {

    public NSP_deleteErrorLogsSchedulerTest() {

    }
    //Static Test Method to Call the Scheduler Class
    static testMethod void testCallDeletionBatchScheduler() {  
        Test.startTest();  
        NSP_deleteErrorLogsScheduler delsch = new NSP_deleteErrorLogsScheduler();
        String sch = '0 0 3 * * ?';
        String jobId = System.schedule('Test Deletion Batch', sch, delsch);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  

}