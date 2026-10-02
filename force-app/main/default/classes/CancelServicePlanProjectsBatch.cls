// @description Batch that finds WO Assets whose Account was Terminated 14+ days ago and cancels
// the related open Service Plan projects (status not Complete/Cancelled, project type Service Plan)
// by setting their status to Cancelled with the "Client Terminated" reason.
// without sharing is intentional: this is an unattended, system-context maintenance job that
// must evaluate every matching Asset org-wide, independent of the scheduling user's sharing.
public without sharing class CancelServicePlanProjectsBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ CancelServicePlanProjectsBatchTest (88%)

    // Fallback used when ServicePlanGracePeriod__c custom setting field is blank.
    private static final Integer DEFAULT_GARCE_PERIOD_DAYS = 14;

    // Default chunk size used when the custom setting BatchSize__c is not populated. Kept small
    // because each Account can fan out to many projects.
    private static final Integer DEFAULT_BATCH_SIZE = 200;

    // Reason written onto the cancelled projects.
    private static final String CANCELLED_REASON = 'Client Terminated';

    private static final Id WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(
        'Asset' ,
        NSP_ServiceConstants.WO_ASSET_RECORDTYPE
    );

    private static final Id PROJECT_PEO_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(
        NSP_ServiceConstants.PROJECT_SOBJECT_NAME ,
        NSP_ServiceConstants.PROJECT_PEO_RECORDTYPE
    );

    // @description Argument-free constructor required so the job can be run/scheduled generically.
    public CancelServicePlanProjectsBatch() {
    }

    //
    // ISelfSchedulable
    //

    // @description Schedules this batch to run every day at 1 AM Central.
    // @return CronTrigger Id of the scheduled job.
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'CancelServicePlanProjectsBatch ~ Cancel open service-plan (PEO) projects for Accounts whose WO Asset has been Terminated for the configured number of days ~ everyday ' + suffix ,
            '0 0 1 ? * * *' ,
            new CancelServicePlanProjectsBatch()
        );
    }

    //
    // Schedulable
    //

    // @description Scheduler entry point; delegates to the generic runner.
    // @param sc SchedulableContext supplied by the platform.
    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    // @description Generic invocation entry point.
    // @param action Action name; only 'run' is supported.
    // @param args Optional arguments (unused).
    // @return AsyncApexJob Id when the batch is queued, otherwise null.
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

    // @description Queues this batch for execution when the custom-setting killswitch is enabled.
    // @return AsyncApexJob Id of the queued batch, or null when disabled.
    public Id run() {
        Id response = null;
        if ( CancelServicePlanProjectsBatch.isEnabled ) {
            response = Database.executeBatch(
                new CancelServicePlanProjectsBatch() ,
                CancelServicePlanProjectsBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    // @description Builds the scope: WO Assets with a non-null Account, Terminated status and an
    // Account Status Date on or before (today - ServicePlanGracePeriod).
    // @param bc BatchableContext supplied by the platform.
    // @return QueryLocator over the matching Asset records.
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Date lagDate = System.today().addDays( -CancelServicePlanProjectsBatch.ServicePlanGracePeriod );
        String finalDate = String.valueOf( lagDate ).removeEnd( ' 00:00:00' );
        List<String> assetFields = new List<String>{
            'Id' ,
            'AccountId' ,
            'RecordTypeId' ,
            'NSP_Account_Status__c' ,
            'NSP_Account_Status_Date__c'
        };
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder( 'Asset' , assetFields )
            .addFilter( 'AccountId' , NULL , NSP_QueryBuilder.Operator.NOT_EQUALS , false )
            .addFilter( 'RecordTypeId' , CancelServicePlanProjectsBatch.WO_ASSET_RECORDTYPE , NSP_QueryBuilder.Operator.EQUALS , true )
            .addFilter( 'NSP_Account_Status__c' , NSP_ServiceConstants.TERMINATED , NSP_QueryBuilder.Operator.EQUALS , true )
            .addFilter( 'NSP_Account_Status_Date__c' , NULL , NSP_QueryBuilder.Operator.NOT_EQUALS , false )
            .addFilter( 'NSP_Account_Status_Date__c' , finalDate , NSP_QueryBuilder.Operator.LESS_THAN_OR_EQUALS , false )
            .setSecurityEnforce( false );
        String query = queryBuilder.build();
        return Database.getQueryLocator( query );
    }

    // @description Collects the distinct Account Ids in the chunk and cancels their open
    // Service Plan projects (one query + one update per chunk keeps SOQL/DML flat).
    // @param bc BatchableContext supplied by the platform.
    // @param scopeAssets Chunk of WO Asset records returned by start().
    public void execute( Database.BatchableContext bc , List<Asset> scopeAssets ) {
        if ( CancelServicePlanProjectsBatch.isEnabled ) {
            Set<Id> accountIds = new Set<Id>();
            if ( scopeAssets != null ) {
                for ( Asset terminatedAsset : scopeAssets ) {
                    if ( terminatedAsset.AccountId != null ) {
                        accountIds.add( terminatedAsset.AccountId );
                    }
                }
            }
            if ( !accountIds.isEmpty() ) {
                cancelProjectsForAccounts( accountIds );
            }
        }
    }

    // @description No post-processing required.
    // @param bc BatchableContext supplied by the platform.
    public void finish( Database.BatchableContext bc ) {
    }

    //
    // Helpers
    //

    // @description Cancels every open Service Plan project owned by the supplied Accounts:
    // projects whose status is neither Complete nor Cancelled and whose project type is
    // Service Plan get their status set to Cancelled with the "Client Terminated" reason.
    // @param accountIds Distinct Account Ids whose open Service Plan projects should be cancelled.
    // @throws Exception details are logged through NSP_ErrorLogHandler.
    private static void cancelProjectsForAccounts( Set<Id> accountIds ) {
        try {
            List<pse__Proj__c> projectsToCancel = [
                SELECT Id , pse__Project_Status__c , NSP_Cancelled_Reason__c
                FROM pse__Proj__c
                WHERE (
                    pse__Account__c IN :accountIds
                    AND pse__Project_Status__c != :NSP_ServiceConstants.PROJECTSTATUSCOMPLETED
                    AND pse__Project_Status__c != :NSP_ServiceConstants.PROJECTSTATUSCANCELLED
                    AND pse__Project_Type__c = :NSP_ServiceConstants.PROJECT_TYPE_SERVICE
                    AND RecordTypeId = :CancelServicePlanProjectsBatch.PROJECT_PEO_RECORDTYPE
                )
            ];
            if ( ( projectsToCancel != null ) && !projectsToCancel.isEmpty() ) {
                for ( pse__Proj__c serviceProject : projectsToCancel ) {
                    serviceProject.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSCANCELLED;
                    serviceProject.NSP_Cancelled_Reason__c = CancelServicePlanProjectsBatch.CANCELLED_REASON;
                }
                updateProjects( projectsToCancel );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CancelServicePlanProjectsBatch.class.getName() ,
                'cancelProjectsForAccounts' ,
                e
            );
        }
    }

    // @description Partial-success update of the cancelled projects; results are logged.
    // @param projectsToCancel Service Plan projects to move to Cancelled status.
    // @throws Exception details are logged through NSP_ErrorLogHandler.
    private static void updateProjects( List<pse__Proj__c> projectsToCancel ) {
        try {
            Database.SaveResult[] results = Database.update( projectsToCancel , false );
            NSP_ErrorLogHandler.logResults(
                CancelServicePlanProjectsBatch.class.getName() ,
                'updateProjects:update' ,
                results
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CancelServicePlanProjectsBatch.class.getName() ,
                'updateProjects' ,
                e
            );
        }
    }

    //
    // Custom setting (CancelServicePlanProjectsBatchSettings__c) accessors
    //

    // @description Cached hierarchy custom setting for the running user.
    private static CancelServicePlanProjectsBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = CancelServicePlanProjectsBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    // @description Killswitch that enables/disables Service Plan project cancellation.
    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( CancelServicePlanProjectsBatch.settings != null ) {
                    local = CancelServicePlanProjectsBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    // @description Batch chunk size sourced from the custom setting, defaulted and clamped to 1-2000.
    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = CancelServicePlanProjectsBatch.DEFAULT_BATCH_SIZE;
                if ( ( CancelServicePlanProjectsBatch.settings != null )
                    && ( CancelServicePlanProjectsBatch.settings.BatchSize__c != null )
                    )
                {
                    local = CancelServicePlanProjectsBatch.settings.BatchSize__c.intValue();
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

    // @description Grace period in days after NSP_Account_Status_Date__c before projects are
    // cancelled. Sourced from ServicePlanGracePeriod__c, defaulted to 14, clamped to 1-365.
    private static Integer ServicePlanGracePeriod {
        private get {
            if ( ServicePlanGracePeriod == null ) {
                Integer local = CancelServicePlanProjectsBatch.DEFAULT_GARCE_PERIOD_DAYS;
                if ( ( CancelServicePlanProjectsBatch.settings != null )
                    && ( CancelServicePlanProjectsBatch.settings.ServicePlanGracePeriod__c != null )
                    )
                {
                    local = CancelServicePlanProjectsBatch.settings.ServicePlanGracePeriod__c.intValue();
                }
                // lag must be at least 1 day...
                if ( local < 1 ) {
                    local = 1;
                }
                // lag capped at 1 year to prevent runaway scope...
                if ( local > 365 ) {
                    local = 365;
                }
                ServicePlanGracePeriod = local;
            }
            return ServicePlanGracePeriod;
        }
        private set;
    }

}
//