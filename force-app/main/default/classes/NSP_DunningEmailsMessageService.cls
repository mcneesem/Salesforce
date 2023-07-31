/**
* @description  : Dunning Email Service Class to customize dunning emails sent from Apex
* @author Rakesh Das
* @date 09/20/2022
* Name : NSP_DunningEmailsMessageService
*/

public class NSP_DunningEmailsMessageService {
    
    private NSP_DunningEmailsMessageService(){}
    /**
* Invocable Method that can be called from Flows
* @param  List of dunningEmailParams objects - dunningEmailParams is a Wrapper Class to pass multiple values from flow
* @return void
* @Author Rakesh Das
* @Since September 2022
*/
    @InvocableMethod(label='Send Dunning Email' description='Sends dunning email reminders based on invoice due dates')
    public static void sendDunningEmail(List<dunningEmailParams> dparams) {
        sendDunningEmailsWithCount(dparams);
    }

    /**
* Single static method called via Flow / Batch to send dunning emails. Depends on generateDunningEmails for email generation.
* @param  List of dunningEmailParams objects - dunningEmailParams is a Wrapper Class to pass multiple values from flow
* @return Integer - count of emails sent
* @Author Rakesh Das
* @Since September 2022
*/    
     public static Integer sendDunningEmailsWithCount(List<dunningEmailParams> dparams) {
         Integer ecount = 0; // count of emails sent
         List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        emails = generateDunningEmails(dparams); // call to generate email from template
        if(emails.size()>0) {
           ecount = NSP_GenericEmailUtility.sendSingleEmailMessages(emails,false); //method to send emails.
        }
         return ecount;
     }
 
 
/**
* Single static method to generate emails.
* @param  List of dunningEmailParams objects - dunningEmailParams is a Wrapper Class to pass multiple values from flow
* @return List of Email Messages - List of Messaging.SingleEmailMessage objects
* @Author Rakesh Das
* @Since September 2022
*/
    public static List<Messaging.SingleEmailMessage> generateDunningEmails(List<dunningEmailParams> dparams) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        if(dparams!=null){
            //variables decalartions to store mappings.
            Map<String, String> templateNameToIdMap = new Map<String, String>();
            Map<String, String> caseToTemplateNameMap = new Map<String, String>();
            List<String> recordIds = new List<String>();
            // taking first template name from param list
            String objectName = dparams.get(0).objectName;
            Set<String> accountIds = new Set<String>();
            //querying org wide address
            OrgWideEmailAddress orgWidAddress = NSP_GenericEmailUtility.getOrgWideAddress( System.label.NSP_no_reply );

            if(objectName == 'Account') {
                Messaging.SingleEmailMessage pendingInvcemail = generateAccount30DaysEmail(dparams[0], orgWidAddress.Id);
                emails.add(pendingInvcemail);
            }
            else {
            for(dunningEmailParams dep : dparams) {
                recordIds.add(dep.recordId);
                caseToTemplateNameMap.put(dep.recordid,dep.templateName); //linking case with template id
                if(!templateNameToIdMap.containsKey(dep.templateName)) {
                    //getTemplateIdFromDevName is called only once per template name, only if it is not present in the map
                    String templateId = NSP_GenericEmailUtility.getTemplateIdFromDevName(dep.templateName);
            		templateNameToIdMap.put(dep.templateName,templateId);
                }
            }
            if(recordIds!=null) {
                //populating case records for Map
                Map<String, Case> recordIdToCaseMap = new  Map<String, Case>();
                for (Case caseCon : [SELECT Id, OwnerId, ContactId, Contact.Email, CaseNumber, AccountId, Origin, Type, RecordTypeId FROM Case WHERE Id IN:recordIds ]) {
                    recordIdToCaseMap.put(caseCon.Id,caseCon);
                    accountIds.add(caseCon.AccountId);
                }
                //populating toaddress list from ACR records
                Map<String, Set<String>> accountIdToContactEmails = new Map<String, Set<String>>();
                for(AccountContactRelation acr : [Select Id, NSP_Dunning_Emails__c, Contact.Email, Contact.Name, ContactId, AccountId from AccountContactRelation WHERE AccountId IN:accountIds AND NSP_Dunning_Emails__c=true  ]) {
                    if(accountIdToContactEmails.containsKey(acr.AccountId)) {
                        Set<String> contactEmails = accountIdToContactEmails.get(acr.AccountId);
                        contactEmails.add(acr.Contact.Email);
                        accountIdToContactEmails.put(acr.AccountId, contactEmails );
                    }
                    else {
                        accountIdToContactEmails.put(acr.AccountId, new Set<String>{acr.Contact.Email});  
                    }
                }
                
                // Primary Email Generation Loop iterating over Cases.
                for(Case cs : recordIdToCaseMap.values()) {
                    String targetObjId = cs.ContactId;
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    //mail.setWhatId(recordId); 
                    String tid;
                    //below code block selects the template id and target object id required for template
                    if(caseToTemplateNameMap.containsKey(cs.Id)) {
                        String tname = caseToTemplateNameMap.get(cs.id);
                        if(tname == NSP_BillingConstants.X135_PAST_DUE){
                            targetObjId = cs.OwnerId;
                        }
                        if(templateNameToIdMap.containsKey(tname)) {
                    	tid = templateNameToIdMap.get(tname);   
                    }
                    }
                    // below code block populates address list
                    List<String> toAddressList = New List<String>();
                    if(accountIdToContactEmails.containsKey(cs.AccountId)) {
                        toAddressList.addAll(accountIdToContactEmails.get(cs.AccountId)); 
                    }
                    if(!toAddressList.contains(cs.Contact.Email)) {
                        toAddressList.add(cs.Contact.Email);
                    }
                    if(tid!=null){
                        // method call to generate email message with vf template id
                        mail = NSP_GenericEmailUtility.generateSingleMessageWithTemplate(tid,cs.id,targetObjId,orgWidAddress.Id,toAddressList, null, null, null);
                    }
                    //mail.setOrgWideEmailAddressId(orgWidAddress.Id);
                    //mail.setCcAddresses();
                    //mail.setToAddresses(toAddressList);
                    mail.setSaveAsActivity(true);
                    emails.add(mail);
                    //System.debug('MAIL : '+mail);
                }
            }
        }
            //NSP_GenericEmailUtility.sendSingleEmailMessages(emails,false);
        }
        return emails;
        
    }

    /**
* Single static method to generate emails.
* @param  dunningEmailParams object - dunningEmailParams is a Wrapper Class to pass multiple values from flow
* @return Single Email Messages - Messaging.SingleEmailMessage object
* @Author Rakesh Das
* @Since September 2022
*/
public static Messaging.SingleEmailMessage generateAccount30DaysEmail(dunningEmailParams dparam, String orgWideId) {

    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    String templateId = NSP_GenericEmailUtility.getTemplateIdFromDevName(dparam.templateName);
    List<String> toAddressList = New List<String>();
    String targetObjId;
    for(AccountContactRelation acr : [Select Id, NSP_Dunning_Emails__c, Contact.Email, Contact.Name, ContactId, AccountId from AccountContactRelation WHERE AccountId =:dparam.recordid AND NSP_Dunning_Emails__c=true  ]) {
        toAddressList.add(acr.Contact.Email);
        targetObjId = acr.ContactId;
    }
    if(templateId!=null){
        // method call to generate email message with vf template id
        mail = NSP_GenericEmailUtility.generateSingleMessageWithTemplate(templateId,dparam.recordid,targetObjId,orgWideId,toAddressList, null, null, null);
        mail.setSaveAsActivity(true);
    }
    return mail;
          
}

 
/**
* @description  : Wrapper Class to pass multiple parameters from Flow
* @author Rakesh Das
* @date 09/20/2022
* Name : dunningEmailParams
*/
    public class dunningEmailParams {
        @InvocableVariable(label='Email Template Name' description='Holds Email Template Developer Name' required=false)
        public String templateName;
        
        @InvocableVariable(label='Object Name' description='Holds Object Name' required=true)
        public String objectName;
        
        @InvocableVariable(label='Record Ids' description='Holds Record Id' required=true)
        public String recordid;
        //constructor
        public dunningEmailParams(String tmpName, String objName, String recid) {
            this.templateName = tmpName;
            this.objectName = objName;
            this.recordId = recid;
        }
        //default constructor
        public dunningEmailParams() {
            
        }
    }    
}