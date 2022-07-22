//***Test Class for Schedulable Apex Class***
/**
* @description  : Test Class for NSP_SalesRenewalOpportunityScheduler Class to schedule Asset Renewal Batch job
* @author Tejas
* @date 11/07/2021
* Name : NSP_SalesRenewalOpportunitySchedulerTest
*/
@isTest
public class NSP_SalesRenewalOpportunitySchedulerTest {

    //Static Test Method to Call the Scheduler Class
    static testMethod void testCallRenewalBatchScheduler() {  
        Test.startTest();  
        NSP_SalesRenewalOpportunityScheduler contractschedule = new NSP_SalesRenewalOpportunityScheduler();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Contract Batch', sch, contractschedule);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  
}