/***Test Class for Schedulable Apex Class***
/*** @description  : Test Class for Scheduler Class to schedule NSP_AccountRegulatedbatch
* @author Bindushree R
* @date 09/03/2021
* Name : NSP_AccountRegulatedArea_Scheduler_Test
*/

@isTest(SeeAllData=false)

public class NSP_AccountRegulatedArea_Scheduler_Test {
    private static final String sch = '0 0 0 * * ? *';
    public NSP_AccountRegulatedArea_Scheduler_Test() {

    }
    //Static Test Method to Call the Scheduler Class
    static testMethod void testAccountRegulatedBatchScheduler() {  
        Test.startTest();  
        String jobId = NSP_AccountRegulatedArea_Scheduler.schedule();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  

}