public with sharing class SetupAuditTrailReport {
    // test w/ SetupAuditTrailQueueableTest (95%)
    // test w/ SetupAuditTrailReportTest (93%)
    private static final String CLASS_NAME = ' ~ SetupAuditTrailReport';
    private static final String FORMAT_USER = 'FORMAT_USER';
    private static final String FORMAT_SUMMARY = 'FORMAT_SUMMARY';

    public SetupAuditTrailReport( Id auditCreatorId ) {
        this.format = SetupAuditTrailReport.FORMAT_USER;
        this.creatorId = auditCreatorId;
    }

    public SetupAuditTrailReport( List<Id> auditCreatorIds ) {
        this.format = SetupAuditTrailReport.FORMAT_SUMMARY;
        this.creatorIds = auditCreatorIds;
    }

    public String getSubject() {
        return this.subject;
    }

    public String getBody() {
        return this.body;
    }

    public Boolean isNotBlank() {
        return String.isNotBlank( this.body );
    }

    //
    //
    //

    private String format { get; set; }

    private Id creatorId { get; set; }

    private List<Id> creatorIds { get; set; }

    //
    //
    //

    private String subject {
        private get {
            if ( subject == null ) {
                String local = '';
                if ( this.format == SetupAuditTrailReport.FORMAT_SUMMARY ) {
                    local = 'SetupAuditTrail Report Summary ('
                        + System.now().format( 'EEEE, MMMM d, YYYY @ h:mm a z' , 'America/Los_Angeles' )
                        + ')';
                } else {
                    // default to FORMAT_USER...
                    String info = 'Unknown User (Id=' + this.creatorId + ')';
                    if ( this.creator != null ) {
                        info = this.creator.Name + ' (Id=' + this.creator.Id + ')';
                    }
                    local = 'SetupAuditTrail Report: ' + info;
                }
                subject = local;
            }
            return subject;
        }
        private set;
    }

    //
    //
    //

    private String body {
        private get {
            if ( body == null ) {
                String local = '';
                if ( this.format == SetupAuditTrailReport.FORMAT_SUMMARY ) {
                    local = this.bodySummary;
                } else {
                    // default to FORMAT_USER...
                    local = this.bodyUser;
                }
                body = local;
            }
            return body;
        }
        private set;
    }

    private String bodySummary {
        private get {
            if ( bodySummary == null ) {
                String local = '';
                if ( ( this.creatorIds != null ) && ( this.creatorIds.size() > 0 ) ) {
                    List<User> auditUsers = SetupAuditTrailReport.getUsers( this.creatorIds );
                    String reportLimit = '(Limit ' + SetupAuditTrailQueueable.soqlUserLimit + ' Users)';
                    reportLimit += ' (Last ' + SetupAuditTrailQueueable.soqlHoursLimit + ' Hours)';
                    String newLine = '\n';
                    String reportBody = '';
                    String reportSummary = 'No SetupAuditTrail Users Found ' + reportLimit + newLine;
                    if ( ( auditUsers != null ) && ( auditUsers.size() > 0 ) ) {
                        reportSummary = 'Found ' + auditUsers.size() + ' SetupAuditTrail Users ' + reportLimit + newLine;
                        for ( User reportUser : auditUsers ) {
                            reportBody += '* ' + reportUser.Name + ' (Id=' + reportUser.Id + ')' + ' (' + reportUser.Username + ')' + newLine;
                        }
                    }
                    if ( String.isNotBlank( reportSummary ) ) {
                        reportBody = reportSummary + reportBody;
                    }
                    local = reportBody;
                }
                bodySummary = local;
            }
            return bodySummary;
        }
        private set;
    }

    private String bodyUser {
        private get {
            String METHOD_NAME = 'bodyUser.get';
            String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
            if ( bodyUser == null ) {
                String local = '';
                if ( this.creator != null ) {
                    String newLine = '\n';
                    // prefix report with User information...
                    String reportUser = this.creator.Name +  + ' (' + this.creator.Username + ')' + newLine;
                    System.URL orgDomainUrl = System.URL.getOrgDomainUrl();
                    if ( orgDomainUrl != null ) {
                        reportUser += orgDomainUrl.toExternalForm() + '/' + this.creator.Id + newLine;
                    }
                    // construct report body from each SetupAuditTrail record created by the User...
                    List<String> reportLines = new List<String>();
                    String reportLimit = '(Last ' + SetupAuditTrailQueueable.soqlHoursLimit + ' Hours)';
                    String reportSummary = 'No SetupAuditTrails Found ' + reportLimit + newLine; // default summary...
                    if ( ( this.audits != null ) && ( this.audits.size() > 0 ) ) {
                        reportSummary = 'Found ' + this.audits.size() + ' SetupAuditTrails ' + reportLimit + newLine;
                        //
                        Map<String,Integer> reportAggregatedSections = new Map<String,Integer>();
                        for ( SetupAuditTrail audit : this.audits ) {
                            // build a report line for each SetupAuditTrail record...
                            SetupAuditTrailReportLine auditLine = new SetupAuditTrailReportLine(
                                audit ,
                                this.creator
                            );
                            // append the formatted report line to the report body...
                            // ~ omit non-critial lines within the report body...
                            if ( auditLine.isCritical() ) {
                                reportLines.add( auditLine.getLine() + newLine );
                            }
                            // aggregate the total record counts for each unique Section...
                            String aggregatedSection = auditLine.getSection();
                            if ( ! reportAggregatedSections.containsKey( aggregatedSection ) ) {
                                reportAggregatedSections.put( aggregatedSection , 0 );
                            }
                            Integer aggregatedSections = reportAggregatedSections.get( aggregatedSection );
                            aggregatedSections++;
                            reportAggregatedSections.put( aggregatedSection , aggregatedSections );
                        }
                        // prefix report with aggregated Section information...
                        // ~ sorted with most frequent Section first...
                        String reportSectionAggregation = '';
                        if ( ( reportAggregatedSections != null ) && ( reportAggregatedSections.size() > 0 ) ) {
                            List<SectionWrapper> sectionWrappers = new List<SectionWrapper>();
                            for ( String aggregatedSection : reportAggregatedSections.keySet() ) {
                                sectionWrappers.add( new SectionWrapper( aggregatedSection , reportAggregatedSections.get( aggregatedSection ) ) );
                            }
                            sectionWrappers.sort();
                            for ( SectionWrapper sectionWrapper : sectionWrappers ) {
                                reportSectionAggregation += '* ' + sectionWrapper.section + ': ' + sectionWrapper.value + newLine;
                            }
                        }
                        if ( String.isNotBlank( reportSectionAggregation ) ) {
                            reportSummary += reportSectionAggregation;
                        }
                    }
                    // finalize report body...
                    if ( ( reportLines != null ) && ( reportLines.size() > 0 ) ) {
                        if ( String.isNotBlank( reportUser ) ) {
                            local += reportUser + newLine;
                        }
                        if ( String.isNotBlank( reportSummary ) ) {
                            local += reportSummary + newLine;
                        }
                        local += String.join( reportLines , '' ) + newLine;
                    }
                }
                bodyUser = local;
            }
            return bodyUser;
        }
        private set;
    }

    private class SectionWrapper implements Comparable {
        private String section;
        private Integer value;
        private SectionWrapper( String section , Integer value ) {
            this.section = section;
            this.value = value;
        }
        public Integer compareTo( Object other ) {
            return ( ((SectionWrapper)other).value - value );
        }
    }

    //
    //
    //

    private User creator {
        private get {
            if ( ( creator == null ) && ( this.creatorId != null ) ) {
                creator = SetupAuditTrailReport.getUser( this.creatorId );
            }
            return creator;
        }
        private set;
    }

    private List<SetupAuditTrail> audits {
        private get {
            if ( ( audits == null ) && ( this.creator != null ) ) {
                List<SetupAuditTrail> local = new List<SetupAuditTrail>();
                if ( Test.isRunningTest() ) {
                 		local = [
                        SELECT
                        Id , Action , Section , Display ,
                        CreatedDate , CreatedById , CreatedBy.Name ,
                        DelegateUser , ResponsibleNamespacePrefix , CreatedByContext , CreatedByIssuer
                        FROM SetupAuditTrail
                        WHERE (
                            (
                                ( CreatedById = :this.creator.Id )
                                OR ( ( DelegateUser != null ) AND ( DelegateUser = :this.creator.Username ) )
                            )
                            AND ( CreatedDate >= :SetupAuditTrailQueueable.startDateTime )
                        )
                        ORDER BY CreatedDate DESC
                        LIMIT 10
                    ];
                } else {
                    local = [
                        SELECT
                        Id , Action , Section , Display ,
                        CreatedDate , CreatedById , CreatedBy.Name ,
                        DelegateUser , ResponsibleNamespacePrefix , CreatedByContext , CreatedByIssuer
                        FROM SetupAuditTrail
                        WHERE (
                            (
                                ( CreatedById = :this.creator.Id )
                                OR ( ( DelegateUser != null ) AND ( DelegateUser = :this.creator.Username ) )
                            )
                            AND ( CreatedDate >= :SetupAuditTrailQueueable.startDateTime )
                        )
                        ORDER BY CreatedDate DESC
                        LIMIT :SetupAuditTrailQueueable.soqlAuditLimit
                    ];
                }
                audits = local;
            }
            return audits;
        }
        private set;
    }

    //
    // User helper methods...
    //

    private static User getUser( Id recordId ) {
        String METHOD_NAME = 'getUser';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ recordId=' + recordId );
        User record = null;
        if ( recordId != null ) {
            List<User> records = SetupAuditTrailReport.getUsers( new List<Id>{ recordId } );
            if ( ( records != null ) && ( records.size() > 0 ) ) {
                record = records[0];
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ record=' + record );
        return record;
    }

    private static List<User> getUsers( List<Id> recordIds ) {
        String METHOD_NAME = 'getUsers';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ recordIds=' + recordIds );
        List<User> records = null;
        if ( recordIds != null ) {
            System.debug( DEBUG_PREFIX + ' ~ recordIds.size=' + recordIds.size() );
            records = [
                SELECT Id , Name , Username
                FROM User
                WHERE ( Id IN :recordIds )
                ORDER BY Name ASC
            ];
        }
        if ( records != null ) {
            System.debug( DEBUG_PREFIX + ' ~ records.size=' + records.size() );
        }
        return records;
    }

}
//