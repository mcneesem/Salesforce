public class NSP_HardwateAssetStatusBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_HardwateAssetStatusBatchTest (91%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_HardwateAssetStatusBatch() {
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
            'NSP_HardwateAssetStatusBatch ~ process hardware assets for terminations and activations ~ M-F at 3 AM' + suffix ,
            '0 0 3 ? * MON-FRI *' ,
            new NSP_HardwateAssetStatusBatch()
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
        if ( NSP_HardwateAssetStatusBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_HardwateAssetStatusBatch() ,
                NSP_HardwateAssetStatusBatch.batchSize
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
                    NSP_Termination_Date__c ,
                    NSP_ActivationDate__c ,
                    Status
                FROM Asset
                WHERE (
                    ( RecordType.Name = :NSP_CPQConstants.HARDWARE_ASSET )
                    AND (
                        ( NSP_Termination_Date__c != null )
                        OR ( NSP_ActivationDate__c != null )
                    )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<Asset> scope ) {
        if ( NSP_HardwateAssetStatusBatch.isEnabled ) {
            try {
                Date today = System.today();
                List<Asset> assetsToUpdate = new List<Asset>();
                for ( Asset eachAsset : scope ) {
                    if ( ( eachAsset.Status == NSP_CPQConstants.ACTIVE )
                        && ( eachAsset.NSP_Termination_Date__c < today )
                        )
                    {
                        eachAsset.Status = NSP_CPQConstants.TERMINATED;
                        eachAsset.NSP_ActivationDate__c = null;
                        eachAsset.NSP_Support__c = false;
                        assetsToUpdate.add( eachAsset );
                    }
                    if ( ( eachAsset.Status == NSP_CPQConstants.TERMINATED )
                        && ( eachAsset.NSP_ActivationDate__c >= today )
                        )
                    {
                        eachAsset.Status = NSP_CPQConstants.ACTIVE;
                        eachAsset.NSP_Termination_Date__c = null;
                        eachAsset.NSP_Support__c = true;
                        assetsToUpdate.add( eachAsset );
                    }
                }
                if ( !assetsToUpdate.isEmpty() ) {
                    List<Database.SaveResult> results = Database.update( assetsToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_HardwateAssetStatusBatch.class.getName() ,
                        'execute:update' ,
                        results
                    );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_HardwateAssetStatusBatch.class.getName() ,
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

    private static HardwareAssetStatusBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = HardwareAssetStatusBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_HardwateAssetStatusBatch.settings != null ) {
                    local = NSP_HardwateAssetStatusBatch.settings.IsEnabled__c;
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
                if ( ( NSP_HardwateAssetStatusBatch.settings != null )
                    && ( NSP_HardwateAssetStatusBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_HardwateAssetStatusBatch.settings.BatchSize__c.intValue();
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