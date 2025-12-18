/**
Apex Class Name      :  NSP_NotificatonIESAlertsBatch
Version              :  1.0 
Author               :  Anil                                                                          
Created Date         :  12/01/22 
Function             :  Sends email when Sub Client Contact meets the specified conditions on Employee Status
Story                :  As part of STY-00542                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                      12/01/22                First Iteration
*/
public without sharing class NSP_NotificatonIESAlertsBatch implements Database.Batchable<sObject>, Schedulable  {
    // test w/ NSP_NotificatonIESAlertsBatch_Test (96%)

    private static final List<String> SUB_CLIENT_CONTACT_FIELDS = new List<String>{
        'Id',
        'NSP_Background_Contact__c',
        'NSP_Employee_Status__c',
        'NSP_Old_Employee_Status__c',
        'NSP_Employee_Status_Changed_Date__c',
        'NSP_Sub_Client__c',
        'NSP_Contact__c',
        'NSP_Contact__r.Name',
        'NSP_Contact__r.FirstName',
        'NSP_Contact__r.LastName',
        'NSP_Sub_Client__r.Name',
        'NSP_Sub_Client__r.NSP_Asset__c',
        'NSP_Sub_Client__r.NSP_Asset__r.Name',
        'NSP_Sub_Client__r.NSP_Sub_Client__c',
        'NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c',
        'NSP_Sub_Client__r.NSP_Asset__r.AccountId'
    };

    private static final String SUB_CLIENT_WO_ACTIVE = 'SubCientWoActive';
    private static final String SUB_CLIENT_WO_TERMINATED = 'SubCientWoTerminated';
    private static final String SUB_CLIENT_LOA = 'SubCientLOA';
    private static final String SUB_CLIENT_RETURNED_LOA = 'SubCientReturnedLOA';
    private static final String SUB_CLIENT_FLMA = 'SubCientFLMA';
    private static final String SUB_CLIENT_RETURNED_FLMA = 'SubCientReturnedFLMA';
    private static final String SUB_CLIENT_REHIRED = 'SubCientRehired';

    private static final String SUB_CLIENT_CONTACT_OBJECT_API_NAME = 'NSP_Sub_Client_Contact__c';
    private static Id recordTypeWOId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
    private static Map<String, Map<String, List<String>> > templateWithContIdSubCC = new Map<String, Map<String, List<String>> >();
    private static Map<String, String> contactIdWithName = new Map<String, String>();
    private static Set<String> accountIds = new Set<String>();
    @TestVisible static Integer emailLimits = 0;
    private static List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
    @TestVisible 
    private static NSP_NotificatonIESAlertsBatch.CheckSubClientContactTemplateCondition templateCondtions = new NSP_NotificatonIESAlertsBatch.CheckSubClientContactTemplateCondition();
    @TestVisible 
    private static NSP_NotificatonIESAlertsBatch.BuildEmailTemplates buildEmails = new NSP_NotificatonIESAlertsBatch.BuildEmailTemplates();


    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = new NSP_QueryBuilder(
                    SUB_CLIENT_CONTACT_OBJECT_API_NAME,
                    SUB_CLIENT_CONTACT_FIELDS
                )
                .addFilter('NSP_Sub_Client__r.NSP_Asset__r.RecordTypeId', recordTypeWOId)
                .addFilter('NSP_Background_Contact__c', TRUE)
                .setSecurityEnforce(false)
                .build();
                query += ' AND NSP_Employee_Status_Changed_Date__c = Today';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<NSP_Sub_Client_Contact__c> subClientContacts) {
        try {
            checkforEligibityRecords(subClientContacts);
            PrepareEmailTemplates();
            if ( EmailDeliverabilityController.IsEnabledOutbound ) {
                Messaging.sendEmail(lstEmailMessages);
            }
            emailLimits = Limits.getEmailInvocations();
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException(
                'NSP_NotificatonIESAlertsBatch',
                'execute',
                ex.getMessage()
            );
        }
    }

    /**
     * @description check for the EligibityRecords that matches the conditions for SubClientContacts
     */
    private static void checkforEligibityRecords(List<NSP_Sub_Client_Contact__c> subClientContacts) {
        for (NSP_Sub_Client_Contact__c subClientContact : subClientContacts) {
            //template condition A
            if(templateCondtions.isTerminatedSubCientWoActive(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_WO_ACTIVE);
            }
            //template condition B
            if(templateCondtions.isTerminatedSubCientWoTerminated(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_WO_TERMINATED);
            }
            //template condition C
            if(templateCondtions.isSubCientLOA(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_LOA);
            }
            //template condition D
            if(templateCondtions.isSubCientReturnedLOA(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_RETURNED_LOA);
            }
            //template condition E
            if(templateCondtions.isSubCientFLMA(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_FLMA);
            }
            //template condition F
            if(templateCondtions.isSubCientReturnedFLMA(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_RETURNED_FLMA);
            }
            //template condition G
            if(templateCondtions.isSubCientRehired(subClientContact)){
                prepareEligibityRecordsMap(subClientContact,SUB_CLIENT_REHIRED);
            }
        }
    }

    /**
     * @description prepare records for eachTemplate to Process for the templates
     */
    private static void prepareEligibityRecordsMap(NSP_Sub_Client_Contact__c subClientContact,String emailAlertName) {
        String aimsSubClient = subClientContact.NSP_Sub_Client__r.NSP_Sub_Client__c != null ? subClientContact.NSP_Sub_Client__r.NSP_Sub_Client__c : '';
        List<String> lstSubClientContacts = new List<String>();
        if(templateWithContIdSubCC.containsKey(emailAlertName)) {
            if(templateWithContIdSubCC.get(emailAlertName).containsKey(subClientContact.NSP_Contact__c)){
                lstSubClientContacts.addAll(templateWithContIdSubCC.get(emailAlertName)?.get(subClientContact.NSP_Contact__c));
                if(!lstSubClientContacts.contains(subClientContact.NSP_Sub_Client__r.Name +' ('+aimsSubClient+')')){
                    templateWithContIdSubCC.get(emailAlertName).get(subClientContact.NSP_Contact__c).add(subClientContact.NSP_Sub_Client__r.Name +' ('+aimsSubClient+')');
                }
            }else{
                templateWithContIdSubCC.get(emailAlertName).put(subClientContact.NSP_Contact__c, new List<String>{ subClientContact.NSP_Sub_Client__r.Name +' ('+aimsSubClient+')' });
            }
        } else {
            templateWithContIdSubCC.put(emailAlertName, new Map<String, List<String>>{
                subClientContact.NSP_Contact__c => new List<String>{ subClientContact.NSP_Sub_Client__r.Name +' ('+aimsSubClient+')' }
            });
        }
        accountIds.add(subClientContact.NSP_Sub_Client__r.NSP_Asset__r.AccountId);
        contactIdWithName.put(subClientContact.NSP_Contact__c, subClientContact.NSP_Contact__r.Name);
    }

    /**
     * @description prepare email templates for the Eligible Records
     */
    private static void prepareEmailTemplates(){
        //Template A
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_WO_ACTIVE)) {
            buildEmails.isTerminatedSubCientWoActiveEmail(templateWithContIdSubCC.get(SUB_CLIENT_WO_ACTIVE));
        }
        //Template B
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_WO_TERMINATED)) {
            buildEmails.isTerminatedSubCientWoTerminatedEmail(templateWithContIdSubCC.get(SUB_CLIENT_WO_TERMINATED));
        }
        //Template C
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_LOA)) {
            buildEmails.isSubCientLOAEmail(templateWithContIdSubCC.get(SUB_CLIENT_LOA));
        }
        //Template D
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_RETURNED_LOA)) {
            buildEmails.isSubCientReturnedLOAEmail(templateWithContIdSubCC.get(SUB_CLIENT_RETURNED_LOA));
        }
        //Template E
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_FLMA)) {
            buildEmails.isSubCientFLMAEmail(templateWithContIdSubCC.get(SUB_CLIENT_FLMA));
        }
        //Template F
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_RETURNED_FLMA)) {
            buildEmails.isSubCientReturnedFLMAEmail(templateWithContIdSubCC.get(SUB_CLIENT_RETURNED_FLMA));
        }
        //Template G
        if(templateWithContIdSubCC.containsKey(SUB_CLIENT_REHIRED)) {
            buildEmails.isSubCientRehiredEmail(templateWithContIdSubCC.get(SUB_CLIENT_REHIRED));
        }
    }

    /**
     * Build EmailTemplates for Notification email alerts for subclientcontact conditions
     */
    private without sharing class BuildEmailTemplates{

        //
        // @description a.If the "Employee Status" for the Sub Client Contact (SCC) 
        // where the contact is identified as a Background Contact is updated from <>TERMINATED to TERMINATED and the WO AIMS status = Active
        //
        public void isTerminatedSubCientWoActiveEmail(Map<String, List<String>> contIdWithSubCC) {
            for(Id contactId :  contIdWithSubCC.keySet()) {
                String body = contactIdWithName.get(contactId)+' has been terminated from '+ String.join(contIdWithSubCC.get(contactId), ', ')
                    +'. Please remove the contact as an authorized Background Screening recipient from your system.'
                    +'<br/><br/>Regards,<br/>'+ 
                    'Salesforce';
                prepareEmailTemplate(
                    'Background Screening Contact for '+String.join(contIdWithSubCC.get(contactId), ', ')+' has been Terminated', 
                    body
                );
            }
        }

        //
        // @description b.If the "Employee Status" for the SCC where the contact is identified 
        // as a Background Contact is updated from <>TERMINATED to TERMINATED and the WO AIMS status = TERMINATED
        //
        public void isTerminatedSubCientWoTerminatedEmail(Map<String, List<String>> contIdWithSubCC) {
            Map<String, Set<String>> accountWithScc = new Map<String, Set<String>>();
            Map<String,String> contactWithName = new Map<String,String>();
            Map<String,String> accountWithWOAsset = new Map<String,String>();

            String query = new NSP_QueryBuilder(
                    SUB_CLIENT_CONTACT_OBJECT_API_NAME,
                    SUB_CLIENT_CONTACT_FIELDS
                )
                .addFilter('NSP_Background_Contact__c', TRUE)
                .addFilter('NSP_Sub_Client__r.NSP_Account__c', new List<String>(accountIds) , NSP_QueryBuilder.Operator.INCLUDES)                
                .build();

            for(NSP_Sub_Client_Contact__c subcc: Database.Query(query)){
                String aimsSubClient = subcc.NSP_Sub_Client__r.NSP_Sub_Client__c != null ? subcc.NSP_Sub_Client__r.NSP_Sub_Client__c : '';
                if(accountWithScc.containsKey(subcc.NSP_Sub_Client__r.NSP_Asset__r.AccountId)){
                    accountWithScc.get(subcc.NSP_Sub_Client__r.NSP_Asset__r.AccountId)
                        .add(subcc.NSP_Sub_Client__r.Name +' ('+aimsSubClient+')');
                }else{
                    accountWithScc.put(subcc.NSP_Sub_Client__r.NSP_Asset__r.AccountId, new Set<String>{
                        subcc.NSP_Sub_Client__r.Name +' ('+aimsSubClient+')' 
                    });
                }
                contactWithName.put(subcc.NSP_Sub_Client__r.NSP_Asset__r.AccountId, subcc.NSP_Contact__r.Name);
                accountWithWOAsset.put(subcc.NSP_Sub_Client__r.NSP_Asset__r.AccountId, subcc.NSP_Sub_Client__r.NSP_Asset__r.Name+' '+subcc.NSP_Sub_Client__r.NSP_Sub_Client__c);
            }
            
            for(Id accId :  accountWithScc.keySet()) {
                List<String> subClients = new List<String>();
                subClients.addAll(accountWithScc.get(accId) !=null ? accountWithScc.get(accId) : new Set<String>());
                String body = accountWithWOAsset.get(accId)+' has terminated their Workforce Optimization or Workforce Synchronization relationship with Insperity.  The Background Screening contact(s) for this account is/are:'
                +'<br/>'+contactWithName.get(accId)+' '+ String.join(subClients, ', ')+'<br/>'+
                +'<br/>Please follow up with the Customer regarding their relationship with Insperity Employment Screening'+     
                +'<br/><br/>Regards,<br/>'+ 
                'Salesforce';
                prepareEmailTemplate(
                    accountWithWOAsset.get(accId)+' has been Terminated', 
                    body
                );
            }
        }

        //
        // @description c. If the "Employee Status" for the SCC where the contact is 
        // identified as a Background Contact is updated from <>(TERMINATED or FMLA or FMLA – WORKERS COMP) to L.O.A., L.O.A. – EDUCATION, OR L.O.A. - MILITARY and the WO AIMS status = Active
        //
        public void isSubCientLOAEmail(Map<String, List<String>> contIdWithSubCC) {
            for(Id contactId :  contIdWithSubCC.keySet()) {
                String body = contactIdWithName.get(contactId)+' has been placed on L.O.A. from '+ String.join(contIdWithSubCC.get(contactId), ', ')
                +'. Please contact the client to determine if the employee’s access to the IES site should be suspended.'
                +'<br/><br/>Regards,<br/>'+ 
                'Salesforce';
                prepareEmailTemplate(
                    'Background Screening Contact for '+String.join(contIdWithSubCC.get(contactId), ', ')+' is on L.O.A',
                    body
                );
            }
        }

        //
        // @description d. If the "Employee Status" for the SCC where the contact is identified as a Background Contact is updated from 
        // L.O.A., L.O.A. – EDUCATION, OR L.O.A. - MILITARY  to <>TERMINATED excluding FMLA or FMLA – WORKERS COMP and the WO AIMS status = Active
        //
        public void isSubCientReturnedLOAEmail(Map<String, List<String>> contIdWithSubCC) {
            for(Id contactId :  contIdWithSubCC.keySet()) {
                String body = contactIdWithName.get(contactId)+' has returned from L.O.A. from '+ String.join(contIdWithSubCC.get(contactId), ', ')
                    +'. If necessary, verify that the contact is still authorized to access the IES site.'
                    +'<br/><br/>Regards,<br/>'+ 
                    'Salesforce';
                prepareEmailTemplate(
                    'Background Screening Contact for '+String.join(contIdWithSubCC.get(contactId), ', ')+' has returned from L.O.A.',
                    body
                );
            }
        }

        //
        // @description e. If the "Employee Status" for the SCC where the contact is identified 
        // as a Background Contact is updated from <>(TERMINATED or L.O.A., L.O.A. – EDUCATION, OR L.O.A. – MILITARY)  to FMLA or FMLA – WORKERS COMP and the WO AIMS status = Active
        //
        public void isSubCientFLMAEmail(Map<String, List<String>> contIdWithSubCC) {
            for(Id contactId :  contIdWithSubCC.keySet()) {
                String body = contactIdWithName.get(contactId)+' is on FMLA leave from '+ String.join(contIdWithSubCC.get(contactId), ', ')
                +'. Please contact the client to determine if the employee’s access to the IES site should be suspended.'
                +'<br/><br/>Regards,<br/>'+ 
                'Salesforce';
                prepareEmailTemplate(
                    'Background Screening Contact for '+ String.join(contIdWithSubCC.get(contactId), ', ')+' is on FMLA',
                    body
                );
            }
        }

        //
        // @description f.If the "Employee Status" for the SCC where the contact is identified as a 
        // Background Contact is updated from FMLA or FMLA – WORKERS COMP to <>TERMINATED excluding L.O.A., L.O.A. – EDUCATION, OR L.O.A. - MILITARY  and the WO AIMS status = Active
        //
        public void isSubCientReturnedFLMAEmail(Map<String, List<String>> contIdWithSubCC) {
            for(Id contactId :  contIdWithSubCC.keySet()) {
                String body = contactIdWithName.get(contactId)+' has returned from FMLA leave at '+ String.join(contIdWithSubCC.get(contactId), ', ')
                +'. If necessary, verify that the contact is still authorized to access the IES site.'
                +'<br/><br/>Regards,<br/>'+ 
                'Salesforce';
                prepareEmailTemplate(
                    'Background Screening Contact for '+String.join(contIdWithSubCC.get(contactId), ', ')+' has returned from FMLA',
                    body
                );
            }
        }

        // @description g.If the "Employee Status" for the SCC where the contact is identified as a Background contact is updated from TERMINATED to <>TERMINATED
        public void isSubCientRehiredEmail(Map<String, List<String>> contIdWithSubCC) {
            for(Id contactId :  contIdWithSubCC.keySet()) {
                String body = contactIdWithName.get(contactId)+' has been rehired to '+String.join(contIdWithSubCC.get(contactId), ', ')+ '.'
                    +' If this contact should not be an authorized recipient of background screening data, please go to OneVoice and remove the Background Contact flag from the Contact’s record.'
                    +'<br/><br/>Regards,<br/>'+ 
                    'Salesforce';
                prepareEmailTemplate(
                    'Previous Background Screening Contact for '+String.join(contIdWithSubCC.get(contactId), ', ')+' has been Rehired',
                    body
                );
            }
        }

        /**
         * @description Perpare Email Templates and Add to the list to send Emails
         */
        public void prepareEmailTemplate(String subject, String mailBody){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{Label.NSP_IES_NotificationAlertEmail});
            if(Label.NSP_OrgWideEmail_Insperity != null && !Test.isRunningTest()){
                mail.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
            }
            mail.setSubject(Subject);
            mail.setHtmlBody(mailBody);               
            lstEmailMessages.add(mail);
        }
    }

    /**
     * check for Notification email alerts for subclientcontact conditions to send an email
     */
    private without sharing class CheckSubClientContactTemplateCondition{ 
        List<String> lstFMLA = new List<String>{
            NSP_ServiceConstants.TERMINATED_STATUS,
            NSP_ServiceConstants.FMLA_STATUS,
            NSP_ServiceConstants.FMLA_WORKERS_STATUS
        };
        List<String> lstLOA = new List<String>{
            NSP_ServiceConstants.LOA_STATUS,
            NSP_ServiceConstants.LOA_EDU_STATUS,
            NSP_ServiceConstants.LOA_MILITARY_STATUS
        };
        List<String> newLstFLMA = new List<String>{
            NSP_ServiceConstants.FMLA_STATUS,
            NSP_ServiceConstants.FMLA_WORKERS_STATUS
        };
        List<String> oldListFLMA = new List<String>{
            NSP_ServiceConstants.TERMINATED_STATUS,
            NSP_ServiceConstants.LOA_STATUS,
            NSP_ServiceConstants.LOA_EDU_STATUS,
            NSP_ServiceConstants.LOA_MILITARY_STATUS
        };
        List<String> oldReturnedFLMA = new List<String>{
            NSP_ServiceConstants.FMLA_STATUS,
            NSP_ServiceConstants.FMLA_WORKERS_STATUS
        };
        List<String> newReturnedFLMA = new List<String>{
            NSP_ServiceConstants.TERMINATED_STATUS,
            NSP_ServiceConstants.LOA_STATUS,
            NSP_ServiceConstants.LOA_EDU_STATUS,
            NSP_ServiceConstants.LOA_MILITARY_STATUS
        };

        //
        // @description a.If the "Employee Status" for the Sub Client Contact (SCC) where the contact is identified as a Background Contact is updated from <>TERMINATED to TERMINATED and the WO AIMS status = Active
        // @return  Boolean if criteria is matched
        //
        public Boolean isTerminatedSubCientWoActive(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Old_Employee_Status__c != NSP_ServiceConstants.TERMINATED_STATUS &&
                subClientContact.NSP_Employee_Status__c == NSP_ServiceConstants.TERMINATED_STATUS &&
                subClientContact.NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c == NSP_ServiceConstants.AIMS_STATUS);
        }

        //
        // @description b. If the "Employee Status" for the SCC where the contact is identified as a Background Contact is updated from <>TERMINATED to TERMINATED and the WO AIMS status = TERMINATED
        // @return  Boolean if criteria is matched
        //
        public Boolean isTerminatedSubCientWoTerminated(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Old_Employee_Status__c != NSP_ServiceConstants.TERMINATED_STATUS &&
                subClientContact.NSP_Employee_Status__c == NSP_ServiceConstants.TERMINATED_STATUS &&
                subClientContact.NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c == NSP_ServiceConstants.TERMINATED_STATUS);
        }

        //
        // @description c. If the "Employee Status" for the SCC where the contact is identified as a Background Contact is updated from <>(TERMINATED or FMLA or FMLA – WORKERS COMP) to L.O.A., L.O.A. – EDUCATION, OR L.O.A. - MILITARY and the WO AIMS status = Active
        // @return  Boolean if criteria is matched
        //
        public Boolean isSubCientLOA(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c == NSP_ServiceConstants.AIMS_STATUS &&
                !lstFMLA.contains(subClientContact.NSP_Old_Employee_Status__c) && 
                lstLOA.contains(subClientContact.NSP_Employee_Status__c));
        }

        //
        // @description d. If the "Employee Status" for the SCC where the contact is identified as a Background Contact is updated from L.O.A., L.O.A. – EDUCATION, OR L.O.A. - MILITARY  to <>TERMINATED excluding FMLA or FMLA – WORKERS COMP and the WO AIMS status = Active
        // @return  Boolean if criteria is matched
        //
        public Boolean isSubCientReturnedLOA(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c == NSP_ServiceConstants.AIMS_STATUS &&
                lstLOA.contains(subClientContact.NSP_Old_Employee_Status__c) && 
                !lstFMLA.contains(subClientContact.NSP_Employee_Status__c));
        }

        //
        // @description e. If the "Employee Status" for the SCC where the contact is identified as a Background Contact is updated from <>(TERMINATED or L.O.A., L.O.A. – EDUCATION, OR L.O.A. – MILITARY)  to FMLA or FMLA – WORKERS COMP and the WO AIMS status = Active
        // @return  Boolean if criteria is matched
        //
        public Boolean isSubCientFLMA(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c == NSP_ServiceConstants.AIMS_STATUS &&
                !oldListFLMA.contains(subClientContact.NSP_Old_Employee_Status__c) &&  
                newLstFLMA.contains(subClientContact.NSP_Employee_Status__c));
        }

        //
        // @description f. If the "Employee Status" for the SCC where the contact is identified as a Background Contact is updated from FMLA or FMLA – WORKERS COMP to <>TERMINATED excluding L.O.A., L.O.A. – EDUCATION, OR L.O.A. - MILITARY  and the WO AIMS status = Active
        // @return  Boolean if criteria is matched
        //
        public Boolean isSubCientReturnedFLMA(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Sub_Client__r.NSP_Asset__r.NSP_Account_Status__c == NSP_ServiceConstants.AIMS_STATUS &&
                oldReturnedFLMA.contains(subClientContact.NSP_Old_Employee_Status__c) && 
                !newReturnedFLMA.contains(subClientContact.NSP_Employee_Status__c));
        }

        //
        // @description g. If the "Employee Status" for the SCC where the contact is identified as a Background contact is updated from TERMINATED to <>TERMINATED
        // @return  Boolean if criteria is matched
        //
        public Boolean isSubCientRehired(NSP_Sub_Client_Contact__c subClientContact) {
            return (subClientContact.NSP_Employee_Status__c != subClientContact.NSP_Old_Employee_Status__c &&
                subClientContact.NSP_Old_Employee_Status__c == NSP_ServiceConstants.TERMINATED_STATUS &&
                subClientContact.NSP_Employee_Status__c != NSP_ServiceConstants.TERMINATED_STATUS);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }

    /**
     * @description scheduling the batch class here
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new NSP_NotificatonIESAlertsBatch());
    }
    
}