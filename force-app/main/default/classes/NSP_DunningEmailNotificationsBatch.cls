public class NSP_DunningEmailNotificationsBatch implements Database.Batchable<sObject>, Database.Stateful {
    // test w/ NSP_DunningEmailNotificationsBatchTest (80%)

    static final string DunningCase_RT = 'Dunning';
    static final Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DunningCase_RT).getRecordTypeId();
    static final string STRING_CASE = 'Case';

    public Integer recordsProcessed = 0; // stores number of records processed.
    public Integer totalMailsSent = 0; // stores number of emails sent.
    public String query;
    public String queueId;

    public NSP_DunningEmailNotificationsBatch(){
        query = 'SELECT Id, CaseNumber, Status, ClosedDate, AccountId, Account.NSP_Max_Days_Overdue__c, NSP_Dunning_Emails_Sent__c, NSP_Dunning_Case_Invoice__c,NSP_Dunning_Automation__c,NSP_CSS_Email__c FROM Case WHERE Status!=\'Closed\' AND Account.NSP_Max_Days_Overdue__c > 30 AND Origin=\'Dunning\' AND RecordTypeId=:DUNNING_CASE_RT_ID';
    }

    // start method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //returns QueryLocator to execute method.
        return Database.getQueryLocator(query);
    }

    // execute method
    public void execute(Database.BatchableContext bc, List<Case> scope){
        try {
            List<NSP_DunningEmailsMessageService.dunningEmailParams> allCasesForEmails = new List<NSP_DunningEmailsMessageService.dunningEmailParams>();
            List<Case> casesToUpdate = new List<Case>();
            Map<String,String> accountToCSSEmail = new Map<String,String>();
            Set<Id> accountIDs = new Set<Id>();
            //adding account ids to set
            for(Case cs : scope ){
                accountIDs.add(cs.AccountId);
            }
            // querying Account Team Member with Role as CSS
            for (NSP_Account_Team__c accTeamMember : [SELECT Id, NSP_Email__c, NSP_First_Name__c, NSP_Last_Name__c, NSP_Account__c, NSP_Role__c, NSP_User__c FROM NSP_Account_Team__c WHERE NSP_Account__c IN:accountIDs AND NSP_Role__c='Customer Success Specialist']){
                if(accTeamMember.NSP_Email__c!=null){
                accountToCSSEmail.put(accTeamMember.NSP_Account__c, accTeamMember.NSP_Email__c);
                }
            }
            // looping through cases in batch scope 
            for(Case cs : scope ){
                recordsProcessed +=1;
                Boolean isCaseToUpdate = false;
                List<String> caseDunningEmailSent = new List<String>();
                if(String.isNotBlank(cs.NSP_Dunning_Emails_Sent__c)){
                    caseDunningEmailSent = cs.NSP_Dunning_Emails_Sent__c.split(';');
                }
                if(cs.NSP_Dunning_Automation__c == NSP_BillingConstants.AUTOMATED && !caseDunningEmailSent.contains('45 Days') && cs.Account.NSP_Max_Days_Overdue__c>=45) {
                    NSP_DunningEmailsMessageService.dunningEmailParams currWrap = new NSP_DunningEmailsMessageService.dunningEmailParams('X45_Days_Past_Due_Reminder',STRING_CASE,cs.Id);
                    allCasesForEmails.add(currWrap);
                    caseDunningEmailSent.add('45 Days');
                    isCaseToUpdate = true;
                } else if(cs.NSP_Dunning_Automation__c == NSP_BillingConstants.AUTOMATED && !caseDunningEmailSent.contains('60 Days') && cs.Account.NSP_Max_Days_Overdue__c>=60) {
                    NSP_DunningEmailsMessageService.dunningEmailParams currWrap = new NSP_DunningEmailsMessageService.dunningEmailParams('X60_Days_Past_Due',STRING_CASE,cs.Id);
                    allCasesForEmails.add(currWrap);
                    caseDunningEmailSent.add('60 Days');
                    isCaseToUpdate = true;
                } else if(cs.NSP_Dunning_Automation__c == NSP_BillingConstants.AUTOMATED && !caseDunningEmailSent.contains('90 Days') && cs.Account.NSP_Max_Days_Overdue__c>=90) {
                    NSP_DunningEmailsMessageService.dunningEmailParams currWrap = new NSP_DunningEmailsMessageService.dunningEmailParams('X90_Days_Past_Due',STRING_CASE,cs.Id);
                    allCasesForEmails.add(currWrap);
                    caseDunningEmailSent.add('90 Days');
                    isCaseToUpdate = true;
                    // Setting CSS Email on 90 Days
                    cs.NSP_CSS_Email__c = System.Label.NSP_CSS_Group_Email;
                    if(accountToCSSEmail.containsKey(cs.AccountId)) {
                        cs.NSP_CSS_Email__c = accountToCSSEmail.get(cs.AccountId);
                    }
                } else if(cs.NSP_Dunning_Automation__c == NSP_BillingConstants.AUTOMATED && !caseDunningEmailSent.contains('120 Days') && cs.Account.NSP_Max_Days_Overdue__c>=120) {
                    NSP_DunningEmailsMessageService.dunningEmailParams currWrap = new NSP_DunningEmailsMessageService.dunningEmailParams('X120_Days_Past_Due',STRING_CASE,cs.Id);
                    allCasesForEmails.add(currWrap);
                    caseDunningEmailSent.add('120 Days');
                    isCaseToUpdate = true;
                } else if(!caseDunningEmailSent.contains('135 Days') && cs.Account.NSP_Max_Days_Overdue__c>=135) {
                    NSP_DunningEmailsMessageService.dunningEmailParams currWrap = new NSP_DunningEmailsMessageService.dunningEmailParams('X135_Days_Past_Due',STRING_CASE,cs.Id);
                    allCasesForEmails.add(currWrap);
                    caseDunningEmailSent.add('135 Days');
                    isCaseToUpdate = true;
                } else {
                    //do nothing
                }
                // setting field values to case record
                if(isCaseToUpdate) {
                    cs.NSP_Dunning_Emails_Sent__c=String.join(caseDunningEmailSent,';');
                    casesToUpdate.add(cs);
                }
            }
            // send emails & update cases
            if(allCasesForEmails.size()>0) {
                Integer emailsSent = NSP_DunningEmailsMessageService.sendDunningEmailsWithCount(allCasesForEmails);
                totalMailsSent+=emailsSent;
                if(casesToUpdate.size()>0) {
                    NSP_CaseTriggerHandler.TriggerDisabled = true;
                    NSP_EmailMessageTriggerHandler.TriggerDisabled = true;
                    NSP_TaskTriggerHandler.TriggerDisabled = true;
                    //update casesToUpdate;
                    List<Database.SaveResult> res = Database.update(casesToUpdate,false);
                    NSP_ErrorLogHandler.logSaveResultsException('NSP_DunningEmailsMessageService', 'Update Case', res);
                }
            }
        } catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_DunningEmailNotificationsBatch','execute',ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc){
        System.debug('Mails Sent :'+totalMailsSent);
        System.debug('Records Processed :'+recordsProcessed);
        //THIS COMMENT IS INTENTIONAL. DO NOT DELETE.
        // This sends an email to Operations team DL. 
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob async = [
            SELECT Id , Status , NumberOfErrors , JobItemsProcessed , TotalJobItems , CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        //String opsEmail = Label.NSP_Operations_Team_DL;
        String[] toAddresses = new String[] {async.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Dunning Email Notifications Batch ' + async.Status);
        mail.setPlainTextBody(
            'The batch Apex job processed ' + async.TotalJobItems +
            ' batches with '+ async.NumberOfErrors + ' failures.' +
            'Total Records :'+recordsProcessed +
            'Total Emails Sent :'+totalMailsSent
        );
        try {
            Messaging.sendEmail( new Messaging.SingleEmailMessage[]{mail} );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DunningEmailNotificationsBatch.class.getName() ,
                'finish' ,
                e
            );
        }
    }

}
//