public with sharing class SetupAuditTrailQueueable implements Queueable {
    // test w/ SetupAuditTrailQueueableTest (90%)
    private static final String CLASS_NAME = ' ~ SetupAuditTrailQueueable';

    //
    // examples...
    //

    // SetupAuditTrailQueueable.enqueueJob( new List<Id>{ '005XXXXXXXXXXXXXXX' } );
    // SetupAuditTrailQueueable.enqueueJob( SetupAuditTrailQueueable.getSetupAuditTrailCreatedByIds() );
    // SetupAuditTrailQueueable.startReport();

    //
    // public entry points...
    //

    // generate summary report and one individual report for each User who created a SetupAuditTrail record in the last N hours...
    public static void startReport() {
        String METHOD_NAME = 'startReport';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ isEnabled=' + SetupAuditTrailQueueable.isEnabled );
        if ( SetupAuditTrailQueueable.isEnabled ) {
            List<Id> reportUserIds = SetupAuditTrailQueueable.getSetupAuditTrailCreatedByIds();
            SetupAuditTrailReport report = new SetupAuditTrailReport( reportUserIds );
            SetupAuditTrailQueueable.sendReportEmailStatic(
                report.getSubject() ,
                report.getBody()
            );
            SetupAuditTrailQueueable.enqueueJob( reportUserIds );
        }
    }

    // generate individual reports for the given Users...
    public static void enqueueJob( List<Id> jobUserIds ) {
        String METHOD_NAME = 'enqueueJob';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ isEnabled=' + SetupAuditTrailQueueable.isEnabled );
        if ( SetupAuditTrailQueueable.isEnabled
            && ( jobUserIds != null )
            && ( jobUserIds.size() > 0 )
           )
        {
            System.debug( DEBUG_PREFIX + ' ~ jobUserIds.size=' + jobUserIds.size() );
            if ( ! Test.isRunningTest() ) {
                System.enqueueJob( new SetupAuditTrailQueueable( jobUserIds ) );
            }
        }
    }

    // separated from class properties to support code coverage...
    public static void testEnqueueJob( List<Id> jobUserIds ) {
        if ( Test.isRunningTest() ) {
            System.enqueueJob( new SetupAuditTrailQueueable( jobUserIds ) );
        }
    }

    // Queueable Interface implementation...
    public void execute( QueueableContext context ) {
        String METHOD_NAME = 'execute';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ isEnabled=' + SetupAuditTrailQueueable.isEnabled );
        if ( SetupAuditTrailQueueable.IsEnabled ) {
            // process the first userId in the List...
            if ( ( this.userIds != null ) && ( this.userIds.size() > 0 ) ) {
                Id userId = this.userIds.remove( 0 );
                SetupAuditTrailReport report = new SetupAuditTrailReport( userId );
                if ( report.isNotBlank() ) {
                    this.sendReportEmail(
                        report.getSubject() ,
                        report.getBody()
                    );
                }
            }
            // re-enqueue the rest of the userIds in the List...
            if ( ( this.userIds != null ) && ( this.userIds.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ RE-ENQUEUE' );
                SetupAuditTrailQueueable.enqueueJob( this.userIds );
            }
        }
    }

    //
    // private attributes and methods...
    //

    // chain of User.Id values to evaluated...
    private List<Id> userIds { get; set; }

    // intentionally private constructor...  see enqueueJob method...
    private SetupAuditTrailQueueable( List<Id> reportUserIds ) {
        this.userIds = reportUserIds;
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionlly static to allow Custom Settings to modify the attributes a running Queueable chain...
    //

    private static SetupAuditTrailReporting__c settings {
        private get {
            if ( settings == null ) {
                settings = SetupAuditTrailReporting__c.getOrgDefaults();
            }
            return settings;
        }
        private set;
    }

    // is the Queueable enabled for execution???
    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( SetupAuditTrailQueueable.settings != null ) {
                    local = SetupAuditTrailQueueable.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    //
    //
    //

    // translates soqlHoursLimit into a specific DateTime value...
    public static DateTime startDateTime {
        public get {
            if ( startDateTime == null ) {
                startDateTime = System.now().addHours( -1 * SetupAuditTrailQueueable.soqlHoursLimit );
            }
            return startDateTime;
        }
        private set;
    }

    // how far back (in hours) should the audit be reported???
    public static Integer soqlHoursLimit {
        public get {
            if ( soqlHoursLimit == null ) {
                Integer local = 0;
                if ( ( SetupAuditTrailQueueable.settings != null ) && ( SetupAuditTrailQueueable.settings.SoqlHoursLimit__c != null ) ) {
                    local = SetupAuditTrailQueueable.settings.SoqlHoursLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlHoursLimit = local;
            }
            return soqlHoursLimit;
        }
        private set;
    }

    // what is the maximum number of User to include in the audit report???
    public static Integer soqlUserLimit {
        public get {
            if ( soqlUserLimit == null ) {
                Integer local = 0;
                if ( ( SetupAuditTrailQueueable.settings != null ) && ( SetupAuditTrailQueueable.settings.SoqlUserLimit__c != null ) ) {
                    local = SetupAuditTrailQueueable.settings.SoqlUserLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlUserLimit = local;
            }
            return soqlUserLimit;
        }
        private set;
    }

    // what is the maximum number of SetupAuditTrail records per User to include in the audit report???
    public static Integer soqlAuditLimit {
        public get {
            if ( soqlAuditLimit == null ) {
                Integer local = 0;
                if ( ( SetupAuditTrailQueueable.settings != null ) && ( SetupAuditTrailQueueable.settings.SoqlAuditLimit__c != null ) ) {
                    local = SetupAuditTrailQueueable.settings.SoqlAuditLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlAuditLimit = local;
            }
            return soqlAuditLimit;
        }
        private set;
    }

    // set of non-critical translated audit sections...
    public static Set<String> nonCriticalTranslatedSections {
        public get {
            if ( nonCriticalTranslatedSections == null ) {
                Set<String> local = new Set<String>();
                if ( SetupAuditTrailQueueable.settings != null ) {
                    String rawNonCriticalTranslatedSecions = SetupAuditTrailQueueable.settings.NonCriticalTranslatedSections__c;
                    if ( String.isNotBlank( rawNonCriticalTranslatedSecions ) ) {
                        List<String> splitNonCriticalTranslatedSecions = rawNonCriticalTranslatedSecions.split( '\r\n' );
                        if ( ( splitNonCriticalTranslatedSecions != null ) && ( splitNonCriticalTranslatedSecions.size() > 0 ) ) {
                            local.addAll( splitNonCriticalTranslatedSecions );
                        }
                    }
                }
                nonCriticalTranslatedSections = local;
            }
            return nonCriticalTranslatedSections;
        }
        private set;
    }

    //
    // summary report helper methods...
    //

    // which Users have created a SetupAuditTrail record...
    // ~ returns list of User.Id values sorted by User.Name...
    public static List<Id> getSetupAuditTrailCreatedByIds() {
        String METHOD_NAME = 'getSetupAuditTrailCreatedByIds';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        List<User> creators = [
            SELECT Id , Name , CreatedDate
            FROM User
            WHERE (
                Id IN (
                    SELECT CreatedById
                    FROM SetupAuditTrail
                    WHERE ( CreatedDate >= :SetupAuditTrailQueueable.startDateTime )
                )
            )
            ORDER BY Name ASC
            LIMIT :SetupAuditTrailQueueable.soqlUserLimit
        ];
        List<Id> auditUserIds = new List<Id>();
        if ( ( creators != null ) && ( creators.size() > 0 ) ) {
            for ( User creator : creators ) {
                auditUserIds.add( creator.Id );
            }
        }
        if ( auditUserIds != null ) {
            System.debug( DEBUG_PREFIX + ' ~ auditUserIds.size=' + auditUserIds.size() );
        }
        return auditUserIds;
    }

    //
    // email message helper methods...
    //

    private void sendReportEmail( String subject , String plainTextBody ) {
        SetupAuditTrailQueueable.sendReportEmailStatic(
            subject ,
            plainTextBody
        );
    }

    private static void sendReportEmailStatic( String subject , String plainTextBody ) {
        SetupAuditTrailQueueable.sendReportEmailStatic(
            SetupAuditTrailQueueable.auditorEmailAddresses ,
            subject ,
            plainTextBody
        );
    }

    private static void sendReportEmailStatic( List<String> toAddresses , String subject , String plainTextBody ) {
        String METHOD_NAME = 'sendReportEmailStatic';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ toAddresses=' + toAddresses );
        System.debug( DEBUG_PREFIX + ' ~ subject=' + subject );
        System.debug( DEBUG_PREFIX + ' ~ plainTextBody=' + plainTextBody );
        if ( ( toAddresses != null ) && ( toAddresses.size() > 0 ) ) {
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            if ( SetupAuditTrailQueueable.orgWideEmailAddressId != null ) {
                emailMessage.setOrgWideEmailAddressId( SetupAuditTrailQueueable.orgWideEmailAddressId );
            }
            emailMessage.setToAddresses( toAddresses );
            // ensure subject is not blank...
            if ( String.isBlank( subject ) ) {
                subject = DEBUG_PREFIX;
            }
            // conditionally prefix subject with Sandbox Name...
            if ( String.isNotBlank( SetupAuditTrailQueueable.sandboxName ) ) {
                subject = SetupAuditTrailQueueable.sandboxName + ': ' + subject;
            }
            emailMessage.setSubject( subject );
            // ensure body is not null...
            if ( String.isBlank( plainTextBody ) ) {
                plainTextBody = '';
            }
            // postfix timestamp on each report...
            plainTextBody += '\n[Report Generated: ' + System.now().format( 'EEEE, MMMM d, YYYY @ h:mm a z' , 'America/Los_Angeles' ) + ']\n';
            emailMessage.setPlainTextBody( plainTextBody );
            // send the report via email...
            try {
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ emailMessage } );
            } catch ( Exception e ) {
                System.debug( DEBUG_PREFIX + ' ~ CATCH ~ e=' + e );
                System.debug( DEBUG_PREFIX + ' ~ CATCH ~ emailMessage=' + emailMessage );
            }
        }
    }

    // which email address should receive the audit reports???
    private static List<String> auditorEmailAddresses  {
        get {
            if ( auditorEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( SetupAuditTrailQueueable.settings != null ) {
                    String rawAuditorEmailAddresses = SetupAuditTrailQueueable.settings.AuditorEmailAddresses__c;
                    if ( String.isNotBlank( rawAuditorEmailAddresses ) ) {
                        List<String> splitAuditorEmailAddresses = rawAuditorEmailAddresses.split( '\r\n' );
                        if ( ( splitAuditorEmailAddresses != null ) && ( splitAuditorEmailAddresses.size() > 0 ) ) {
                            local = splitAuditorEmailAddresses;
                        }
                    }
                }
                auditorEmailAddresses = local;
            }
            return auditorEmailAddresses;
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

    public static String sandboxName {
        public get {
            if ( sandboxName == null ) {
                String local = '';
                System.URL orgDomainUrl = System.URL.getOrgDomainUrl();
                if ( orgDomainUrl != null ) {
                    System.Domain orgDomain = System.DomainParser.parse( orgDomainUrl );
                    if ( ( orgDomain != null )
                        && String.isNotBlank( orgDomain.getSandboxName() )
                        )
                    {
                        local = orgDomain.getSandboxName();
                    }
                }
                if ( String.isNotBlank( local ) ) {
                    local = local.toUpperCase();
                }
                sandboxName = local;
            }
            return sandboxName;
        }
        private set;
    }

    //
    //
    //

    /*
    // SetupAuditTrailQueueable.debugFieldMaps();
    // validate NSP_SObject_Field_History__mdt records against the fieldMaps for each DescribeSObjectResult...
    // ~ identify any combination of (NSP_SObject_Name__c,NSP_Field_API_Name__c) that does not exist within the Org...
    public static void debugFieldMaps() {
        //
        // select all NSP_SObject_Field_History__mdt records...
        //
        List<NSP_SObject_Field_History__mdt> records = [
            SELECT Id , MasterLabel , DeveloperName , NSP_SObject_Name__c , NSP_Field_API_Name__c
            FROM NSP_SObject_Field_History__mdt
            ORDER BY NSP_SObject_Name__c ASC , NSP_Field_API_Name__c ASC
        ];
        System.debug( ' ~ records.size=' + records.size() );
        //
        // cache the DescribeSObjectResults for the minimum required SObjectTypes...
        //
        Set<String> sObjectNamesSet = new Set<String>();
        for ( NSP_SObject_Field_History__mdt record : records ) {
            sObjectNamesSet.add( record.NSP_SObject_Name__c );
        }
        System.debug( ' ~ sObjectNamesSet.size=' + sObjectNamesSet.size() );
        List<String> sObjectNames = new List<String>();
        sObjectNames.addAll( sObjectNamesSet );
        List<Schema.DescribeSObjectResult> describeResults = Schema.describeSObjects( sObjectNames );
        System.debug( ' ~ describeResults.size=' + describeResults.size() );
        Map<String,Map<String,Schema.SObjectField>> fieldMapMap = new Map<String,Map<String,Schema.SObjectField>>();
        for ( Schema.DescribeSObjectResult describeResult : describeResults ) {
            fieldMapMap.put(
                String.valueOf( describeResult.getSObjectType() ) ,
                describeResult.fields.getMap()
            );
        }
        System.debug( ' ~ fieldMapMap.size=' + fieldMapMap.size() );
        //
        // check each combination of (NSP_SObject_Name__c,NSP_Field_API_Name__c) against the cached field maps from each DescribeSObjectResult...
        //
        Map<String,Set<String>> missingTokenMap = new Map<String,Set<String>>();
        for ( NSP_SObject_Field_History__mdt record : records ) {
            String sObjectName = record.NSP_SObject_Name__c;
            String fieldName = record.NSP_Field_API_Name__c;
            Set<String> tokens = fieldMapMap.get( sObjectName ).keySet();
            if ( ! tokens.contains( fieldName.toLowerCase() ) ) {
                //
                // found a combination that does not exist within the Org...
                //
                if ( ! missingTokenMap.containsKey( sObjectName ) ) {
                    missingTokenMap.put( sObjectName , new Set<String>() );
                }
                Set<String> missingTokenSet = missingTokenMap.get( sObjectName );
                missingTokenSet.add( fieldName );
                missingTokenMap.put( sObjectName , missingTokenSet );
            }
        }
        System.debug( ' ~ missingTokenMap.size=' + missingTokenMap.size() );
        System.debug( ' ~ records.size=' + records.size() );
        //
        // output the summary information...
        //
        for ( String sObjectName : missingTokenMap.keySet() ) {
            Set<String> missingTokens = missingTokenMap.get( sObjectName );
            System.debug( ' ~ ' + missingTokens.size() + ' ~ missingTokenMap( ' + sObjectName + ' )=' + missingTokens );
        }
        //
        // output the missing sObject.Field combinations...
        //
        for ( String sObjectName : missingTokenMap.keySet() ) {
            for ( String missingToken : missingTokenMap.get( sObjectName ) ) {
                System.debug( ' ~ MISSING ~ ' + sObjectName + '.' + missingToken );
            }
        }
    }
    */

}
//