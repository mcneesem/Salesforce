/**
* @description  : Scheduler Class to schedule Dunning Case Creation Batch job
* @author Billing Team
* @date 10/18/2022
* Name : NSP_DunningEmailNotification_Scheduler
*/
global class NSP_DunningEmailNotification_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        NSP_DunningEmailNotificationsBatch nbatch = new NSP_DunningEmailNotificationsBatch();
        Database.executeBatch(nbatch);
    }
}