public with sharing class JobRunnerController {
    // test w/ JobRunnerControllerTest (92%)
    // test w/ JobRunnerEmailHandlerTest (15%)
    private static String CLASS_NAME = ' ~ JobRunnerController';
    private static String USE_JOB_RUNNER = 'Use_Job_Runner';
    private static String HORIZONTAL_RULE = '~~~~~~~~~~ ~~~~~~~~~~ ~~~~~~~~~~';

    private static Boolean hasPermission {
        private get {
            if ( hasPermission == null ) {
                hasPermission = CustomPermissionController.checkUserPermission(
                    JobRunnerController.USE_JOB_RUNNER ,
                    UserInfo.getUserId()
                );
            }
            return hasPermission;
        }
        private set;
    }

    //
    //
    //

    @AuraEnabled(cacheable=true)
    public static Boolean isAccessible() {
        return ( JobRunnerController.hasPermission && JobRunnerController.isEnabled );
    }

    @AuraEnabled(cacheable=true)
    public static Integer getPageSize() {
        return JobRunnerController.pageSize;
    }

    @AuraEnabled(cacheable=true)
    public static Integer getClickWaitingSeconds() {
        return JobRunnerController.clickWaitingSeconds;
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getBatchClassOptions() {
        List<Map<String,String>> options = new List<Map<String,String>>();
        if ( JobRunnerController.hasPermission
            && JobRunnerController.isEnabled
            )
        {
            // prepare a simple Map that can be converted to picklist options by the LWC...
            for ( ApexClass batchableClass : JobRunnerController.batchableClasses ) {
                options.add(
                    new Map<String,String>{
                        'label' => batchableClass.Name ,
                        'value' => batchableClass.Name
                    }
                );
            }
        }
        return options;
    }

    private static List<ApexClass> batchableClasses {
        private get {
            if ( batchableClasses == null ) {
                // find all Apex Classes that implement Batchable...
                batchableClasses = [
                    SELECT Id , Name
                    FROM ApexClass
                    WHERE (
                        ( NamespacePrefix = null )
                        AND ( IsValid = true )
                        AND (
                            Id IN (
                                SELECT ApexClassId
                                FROM ApexTypeImplementor
                                WHERE ( InterfaceName = 'Batchable' )
                            )
                        )
                    )
                    ORDER BY Name ASC
                ];
            }
            return batchableClasses;
        }
        private set;
    }

    // build a Set of lower-case tokens for easy confirmation of existing batchable classes...
    private static Set<String> batchableClassTokens {
        private get {
            if ( batchableClassTokens == null ) {
                // ensure Set is never null...
                Set<String> local = new Set<String>();
                if ( ( JobRunnerController.batchableClasses != null )
                    && !JobRunnerController.batchableClasses.isEmpty()
                    )
                {
                    for ( ApexClass batchableClass : JobRunnerController.batchableClasses ) {
                        local.add( batchableClass.Name.toLowerCase() );
                    }
                }
                batchableClassTokens = local;
            }
            return batchableClassTokens;
        }
        private set;
    }

    @AuraEnabled
    public static List<AsyncApexJob> getBatchJobStatuses( String batchClassName ) {
        List<AsyncApexJob> response = new List<AsyncApexJob>();
        if ( JobRunnerController.hasPermission
            && String.isNotBlank( batchClassName )
            && JobRunnerController.batchableClassTokens.contains( batchClassName.toLowerCase() )
            )
        {
            // select the recent executions of the given Batchable Apec Class, ignoring the worker threads...
            response = [
                SELECT
                    Id ,
                    JobType ,
                    Status ,
                    ExtendedStatus ,
                    TotalJobItems ,
                    NumberOfErrors ,
                    ApexClassId ,
                    ApexClass.Name ,
                    MethodName ,
                    JobItemsProcessed ,
                    CreatedBy.Name ,
                    CreatedDate ,
                    CompletedDate
                FROM AsyncApexJob
                WHERE (
                    ( ApexClass.Name = :batchClassName )
                    AND ( CreatedDate >= :JobRunnerController.createdDateTime )
                    AND ( JobType != 'BatchApexWorker' )
                )
                ORDER BY CreatedDate DESC
            ];
        }
        return response;
    }

    @AuraEnabled
    public static void requestJobExecution( String batchClassName ) {
        String message = 'No action performed.';
        if ( JobRunnerController.hasPermission
            && JobRunnerController.isEnabled
            && String.isNotBlank( batchClassName )
            && JobRunnerController.batchableClassTokens.contains( batchClassName.toLowerCase() )
            )
        {
            Boolean hasWaitingJobs = JobRunnerController.checkWaitingJobs( batchClassName );
            message = ( ( hasWaitingJobs ) ? 'Has waiting jobs.' : message );
            if ( !hasWaitingJobs ) {
                try {
                    // send email to service address that handles all job requests...
                    Messaging.SingleEmailMessage mail = JobRunnerController.prepareEmailMessage( batchClassName );
                    Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
                    // log results...
                    NSP_ErrorLogHandler.logInfo(
                        JobRunnerController.class.getName() ,
                        'requestJobExecution' ,
                        JSON.serializePretty( mail )
                    );
                    message = null; // blank message implies success in LWC (c-job-runner)...
                } catch ( Exception e ) {
                    message = e.getMessage();
                    NSP_ErrorLogHandler.logException(
                        JobRunnerController.class.getName() ,
                        'requestJobExecution' ,
                        e
                    );
                }
            }
        }
        if ( String.isNotBlank( message ) ) {
            throw new AuraHandledException( message );
        }
    }

    private static Messaging.SingleEmailMessage prepareEmailMessage( String requestedClassName ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if ( JobRunnerController.orgWideEmailAddressId != null ) {
            mail.setOrgWideEmailAddressId( JobRunnerController.orgWideEmailAddressId );
        }
        if ( String.isNotBlank( JobRunnerController.serviceAddress ) ) {
            mail.setToAddresses( new List<String>{ JobRunnerController.serviceAddress } );
        }
        if ( ( JobRunnerController.bccAddresses != null )
            && !JobRunnerController.bccAddresses.isEmpty()
            )
        {
            mail.setBccAddresses( JobRunnerController.bccAddresses );
        }
        mail.setSubject( 'Job Runner: ' + requestedClassName );
        String newLine = '\n';
        String plainTextBody = '';
        plainTextBody += 'Job Runner Requested Execution' + newLine;
        plainTextBody += JobRunnerController.HORIZONTAL_RULE + newLine;
        plainTextBody += 'ApexClass.Name:: ' + requestedClassName + newLine;
        plainTextBody += 'User:: ' + UserInfo.getName() + newLine;
        plainTextBody += 'User.Id:: ' + UserInfo.getUserId() + newLine;
        plainTextBody += 'User.Username:: ' + UserInfo.getUserName() + newLine;
        mail.setPlainTextBody( plainTextBody );
        return mail;
    }

    private static Boolean checkWaitingJobs( String requestedClassName ) {
        DateTime waitDateTime = System.now().addMinutes( -1 * JobRunnerController.jobWaitingMinutes );
        List<AsyncApexJob> waitingJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE (
                ( ApexClass.Name = :requestedClassName )
                AND ( CreatedDate >= :waitDateTime )
                AND ( JobType != 'BatchApexWorker' )
                AND ( Status NOT IN ( 'Aborted' , 'Completed' , 'Failed' ) )
            )
            ORDER BY CompletedDate DESC
        ];
        return ( ( waitingJobs != null ) && !waitingJobs.isEmpty() );
    }

    // see JobRunnerEmailHandler
    public static void handleJobRequest( Messaging.InboundEmail email , Messaging.InboundEnvelope envelope ) {
        if ( JobRunnerController.hasPermission
            && JobRunnerController.isEnabled
            )
        {
            try {
                // prepare a log for all attempts to execute a job via the service address...
                String requestDescription = JobRunnerController.describeJobRequest( email );
                // extract the Batch Apex Class name from the subject of the job request email...
                String requestedClassName = JobRunnerController.parseRequestedClassName( email );
                // confirm that the requested class exist in the Org...
                // and implements Batchable...
                // and ensure there are no waiting jobs...
                Id processId = null;
                if ( String.isNotBlank( requestedClassName )
                    && JobRunnerController.batchableClassTokens.contains( requestedClassName.toLowerCase() )
                    && !JobRunnerController.checkWaitingJobs( requestedClassName )
                    )
                {
                    // execute batch class as Deployment Manager...
                    Type requestedClassType = Type.forName( requestedClassName );
                    if ( requestedClassType != null ) {
                        processId = Database.executeBatch(
                            (Database.Batchable<SObject>)requestedClassType.newInstance() ,
                            JobRunnerController.batchSize
                        );
                    }
                }
                // log results...
                NSP_ErrorLogHandler.logInfo(
                    JobRunnerController.class.getName() ,
                    'handleJobRequest' ,
                    requestDescription + requestedClassName + '\n' + processId + '\n'
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    JobRunnerController.class.getName() ,
                    'handleJobRequest' ,
                    e
                );
            }
        }
    }

    private static String parseRequestedClassName( Messaging.InboundEmail email ) {
        String requestedClassName = null;
        if ( ( email != null ) && String.isNotBlank( email.subject ) ) {
            requestedClassName = email.subject.toLowerCase().remove( 're:' ).remove( 'fw:' ).remove( 'sandbox:' ).remove( 'job runner:').trim();
        }
        return requestedClassName;
    }

    private static String describeJobRequest( Messaging.InboundEmail email ) {
        String description = '';
        if ( email != null ) {
            String newLine = '\n';
            description += 'From Address: ' + email.fromAddress + newLine;
            description += 'From Name: ' + email.fromName + newLine;
            description += 'Reply To: ' + email.replyTo + newLine;
            description += 'To Addresses: ' + email.toAddresses + newLine;
            description += 'CC Addresses: ' + email.ccAddresses + newLine;
            description += 'Subject: ' + email.subject + newLine;
            description += JobRunnerController.HORIZONTAL_RULE + newLine;
            description += 'Plain Text Body: ' + newLine + email.plainTextBody + newLine;
            description += JobRunnerController.HORIZONTAL_RULE + newLine;
            description += 'HTML Body: ' + newLine + email.htmlBody + newLine;
            description += JobRunnerController.HORIZONTAL_RULE + newLine;
        }
        return description;
    }

    //
    //
    //

    private static JobRunnerSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = JobRunnerSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( JobRunnerController.settings != null ) {
                    local = JobRunnerController.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    // translates soqlDaysLimit into a specific DateTime value...
    private static DateTime createdDateTime {
        private get {
            if ( createdDateTime == null ) {
                createdDateTime = System.now().addDays( -1 * JobRunnerController.soqlDaysLimit );
            }
            return createdDateTime;
        }
        private set;
    }

    // how far back (in days) should be queried???
    private static Integer soqlDaysLimit {
        private get {
            if ( soqlDaysLimit == null ) {
                Integer local = 7;
                if ( ( JobRunnerController.settings != null )
                    && ( JobRunnerController.settings.SoqlDaysLimit__c != null )
                    )
                {
                    local = JobRunnerController.settings.SoqlDaysLimit__c.intValue();
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

    // how long (in minutes) should we wait to prevent re-enqueues???
    private static Integer jobWaitingMinutes {
        private get {
            if ( jobWaitingMinutes == null ) {
                Integer local = 10;
                if ( ( JobRunnerController.settings != null )
                    && ( JobRunnerController.settings.JobWaitingMinutes__c != null )
                    )
                {
                    local = JobRunnerController.settings.JobWaitingMinutes__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                jobWaitingMinutes = local;
            }
            return jobWaitingMinutes;
        }
        private set;
    }

    // how long (in seconds) should we wait to prevent re-clicks???
    private static Integer clickWaitingSeconds {
        private get {
            if ( clickWaitingSeconds == null ) {
                Integer local = 10;
                if ( ( JobRunnerController.settings != null )
                    && ( JobRunnerController.settings.ClickWaitingSeconds__c != null )
                    )
                {
                    local = JobRunnerController.settings.ClickWaitingSeconds__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                clickWaitingSeconds = local;
            }
            return clickWaitingSeconds;
        }
        private set;
    }

    private static Integer pageSize {
        private get {
            if ( pageSize == null ) {
                Integer local = 20;
                if ( ( JobRunnerController.settings != null )
                    && ( JobRunnerController.settings.PageSize__c != null )
                    )
                {
                    local = JobRunnerController.settings.PageSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                pageSize = local;
            }
            return pageSize;
        }
        private set;
    }

    // email address used to request a new job run...
    private static String serviceAddress {
        private get {
            if ( serviceAddress == null ) {
                String local = '';
                if ( ( JobRunnerController.settings != null )
                    && ( JobRunnerController.settings.ServiceAddress__c != null )
                    )
                {
                    local = JobRunnerController.settings.ServiceAddress__c;
                }
                serviceAddress = local;
            }
            return serviceAddress;
        }
        private set;
    }

    private static List<String> bccAddresses  {
        private get {
            if ( bccAddresses == null ) {
                List<String> local = new List<String>();
                if ( JobRunnerController.settings != null ) {
                    String rawBccAddresses = JobRunnerController.settings.BccAddresses__c;
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

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( JobRunnerController.settings != null )
                    && ( JobRunnerController.settings.BatchSize__c != null )
                    )
                {
                    local = JobRunnerController.settings.BatchSize__c.intValue();
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

    // identify the no-reply email address for current Org...
    private static Id orgWideEmailAddressId {
        private get {
            if ( orgWideEmailAddressId == null ) {
                List<OrgWideEmailAddress> orgWideEmailAddresses = [
                    SELECT Id
                    FROM OrgWideEmailAddress
                    WHERE ( Purpose IN ( 'DefaultNoReply' , 'UserSelectionAndDefaultNoReply' ) )
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
                if ( ( orgWideEmailAddresses != null ) && ( orgWideEmailAddresses.size() > 0 ) ) {
                    orgWideEmailAddressId = orgWideEmailAddresses[0].Id;
                }
            }
            return orgWideEmailAddressId;
        }
        private set;
    }

}
//