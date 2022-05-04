//***Schedulable Apex Class***
/**
* @description  : Scheduler Class to schedule Asset Renewal Batch job
* @author Tejas Patkar
* @date 21/09/2021
* Name : NSP_SalesRenewalOpportunityScheduler
*/

global class NSP_SalesRenewalOpportunityScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        NSP_SalesAssetRenewalBatch batchObject = new NSP_SalesAssetRenewalBatch();
		Database.executeBatch(batchObject);
    }
}