@isTest
public class LoadFullAccessPermSetsSchedulableTest {

    static testMethod void testLoadFullAccessPermSetsSchedulable() {  
        Test.startTest();  
        LoadFullAccessPermSetsSchedulable loadPSschedule = new LoadFullAccessPermSetsSchedulable();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test LoadPermSets', sch, loadPSschedule);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  
}