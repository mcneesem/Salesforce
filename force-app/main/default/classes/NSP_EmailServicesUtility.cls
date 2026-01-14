// This class is used as a generic class to send emails by passing specific parameters like toAddress, ccAddress, templateId, etc.
public class NSP_EmailServicesUtility {
    // test w/ NSP_EmailServicesUtilityTest, NSP_EmailServiceTest (??%)
    // test w/ NSP_EmailServicesUtilityTest (36%)
    // test w/ NSP_EmailServiceTest (??%)

    // Iterates through all ClosedWon Opportunities and fetches the right email template API, TOs, CCs from custom metadata to send emails to the service team.
    public static void sendEmailsTOService(List<Opportunity> closedWonOpptyList, Map<Id,Opportunity> newOpportunityMap, List<String> workforceProductsList) {
        List<NSP_EmailTemplatesAndRecipientsMapping__mdt> emailTemplateMdtList = [SELECT Id,MasterLabel,DeveloperName,NSP_Email_Template_Name_API__c,
                                                                                  NSP_Is_MidMarket__c,NSP_MidMarket_National_Account__c,NSP_OpportunityProduct__c,
                                                                                  NSP_RecipientEmailIds_CC__c,NSP_Recipients_Email_Ids_TO__c
                                                                                  FROM NSP_EmailTemplatesAndRecipientsMapping__mdt
                                                                                  WHERE DeveloperName!=null];
        //Map to store Product vs CustomMetadata of template and primaryProduct
        Map<String, List<NSP_EmailTemplatesAndRecipientsMapping__mdt>> productTemplateMdtMap = new Map<String, List<NSP_EmailTemplatesAndRecipientsMapping__mdt>>();


        //creating map to store custom metadata for each type of Workforce products
        for(NSP_EmailTemplatesAndRecipientsMapping__mdt emailTemplateMdt : emailTemplateMdtList){

            if(productTemplateMdtMap.containsKey(emailTemplateMdt.NSP_OpportunityProduct__c)) {
                productTemplateMdtMap.get(emailTemplateMdt.NSP_OpportunityProduct__c).add(emailTemplateMdt);
            } else {
                productTemplateMdtMap.put(emailTemplateMdt.NSP_OpportunityProduct__c, new List<NSP_EmailTemplatesAndRecipientsMapping__mdt> {emailTemplateMdt});
            }
        }

        //Map to store opportunity and its corresponding EmailTemplate to be used
        Map<Id, String> opportunityIdEmailTemplateMap = new Map<Id, String>();
        Map<Id, NSP_EmailTemplatesAndRecipientsMapping__mdt> opptyMdtMap = new Map<Id, NSP_EmailTemplatesAndRecipientsMapping__mdt>();
        for(Opportunity opportunity : closedWonOpptyList){
            if(workforceProductsList.contains(opportunity.NSP_PrimaryProduct__c)){
                List<NSP_EmailTemplatesAndRecipientsMapping__mdt> templatesForProductList = productTemplateMdtMap.get(opportunity.NSP_PrimaryProduct__c);

                if(opportunity.NSP_PrimaryProduct__c=='WX'){
                    opportunityIdEmailTemplateMap.put(opportunity.Id, templatesForProductList[0].NSP_Email_Template_Name_API__c);
                    opptyMdtMap.put(opportunity.Id, templatesForProductList[0]);
                }else if(opportunity.NSP_PrimaryProduct__c=='WA'){
                    opportunityIdEmailTemplateMap.put(opportunity.Id, templatesForProductList[0].NSP_Email_Template_Name_API__c);
                    opptyMdtMap.put(opportunity.Id, templatesForProductList[0]);
                }else if(opportunity.NSP_PrimaryProduct__c=='WS' && opportunity.NSP_Number_of_Employees__c>=150){
                    opportunityIdEmailTemplateMap.put(opportunity.Id, templatesForProductList[0].NSP_Email_Template_Name_API__c);
                    opptyMdtMap.put(opportunity.Id, templatesForProductList[0]);
                }else{
                    for(NSP_EmailTemplatesAndRecipientsMapping__mdt customMdt : templatesForProductList){
                        if(opportunity.NSP_Number_of_Employees__c>=150 && customMdt.NSP_Is_MidMarket__c){
                            opportunityIdEmailTemplateMap.put(opportunity.Id, customMdt.NSP_Email_Template_Name_API__c);
                            opptyMdtMap.put(opportunity.Id, customMdt);
                        } else if(! customMdt.NSP_Is_MidMarket__c && opportunity.NSP_MidMarketNationalAccount__c == customMdt.NSP_MidMarket_National_Account__c){
                            opportunityIdEmailTemplateMap.put(opportunity.Id, customMdt.NSP_Email_Template_Name_API__c);
                            opptyMdtMap.put(opportunity.Id, customMdt);
                        }
                    }
                }
            }
        }//done creating opptyId : EmailTemplateNames

        generateEmailTemplates(opportunityIdEmailTemplateMap, opptyMdtMap,newOpportunityMap);
    }


    public static void generateEmailTemplates(Map<Id, String> opportunityIdEmailTemplateMap, Map<Id, NSP_EmailTemplatesAndRecipientsMapping__mdt> opptyMdtMap, Map<Id, Opportunity> newOpportunityMap){
        List<EmailTemplate> emailTemplateList = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body FROM EmailTemplate
                                                 WHERE DeveloperName IN :opportunityIdEmailTemplateMap.values()];
        //Map to store EmailTemplateDeveloperName as key and EmailTemplate record as its corresponding value
        Map<String, EmailTemplate> developerNameEmailTemplateMap = new Map<String, EmailTemplate>();

        //creating map of EmailTemplateDeveloperName and EmailTemplate record
        for(EmailTemplate emailTemplateRecord : emailTemplateList){
            developerNameEmailTemplateMap.put(emailTemplateRecord.DeveloperName, emailTemplateRecord);
        }


        List<Messaging.SingleEmailMessage> emailMessagesArray = new List<Messaging.SingleEmailMessage>();

        for(Id opptyId : opportunityIdEmailTemplateMap.keySet()){
            Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
            List<String> setCCList = New List<String>();
            List<String> setTOList = New List<String>();
            Id targetObjectId = newOpportunityMap.get(opptyId).OwnerId;
            EmailTemplate template = new EmailTemplate();
            if(newOpportunityMap.get(opptyId).NSP_PrimaryProduct__c == 'WX'  ||
                newOpportunityMap.get(opptyId).NSP_PrimaryProduct__c == 'WA' ){
                if(newOpportunityMap.get(opptyId).NSP_BPA__c != null){
                    setCCList.add(newOpportunityMap.get(opptyId).NSP_BPA__c);
                }
                if(newOpportunityMap.get(opptyId).NSP_DA_User__c != null){
                    setCCList.add(newOpportunityMap.get(opptyId).NSP_DA_User__c);
                }
                if(newOpportunityMap.get(opptyId).NSP_DM_User__c != null){
                    setCCList.add(newOpportunityMap.get(opptyId).NSP_DM_User__c);
                }
            }else{
                setCCList = opptyMdtMap.get(opptyId).NSP_RecipientEmailIds_CC__c.split(',');
            }

            if(String.isNotBlank(opptyMdtMap.get(opptyId).NSP_Recipients_Email_Ids_TO__c)){
                setTOList = opptyMdtMap.get(opptyId).NSP_Recipients_Email_Ids_TO__c.split(',');
            }else{
                setTOList.add(newOpportunityMap.get(opptyId).OwnerId);
            }

            template = developerNameEmailTemplateMap.get(opportunityIdEmailTemplateMap.get(opptyId));
            // Added as a part of Defect DF-01325
            List<Messaging.EmailFileAttachment> emailattachments=getOpportunityAttachments(opptyId);
            emailMessage = sendVFEmailTemplate(targetObjectId, setCCList, template, opptyId,emailattachments);
            emailMessage.setToAddresses(setTOList);
            emailMessage.setUseSignature(true);
            emailMessagesArray.add(emailMessage);
        }//done creating emailMessageList

        if(emailMessagesArray.size() > 0) {
            //boolean isEmailSuccess = sendEmailMessage(emailMessagesArray); //commented as a part of code scan
            sendEmailMessage(emailMessagesArray);
        }

    }




/*************************************
Method: sendVFEmailTemplate
Paratmenters: Id, String, EmailTemplate, Id
Description: create a dynamic email message for the given template, To and CC email users.
Return : Messaging.SingleEmailMessage
**************************************/
    public static Messaging.SingleEmailMessage sendVFEmailTemplate(Id ToEmailUserid, String[] ToCcEmailUsers, EmailTemplate template, Id ObjectForMergeFieldsId,List<Messaging.EmailFileAttachment> emailattachments){
        for(integer len=0; len<ToCcEmailUsers.size(); len++) {
            if(ToCcEmailUsers[len]==null){
                ToCcEmailUsers.remove(len);
            }
        }

        Messaging.SingleEmailMessage emailMessageToOwner = new Messaging.SingleEmailMessage();
        emailMessageToOwner.setTargetObjectId(ToEmailUserid);
        if(ToCcEmailUsers.size() > 0){
            emailMessageToOwner.setCcAddresses(ToCcEmailUsers);
        }
        emailMessageToOwner.setTemplateId(template.Id);
        emailMessageToOwner.setwhatId(ObjectForMergeFieldsId);
        emailMessageToOwner.setSaveAsActivity(false);
        if(!emailattachments.isEmpty()){
            emailMessageToOwner.setFileAttachments(emailattachments);
        }
        String orgwideEmailId = '';
        if(!String.isBlank(orgwideEmailId)){
            emailMessageToOwner.setOrgWideEmailAddressId(ID.valueOf(orgwideEmailId));
        }
        /*DF-105068:End*/

        Messaging.SingleEmailMessage[] emailMessages = new List<Messaging.SingleEmailMessage> {emailMessageToOwner};

        return emailMessageToOwner;
    }


    /*************************************
Class: EmailMessageWrapper
Description: Generic wrapper class to accommodate different number of parameters for both subject and the body text in an email template.
Provide different constructors to capture email information according to requirement.
**************************************/
    public class EmailMessageWrapper{
        public String senderDisplayName;
        public String[] toAddr;
        public String subject;
        public String body;
        public Map<String, String> mapSubjectParams;
        public Map<String, String> mapBodyParams;

        public EmailMessageWrapper(String senderDisplayName, String[] toAddr, String subject, String body, Map<String, String> mapSubjectParams, Map<String, String> mapBodyParams){
            this.senderDisplayName = senderDisplayName;
            this.toAddr = toAddr;
            this.subject = subject;
            this.subject = body;
            this.mapSubjectParams = mapSubjectParams;
            this.mapBodyParams = mapBodyParams;
        }
    }

    /*************************************
Method: sendDynamicEmailFromEmailTemplate
Paratmenters: List<EmailMessageWrapper> , Id
Description: Use this method to dynamically populate the data (subject and body) in an email template and send email based on email template.
Return : void
**************************************/
    public static void sendDynamicEmailFromEmailTemplate(List<EmailMessageWrapper> listEmailMessageWrapper, Id emailTemplateId){
        //boolean isEmailSent; //commented as part of code scan
        EmailTemplate emailTemplate;
        List<Messaging.Singleemailmessage> listSingleEmailMessages = new List<Messaging.Singleemailmessage>();

        if(emailTemplateId !=null){
            try{
                emailTemplate = [SELECT Id,Subject,HtmlValue,Body FROM EmailTemplate WHERE Id =:emailTemplateId];
            }
            catch(QueryException ex){
                NSP_CustomException.LogException(ex);
            }
        }

        //Loop through the emailMessageWarpper and dynamically set the subject and body content
        for (EmailMessageWrapper emailMessageWrapper : listEmailMessageWrapper){
            String subject = null;
            String plainBody = null;
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            if(emailTemplate !=null){
                mail.setTemplateID(emailTemplate.Id);
                subject = emailTemplate.Subject;
                plainBody = emailTemplate.Body;
            }
            mail.setSenderDisplayName(emailMessageWrapper.senderDisplayName);
            mail.setToAddresses(emailMessageWrapper.toAddr);
            /*DF-105068:Start*/
            String orgwideEmailId = '';//Label.OrgWideEmailAddressID;
            if(!String.isBlank(orgwideEmailId)){
                mail.setOrgWideEmailAddressId(ID.valueOf(orgwideEmailId));
            }
            /*DF-105068:End*/

            //Check if the email template subject is used or a custom subject is set by Apex code
            if(emailMessageWrapper.Subject != null){
                mail.setSubject(emailMessageWrapper.Subject);
                subject = emailMessageWrapper.Subject;
            }

            //Dynamically set the subject content by replacing the {!variable} defined in email template subject by the value of mapSubjectParams
            if(emailMessageWrapper.mapSubjectParams !=null){
                if(emailMessageWrapper.mapSubjectParams.size()>0){
                    for(String key: emailMessageWrapper.mapSubjectParams.keySet()){
                        subject = subject.replace(key, (emailMessageWrapper.mapSubjectParams.get(key) == null ? '' : emailMessageWrapper.mapSubjectParams.get(key)));
                    }
                }
            }
            mail.setSubject(subject);

            //Check if the email template body is used or a custom body is set by Apex code
            if(emailMessageWrapper.body !=null){
                mail.setPlainTextBody(emailMessageWrapper.body);
                plainBody = emailMessageWrapper.body;
            }

            //Dynamically set the body content by replacing the {!variable} defined in email template body by the value of mapBodyParams
            if(emailMessageWrapper.mapBodyParams !=null){
                if(emailMessageWrapper.mapBodyParams.size()>0){
                    for (String key : emailMessageWrapper.mapBodyParams.keySet()) {
                        plainBody = plainBody.replace(key, (emailMessageWrapper.mapBodyParams.get(key) == null) ? '' : emailMessageWrapper.mapBodyParams.get(key));
                    }
                }
            }
            mail.setPlainTextBody(plainBody);

            listSingleEmailMessages.add(mail);
            //isEmailSent = NSP_EmailServicesUtility.sendEmailMessage(listSingleEmailMessages); //commented as part of code scan
            NSP_EmailServicesUtility.sendEmailMessage(listSingleEmailMessages);
        }
    }

    public static boolean sendEmailMessage( Messaging.SingleEmailMessage[] emailMessages ) {
        Boolean isEmailSent = true;
        try {
            if ( EmailDeliverabilityController.isEnabledOutbound ) {
                Messaging.sendEmail( emailMessages );
            } else {
                isEmailSent = false;
            }
        } catch( System.EmailException e ) {
            isEmailSent = false;
        }
        return isEmailSent;
    }

    /***********************************************************************************************
    * MethodName: getOpportunityAttachments
    * Description : This method retreive the completed attachments for WX and WA Opportunity
    * Params:      String recordId
    * ********************************************************************************************/
    public static  List<Messaging.EmailFileAttachment> getOpportunityAttachments(String recordId){
    List<ContentDocumentLink> contentdocLinkList= [SELECT Id , ContentDocumentId FROM
                                                   ContentDocumentLink WHERE LinkedEntityId=:recordId ORDER BY SystemModstamp ASC ];
    Set<Id> contentDocumentIds = new Set<Id>();
    for(ContentDocumentLink cdl:contentdocLinkList){
        contentDocumentIds.add(cdl.ContentDocumentId);
    }

    List<ContentVersion> contentversionList=[SELECT Id, Title, FileType,versiondata  FROM contentversion
                                             WHERE ContentDocumentId IN: contentDocumentIds And IsLatest = true];

    List<Messaging.EmailFileAttachment> emailattachments = new List<Messaging.EmailFileAttachment>();
    List<String>WxfileAttachmentName=System.Label.NSP_OpportunityWXAttachmentName.split(',');
    List<String>WAfileAttachmentName=System.Label.NSP_OpportunityWAAttachmentName.split(',');
    if(!contentversionList.isEmpty() && (!WxfileAttachmentName.isEmpty()||!WAfileAttachmentName.isEmpty())){
        for(ContentVersion contentversions:contentversionList){
            if((contentversions.Title.contains(WxfileAttachmentName[0]) && contentversions.Title.contains(WxfileAttachmentName[1])
                && contentversions.Title.contains(WxfileAttachmentName[2])) ||
               (contentversions.Title.contains(WAfileAttachmentName[0]) && contentversions.Title.contains(WAfileAttachmentName[1]) &&
                contentversions.Title.contains(WAfileAttachmentName[2])) ){
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    Blob Data = contentversions.VersionData;
                    String AttachmentFileName=contentversions.Title+'.'+contentversions.FileType;
                    efa.setFileName(AttachmentFileName);
                    efa.setBody(Data);
                    emailattachments.add(efa);
                }
        }
    }
    return emailattachments;
    }
}