public class NSP_InvoiceBatch implements Database.Batchable<SObject> , Database.Stateful , Schedulable {
    // test w/ NSP_InvoiceBatch_Test (84%)

    private Integer processedRecords = 0;
    private List<Id> invoiceIds = null;

    public NSP_InvoiceBatch() {
    }

    public NSP_InvoiceBatch( List<Id> local ) {
        this.invoiceIds = local;
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        if ( bc != null ) {
            AsyncApexJob job = this.selectAsyncApexJob( bc.getJobId() );
            this.sendEmailNotification(
                job ,
                'The batch apex job started.'
            );
        }
        Database.QueryLocator locator = Database.getQueryLocator(
            [
                SELECT Id , blng__InvoiceStatus__c
                FROM blng__Invoice__c
                WHERE (
                    blng__InvoiceStatus__c = 'Draft'
                    AND CreatedDate >= :NSP_InvoiceBatch.startDateTime
                    AND NSP_Invoice_External_ID__c = null
                )
            ]
        );
        if ( this.invoiceIds != null ) {
            locator = Database.getQueryLocator(
                [
                    SELECT Id , blng__InvoiceStatus__c
                    FROM blng__Invoice__c
                    WHERE (
                        blng__InvoiceStatus__c = 'Draft'
                        AND CreatedDate >= :NSP_InvoiceBatch.startDateTime
                        AND NSP_Invoice_External_ID__c = null
                        AND Id IN :this.invoiceIds
                    )
                ]
            );
        }
        return locator;
    }

    public void execute( Database.BatchableContext bc , List<blng__Invoice__c> scope ) {
        if ( NSP_InvoiceBatch.isEnabled ) {
            try {
                for ( blng__Invoice__c record : scope ) {
                    record.blng__InvoiceStatus__c = 'Posted';
                    this.processedRecords++;
                }
                List<Database.SaveResult> results = Database.update( scope , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_InvoiceBatch.class.getName() ,
                    'execute:update' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_InvoiceBatch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        if ( bc != null ) {
            AsyncApexJob job = this.selectAsyncApexJob( bc.getJobId() );
            this.sendEmailNotification(
                job ,
                'The batch apex job processed ' + job.TotalJobItems
                + ' batches with ' + job.NumberOfErrors + ' failures.'
                + ' Total Records :' + this.processedRecords
            );
        }
    }

    private AsyncApexJob selectAsyncApexJob( String jobId ) {
        List<AsyncApexJob> jobs = null;
        if ( String.isNotBlank( jobId ) ) {
            jobs = [
                SELECT Id , Status , NumberOfErrors , JobItemsProcessed , TotalJobItems , CreatedBy.Email
                FROM AsyncApexJob
                WHERE ( Id = :jobId )
            ];
        }
        AsyncApexJob job = null;
        if ( ( jobs != null ) && !jobs.isEmpty() ) {
            job = jobs[0];
        }
        return job;
    }

    private void sendEmailNotification( AsyncApexJob job , String plainTextBody ) {
        try {
            if ( EmailDeliverabilityController.isEnabledOutbound ) {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<String> toAddresses = new List<String>();
                if ( job != null ) {
                    toAddresses.add( job.CreatedBy.Email );
                } else {
                    toAddresses.add( UserInfo.getUserEmail() );
                }
                mail.setToAddresses( toAddresses );
                if ( ( NSP_InvoiceBatch.bccAddresses != null ) && !NSP_InvoiceBatch.bccAddresses.isEmpty() ) {
                    mail.setBccAddresses( NSP_InvoiceBatch.bccAddresses );
                }
                String statusSuffix = '';
                if ( job != null ) {
                    statusSuffix = ': ' + job.Status;
                }
                mail.setSubject( 'Draft Invoice Post Batch Job' + statusSuffix );
                if ( String.isBlank( plainTextBody ) ) {
                    plainTextBody = '.';
                }
                mail.setPlainTextBody( plainTextBody );
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_InvoiceBatch.class.getName() ,
                'sendEmailNotification' ,
                e
            );
        }
    }

    public void execute( SchedulableContext sc ) {
        if ( NSP_InvoiceBatch.isEnabled ) {
            Database.executeBatch(
                new NSP_InvoiceBatch() ,
                Integer.valueOf( NSP_InvoiceBatch.batchSize )
            );
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static InvoiceBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = InvoiceBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_InvoiceBatch.settings != null ) {
                    local = NSP_InvoiceBatch.settings.IsEnabled__c;
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
                if ( ( NSP_InvoiceBatch.settings != null )
                    && ( NSP_InvoiceBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_InvoiceBatch.settings.BatchSize__c.intValue();
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

    @AuraEnabled(cacheable=true)
    public static Integer getBatchSize() {
        return NSP_InvoiceBatch.batchSize;
    }

    private static List<String> bccAddresses  {
        private get {
            if ( bccAddresses == null ) {
                List<String> local = new List<String>();
                if ( NSP_InvoiceBatch.settings != null ) {
                    String rawBccAddresses = NSP_InvoiceBatch.settings.BccAddresses__c;
                    if ( String.isNotBlank( rawBccAddresses ) ) {
                        List<String> splitBccAddresses = rawBccAddresses.split( '\r\n' );
                        if ( ( splitBccAddresses != null ) && ( splitBccAddresses.size() > 0 ) ) {
                            local = splitBccAddresses;
                        }
                    }
                }
                bccAddresses = local;
            }
            return bccAddresses;
        }
        private set;
    }

    // translates soqlDaysLimit into a specific DateTime value...
    private static DateTime startDateTime {
        private get {
            if ( startDateTime == null ) {
                startDateTime = System.now().addHours( -1 * NSP_InvoiceBatch.soqlDaysLimit );
            }
            return startDateTime;
        }
        private set;
    }

    // how far back (in days) should be invoiced???
    private static Integer soqlDaysLimit {
        private get {
            if ( soqlDaysLimit == null ) {
                Integer local = 90;
                if ( ( NSP_InvoiceBatch.settings != null ) && ( NSP_InvoiceBatch.settings.SoqlDaysLimit__c != null ) ) {
                    local = NSP_InvoiceBatch.settings.SoqlDaysLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysLimit = local;
            }
            return soqlDaysLimit;
        }
        private set;
    }

}
//