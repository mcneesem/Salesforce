/**
* Class Type: Schedulable
* Description: Executes NSP_deleteErrorLogsBatch batch
*/
public class NSP_deleteErrorLogsScheduler implements Schedulable {
	
    public void execute (SchedulableContext sc) {
        NSP_deleteErrorLogsBatch delbatch = new NSP_deleteErrorLogsBatch();
        database.executeBatch(delbatch);
    }
}