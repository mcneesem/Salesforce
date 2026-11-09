public with sharing class NSP_PaperlessBatchDateBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_PaperlessBatchDateBatchTest (100%)

    // @description Sets the paperless account flag based on account team role in AIMS so that the paperless account flag will be added or removed automatically.

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_PaperlessBatchDateBatch() {
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
            'NSP_PaperlessBatchDateBatch ~ Sets the paperless account flag based on account team role in AIMS so that the paperless account flag will be added or removed automatically. ~ Schedule to run daily 2 AM' + suffix ,
            '0 0 2 ? * * *' ,
            new NSP_PaperlessBatchDateBatch()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String, Object> args ) {
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
            new NSP_PaperlessBatchDateBatch() ,
            200
        );
    }

    //
    // Batchable
    //

    public database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Paperless_Batch_Date__c ,
                    NSP_IsPaperless__c ,
                    NSP_Paid_Non_Paid__c ,
                    NSP_Employee_Status__c ,
                    NSP_Sub_Client__r.NSP_Account_Status__c ,
                    NSP_Sub_Client__c ,
                    NSP_Sub_Client__r.NSP_Paperless_Batch_Date__c ,
                    NSP_Sub_Client__r.NSP_Asset__c ,
                    NSP_Sub_Client__r.NSP_Asset__r.Status ,
                    NSP_Sub_Client__r.NSP_Asset__r.NSP_Paperless_Batch_Date__c
                FROM NSP_Sub_Client_Contact__c
                WHERE (
                    ( NSP_Sub_Client__r.NSP_Asset__r.RecordType.Name = 'WO' )
                    AND (
                        ( NSP_Paperless_Batch_Date__c = YESTERDAY )
                        OR ( NSP_Sub_Client__r.NSP_Paperless_Batch_Date__c = YESTERDAY )
                        OR ( NSP_Sub_Client__r.NSP_Asset__r.NSP_Paperless_Batch_Date__c = YESTERDAY )
                    )
                )
            ]
        );
    }

    public void execute ( Database.BatchableContext bc , List<NSP_Sub_Client_Contact__c> scope ) {
        NSP_PaperlessBatchDateService.updatePaperlessOnAsset( scope );
    }

    public void finish ( Database.BatchableContext bc ) {
    }

}
//
