public class NSP_ContractRenewal_Batch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_ContractRenewal_Batch_Test (91%)

    private Integer recordsProcessed = 0; // stores number of records processed.
    private String query;
    private Map<String,NSP_Contract_Renewal_Configurations__mdt> productTypeToConfigMap = new Map<String,NSP_Contract_Renewal_Configurations__mdt>();
    private Map<String,String> userNameToIdMap = new Map<String,String>();

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_ContractRenewal_Batch() {
        //List to store products with renewal date ranges
        List<String> productsWith30DaysList = new List<String>();
        List<String> productsWith60DaysList = new List<String>();
        List<String> ownerUsernames = new List<String>();
        Map<String,NSP_Contract_Renewal_Configurations__mdt> renewalConfigs = NSP_Contract_Renewal_Configurations__mdt.getAll();
        if ( !renewalConfigs.isEmpty() ) {
            //looping through renewal configuration map to put in respective lists by date range
            for ( NSP_Contract_Renewal_Configurations__mdt configrec : renewalConfigs.values() ) {
                if ( configrec.NSP_Days_Before_Expiry__c == 30 ) {
                    productsWith30DaysList.add( configrec.NSP_Linked_ProductType__c );
                }
                if ( configrec.NSP_Days_Before_Expiry__c == 60 || configrec.DeveloperName == 'Sage' ) { // This static string is intentional. It might be removed in future.
                    productsWith60DaysList.add( configrec.NSP_Linked_ProductType__c );
                }
                this.productTypeToConfigMap.put( configrec.NSP_Linked_ProductType__c , configrec );
                ownerUsernames.add( configrec.NSP_Default_Opportunity_Owner__c );
            }
        }
        // get renewal owner user ids
        if ( !ownerUsernames.isEmpty() ) {
            for ( User usr : [
                        SELECT Id , Username
                        FROM User
                        WHERE ( Username IN :ownerUsernames )
                    ]
                )
            {
                this.userNameToIdMap.put( usr.Username , usr.Id );
            }
        }
        String days30ListasString = '(\'' + String.join( productsWith30DaysList , '\', \'' ) + '\')';
        String days60ListasString = '(\'' + String.join( productsWith60DaysList , '\', \'' ) + '\')';
        this.query = 'SELECT Id , SBQQ__RenewalForecast__c , SBQQ__RenewalQuoted__c , ContractTerm , NSP_Product_Type__c , SBQQ__ActiveContract__c ';
        this.query += 'FROM Contract ';
        this.query += 'WHERE ';
        this.query += '( SBQQ__RenewalForecast__c = false ) ';
        this.query += 'AND ( SBQQ__RenewalQuoted__c = false ) ';
        this.query += 'AND ( ContractTerm > 1 ) ';
        this.query += 'AND ( SBQQ__ActiveContract__c = 1 ) ';
        this.query += 'AND ( EndDate >= TODAY ) ';
        this.query += 'AND ( ';
        this.query += '    ( NSP_Product_Type__c INCLUDES ' + days30ListasString + ' AND EndDate <= NEXT_N_DAYS:30 ) ';
        this.query += '    OR ( NSP_Product_Type__c INCLUDES ' + days60ListasString + ' AND EndDate <= NEXT_N_DAYS:62 ) ';
        this.query += ')';
    }

    //
    // ISelfSchedulable
    //

    // runs monday at 5am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_ContractRenewal_Batch ~ create renewal opportunities and quotes based on renewal term and product type ~ monday at 5 AM' + suffix ,
            '0 0 5 ? * MON *' ,
            new NSP_ContractRenewal_Batch()
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
        if ( NSP_ContractRenewal_Batch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_ContractRenewal_Batch() ,
                NSP_ContractRenewal_Batch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator( this.query );
    }

    public void execute( Database.BatchableContext bc , List<Contract> scope ) {
        if ( NSP_ContractRenewal_Batch.isEnabled ) {
            try {
                for ( Contract contract : scope ) {
                    NSP_Contract_Renewal_Configurations__mdt contractRenewConfig = this.productTypeToConfigMap.get( contract.NSP_Product_Type__c );
                    if ( contractRenewConfig != null ) {
                        contract.SBQQ__RenewalForecast__c = true;
                        contract.SBQQ__RenewalQuoted__c = true;
                        contract.NSP_Customer_Signature_Required__c = contractRenewConfig.NSP_Renewal_Signature_Required__c;
                        if ( this.userNameToIdMap.containskey( contractRenewConfig.NSP_Default_Opportunity_Owner__c ) ) {
                            contract.SBQQ__RenewalOwner__c = this.userNameToIdMap.get( contractRenewConfig.NSP_Default_Opportunity_Owner__c );
                        }
                        this.recordsProcessed = ( this.recordsProcessed + 1 );
                    }
                }
                Database.SaveResult[] results = Database.update( scope , NSP_ContractRenewal_Batch.isAllOrNone );
                NSP_ErrorLogHandler.logResults(
                    NSP_ContractRenewal_Batch.class.getName() ,
                    'execute:update' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_ContractRenewal_Batch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        //THIS COMMENT IS INTENTIONAL. DO NOT DELETE.
        // This sends an email to Operations team DL. Will be used in Phase 2 when contracts are loaded into system.
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        if ( EmailDeliverabilityController.isEnabledOutbound ) {
            AsyncApexJob apexJob = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :BC.getJobId()
            ];
            // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {apexJob.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Contract Renewal Batch ' + apexJob.Status);
            mail.setPlainTextBody(
                'The batch Apex job processed ' + apexJob.TotalJobItems +
                ' batches with '+ apexJob.NumberOfErrors + ' failures.' +
                'Total Records :'+recordsProcessed
            );
            try {
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
            } catch ( Exception e ) {
                System.debug( ' ~ CATCH ~ e=' + e );
            }
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static ContractRenewalBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ContractRenewalBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( NSP_ContractRenewal_Batch.settings != null ) {
                    local = NSP_ContractRenewal_Batch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Boolean isAllOrNone {
        private get {
            if ( isAllOrNone == null ) {
                Boolean local = false;
                if ( NSP_ContractRenewal_Batch.settings != null ) {
                    local = NSP_ContractRenewal_Batch.settings.IsAllOrNone__c;
                }
                isAllOrNone = local;
            }
            return isAllOrNone;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                // batch size should be 1 because sbqq contract amendment api works for only 1 record...
                Integer local = 1;
                if ( ( NSP_ContractRenewal_Batch.settings != null )
                    && ( NSP_ContractRenewal_Batch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_ContractRenewal_Batch.settings.BatchSize__c.intValue();
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