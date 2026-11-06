// intentionally `without sharing` to preserve default sharing at api version 65...
public without sharing class NSP_DunningEmailNotificationsBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> , Database.Stateful {
    // test w/ NSP_DunningEmailNotificationsBatchTest (86%)

    private static final string STRING_CASE = 'Case';
    private Integer recordsProcessed = 0; // stores number of records processed.
    private Integer totalMailsSent = 0; // stores number of emails sent.
    private Integer emailFails = 0;//total number of exceptions from email service class
    private String queueId;

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_DunningEmailNotificationsBatch() {
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
            'NSP_DunningEmailNotificationsBatch ~ every Moday at 7:00 AM CT' + suffix ,
            '0 0 7 ? * MON *' ,
            new NSP_DunningEmailNotificationsBatch()
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
            new NSP_DunningEmailNotificationsBatch() ,
            NSP_DunningEmailNotificationsBatch.batchSize
        );
    }

    //
    // Batchable
    //

    // start method
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    AccountId ,
                    NSP_Dunning_Emails_Sent__c ,
                    NSP_Dunning_Automation__c ,
                    NSP_CSS_Email__c
                FROM Case
                WHERE (
                    ( Status != 'Closed' )
                    AND ( Origin = 'Dunning' )
                )
            ]
        );
    }

    // execute method
    public void execute( Database.BatchableContext bc , List<Case> scope ) {
        try {
            if ( NSP_DunningEmailNotificationsBatch.isEnabled
                && ( scope != null )
                )
            {
                //every chunk of scope has Dunning Cases from unique Accounts
                Set<Id> accounts = new Set<Id>();
                //get all accounts from Cases
                for ( Case cs : scope ) {
                    if ( cs.AccountId != null ) {
                        accounts.add( cs.AccountId );
                    }
                }
                //map of accounts and the oldest invoice due date on them
                Map<Id,Date> accountToOldestDueDate = new Map<Id,Date>();
                //use aggregate query to find oldest due invoice for the desired accounts
                for ( AggregateResult ar: [
                            SELECT
                                blng__Account__c ,
                                MIN(blng__DueDate__c) oldestDueDate
                            FROM blng__Invoice__c
                            WHERE (
                                ( blng__Account__c IN :accounts )
                                AND ( blng__Balance__c > 0 )
                                AND ( blng__InvoiceStatus__c = 'Posted' )
                                AND ( blng__DueDate__c < LAST_N_DAYS:30 )
                            )
                            GROUP BY blng__Account__c
                        ]
                    )
                {
                    if ( ( ar.get( 'blng__Account__c' ) != null )
                        && ( ar.get( 'oldestDueDate' ) != null )
                        )
                    {
                        accountToOldestDueDate.put(
                            (Id)ar.get( 'blng__Account__c' ) ,
                            (Date)ar.get( 'oldestDueDate' )
                        );
                    }
                }
                //store all parameters for Emails
                List<NSP_DunningEmailsMessageService.dunningEmailParams> allCasesForEmails = new List<NSP_DunningEmailsMessageService.dunningEmailParams>();
                List<Case> casesToUpdate = this.decideNotificationType(
                    scope ,
                    accountToOldestDueDate ,
                    allCasesForEmails
                );
                //send out emails and update case records
                this.callEmailService( allCasesForEmails , casesToUpdate );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DunningEmailNotificationsBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
        try {
            if ( NSP_DunningEmailNotificationsBatch.isEnabled ) {
                //THIS COMMENT IS INTENTIONAL. DO NOT DELETE.
                // This sends an email to Operations team DL.
                // Get the ID of the AsyncApexJob representing this batch job
                // from Database.BatchableContext.
                // Query the AsyncApexJob object to retrieve the current job's information.
                List<AsyncApexJob> asyncJobs = [
                    SELECT
                        Id ,
                        Status ,
                        NumberOfErrors ,
                        JobItemsProcessed ,
                        TotalJobItems ,
                        CreatedBy.Email
                    FROM AsyncApexJob
                    WHERE ( Id = :bc.getJobId() )
                ];
                if ( !asyncJobs.isEmpty() ) {
                    AsyncApexJob job = asyncJobs[0];
                    List<String> toAddresses = new List<String>{ job.CreatedBy.Email };
                    Map<String,Object> inputs = new Map<String,Object>();
                    inputs.put( 'toEmailAddresses' , toAddresses );
                    inputs.put( 'emailSubject' , 'Dunning Email Notifications Batch ' + job.Status );
                    inputs.put(
                        'emailBody' ,
                        'The batch Apex job processed ' + job.TotalJobItems
                        + ' batches with '+ job.NumberOfErrors + ' failures.'
                        + ' Total Records : ' + this.recordsProcessed
                        + ' Total Emails Sent : ' + this.totalMailsSent
                        + ' Total Email Fails : ' + this.emailFails
                    );
                    Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
                    sendEmailFlow.start();
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DunningEmailNotificationsBatch.class.getName() ,
                'finish' ,
                e
            );
        }
    }

    //method to decide Email Notification Template
    private List<Case> decideNotificationType(
        List<Case> scope ,
        Map<Id,Date> accountToOldestDueDate ,
        List<NSP_DunningEmailsMessageService.dunningEmailParams> allCasesForEmails
        )
    {
        List<Case> casesToUpdate = new List<Case>();
        if ( ( scope != null ) && ( accountToOldestDueDate != null ) ) {
            //for every case, use account and invoice due date map to find notification type
            for ( Case cs : scope ) {
                Boolean isCaseToUpdate = False;
                List<String> caseDunningEmailSent = this.getSentEmails( cs.NSP_Dunning_Emails_Sent__c );
                Integer maxDaysOverDue = this.getMaxDaysOverDue( accountToOldestDueDate , cs.AccountId );
                isCaseToUpdate = this.checkCaseForEmail(
                    maxDaysOverDue ,
                    caseDunningEmailSent ,
                    cs ,
                    allCasesForEmails
                );
                // setting field values to case record
                if ( isCaseToUpdate ) {
                    cs.NSP_Dunning_Emails_Sent__c = String.join( caseDunningEmailSent , ';' );
                    casesToUpdate.add( cs );
                }
            }
        }
        return casesToUpdate;
    }

    //method to extract history of sent emails
    private List<String> getSentEmails( String sentEmails ) {
        List<String> caseDunningEmailSent = new List<String>();
        if ( String.isNotBlank( sentEmails ) ) {
            caseDunningEmailSent = sentEmails.split( ';' );
        }
        return caseDunningEmailSent;
    }

    //method to find max days over due for the invoice
    private Integer getMaxDaysOverDue( Map<Id,Date> accountToOldestDueDate , String accountId ) {
        Integer maxDaysOverDue = 0;
        if ( ( String.isNotBlank( accountId ) )
            && ( accountToOldestDueDate != null )
            && accountToOldestDueDate.containsKey( accountId )
            )
        {
            maxDaysOverDue = accountToOldestDueDate.get( accountId ).daysBetween( Date.today() );
        }
        return maxDaysOverDue;
    }

    //method to check email template to use
    private Boolean checkCaseForEmail(
        Integer maxDaysOverDue , //due days for oldest invoice on account
        List<String> caseDunningEmailSent ,
        Case cs ,
        List<NSP_DunningEmailsMessageService.dunningEmailParams> allCasesForEmails
        )
    {
        Boolean isCaseToUpdate = False;
        if ( ( maxDaysOverDue != null )
            && ( maxDaysOverDue >= 45 )
            && ( caseDunningEmailSent != null )
            && ( cs != null )
            && ( allCasesForEmails != null )
            )
        {
            for ( Integer threshold : new List<Integer>{ 135 , 120 , 90 , 60 , 45 } ) {
                String dayLimit = String.valueOf( threshold ) + ' Days';
                if ( ( maxDaysOverDue >= threshold )
                    && ( !caseDunningEmailSent.contains( dayLimit ) )
                    && ( cs.NSP_Dunning_Automation__c == NSP_BillingConstants.AUTOMATED )
                    && ( threshold > this.extractLatestEmail( caseDunningEmailSent ) )
                    )
                {
                    NSP_DunningEmailsMessageService.dunningEmailParams currWrap = new NSP_DunningEmailsMessageService.dunningEmailParams(
                        'X' + String.valueOf( threshold ) + '_Days_Past_Due' ,
                        STRING_CASE ,
                        cs.Id
                    );
                    allCasesForEmails.add( currWrap );
                    caseDunningEmailSent.add( dayLimit );
                    isCaseToUpdate = true;
                    break; //limit iterations to send email for max threshold
                }

                if( ( maxDaysOverDue < threshold ) && ( caseDunningEmailSent.contains( dayLimit ) ) ){
                    caseDunningEmailSent.remove( caseDunningEmailSent.indexOf( dayLimit ) );
                }
            }
        }
        return isCaseToUpdate;
    }

    //method to extract last email that has been already sent
    private Integer extractLatestEmail( List<String> caseDunningEmailSent ) {
        List<Integer> daysList = new List<Integer>();
        if ( ( caseDunningEmailSent != null ) && !caseDunningEmailSent.isEmpty() ) {
            for ( String day : caseDunningEmailSent ) {
                daysList.add( Integer.valueOf( day.remove(' Days' ) ) );
            }
        }
        Integer lastEmail = 0;
        if ( !daysList.isEmpty() ) {
            daysList.sort();
            lastEmail = daysList[ daysList.size() - 1 ];
        }
        return lastEmail;
    }

    //method for calling the email service class and updating case records
    private void callEmailService(
        List<NSP_DunningEmailsMessageService.dunningEmailParams> allCasesForEmails ,
        List<Case> casesToUpdate
        )
    {
        try {
            // send emails & update cases
            if( allCasesForEmails != null && !allCasesForEmails.isEmpty() ) {
                //send out email
                List<Integer> emailsSummary = NSP_DunningEmailsMessageService.processDunningEmails( allCasesForEmails );
                if ( ( emailsSummary != null ) && !emailsSummary.isEmpty() ) {
                    this.totalMailsSent += emailsSummary[0];
                    this.emailFails += emailsSummary[1];
                }
                //update cases
                if ( !casesToUpdate.isEmpty() ) {
                    //update casesToUpdate
                    List<Database.SaveResult> res = Database.update( casesToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_DunningEmailNotificationsBatch.class.getName() ,
                        'callEmailService:update' ,
                        res
                    );
                    this.recordsProcessed += casesToUpdate.size();
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DunningEmailNotificationsBatch.class.getName() ,
                'callEmailService' ,
                e
            );
        }
    }

    //
    //
    //

    private static DunningEmailNotificationBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = DunningEmailNotificationBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_DunningEmailNotificationsBatch.settings != null ) {
                    local = NSP_DunningEmailNotificationsBatch.settings.IsEnabled__c;
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
                if ( ( NSP_DunningEmailNotificationsBatch.settings != null )
                    && ( NSP_DunningEmailNotificationsBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_DunningEmailNotificationsBatch.settings.BatchSize__c.intValue();
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

    public static Set<String> financeEmailAddresses {
        public get {
            if ( financeEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( ( NSP_DunningEmailNotificationsBatch.settings != null )
                    && String.isNotBlank( NSP_DunningEmailNotificationsBatch.settings.FinanceEmailAddresses__c )
                    )
                {
                    local = NSP_DunningEmailNotificationsBatch.settings.FinanceEmailAddresses__c.split( '\r\n' );
                }
                financeEmailAddresses = new Set<String>( local );
            }
            return financeEmailAddresses;
        }
        private set;
    }

}
//