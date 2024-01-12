//***Schedulable Apex Class***
/**
* @description  : Scheduler Class to schedule Renewal Batch job
* Name : NSP_AccountRegulatedArea_Scheduler
*/
public without sharing class NSP_AccountRegulatedArea_Scheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        NSP_RegulatedAreaBatch batchObject = new NSP_RegulatedAreaBatch();
        Database.executeBatch(batchObject, 2000);
    }
}