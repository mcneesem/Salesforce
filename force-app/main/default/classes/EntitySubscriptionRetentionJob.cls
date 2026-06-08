public with sharing class EntitySubscriptionRetentionJob implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ EntitySubscriptionRetentionJobTest (80%)

    //
    // argument-free constructor is required to be "runnable"...
    //
    public EntitySubscriptionRetentionJob() {
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
            'EntitySubscriptionRetentionJob ~ Unfolllow Case ~ monday at 5 AM' + suffix ,
            '0 0 5 ? * MON *' ,
            new EntitySubscriptionRetentionJob()
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
    public Id run(){
        Id response = null;
        if ( EntitySubscriptionRetentionJob.isEnabled ) {
            response = Database.executeBatch(
                new EntitySubscriptionRetentionJob() ,
                EntitySubscriptionRetentionJob.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Set<Id> parentIds = new Set<Id>();
        Map<Id,ContentDocument> documentsMap = new Map<Id,ContentDocument>(
            [
                SELECT Id
                FROM ContentDocument
                WHERE ( CreatedDate <= :EntitySubscriptionRetentionJob.contentDocumentCreatedDateTime )
            ]
        );
        parentIds.addAll( documentsMap.keySet() );
        Map<Id,Case> casesMap = new Map<Id,Case>(
            [
                SELECT Id
                FROM Case
                WHERE (
                    ( IsClosed = true )
                    AND ( ClosedDate <= :EntitySubscriptionRetentionJob.caseClosedDateTime )
                )
            ]
        );
        parentIds.addAll( casesMap.keySet() );
        return Database.getQueryLocator(
            [
                SELECT Id
                FROM EntitySubscription
                WHERE ParentId IN :parentIds
                ORDER BY CreatedDate ASC
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<EntitySubscription> scope ) {
        try {
            if ( EntitySubscriptionRetentionJob.isEnabled
                && ( scope != null )
                && !scope.isEmpty()
                )
            {
                List<Database.DeleteResult> results = Database.delete( scope , false );
                NSP_ErrorLogHandler.logResults(
                    EntitySubscriptionRetentionJob.class.getName() ,
                    'execute:delete' ,
                    results
                );
            }
        } catch( Exception e ) {
            NSP_ErrorLogHandler.logException(
                EntitySubscriptionRetentionJob.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static EntitySubscriptionRetentionJobSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = EntitySubscriptionRetentionJobSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( EntitySubscriptionRetentionJob.settings != null ) {
                    local = EntitySubscriptionRetentionJob.settings.IsEnabled__c;
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
                if ( ( EntitySubscriptionRetentionJob.settings != null )
                    && ( EntitySubscriptionRetentionJob.settings.BatchSize__c != null )
                    )
                {
                    local = EntitySubscriptionRetentionJob.settings.BatchSize__c.intValue();
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

    // how far back (in days) should be queried???
    private static Integer soqlDaysLimitCases {
        private get {
            if ( soqlDaysLimitCases == null ) {
                Integer local = 30;
                if ( ( EntitySubscriptionRetentionJob.settings != null )
                    && ( EntitySubscriptionRetentionJob.settings.SoqlDaysLimitCases__c != null )
                    )
                {
                    local = EntitySubscriptionRetentionJob.settings.SoqlDaysLimitCases__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysLimitCases = local;
            }
            return soqlDaysLimitCases;
        }
        private set;
    }

    // translates soqlDaysLimitCases into a specific DateTime value...
    private static DateTime caseClosedDateTime {
        private get {
            if ( caseClosedDateTime == null ) {
                caseClosedDateTime = System.now().addDays( -1 * EntitySubscriptionRetentionJob.soqlDaysLimitCases );
            }
            return caseClosedDateTime;
        }
        private set;
    }

    // how far back (in days) should be queried???
    private static Integer soqlDaysLimitContentDocuments  {
        private get {
            if ( soqlDaysLimitContentDocuments == null ) {
                Integer local = 180;
                if ( ( EntitySubscriptionRetentionJob.settings != null )
                    && ( EntitySubscriptionRetentionJob.settings.SoqlDaysLimitContentDocuments__c != null )
                    )
                {
                    local = EntitySubscriptionRetentionJob.settings.SoqlDaysLimitContentDocuments__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysLimitContentDocuments = local;
            }
            return soqlDaysLimitContentDocuments;
        }
        private set;
    }

    // translates soqlDaysLimitContentDocuments into a specific DateTime value...
    private static DateTime contentDocumentCreatedDateTime {
        private get {
            if ( contentDocumentCreatedDateTime == null ) {
                contentDocumentCreatedDateTime = System.now().addDays( -1 * EntitySubscriptionRetentionJob.soqlDaysLimitContentDocuments );
            }
            return contentDocumentCreatedDateTime;
        }
        private set;
    }

}
//