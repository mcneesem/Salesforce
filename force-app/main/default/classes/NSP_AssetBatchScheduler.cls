/**
* @description  : Scheduler Class to schedule Asset Biometric Indicator Expiration
* @author Manjeet Singh
* @date 11/08/2021
* Name : NSP_AssetBatchScheduler
*/
public class NSP_AssetBatchScheduler implements Schedulable{
    public void execute(SchedulableContext SC){
        Database.executeBatch(new NSP_AssetBatch());
    }
}