public class NSP_TerminateHardwateAssetBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_TerminateHardwareAssetBatchTest (90%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_TerminateHardwateAssetBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F at 3am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_TerminateHardwateAssetBatch ~ terminates hardware assets for non-renewed subscriptions ~ M-F at 3 AM' + suffix ,
            '0 0 3 ? * MON-FRI *' ,
            new NSP_TerminateHardwateAssetBatch()
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

    public Object call( String action , Map<String,Object> args ) {
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
        Id response = null;
        if ( NSP_TerminateHardwateAssetBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_TerminateHardwateAssetBatch() ,
                NSP_TerminateHardwateAssetBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getqueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Covered_Asset__c ,
                    NSP_Supported_Subscription__c
                FROM NSP_Support_Entitlement__c
                WHERE (
                    NSP_Supported_Subscription__c IN (
                        SELECT Id
                        FROM SBQQ__Subscription__c
                        WHERE (
                            ( SBQQ__EndDate__c != null )
                            AND ( SBQQ__EndDate__c < TODAY )
                            AND ( SBQQ__RenewedDate__c = null )
                        )
                    )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<NSP_Support_Entitlement__c> scope ) {
        if ( NSP_TerminateHardwateAssetBatch.isEnabled ) {
            try {
                List<Id> hadrwareIds = new List<Id>();
                for ( NSP_Support_Entitlement__c support : scope ) {
                    hadrwareIds.add( support.NSP_Covered_Asset__c );
                }
                if ( !hadrwareIds.isEmpty() ) {
                    List<Asset> assetsToTerminate=[
                        SELECT Id , Status
                        FROM Asset
                        WHERE ( Id IN :hadrwareIds )
                    ];
                    for ( Asset eachAsset : assetsToTerminate ) {
                        eachAsset.Status = NSP_CPQConstants.TERMINATED;
                    }
                    if ( !assetsToTerminate.isEmpty() ) {
                        List<Database.SaveResult> results = Database.update( assetsToTerminate , false );
                        NSP_ErrorLogHandler.logResults(
                            NSP_TerminateHardwateAssetBatch.class.getName() ,
                            'execute:update' ,
                            results
                        );
                    }
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_TerminateHardwateAssetBatch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static TerminateHardwareAssetBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = TerminateHardwareAssetBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_TerminateHardwateAssetBatch.settings != null ) {
                    local = NSP_TerminateHardwateAssetBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_TerminateHardwateAssetBatch.settings != null )
                    && ( NSP_TerminateHardwateAssetBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_TerminateHardwateAssetBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

}
//