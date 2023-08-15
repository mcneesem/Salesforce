/**
* @description  : Scheduler class to schedule Delete merge case batch 
* @author Prakash Dalvi
* @date 04/08/2023
* Name : NSP_DeleteMergeCaseBatchScheduler
*/
public class NSP_DeleteMergeCaseBatchScheduler implements Schedulable{
    // test w/ NSP_DeleteMergeCaseBatch_Test (??%)

    public void execute(SchedulableContext SC){
        Database.executeBatch(new NSP_DeleteMergeCaseBatch());
    }

}