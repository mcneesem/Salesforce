/**
* @description  : schedule class to call the NSP_AutomaticProjectBatchClass to create a project--->calls the batch class nightly
   Automatically Creating a Service Plan Project for a new client based on STY-01029
* @date 05/12/2022
* Name : NSP_AutomaticProjectScheduler
*/
global class NSP_AutomaticProjectScheduler implements Schedulable{
    global void execute(SchedulableContext ctx) {
        //scheduling the NSP_AutomaticProjectBatchClass 
        NSP_AutomaticProjectBatchClass automatic = new NSP_AutomaticProjectBatchClass();
		Id batchId = Database.executeBatch(automatic, 1);
    }
}