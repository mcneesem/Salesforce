public class NSP_DunningCaseCreationBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject>, Database.Stateful {
    // test w/ NSP_DunningCaseCreationBatchTest (92%)

    private static final Id DUNNING_CASE_RT_ID = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'Dunning' );

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_DunningCaseCreationBatch(){}

    //
    // ISelfSchedulable
    //

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_DunningCaseCreationBatch ~ every Sunday at 2:00 PM CT' + suffix ,
            '0 0 14 ? * SUN *' ,
            new NSP_DunningCaseCreationBatch()
        );
    }

    //
    // Scheduleable
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
        return Database.executeBatch(
            new NSP_DunningCaseCreationBatch() ,
            NSP_DunningCaseCreationBatch.batchSize
        );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        // fetch all unpaid invoices older than 45 days and created after cut-off date
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    blng__Account__c ,
                    blng__Account__r.Name ,
                    blng__BillToContact__c
                FROM blng__Invoice__c
                WHERE (
                    ( blng__DueDate__c <= N_DAYS_AGO:45 )
                    AND ( blng__Balance__c > 0 )
                    AND ( blng__InvoiceStatus__c = 'Posted' )
                    AND ( blng__PaymentStatus__c != 'Paid' )
                    AND ( blng__InvoicePostedDate__c > :NSP_DunningCaseCreationBatch.cutOffDate )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<blng__Invoice__c> scope ) {
        try {
            if ( ( NSP_DunningCaseCreationBatch.isEnabled )
                && ( scope != null )
                )
            {
                Set<Id> accountIds = new Set<Id>();
                Map<String,Case> accountIdToCaseMap = new Map<String,Case>();
                //get unqiue accounts from all invoices except Insp. WO blng Acc
                for ( blng__Invoice__c inv : scope ) {
                    if ( ( inv.blng__Account__c != null )
                        && ( inv.blng__Account__r.Name != 'Insperity WO Billing Account' )
                        )
                    {
                        accountIds.add( inv.blng__Account__c );
                    }
                }
                //fetch already open dunning cases for the accounts
                List<Case> openDunningCases = [
                    SELECT Id , AccountId
                    FROM Case
                    WHERE (
                        ( AccountId IN :accountIds )
                        AND ( Status != 'Closed' )
                        AND ( Type = :NSP_BillingConstants.DUNNING_ACCOUNT )
                        AND ( NSP_Dunning_Type__c = :NSP_BillingConstants.OPEN_INVOICE )
                        AND ( RecordTypeId = :DUNNING_CASE_RT_ID )
                    )
                ];
                //map Accounts with open dunning cases
                for ( Case cs : openDunningCases ) {
                    accountIdToCaseMap.put( cs.AccountId , cs );
                }
                List<Case> casesToInsert = this.createCases( scope , accountIdToCaseMap );
                List<Database.SaveResult> results = Database.insert( casesToInsert , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_DunningCaseCreationBatch.class.getName() ,
                    'execute:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DunningCaseCreationBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //method to create cases
    private List<Case> createCases( List<blng__Invoice__c> scope , Map<String,Case> accountIdToCaseMap ) {
        List<Case> casesToInsert = new List<Case>();
        if ( ( scope != null )
            && !scope.isEmpty()
            && ( accountIdToCaseMap != null )
            )
        {
            for ( blng__Invoice__c inv : scope ) {
                //if account doesn't have a dunning case already and the account is not Insp. WO blng acc
                if ( ( inv.blng__Account__c != null )
                    && ( !accountIdToCaseMap.containsKey( inv.blng__Account__c ) )
                    && ( inv.blng__Account__r.Name != 'Insperity WO Billing Account' )
                    && ( inv.blng__BillToContact__c != null )
                    )
                {
                    Case dunCase = new Case();
                    dunCase.AccountId = inv.blng__Account__c;
                    dunCase.ContactId = inv.blng__BillToContact__c;
                    dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
                    dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
                    dunCase.recordTypeId = DUNNING_CASE_RT_ID;
                    dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
                    dunCase.Origin = NSP_BillingConstants.DUNNING;
                    duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
                    dunCase.OwnerId = NSP_DunningCaseCreationBatch.queueId;
                    dunCase.NSP_Category__c = 'Dunning';
                    dunCase.NSP_SubCategory__c = 'Delinquent Invoice';
                    casesToInsert.add( dunCase );
                    accountIdToCaseMap.put( inv.blng__Account__c,dunCase );
                }
            }
        }
        return casesToInsert;
    }

    //
    //
    //

    private static DunningCaseCreationBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = DunningCaseCreationBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( NSP_DunningCaseCreationBatch.settings != null ) {
                    local = NSP_DunningCaseCreationBatch.settings.IsEnabled__c;
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
                if ( ( NSP_DunningCaseCreationBatch.settings != null )
                    && ( NSP_DunningCaseCreationBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_DunningCaseCreationBatch.settings.BatchSize__c.intValue();
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

    private static Date cutOffDate {
        private get {
            if ( cutOffDate == null ) {
                Date local = System.today();
                if ( ( NSP_DunningCaseCreationBatch.settings != null )
                    && ( NSP_DunningCaseCreationBatch.settings.CutOffDate__c != null )
                    )
                {
                    local = NSP_DunningCaseCreationBatch.settings.CutOffDate__c;
                }
                cutOffDate = local;
            }
            return cutOffDate;
        }
        private set;
    }

    private static String queueId {
        private get {
            if ( ( queueId == null )
                && ( NSP_DunningCaseCreationBatch.settings != null )
                && ( NSP_DunningCaseCreationBatch.settings.IsEnabled__c )
                )
            {
                String local = '';
                List<Group> orderProcessingQueue = [
                    SELECT Id
                    FROM Group
                    WHERE (
                        ( Type = 'Queue' )
                        AND ( DeveloperName = 'NSP_Order_Processing_Queue' )
                    )
                    LIMIT 1
                ];
                if ( ( orderProcessingQueue != null ) && ( !orderProcessingQueue.isEmpty() ) ) {
                    local = orderProcessingQueue[0].Id;
                }
                queueId = local;
            }
            return queueId;
        }
        private set;
    }

}
//