public with sharing class SetupAuditTrailReportLine {
    // test w/ SetupAuditTrailReportLineTest (89%)
    private static final String CLASS_NAME = ' ~ SetupAuditTrailReportLine';

    public SetupAuditTrailReportLine( SetupAuditTrail auditRecord , User auditCreator ) {
        this.audit = auditRecord;
        this.creator = auditCreator;
    }

    public String getLine() {
        return this.line;
    }

    public String getSection() {
        return this.translatedSection;
    }

    public Boolean isCritical() {
        Boolean local = True;
        if ( String.isNotBlank( this.translatedSection )
            && ( this.nonCriticalTranslatedSections != null )
            && this.nonCriticalTranslatedSections.contains( this.translatedSection )
           )
        {
            local = False;
        }
        return local;
    }

    //
    //
    //

    private SetupAuditTrail audit { get; set; }

    private User creator { get; set; }

    // a formatted report line for the given SetupAuditTrail and User...
    private String line {
        private get {
            if ( line == null ) {
                String local = '';
                if ( ( this.audit != null )
                    && ( this.creator != null )
                   )
                {
                    String newLine = '\n';
                    local += '>>> ' + this.creator.Name;
                    if ( this.audit.CreatedDate != null ) {
                        local += ' on ' + this.audit.CreatedDate.format( 'EEEE, MMMM d, YYYY @ h:mm a z' , 'America/Los_Angeles' );
                    }
                    local += newLine;
                    local += 'Section: ' + this.lineSection + newLine;
                    local += 'Action: ' + this.audit.Action + newLine;
                    local += 'Display: ' + this.audit.Display + newLine;
                    if ( String.isNotBlank( this.audit.DelegateUser ) ) {
                        local += 'DelegateUser: ' + this.audit.DelegateUser;
                        if ( ( this.audit.CreatedBy != null )
                            && String.isNotBlank( this.audit.CreatedBy.Name )
                           )
                        {
                            local += ' logged-in-as ' + this.audit.CreatedBy.Name;
                        }
                        local += newLine;
                    }
                    if ( String.isNotBlank( this.audit.ResponsibleNamespacePrefix ) ) {
                        local += 'ResponsibleNamespacePrefix: ' + this.audit.ResponsibleNamespacePrefix + newLine;
                    }
                    if ( String.isNotBlank( this.audit.CreatedByContext ) ) {
                        local += 'CreatedByContext: ' + this.audit.CreatedByContext + newLine;
                    }
                    if ( String.isNotBlank( this.audit.CreatedByIssuer ) ) {
                        local += 'CreatedByIssuer: ' + this.audit.CreatedByIssuer + newLine;
                    }
                }
                line = local;
            }
            return line;
        }
        private set;
    }

    // a formatted audit section for the report line for the given SetupAuditTrail and User records...
    private String lineSection {
        private get {
            if ( lineSection == null ) {
                String local = '';
                if ( this.audit != null ) {
                    local = this.audit.Section;
                    if ( String.isNotBlank( this.translatedSection )
                        && ( this.translatedSection != local )
                       )
                    {
                        local += ' (' + this.translatedSection + ')';
                    }
                }
                lineSection = local;
            }
            return lineSection;
        }
        private set;
    }

    // a translated audit section to help explain the overly generic 'Manage Users' section...
    private String translatedSection {
        private get {
            if ( translatedSection == null ) {
                String local = '';
                if ( ( this.audit != null )
                    && ( this.creator != null )
                   )
                {
                    // identify special scenarios for various sections...
                    local = SetupAuditTrailReportLine.translateSection(
                        this.audit.Section ,
                        this.audit.Action ,
                        this.audit.Display ,
                        this.creator
                    );
                }
                translatedSection = local;
            }
            return translatedSection;
        }
        private set;
    }

    // separated from class properties to support code coverage...
    // ~ SetupAuditTrail records can't be created and are not constants, must be able to force every path thru this string-multiplexor...
    private static String translateSection( String section , String action , String display , User auditCreator ) {
        // identify special scenarios for various sections...
        String local = section;
        if ( String.isNotBlank( local )
            && String.isNotBlank( action )
            && String.isNotBlank( display )
           )
        {
            if ( local == 'Manage Users' ) {
                // ...translate 'Manage Users' section into...
                // ~ 'Permission Set Assignments'
                // ~ 'Permission Set License Assignments'
                // ~ 'Permission Change'
                // ~ 'Field-Level Security'
                // ~ 'Tab Visibility'
                // ~ 'Page Layout Assignments'
                // ~ 'Login-As Access'
                // ~ 'Self Management'
                if (
                    ( action == 'PermSetAssign' )
                    || ( action == 'PermSetUnassign' )
                )
                {
                    local = 'Permission Set Assignments';
                } else if (
                    ( action == 'PermSetLicenseAssign' )
                    || ( action == 'PermSetLicenseUnassign' )
                )
                {
                    local = 'Permission Set License Assignments';
                } else if ( action == 'changedpassword' ) {
                    local = 'Changed Password';
                } else if ( action.contains( 'PermChanged' ) ) {
                    local = 'Permission Change';
                } else if ( action.contains( 'FlsChanged' ) ) {
                    local = 'Field-Level Security';
                } else if ( action.contains( 'TabsetChanged' ) ) {
                    local = 'Tab Visibility';
                } else if ( action.contains( 'PageLayoutChanged' ) ) {
                    local = 'Page Layout Assignments';
                } else if ( display.contains( 'using Login-As access for' ) ) {
                    local = 'Login-As Access';
                } else if (
                    action.contains( auditCreator.Name )
                    || action.contains( auditCreator.Username )
                    || action.contains( String.valueOf( auditCreator.Id ).substring( 0 , 15 ) )
                )
                {
                    local = 'Self Management';
                }
            } else if (
                ( local == 'Custom Objects' )
                || local.startsWith( 'Customize ' )
            )
            {
                // ...translate 'Customize %sObjectType%' section into...
                if ( action.endsWith( 'layout' ) ) {
                    local = 'Page Layouts';
                }
            } else if ( local == 'Security Controls' ) {
                if ( action == 'remoteproxy' ) {
                    local = 'Remote Proxy';
                }
            }
        }
        return local;
    }

    // separated from class properties to support code coverage...
    // ~ SetupAuditTrail records can't be created and are not constants, must be able to force every path thru this string-multiplexor...
    public static String testTranslateSection( String section , String action , String display , User auditCreator ) {
        String local = null;
        if ( Test.isRunningTest() ) {
            local = translateSection( section , action , display , auditCreator );
        }
        return local;
    }

    // set of non-critical translated audit sections...
    private Set<String> nonCriticalTranslatedSections {
        private get {
            if ( nonCriticalTranslatedSections == null ) {
                nonCriticalTranslatedSections = SetupAuditTrailQueueable.nonCriticalTranslatedSections;
            }
            return nonCriticalTranslatedSections;
        }
        private set;
    }

}
//