/***Test Class for Schedulable Apex Class***
/*** @description  : Test Class for Scheduler Class to schedule NSP_AccountRegulatedbatch
* @author Bindushree R
* @date 09/03/2021
* Name : NSP_AccountRegulatedArea_Scheduler_Test
*/

@isTest(SeeAllData=false)

public class NSP_AccountRegulatedArea_Scheduler_Test {
    public NSP_AccountRegulatedArea_Scheduler_Test() {

    }
    //Static Test Method to Call the Scheduler Class
    static testMethod void testAccountRegulatedBatchScheduler() {  
        Test.startTest();  
        NSP_AccountRegulatedArea_Scheduler regualtedAreaScheduler = new NSP_AccountRegulatedArea_Scheduler();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Regulated Batch', sch, regualtedAreaScheduler);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  

}