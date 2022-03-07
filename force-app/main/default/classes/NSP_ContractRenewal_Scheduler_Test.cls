//***Test Class for Schedulable Apex Class***
/**
* @description  : Test Class for Scheduler Class to schedule Renewal Batch job
* @author Rakesh Das
* @date 09/03/2021
* Name : NSP_ContractRenewal_Scheduler_Test
*/

@isTest(SeeAllData=false)
public with sharing class NSP_ContractRenewal_Scheduler_Test {
    public NSP_ContractRenewal_Scheduler_Test() {

    }
    //Static Test Method to Call the Scheduler Class
    static testMethod void testCallRenewalBatchScheduler() {  
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
