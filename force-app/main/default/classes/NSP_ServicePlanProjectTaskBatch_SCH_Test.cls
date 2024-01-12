/**
 * Apex Class Name : NSP_ServicePlanProjectTaskBatch_SCH_Test
 * Function        : Represents test class for NSP_ServicePlanProjectTaskBatch_SCH class
 */
@IsTest
public class NSP_ServicePlanProjectTaskBatch_SCH_Test {
    /**
     * Apex mehtod Name : executeTests
     * Description      : this method runs the test scripts for NSP_ServicePlanProjectTaskBatch_SCH class
     */
	@IsTest
    public static void executeTests(){
        Test.startTest();
        NSP_ServicePlanProjectTaskBatch_SCH objBatchTest = new NSP_ServicePlanProjectTaskBatch_SCH();
        String cronExp = '0 0 0 * * ?';
		String jobId = system.schedule('Test Scheduler', cronExp, objBatchTest);
        CronTrigger ctrigger = [SELECT Id, CronExpression FROM CronTrigger WHERE Id =:jobId];
        System.assertEquals(ctrigger.CronExpression, cronExp,'It is Same.');
        Test.stopTest();
    }
}