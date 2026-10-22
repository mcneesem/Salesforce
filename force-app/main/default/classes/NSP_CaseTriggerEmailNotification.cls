/***************************************************************************************************
* @Class            : NSP_CaseTriggerEmailNotification
* @Author           : Sumit
* @Version History  : 1.0
* @Creation         : 02/12/2022
* @Description      : This class is used for sending Case Email Notification
******************************************************************************************************/
public class NSP_CaseTriggerEmailNotification {
    // test w/ NSP_CaseTriggerEmailNotificationTest (87%)

    //Variable Declaration
    private static final String REQUEST_NOT_COMPLETE_TEMPLATE = 'NSP_Report_Dev_Case_Request_Not_Complete_Email';
    private static final String REFERRED_TO_EXISTING_TEMPLATE = 'NSP_Report_Dev_Case_Referred_to_Existing_Email';
    private static final String AWAITING_VERIFICATION_TEMPLATE = 'NSP_Report_Dev_Case_Awaiting_Verification_Email';
    private static final String MIGRATION_COMPLETE_TEMPLATE = 'NSP_Report_Dev_Case_Wire_Migration_Complete_Email';
    private static List<String> groupFields = new List<String>{'Id', 'Type','DeveloperName','Email'};

    /*
    * @Name        :  sendRequestNotCompleteMail
    * @Param       :  List<Case> caseList
    * @Return      :  void
    * @Description :  To send email when request is not complete
    */
    public static void sendRequestNotCompleteMail(List<Case> caseList){
        Set<Id> caseIdSet = new Set<Id>();
        List<String> toAddresses = new List<String>();
        String mailBody;
        List<String> fields = new List<String>{'Id'};
        Id templateId = NSP_sObjectSelector.selectByDeveloperName(fields, REQUEST_NOT_COMPLETE_TEMPLATE).Id;
        String queueEmail = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.REPORTDEVELOPMENT, groupFields).Email;
        String queueOwnerId;
        for(Case caseRecord : caseList){
            queueOwnerId = String.valueof(caseRecord.OwnerId);
            caseIdSet.add(caseRecord.Id);
            toAddresses.add(caseRecord.CreatedById);
            if(queueOwnerId.startsWith('00G')  && String.isNotBlank(queueEmail)){
                toAddresses.add(queueEmail);
            }
            if(queueOwnerId.startsWith('005')){
                toAddresses.add(caseRecord.OwnerId);
            }
        }

        if(!toAddresses.isEmpty() && templateId != null){
            mailBody = getMailBody(caseIdSet, templateId);
            sendMail(templateId, mailBody, caseList, toAddresses);
        }
    }

    /*
    * @Name        :  sendReferredToExistingEmail
    * @Param       :  List<Case> caseList
    * @Return      :  void
    * @Description :  To send Referred To Existing email
    */
    public static void sendReferredToExistingEmail(List<Case> caseList){
        Set<Id> caseIdSet = new Set<Id>();
        List<String> toAddresses = new List<String>();
        String mailBody;
        List<String> fields = new List<String>{'Id'};
        Id templateId = NSP_sObjectSelector.selectByDeveloperName(fields, REFERRED_TO_EXISTING_TEMPLATE).Id;
        String queueEmail = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.REPORTDEVELOPMENT, groupFields).Email;
        String queueOwnerId;
        for(Case caseRecord : caseList){
            queueOwnerId = String.valueof(caseRecord.OwnerId);
            caseIdSet.add(caseRecord.Id);
            toAddresses.add(caseRecord.CreatedById);
            if(queueOwnerId.startsWith('00G')  && String.isNotBlank(queueEmail)){
                toAddresses.add(queueEmail);
            }
            if(queueOwnerId.startsWith('005')){
                toAddresses.add(caseRecord.OwnerId);
            }
        }

        if(!toAddresses.isEmpty() && templateId != null){
            mailBody = getMailBody(caseIdSet, templateId);
            sendMail(templateId, mailBody, caseList, toAddresses);
        }
    }

    /*
    * @Name        :  sendAwaitingVerificationEmail
    * @Param       :  List<Case> caseList
    * @Return      :  void
    * @Description :  To send Awaiting Verification email
    */
    public static void sendAwaitingVerificationEmail(List<Case> caseList){
        Set<Id> caseIdSet = new Set<Id>();
        List<String> toAddresses = new List<String>();
        String mailBody;
        List<String> fields = new List<String>{'Id'};
        Id templateId = NSP_sObjectSelector.selectByDeveloperName(fields, AWAITING_VERIFICATION_TEMPLATE).Id;
        String queueEmail = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.REPORTDEVELOPMENT, groupFields).Email;
        String queueOwnerId;
        for(Case caseRecord : caseList){
            queueOwnerId = String.valueof(caseRecord.OwnerId);
            caseIdSet.add(caseRecord.Id);
            toAddresses.add(caseRecord.CreatedById);
            if(queueOwnerId.startsWith('00G')  && String.isNotBlank(queueEmail)){
                toAddresses.add(queueEmail);
            }
            if(queueOwnerId.startsWith('005')){
                toAddresses.add(caseRecord.OwnerId);
            }
        }

        if(!toAddresses.isEmpty() && templateId != null){
            mailBody = getMailBody(caseIdSet, templateId);
            sendMail(templateId, mailBody, caseList, toAddresses);
        }
    }

    /*
    * @Name        :  sendMigrationCompleteEmail
    * @Param       :  List<Case> caseList
    * @Return      :  void
    * @Description :  To send Migration Complete email
    */
    public static void sendMigrationCompleteEmail(List<Case> caseList){
        List<String> toAddresses = new List<String>();
        String mailBody;
        List<String> fields = new List<String>{'Id'};
        String queueOwnerId;
        Id templateId = NSP_sObjectSelector.selectByDeveloperName(fields, MIGRATION_COMPLETE_TEMPLATE).Id;
        String queueEmail = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.GroupType, NSP_ServiceConstants.REPORTDEVELOPMENT, groupFields).Email;
        for(Case caseRecord : caseList){
            queueOwnerId = String.valueof(caseRecord.OwnerId);

            if(queueOwnerId.startsWith('00G')  && String.isNotBlank(queueEmail)){

                    toAddresses.add(queueEmail);

            }
            if(queueOwnerId.startsWith('005')){
                toAddresses.add(caseRecord.OwnerId);
            }
            toAddresses.add(caseRecord.CreatedById);
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, null ,caseRecord.Id);
            mailBody=email.htmlbody;
        }

        if(!toAddresses.isEmpty() && templateId != null){
            sendMail(templateId, mailBody, caseList, toAddresses);
        }
    }

    /*
    * @Name        :  getMailBody
    * @Param       :  Set<Id> caseIdSet, Id templateId
    * @Return      :  String
    * @Description :  To get email body
    */
    private static String getMailBody(Set<Id> caseIdSet, Id templateId){
        String mailBody;
        List<String> caseIdList = new List<String>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        for(Id caseId : caseIdSet){
            caseIdList.add(caseId);
            email = Messaging.renderStoredEmailTemplate(templateId, null , caseId);
        }

        //Querying List of case related notes
        List<String> fields = new List<String>{ 'Id','CreatedBy.Name','CreatedDate','Case__c' };
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.NOTE_SOBJECT_TYPE, fields)
                        .addFilter('Case__c', caseIdList, NSP_QueryBuilder.Operator.INCLUDES)
                        .orderBy('createdDate', 'DESC', false).build();
        List<NSP_Note__c> notesList = (List<NSP_Note__c>)Database.query(query);

        if(!notesList.isEmpty()){
            for(NSP_Note__c note : notesList){
                email = Messaging.renderStoredEmailTemplate(templateId, null , note.Case__c);
            }
        }

        mailBody = email.htmlbody;
        if(!notesList.isEmpty()){
            mailBody += 'Case Notes<br/>';
            mailBody += '<table border="1"><tr><th>Note Created By</th><th>Note Created Date</th><th>Note</th></tr>';
            for(NSP_Note__c note : notesList){
                //Creating HTML table in body of email
                mailBody +='<tr><td>'+note.CreatedBy.Name+'</td><td>'+ note.CreatedDate+'</td></tr>';
            }
            mailBody += '</table><br/><br/>';
        }
        mailBody += 'Thank you,'+'<br/>';
        mailBody += 'The Report Development Team'+'<br/>';

        return mailBody;
    }

    //
    // @Name : sendMail
    // @Param : Id emailTemplateId, String htmlBody, List<Case> caseList, List<String> toAddresses
    // @Return : void
    // @Description : To send email with template structure
    //
    public static void sendMail( Id emailTemplateId , String htmlBody , List<Case> caseList , List<String> toAddresses ) {
        if ( EmailDeliverabilityController.isEnabledOutbound ) {
            //set template structure for the email template
            OrgWideEmailAddress orgWideAddress;
            List<String> ccAddresses = new List<String>{System.Label.NSP_Report_Dev_Team_CC_Address};
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
            try{
                if(Label.NSP_Report_Dev_OrgWideEmail != null && !Test.isRunningTest()){
                    List<String> orgWideEmailFields = new List<String>{'Id'};
                    String query = new NSP_QueryBuilder(NSP_ServiceConstants.ORG_WIDE_EMAIL_SOBJECT_TYPE, orgWideEmailFields)
                                    .addFilter('Address', Label.NSP_Report_Dev_OrgWideEmail).setSecurityEnforce(false).build();
                    orgWideAddress = Database.query(query);
                }
                for(Case caseRec : caseList){
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email= Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId() , caseRec.Id);
                    email.setTemplateId(emailTemplateId);
                    email.setToAddresses(toAddresses);
                    email.setHtmlBody(htmlBody);
                    email.setWhatId(caseRec.Id);
                    email.setSaveAsActivity(true);
                    email.setTargetObjectId(UserInfo.getUserId());
                    email.setTreatTargetObjectAsRecipient(false);
                    email.setUseSignature(false);
                    email.setCcAddresses(ccAddresses);
                    if(orgWideAddress != null && orgWideAddress.Id != null && !Test.isRunningTest()){
                        email.setOrgWideEmailAddressId(orgWideAddress.Id);
                    }
                    emailList.add(email);
                }
                if(emailList.size() > 0){
                    Messaging.sendEmail(emailList);
                }
            } catch (Exception ex) {
                NSP_ErrorLogHandler.logSaveException('NSP_CaseTriggerEmailNotification', 'sendMail', ex.getMessage());
            }
        }
    }

}