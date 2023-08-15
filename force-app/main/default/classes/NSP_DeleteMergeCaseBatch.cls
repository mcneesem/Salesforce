/**
* @description  :  Batch Class to delete Merged cases
* @date 04/08/2023
* Author : Prakash Dalvi
* Name : NSP_DeleteMergeCaseBatch
* Story : STY-00861 - Merge Case
*/
public class NSP_DeleteMergeCaseBatch implements Database.Batchable<SObject> {
    // test w/ NSP_DeleteMergeCaseBatch_Test (??%)

    public static final String CASE_MERGED = 'Merged';
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        List<String> caseFields = new List<String>{'Id', 'Status'};
            
        //query to get Merged cases
        String query = new NSP_QueryBuilder('Case', caseFields)
                            .addFilter('Status', CASE_MERGED)
                            .build();
        
        return Database.getQueryLocator(query);
        
    }
    
    public void execute(Database.BatchableContext bc, List<Case> caseList){

        Database.DeleteResult[] caseDeleteResultList = Database.Delete(caseList, false);        
        NSP_ErrorLogHandler.logDeleteResultsException('NSP_DeleteMergeCaseBatch', 'ExecuteMethod', caseDeleteResultList );
        
    }
    
    public void finish(Database.BatchableContext bc){        
    }
}