/**
* @description  : Scheduler Class to schedule Dunning Case Creation Batch job
* @author Billing Team
* @date 10/18/2022
* Name : NSP_DunningCaseCreation_Scheduler
*/
global class NSP_DunningCaseCreation_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
        Database.executeBatch(cbatch);
    }
}