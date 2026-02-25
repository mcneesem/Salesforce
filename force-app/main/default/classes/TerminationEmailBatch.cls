public with sharing class TerminationEmailBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ TerminationEmailBatchTest (81%)

    //Constants for Email Template DeveloperNames
    private static final String TEMPLATE_INITIAL = 'Term_Letter_Initial';
    private static final String TEMPLATE_REVISED = 'Term_Team_Letter_Revised';
    private static final String TEMPLATE_REINSTATE_INITIAL = 'Term_Team_Reinstate_Letter_Initial';
    private static final String TEMPLATE_REINSTATE_REVISED = 'Term_Team_Reinstate_Letter_Revised';

    //Constants for RecordType DeveloperNames
    private static final String CREDIT_SPECIALIST = 'NSP_Credit_Specialist_Form';

    //Constants for Email Status Field Values
    private static final String EMAIL_STATUS_SENT = 'Email Sent';

    //
    // argument-free constructor is required to be "runnable"...
    //

    public TerminationEmailBatch() {
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
            'TerminationEmailBatch ~ every weekday at 5:00 PM CT' + suffix ,
            '0 0 17 ? * MON-FRI' ,
            new TerminationEmailBatch()
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
            new TerminationEmailBatch() ,
            TerminationEmailBatch.batchSize
        );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Set<String> recordTypeApiNames = new Set<String>{
            TerminationEmailBatch.CREDIT_SPECIALIST ,
            NSP_ServiceConstants.NSP_Payroll_Specialist_Form ,
            NSP_ServiceConstants.NSP_Client_Reinstatement
        };
        return Database.getQueryLocator(
            [
                SELECT
                    Client_Owner_Email__c ,
                    NSP_Revision__c ,
                    RecordType.DeveloperName ,
                    RecordTypeId ,
                    NSP_Status__c ,
                    Termination_Email_Status__c ,
                    NSP_Last_Date_Wages_Paid_Through__c
                FROM NSP_Termination_Form__c
                WHERE (
                    ( NSP_Status__c = :NSP_ServiceConstants.TERM_TEAM_APPROVED )
                    AND ( Termination_Email_Status__c = 'Ready to be sent' )
                    AND ( Client_Owner_Email__c != null )
                    AND ( NSP_Revision__c != null )
                    AND ( RecordType.DeveloperName IN :recordTypeApiNames )
                )
            ]
       );
    }

    public void execute( Database.BatchableContext bc, List<NSP_Termination_Form__c> forms ) {
        if ( TerminationEmailBatch.isEnabled
            && ( forms != null )
            && !forms.isEmpty()
            && String.isNotBlank( TerminationEmailBatch.orgWideEmailAddressId )
            )
        {
            Map<Id,ContentDocumentLink> docMap = this.getAttachments( forms );
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<NSP_Termination_Form__c> formsToUpdate = new List<NSP_Termination_Form__c>();
            for ( NSP_Termination_Form__c form : forms ) {
                String templateName = this.getTemplateName( form );
                ContentDocumentLink docLink = null;
                if ( docMap.containsKey( form.Id ) ) {
                    docLink = docMap.get( form.Id );
                }
                if ( ( TerminationEmailBatch.templateMap != null )
                    && TerminationEmailBatch.templateMap.containsKey( templateName )
                    && ( TerminationEmailBatch.templateMap.get( templateName ) != null )
                    )
                {
                    this.buildEmail(
                        form ,
                        TerminationEmailBatch.templateMap.get( templateName ) ,
                        docLink ,
                        emails
                    );
                }
            }
            this.sendAndProcessEmails( emails , forms , formsToUpdate );
            this.performDML( formsToUpdate );
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    private Map<Id,ContentDocumentLink> getAttachments( List<NSP_Termination_Form__c> forms ) {
        Map<Id,ContentDocumentLink> attachmentMap = new Map<Id,ContentDocumentLink>();
        if ( ( forms != null )
            && !forms.isEmpty()
            )
        {
            Set<Id> formIds = new Map<Id,NSP_Termination_Form__c>( forms ).keySet();
            for ( ContentDocumentLink link : [
                        SELECT
                            LinkedEntityId ,
                            ContentDocument.LatestPublishedVersionId
                        FROM ContentDocumentLink
                        WHERE (
                            ( LinkedEntityId IN : formIds )
                            AND ( ContentDocument.LatestPublishedVersion.Title LIKE 'LTR-%' )
                        )
                        ORDER BY SystemModstamp DESC
                    ]
                )
            {
                if ( !attachmentMap.containsKey( link.LinkedEntityId ) ) {
                    attachmentMap.put( link.LinkedEntityId , link );
                }
            }
        }
        return attachmentMap;
    }

    private void buildEmail(
        NSP_Termination_Form__c form ,
        Id templateId ,
        ContentDocumentLink docLink ,
        List<Messaging.SingleEmailMessage> emails
        )
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if ( ( form != null )
            && ( form.Id != null )
            && ( templateId != null )
            && String.isNotBlank( form.Client_Owner_Email__c )
            && ( form.RecordType != null )
            && String.isNotBlank( TerminationEmailBatch.orgWideEmailAddressId )
            )
        {
            List<Id> attachmentIds = new List<Id>();
            Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate( templateId , null , form.Id );
            email.setSubject( renderStoredEmailTemplate.getSubject() );
            email.setHtmlBody( renderStoredEmailTemplate.getHtmlBody() );
            email.setPlainTextBody( renderStoredEmailTemplate.getPlainTextBody() );
            email.setToAddresses( new List<String>{ form.Client_Owner_Email__c } );
            email.setOrgWideEmailAddressId( TerminationEmailBatch.orgWideEmailAddressId );
            email.setSaveAsActivity( true );
            email.setWhatId( form.Id );
            attachmentIds = this.getDefaultAttachments(
                form.NSP_Last_Date_Wages_Paid_Through__c ,
                form.RecordType.DeveloperName
            );
            if ( ( docLink != null )
                && ( docLink.ContentDocument != null )
                && ( docLink.ContentDocument.LatestPublishedVersionId != null )
                )
            {
                attachmentIds.add( docLink.ContentDocument.LatestPublishedVersionId );
            }
            if ( !attachmentIds.isEmpty() ) {
                email.setEntityAttachments( attachmentIds );
            }
        }
        if ( email != null ) {
            emails.add( email );
        }
    }

    private  List<Id> getDefaultAttachments( Date lastWagesPaidDate , String recordTypeDeveloperName ) {
        List<Id> attachmentIds = new List<Id>();
        if ( String.isNotBlank( recordTypeDeveloperName )
            && ( recordTypeDeveloperName != NSP_ServiceConstants.NSP_Client_Reinstatement )
            )
        {
            if ( lastWagesPaidDate != null ) {
                Integer year = lastWagesPaidDate.year();
                if ( ( year != null )
                    && ( TerminationEmailBatch.fileYearMap != null )
                    && TerminationEmailBatch.fileYearMap.containsKey( year )
                    && String.isNotBlank( TerminationEmailBatch.fileYearMap.get( year ) )
                    )
                {
                    attachmentIds.add( TerminationEmailBatch.fileYearMap.get( year ) );
                }
            }
            if ( TerminationEmailBatch.alwaysAttachedIds != null 
                && !( TerminationEmailBatch.alwaysAttachedIds.isEmpty() )
               )
            {
                attachmentIds.addAll( TerminationEmailBatch.alwaysAttachedIds );
            }
        }
        return attachmentIds;
    }

    private String getTemplateName( NSP_Termination_Form__c form ) {
        String templateName = '';
        if ( ( form != null )
            && ( form.RecordType != null )
            && String.isNotBlank( form.NSP_Revision__c )
            )
        {
            String rt = form.RecordType.DeveloperName;
            String rev = form.NSP_Revision__c;
            if ( ( rt == TerminationEmailBatch.CREDIT_SPECIALIST )
                || ( rt == NSP_ServiceConstants.NSP_Payroll_Specialist_Form )
                )
            {
                if ( rev == NSP_ServiceConstants.NO ) {
                    templateName = TerminationEmailBatch.TEMPLATE_INITIAL;
                } else if ( rev == NSP_ServiceConstants.YES ) {
                    templateName = TerminationEmailBatch.TEMPLATE_REVISED;
                }
            } else if ( rt == NSP_ServiceConstants.NSP_Client_Reinstatement ) {
                if ( rev == NSP_ServiceConstants.NO ) {
                    templateName = TerminationEmailBatch.TEMPLATE_REINSTATE_INITIAL;
                } else if ( rev == NSP_ServiceConstants.YES ) {
                    templateName = TerminationEmailBatch.TEMPLATE_REINSTATE_REVISED;
                }
            }
        }
        return templateName;
    }

    private void sendAndProcessEmails(
        List<Messaging.SingleEmailMessage> emailMessages ,
        List<NSP_Termination_Form__c> originalForms ,
        List<NSP_Termination_Form__c> formsToUpdate
        )
    {
        if ( ( emailMessages != null )
            && ( originalForms != null )
            && !emailMessages.isEmpty()
            && !originalForms.isEmpty()
            )
        {
            try{
                Messaging.SendEmailResult[] results = Messaging.sendEmail( emailMessages , false );
                system.debug('default attachments>>>>>>>>>>>>>>'+alwaysAttachedIds);
                system.debug('fileYearMap>>>>>>>>>>>>>>'+fileYearMap);
                for ( Integer i = 0; i < results.size(); i++ ) {
                    if ( results[i].isSuccess() ) {
                        NSP_Termination_Form__c form = originalForms[i];
                        if ( form != null ) {
                            form.Termination_Email_Status__c = EMAIL_STATUS_SENT;
                            formsToUpdate.add( form );
                        }
                    }
                }
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    TerminationEmailBatch.class.getName() ,
                    'sendAndProcessEmails' ,
                    e
                );
            }
        }
    }

    @testVisible()
    private void performDML( List<sObject> records ) {
        if ( ( records != null )
            && !records.isEmpty()
            )
        {
            try {
                List<Database.SaveResult> results = Database.update( records , false );
                NSP_ErrorLogHandler.logResults(
                    TerminationEmailBatch.class.getName() ,
                    'performDML:update' ,
                    results
                );
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    TerminationEmailBatch.class.getName() ,
                    'performDML' ,
                    e
                );
            }
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a running job...
    //

    private static TerminationEmailBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = TerminationEmailBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( TerminationEmailBatch.settings != null ) {
                    local = TerminationEmailBatch.settings.IsEnabled__c;
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
                if ( ( TerminationEmailBatch.settings != null )
                    && ( TerminationEmailBatch.settings.BatchSize__c != null )
                    )
                {
                    local = TerminationEmailBatch.settings.BatchSize__c.intValue();
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

    private static Id orgWideEmailAddressId {
        private get {
            if ( orgWideEmailAddressId == null ) {
                Id local = UserInfo.getUserId();
                if ( ( TerminationEmailBatch.settings != null )
                    && String.isNotBlank( TerminationEmailBatch.settings.OrgWideEmailAddressId__c )
                    && ( TerminationEmailBatch.settings.OrgWideEmailAddressId__c InstanceOf Id )
                    )
                {
                    Id checkId = Id.valueOf( TerminationEmailBatch.settings.OrgWideEmailAddressId__c );
                    if ( checkId.getSObjectType() == OrgWideEmailAddress.getSObjectType() ) {
                        local = checkId;
                    }
                }
                orgWideEmailAddressId = local;
            }
            return orgWideEmailAddressId;
        }
        private set;
    }

    private static List<Id> alwaysAttachedIds {
        private get {
            if ( alwaysAttachedIds == null ) {
                List<Id> local = new List<Id>();
                if ( ( TerminationEmailBatch.activeAttachments != null )
                    && !TerminationEmailBatch.activeAttachments.isEmpty()
                    )
                {
                    Set<Id> documentIds = new Set<Id>();
                    for ( Termination_Email_Attachment__mdt record : TerminationEmailBatch.activeAttachments ) {
                        if ( record.Is_Always_Attached__c
                            && String.isNotBlank( record.Document_Id__c )
                            && ( record.Document_Id__c InstanceOf Id )
                           )
                        {
                            Id checkId = Id.valueOf( record.Document_Id__c );
                            if ( checkId.getSObjectType() == ContentDocument.getSObjectType() ) {
                                documentIds.add( checkId );
                            }
                        }
                    }
                    if ( !documentIds.isEmpty() ) {
                        for ( ContentDocument file : [
                                    SELECT LatestPublishedVersionId
                                    FROM ContentDocument
                                    WHERE (
                                        ( Id = :documentIds )
                                        AND ( LatestPublishedVersionId != null )
                                    )
                                ]
                            )
                        {
                            local.add( file.LatestPublishedVersionId );
                        }
                    }
                }
                alwaysAttachedIds = local;
            }
            return alwaysAttachedIds;
        }
        private set;
    }

    private static Map<String,Id> templateMap {
        private get {
            if ( templateMap == null ) {
                Map<String,Id> temMap = new Map<String,Id>();
                Set<String> templateApiNames = new Set<String>{
                    TerminationEmailBatch.TEMPLATE_INITIAL ,
                    TerminationEmailBatch.TEMPLATE_REVISED ,
                    TerminationEmailBatch.TEMPLATE_REINSTATE_INITIAL ,
                    TerminationEmailBatch.TEMPLATE_REINSTATE_REVISED
                };
                for ( EmailTemplate template : [
                            SELECT DeveloperName
                            FROM EmailTemplate
                            WHERE ( DeveloperName IN :templateApiNames )
                        ]
                    )
                {
                    temMap.put( template.DeveloperName , template.Id );
                }
                templateMap = temMap;
            }
            return templateMap;
        }
        private set;
    }

    // Selection of all active Termination_Email_Attachment__mdt records...
    private static List<Termination_Email_Attachment__mdt> activeAttachments {
        private get {
            if ( activeAttachments == null ) {
                activeAttachments = [
                    SELECT
                        DeveloperName ,
                        MasterLabel ,
                        Active__c ,
                        Document_Id__c ,
                        Is_Always_Attached__c ,
                        Year__c
                    FROM Termination_Email_Attachment__mdt 
                    WHERE (
                        ( Active__c = true )
                        AND ( Document_Id__c != null )
                    )
                ];
            }
            return activeAttachments;
        }
        private set;
    }

    // Map from Year, as Integer, to ContentDocument.Id...
    private static Map<Integer,Id> documentYearMap {
        private get {
            if ( documentYearMap == null ) {
                Map<Integer,Id> local = new Map<Integer,Id>();
                if ( ( TerminationEmailBatch.activeAttachments != null )
                    && !TerminationEmailBatch.activeAttachments.isEmpty()
                    )
                {
                    for ( Termination_Email_Attachment__mdt record : TerminationEmailBatch.activeAttachments ) {
                        if ( ( record.Year__c != null )
                            && String.isNotBlank( record.Document_Id__c )
                            && ( record.Document_Id__c InstanceOf Id )
                           )
                        {
                            Id checkId = Id.valueOf( record.Document_Id__c );
                            if ( checkId.getSObjectType() == ContentDocument.getSObjectType() ) {
                                local.put(
                                    record.Year__c.intValue() ,
                                    checkId
                                );
                            }
                        }
                    }
                }
                documentYearMap = local;
            }
            return documentYearMap;
        }
        private set;
    }

    // Map from ContentDocument.Id to ContentDocument.LatestPublishedVersionId, which is-a ContentVersion.Id...
    private static Map<Id,Id> latestVersionMap {
        private get {
            if ( latestVersionMap == null ) {
                Map<Id,Id> local = new Map<Id,Id>();
                if ( ( TerminationEmailBatch.documentYearMap != null )
                    && !TerminationEmailBatch.documentYearMap.isEmpty()
                    )
                {
                    for ( ContentDocument file : [
                                SELECT LatestPublishedVersionId
                                FROM ContentDocument
                                WHERE (
                                    ( Id = :TerminationEmailBatch.documentYearMap.values() )
                                    AND ( LatestPublishedVersionId != null )
                                )
                            ]
                        )
                    {
                        local.put( file.Id , file.LatestPublishedVersionId );
                    }
                }
                latestVersionMap = local;
            }
            return latestVersionMap;
        }
        private set;
    }

    // Map from Year, as Integer, to ContentDocument.LatestPublishedVersionId, which is-a ContentVersion.Id...
    private static Map<Integer,Id> fileYearMap {
        private get {
            if ( fileYearMap == null ) {
                Map<Integer,Id> local = new Map<Integer,Id>();
                if ( ( TerminationEmailBatch.documentYearMap != null )
                    && !TerminationEmailBatch.documentYearMap.isEmpty()
                    && ( TerminationEmailBatch.latestVersionMap != null )
                    && !TerminationEmailBatch.latestVersionMap.isEmpty()
                    )
                {
                    for ( Integer year : TerminationEmailBatch.documentYearMap.keySet() ) {
                        Id documentId = TerminationEmailBatch.documentYearMap.get( year );
                        if ( ( documentId != null )
                            && TerminationEmailBatch.latestVersionMap.containsKey( documentId )
                            )
                        {
                            Id versionId = TerminationEmailBatch.latestVersionMap.get( documentId );
                            if ( versionId != null ) {
                                local.put( year , versionId );
                            }
                        }
                    }
                }
                fileYearMap = local;
            }
            return fileYearMap;
        }
        private set;
    }

}
//