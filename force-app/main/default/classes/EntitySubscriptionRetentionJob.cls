Public without sharing class EntitySubscriptionRetentionJob implements ISelfSchedulable, Schedulable, Callable, IJobRunnable, Database.Batchable<SObject> {
    // test w/ EntitySubscriptionRetentionJobTest (80%)
    public String query;

    //Constructor
    public EntitySubscriptionRetentionJob(){

    }


    //ISelfSchedulable
    public static String schedule(){
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


    //Schedulable
    public void execute(SchedulableContext sc){
        this.call( 'run' , null );
    }


    //Callable
    public Object call( String action, Map<String, Object> args){
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }


    // IJobRunnable
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

    //Batchable
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Integer days = 0;
        if ( EntitySubscriptionRetentionJob.settings != null ) {
            days = (Integer)EntitySubscriptionRetentionJob.settings.SoqlDaysLimitCases__c ;
        }
		Date thresholdDate = Date.today().addDays(-days);
        return Database.getQueryLocator([
			SELECT Id
			FROM EntitySubscription
			WHERE ParentId IN (
				SELECT Id
				FROM Case
				WHERE IsClosed = true
				AND ClosedDate <= :thresholdDate
			)
			ORDER BY CreatedDate ASC
		]);
    }

    public void execute(Database.BatchableContext bc, List<EntitySubscription> scope) {
        if(scope != null && !scope.isEmpty()){
            try{
                List<Database.DeleteResult> results = Database.delete( scope , false );
                NSP_ErrorLogHandler.logResults(
                    EntitySubscriptionRetentionJob.class.getName() ,
                    'execute:delete' ,
                    results
                );
            }catch( Exception e ){
                NSP_ErrorLogHandler.logException(EntitySubscriptionRetentionJob.class.getName() ,'execute' ,  e);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Finish logic here
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

}