/***************************************************************************************************/
/* @description : Batch class sends emails with attachments for approved termination forms.
/* @author : Masthan Bhogireddy
/* @date : 10/14/2025
/***************************************************************************************************/

public without sharing class TerminationEmailBatch implements ISelfSchedulable , Schedulable, Database.Batchable<SObject> {
    //test w/ TerminationEmailBatch_Test (82%)
    
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
    
    //Map for Termination Email Templates
    private Map<String, Id> templateMap = new MAP<String, Id>();
    
    private Id defaultTemplateAttachmentId;
    private static final String attachmentFilter = 'LTR-%';
    private String orgWideEmailId;
    
    public TerminationEmailBatch() { 
        Set<String> templateApiNames = new Set<String>{ 
            TEMPLATE_INITIAL, 
            TEMPLATE_REVISED,
            TEMPLATE_REINSTATE_INITIAL,
            TEMPLATE_REINSTATE_REVISED
         };       
         if( String.isNotBlank ( TerminationEmailBatch.OrgWideEmailDisplayName) ) {
             List<OrgWideEmailAddress> emails = [
                 SELECT Id 
                 FROM OrgWideEmailAddress
                 WHERE ( IsVerified = true AND DisplayName =: TerminationEmailBatch.OrgWideEmailDisplayName AND Address != NULL)
                 LIMIT 1
             ];
             if ( !emails.isEmpty() )
             {
                 orgWideEmailId = emails[0].Id;
             } else if( Test.isRunningTest() ){
                 orgWideEmailId = UserInfo.getUserId();
             }
         }
        for (EmailTemplate template : [ SELECT DeveloperName 
                                        FROM EmailTemplate 
                                        WHERE DeveloperName IN: templateApiNames
                                      ]
            )
        {
            this.templateMap.put(template.DeveloperName, template.Id);
        }
        
        if(String.isNotBlank(TerminationEmailBatch.defaultAttachmentName)){
            
            List<ContentVersion> contentVersions = [
                SELECT Id,
                    Title,
                    ContentDocumentId
                FROM ContentVersion
                WHERE Title =:TerminationEmailBatch.defaultAttachmentName
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];

            if (!contentVersions.isEmpty() && contentVersions != null) {
                defaultTemplateAttachmentId = contentVersions[0].Id;
            }

        }
    }
    
     
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Set<String> recordTypeApiNames = new Set<String>{ 
            CREDIT_SPECIALIST,
            NSP_ServiceConstants.NSP_Payroll_Specialist_Form,
            NSP_ServiceConstants.NSP_Client_Reinstatement
        }; 
        return Database.getQueryLocator([
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
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<NSP_Termination_Form__c> forms) {
        if ( forms !=null 
            && !forms.isEmpty()
            && String.isNotBlank( orgWideEmailId )
            && TerminationEmailBatch.isEnabled
           )
            
        {
            Map<Id, ContentDocumentLink> docMap = getAttachments(forms);
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<NSP_Termination_Form__c> formsToUpdate = new List<NSP_Termination_Form__c>();
            
            for (NSP_Termination_Form__c form : forms) {
                String templateName = getTemplateName(form);
                ContentDocumentLink docLink = new ContentDocumentLink();
                if(docMap.containsKey(form.Id)){
                    docLink = docMap.get(form.Id);
                }
                if ( this.templateMap.containsKey(templateName) && this.templateMap.get( templateName ) != null ){
                    buildEmail(form, this.templateMap.get(templateName),docLink,emails);
                }
            }
            
            sendAndProcessEmails(emails,forms,formsToUpdate);
            performDML(formsToUpdate);
        }
        
    }
    
    public void finish(Database.BatchableContext bc) {}
    
    private Map<Id, ContentDocumentLink> getAttachments(List<NSP_Termination_Form__c> forms) {
        Map<Id, ContentDocumentLink> attachmentMap = new Map<Id, ContentDocumentLink>();
        if( forms != null 
           && !forms.isEmpty()
        ){   
            Set<Id> formIds = new Map<Id, NSP_Termination_Form__c>(forms).keySet();
            for (ContentDocumentLink link : [
                SELECT LinkedEntityId, 
                ContentDocument.LatestPublishedVersionId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN: formIds 
                AND ContentDocument.LatestPublishedVersion.Title like: attachmentFilter
                ORDER BY SystemModstamp DESC 
            ] ) {
                if (!attachmentMap.containsKey(link.LinkedEntityId)) {
                    attachmentMap.put(link.LinkedEntityId, link);
                }
            }
        }
        return attachmentMap;
    }
    
    private void buildEmail(NSP_Termination_Form__c form, Id templateId, ContentDocumentLink docLink,List<Messaging.SingleEmailMessage> emails) {
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        if ( form != null 
            && templateId != null 
            && String.isNotBlank( form.Client_Owner_Email__c ) 
            && String.isNotBlank( orgWideEmailId )
           ) 
        { 
            List<Id> attachmentIds = new List<Id>();
            Messaging.SingleEmailMessage renderStoredEmailTemplate = Messaging.renderStoredEmailTemplate(templateId,null,form.Id );
            email.setSubject(renderStoredEmailTemplate.getSubject());
            email.setHtmlBody(renderStoredEmailTemplate.getHtmlBody());
            email.setPlainTextBody(renderStoredEmailTemplate.getPlainTextBody());
            email.setToAddresses(new List<String>{form.Client_Owner_Email__c});
            email.setOrgWideEmailAddressId( orgWideEmailId );
            email.setSaveAsActivity(true);
            email.setWhatId(form.Id);
            System.debug('defaultTemplateAttachmentId---->'+defaultTemplateAttachmentId);
            
            attachmentIds.add( defaultTemplateAttachmentId );
            if( docLink != null &&
                docLink.ContentDocument != null &&
                docLink.ContentDocument.LatestPublishedVersionId != null 
              ) 
            {  
                attachmentIds.add( docLink.ContentDocument.LatestPublishedVersionId );
            }
            if( !attachmentIds.isEmpty() ){
                email.setEntityAttachments(attachmentIds);
            }
        }
        if ( email != null){ 
            emails.add(email);
        }
    }
    
    private String getTemplateName(NSP_Termination_Form__c form) {
        String templateName = '';
        if (form != null && form.RecordType != null && String.isNotBlank(form.NSP_Revision__c)) {
            String rt = form.RecordType.DeveloperName;
            String rev = form.NSP_Revision__c;
            if ((rt == CREDIT_SPECIALIST || rt == NSP_ServiceConstants.NSP_Payroll_Specialist_Form) && rev == NSP_ServiceConstants.NO) {
                templateName = TEMPLATE_INITIAL;
            } else if ((rt == CREDIT_SPECIALIST || rt == NSP_ServiceConstants.NSP_Payroll_Specialist_Form) && rev == NSP_ServiceConstants.YES) {
                templateName = TEMPLATE_REVISED;
            } else if (rt == NSP_ServiceConstants.NSP_Client_Reinstatement && rev == NSP_ServiceConstants.NO) {
                templateName = TEMPLATE_REINSTATE_INITIAL;
            } else if (rt == NSP_ServiceConstants.NSP_Client_Reinstatement && rev == NSP_ServiceConstants.YES) {
                templateName = TEMPLATE_REINSTATE_REVISED;
            }
        }
        return templateName;
    }
    
    private void sendAndProcessEmails( List<Messaging.SingleEmailMessage> emailMessages,List<NSP_Termination_Form__c> originalForms, List<NSP_Termination_Form__c> formsToUpdate ) {
        if ( emailMessages != null
            && originalForms != null
            && !emailMessages.isEmpty()
            && !originalForms.isEmpty()
            && !Test.isRunningTest()
           )
        {
            try{
                system.debug('enter send emails'+emailMessages);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMessages, false);
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        NSP_Termination_Form__c form = originalForms[i];
                        if (form != null) {
                            form.Termination_Email_Status__c = EMAIL_STATUS_SENT;
                            formsToUpdate.add(form);
                        }
                    }else{
                        system.debug('issues'+results[i]);
                    }
                }
               
            } catch(Exception e){
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
        if ( ( records != null ) && !records.isEmpty() ) {
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
                    'performDML:updates' ,
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
    
    private static String OrgWideEmailDisplayName {
        private get{
            if( OrgWideEmailDisplayName == null){ 
               OrgWideEmailDisplayName = TerminationEmailBatch.settings.OrgWideEmailDisplayName__c;
            }
            return OrgWideEmailDisplayName;
        }
        private set;
    }
    
    private static String defaultAttachmentName {
        private get{
            if( defaultAttachmentName == null){ 
               defaultAttachmentName = TerminationEmailBatch.settings.DefaultAttachmentName__c;
            }
            return defaultAttachmentName;
        }
        private set;
    }
    
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
}