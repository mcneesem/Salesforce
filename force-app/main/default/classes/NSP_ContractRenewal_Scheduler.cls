//***Schedulable Apex Class***
/**
* @description  : Scheduler Class to schedule Renewal Batch job
* @author Rakesh Das
* @date 08/04/2021
* Name : NSP_ContractRenewal_Scheduler
*/

global class NSP_ContractRenewal_Scheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        NSP_ContractRenewal_Batch batchObject = new NSP_ContractRenewal_Batch();
        Database.executeBatch(batchObject, 1);
    }
}