/***************************************************************************************************/
/* @description : Batch class sends emails with attachments for approved termination forms.
/* @author : Masthan Bhogireddy
/* @date : 10/14/2025
/***************************************************************************************************/

public with sharing class TerminationEmailBatch implements ISelfSchedulable, Schedulable, Database.Batchable<SObject> {
    //test w/ TerminationEmailBatchTest (84%)

    //Constants for Email Template DeveloperNames
    private static final String TEMPLATE_INITIAL = 'Term_Letter_Initial';
    private static final String TEMPLATE_REVISED = 'Term_Team_Letter_Revised';
    private static final String TEMPLATE_REINSTATE_INITIAL = 'Term_Team_Reinstate_Letter_Initial';
    private static final String TEMPLATE_REINSTATE_REVISED = 'Term_Team_Reinstate_Letter_Revised';

    //Constants for RecordType DeveloperNames
    private static final String CREDIT_SPECIALIST = 'NSP_Credit_Specialist_Form';

    //Constants for Email Status Field Values
    private static final String EMAIL_STATUS_READY = 'Ready to be sent';
    private static final String EMAIL_STATUS_SENT = 'Email Sent';

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'TerminationEmailBatch ~ every weekday at 5:00 PM CT' + suffix,
            '0 0 17 ? * MON-FRI',
            new TerminationEmailBatch()
        );
    }

    public void execute( SchedulableContext scon ) {
        Database.executeBatch( new TerminationEmailBatch() , TerminationEmailBatch.batchSize );
    }
    
    public Database.QueryLocator start( Database.BatchableContext bc ) {

        Set<String> recordTypeApiNames = new Set<String>{ 
            TerminationEmailBatch.CREDIT_SPECIALIST,
            NSP_ServiceConstants.NSP_Payroll_Specialist_Form,
            NSP_ServiceConstants.NSP_Client_Reinstatement
        }; 

        return Database.getQueryLocator(
            [
            	SELECT Client_Owner_Email__c,
                    NSP_Revision__c,
                    RecordType.DeveloperName,
                    RecordTypeId,
                    NSP_Status__c,
                    Termination_Email_Status__c
                FROM NSP_Termination_Form__c
                WHERE NSP_Status__c =: NSP_ServiceConstants.TERM_TEAM_APPROVED
                AND Termination_Email_Status__c =: EMAIL_STATUS_READY
                AND Client_Owner_Email__c != null 
                AND NSP_Revision__c != null
                AND RecordType.DeveloperName IN: recordTypeApiNames 
            ]
       );
    }

    public void execute( Database.BatchableContext bc, List<NSP_Termination_Form__c> forms ) {

        if ( TerminationEmailBatch.isEnabled
            && forms != null
            && !forms.isEmpty()
            && String.isNotBlank( TerminationEmailBatch.orgWideEmailAddressId )
            
           )
        {
            Map<Id, ContentDocumentLink> docMap = getAttachments( forms );
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<NSP_Termination_Form__c> formsToUpdate = new List<NSP_Termination_Form__c>();
            
            for ( NSP_Termination_Form__c form : forms ) {
                String templateName = this.getTemplateName( form );
                ContentDocumentLink docLink = null;
                if ( docMap.containsKey( form.Id ) )
                {
                    docLink = docMap.get( form.Id );
                }
                if ( TerminationEmailBatch.templateMap != null
                    && TerminationEmailBatch.templateMap.containsKey( templateName ) 
                    && TerminationEmailBatch.templateMap.get( templateName ) != null
                   )
                {
                    this.buildEmail( form, TerminationEmailBatch.templateMap.get( templateName ), docLink, emails );
                }
            }
            
            this.sendAndProcessEmails( emails, forms, formsToUpdate );
            this.performDML( formsToUpdate );
        }
        
    }

    public void finish(Database.BatchableContext bc) {}

    private Map<Id, ContentDocumentLink> getAttachments( List<NSP_Termination_Form__c> forms ) {

        Map<Id, ContentDocumentLink> attachmentMap = new Map<Id, ContentDocumentLink>();

        if ( forms != null 
            && !forms.isEmpty()
           )
        {
            Set<Id> formIds = new Map<Id, NSP_Termination_Form__c>( forms ).keySet();
            for ( ContentDocumentLink link : [ SELECT LinkedEntityId, 
                                                   ContentDocument.LatestPublishedVersionId
                                               FROM ContentDocumentLink
                                               WHERE LinkedEntityId IN: formIds 
                                               AND ContentDocument.LatestPublishedVersion.Title LIKE 'LTR-%'
                                               ORDER BY SystemModstamp DESC 
                                             ]
                )
            {
                if ( !attachmentMap.containsKey( link.LinkedEntityId ) ) {
                    attachmentMap.put( link.LinkedEntityId, link );
                }
            }
        }

        return attachmentMap;
    }

    private void buildEmail( NSP_Termination_Form__c form,
                             Id templateId,
                             ContentDocumentLink docLink,
                             List<Messaging.SingleEmailMessage> emails
                           )
    {

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        if (form != null
            && form.Id != null
            && templateId != null
            && String.isNotBlank( form.Client_Owner_Email__c )
            && String.isNotBlank( TerminationEmailBatch.orgWideEmailAddressId )
           )
        {
            List<Id> attachmentIds = new List<Id>();
            Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate( templateId, null, form.Id );
            email.setSubject( renderStoredEmailTemplate.getSubject() );
            email.setHtmlBody( renderStoredEmailTemplate.getHtmlBody() );
            email.setPlainTextBody( renderStoredEmailTemplate.getPlainTextBody() );
            email.setToAddresses( new List<String>{ form.Client_Owner_Email__c } );
            email.setOrgWideEmailAddressId( TerminationEmailBatch.orgWideEmailAddressId );
            email.setSaveAsActivity( true );
            email.setWhatId( form.Id );
            if( TerminationEmailBatch.defaultTemplateAttachmentId != null ){
               attachmentIds.add( TerminationEmailBatch.defaultTemplateAttachmentId );
            }
            if( docLink != null &&
                docLink.ContentDocument != null &&
                docLink.ContentDocument.LatestPublishedVersionId != null
              )
            {
                attachmentIds.add( docLink.ContentDocument.LatestPublishedVersionId );
            }
            if( !attachmentIds.isEmpty() ){
                email.setEntityAttachments( attachmentIds );
            }
        }
        if ( email != null){
            emails.add(email);
        }
    }

    private String getTemplateName( NSP_Termination_Form__c form ) {

        String templateName = '';

        if ( form != null && form.RecordType != null
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

    private void sendAndProcessEmails( List<Messaging.SingleEmailMessage> emailMessages,
                                       List<NSP_Termination_Form__c> originalForms,
                                       List<NSP_Termination_Form__c> formsToUpdate 
                                     )
    {
        if ( emailMessages != null
            && originalForms != null
            && !emailMessages.isEmpty()
            && !originalForms.isEmpty()
           )
        {
            try{
                Messaging.SendEmailResult[] results = Messaging.sendEmail( emailMessages, false );
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
                    'sendAndProcessEmails:sendEmail' ,
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
    
    private static Id defaultTemplateAttachmentId {
        private get{
            if( defaultTemplateAttachmentId == null 
               && TerminationEmailBatch.settings != null
               && String.isNotBlank( TerminationEmailBatch.settings.DefaultTemplateAttachmentId__c )
               && TerminationEmailBatch.settings.DefaultTemplateAttachmentId__c InstanceOf Id )
            { 
                Id checkId = Id.valueOf( TerminationEmailBatch.settings.DefaultTemplateAttachmentId__c );
                if ( checkId.getSObjectType() == ContentVersion.getSObjectType() ) {
                    defaultTemplateAttachmentId = checkId;
                }
                defaultTemplateAttachmentId = TerminationEmailBatch.settings.DefaultTemplateAttachmentId__c;
            }
            return defaultTemplateAttachmentId;
        }
        private set;
    }
    
    private static Map<String, Id> templateMap {
        private get{
            if( templateMap == null )
            { 
                Map<String, Id> temMap = new Map<String, Id>();
                Set<String> templateApiNames = new Set<String>{ 
                    TerminationEmailBatch.TEMPLATE_INITIAL,
                        TerminationEmailBatch.TEMPLATE_REVISED,
                        TerminationEmailBatch.TEMPLATE_REINSTATE_INITIAL,
                        TerminationEmailBatch.TEMPLATE_REINSTATE_REVISED
                        };
                            
                            for ( EmailTemplate template : [ SELECT DeveloperName 
                                                            FROM EmailTemplate 
                                                            WHERE DeveloperName IN: templateApiNames
                                                           ]
                                )
                        {
                            temMap.put( template.DeveloperName, template.Id );
                        }
                templateMap = temMap;
                
            }
            return templateMap;
        }
        private set;
    }

}