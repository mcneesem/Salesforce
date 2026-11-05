public with sharing class NSP_DeleteMergeCaseBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_DeleteMergeCaseBatch_Test (100%)

    // @description Batch class to delete Cases in Merged status; self-scheduling, callable, and runnable.

    //
    // argument-free constructor is required to be "runnable"...
    //

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

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT Id , Status
                FROM Case
                WHERE ( Status = 'Merged' )
                WITH SECURITY_ENFORCED 
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<Case> scope ) {
        Database.DeleteResult[] results = Database.delete( scope , false );
        NSP_ErrorLogHandler.logResults(
            NSP_DeleteMergeCaseBatch.class.getName() ,
            'execute' ,
            results
        );
    }

    public void finish( Database.BatchableContext bc ) {
    }

}
//
