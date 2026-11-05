public with sharing class NSP_DeleteMergeCaseBatch implements ISelfSchedulable, Schedulable, Callable, IJobRunnable, Database.Batchable<SObject> {
    // test w/ NSP_DeleteMergeCaseBatch_Test (100%)
    // @description Batch class to delete Cases in Merged status; self-scheduling, callable, and runnable.

    public static final String CASE_MERGED = 'Merged';

    public NSP_DeleteMergeCaseBatch() {
    }

    //
    // ISelfSchedulable
    //

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_DeleteMergeCaseBatchScheduler ~ Delete Cases that are in a status of merged ~ Scheduled to run weekly at 12am' + suffix,
            '0 0 0 ? * * *',
            new NSP_DeleteMergeCaseBatch()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run', null );
    }

    //
    // Callable
    //

    public Object call( String action, Map<String, Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return Database.executeBatch(
            new NSP_DeleteMergeCaseBatch(),
            200
        );
    }

    //
    // Batchable
    //

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
//
