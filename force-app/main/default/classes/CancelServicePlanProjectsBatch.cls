//
// @description Batch that finds WO Assets whose Account was Terminated 14+ days ago and cancels
// the related open Service Plan projects (status not Complete/Cancelled, project type Service Plan)
// by setting their status to Cancelled with the "Client Terminated" reason.
// must evaluate every matching Asset org-wide, independent of the scheduling user's sharing.
//
// intentionally `without sharing` to ensure visibility of all Asset and pse__Proj__c records...
public without sharing class CancelServicePlanProjectsBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ CancelServicePlanProjectsBatchTest (88%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public CancelServicePlanProjectsBatch() {
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
            'CancelServicePlanProjectsBatch ~ Cancel open service-plan (PEO) projects for Accounts whose WO Asset has been Terminated for the configured number of days ~ everyday at 1am' + suffix ,
            '0 0 1 ? * * *' ,
            new CancelServicePlanProjectsBatch()
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
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    AccountId ,
                    RecordTypeId ,
                    NSP_Account_Status__c ,
                    NSP_Account_Status_Date__c
                FROM Asset
                WHERE (
                    ( AccountId != null )
                    AND ( RecordTypeId = :NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' ) )
                    AND ( NSP_Account_Status__c = 'Terminated' )
                    AND ( NSP_Account_Status_Date__c != null )
                    AND ( NSP_Account_Status_Date__c > :CancelServicePlanProjectsBatch.statusDaysMaximumDate )
                    AND ( NSP_Account_Status_Date__c <= :CancelServicePlanProjectsBatch.statusDaysMinimumDate )
                )
            ]
        );
    }

    // @description Collects the distinct Account Ids in the chunk and cancels their open
    // Service Plan projects (one query + one update per chunk keeps SOQL/DML flat).
    // @param bc BatchableContext supplied by the platform.
    // @param scopeAssets Chunk of WO Asset records returned by start().
    public void execute( Database.BatchableContext bc , List<Asset> scopeAssets ) {
        if ( CancelServicePlanProjectsBatch.isEnabled ) {
            Set<Id> accountIds = new Set<Id>();
            if ( scopeAssets != null && !scopeAssets.isEmpty() ) {
                for ( Asset terminatedAsset : scopeAssets ) {
                    if ( terminatedAsset.AccountId != null ) {
                        accountIds.add( terminatedAsset.AccountId );
                    }
                }
            }
            if ( !accountIds.isEmpty() ) {
                this.cancelProjectsForAccounts( accountIds );
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
    private void cancelProjectsForAccounts( Set<Id> accountIds ) {
        try {
            List<pse__Proj__c> projectsToCancel = [
                SELECT
                    Id ,
                    pse__Project_Status__c ,
                    NSP_Cancelled_Reason__c
                FROM pse__Proj__c
                WHERE (
                    ( pse__Account__c IN :accountIds )
                    AND (
                        pse__Project_Status__c NOT IN (
                            'Complete' ,
                            'Cancelled'
                        )
                    )
                    AND ( pse__Project_Type__c = 'Service Plan' )
                    AND ( RecordTypeId = :NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'PEO_Project' ) )
                )
            ];
            if ( ( projectsToCancel != null ) && !projectsToCancel.isEmpty() ) {
                for ( pse__Proj__c serviceProject : projectsToCancel ) {
                    serviceProject.pse__Project_Status__c = 'Cancelled';
                    serviceProject.NSP_Cancelled_Reason__c = 'Client Terminated';
                }
                List<Database.SaveResult> results = Database.update( projectsToCancel , false );
                NSP_ErrorLogHandler.logResults(
                    CancelServicePlanProjectsBatch.class.getName() ,
                    'cancelProjectsForAccounts:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CancelServicePlanProjectsBatch.class.getName() ,
                'cancelProjectsForAccounts' ,
                e
            );
        }
    }

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
                Integer local = 200;
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

    // Grace Period translates statusDaysMinimum into a specific Date value...
    private static Date statusDaysMinimumDate {
        private get {
            if ( statusDaysMinimumDate == null ) {
               statusDaysMinimumDate = System.today().addDays( -1 * CancelServicePlanProjectsBatch.statusDaysMinimum );
            }
            return statusDaysMinimumDate;
        }
        private set;
    }

    // Grace Peiord allow Rep to Complete Pending Work on the Project before its Cancel
    private static Integer statusDaysMinimum {
        private get {
            if ( statusDaysMinimum == null ) {
                Integer local = 14;
                if ( ( CancelServicePlanProjectsBatch.settings != null )
                    && ( CancelServicePlanProjectsBatch.settings.StatusDaysMinimum__c != null )
                    )
                {
                    local = CancelServicePlanProjectsBatch.settings.StatusDaysMinimum__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                statusDaysMinimum = local;
            }
            return statusDaysMinimum;
        }
        private set;
    }

    // translates statusDaysMaximum into a specific Date value...
    private static Date statusDaysMaximumDate {
        private get {
            if ( statusDaysMaximumDate == null ) {
                statusDaysMaximumDate = System.today().addDays( -1 * CancelServicePlanProjectsBatch.statusDaysMaximum );
            }
            return statusDaysMaximumDate;
        }
        private set;
    }

    // how far back (in days) should be queried??? Avoid re-Scan all Termed Asset everytime once processed
    private static Integer statusDaysMaximum {
        private get {
            if ( statusDaysMaximum == null ) {
                Integer local = CancelServicePlanProjectsBatch.statusDaysMinimum;
                if ( ( CancelServicePlanProjectsBatch.settings != null )
                    && ( CancelServicePlanProjectsBatch.settings.StatusDaysMaximum__c != null )
                    )
                {
                    local = CancelServicePlanProjectsBatch.settings.StatusDaysMaximum__c.intValue();
                }
                // limit must be greater than or equal to the minimum...
                if ( local < CancelServicePlanProjectsBatch.statusDaysMinimum ) {
                    local = CancelServicePlanProjectsBatch.statusDaysMinimum;
                }
                statusDaysMaximum = local;
            }
            return statusDaysMaximum;
        }
        private set;
    }

}
//
