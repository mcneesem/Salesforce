/***Test Class for Schedulable Apex Class***
/*** @description  : Test Class for Scheduler Class to schedule NSP_AutomaticProjectBatchClass 
* @date 03/09/2023
* Name : NSP_AutomaticProjectSchedulerTest 
*/
@isTest(SeeAllData=false)
public class NSP_AutomaticProjectSchedulerTest {
     	//Static Test Method to Call the Scheduler Class
    @isTest
    static void testNSPAutomaticProjectScheduler() {  
        Test.startTest();  
        NSP_AutomaticProjectScheduler automaticProjectScheduler = new NSP_AutomaticProjectScheduler();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Automatic Project Batch', sch, automaticProjectScheduler);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  
}