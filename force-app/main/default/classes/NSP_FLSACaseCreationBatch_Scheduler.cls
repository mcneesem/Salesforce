//***Schedulable Apex Class***
/**
* @description  : Scheduler Class to schedule FLSA Case Creation job
* 
* Name : NSP_FLSACaseCreationBatch_Scheduler
*/
global class NSP_FLSACaseCreationBatch_Scheduler implements Schedulable{
	global void execute(SchedulableContext ctx) {
        NSP_FLSACaseCreationBatch batchObject = new NSP_FLSACaseCreationBatch();
        Id batchId = Database.executeBatch(batchObject);
    }
}