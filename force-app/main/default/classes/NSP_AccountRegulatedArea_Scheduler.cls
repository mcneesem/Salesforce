//***Schedulable Apex Class***
/**
* @description  : Scheduler Class to schedule Renewal Batch job
* Name : NSP_AccountRegulatedArea_Scheduler
*/
public without sharing class NSP_AccountRegulatedArea_Scheduler implements Schedulable {
    // test w/ NSP_AccountRegulatedArea_Scheduler_Test (100%)
    public void execute(SchedulableContext ctx) {
        NSP_RegulatedAreaBatch batchObject = new NSP_RegulatedAreaBatch();
        Database.executeBatch(batchObject, 2000);
    }
    public static String schedule() {
    return System.schedule(
        'NSP_AccountRegulatedArea_Scheduler ~ When SCC is added to the account and the zip code or city is present in regulated area it will create case and account regulated area ~ everyday at 12 AM' ,
        '0 0 0 * * ? *' ,
        new NSP_AccountRegulatedArea_Scheduler()
    );
}
}