//***Schedulable Apex Class***
/**
* @description  : Scheduler Class to schedule NSP_ServicePlanProjectTaskBatch
* 
* Name : NSP_ServicePlanProjectTaskBatch_SCH
*/
global class NSP_ServicePlanProjectTaskBatch_SCH implements Schedulable{
	global void execute(SchedulableContext ctx) {
        NSP_ServicePlanProjectTaskBatch batchObject = new NSP_ServicePlanProjectTaskBatch();
         Database.executeBatch(batchObject);
    }
}