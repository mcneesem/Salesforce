/**
*************************************************************
* 
* @description  : Batch Class to process the termination form for the email template.
* @author Shruti Patil
* @date : 10/18/2021
* Name : NSP_TerminationForm_Batch
*
*************************************************************
*/


public class NSP_TerminationForm_Batch implements Database.Batchable<SObject>, Database.Stateful {

    public List<String> toEmailAddressList = new List<String>();
    public List<String> ccEmailAddressList = new List<String>();
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Name, NSP_Client_Term_Date__c, NSP_Status__c, NSP_Term_Code__c, NSP_Benefit_Termination_Date__c, NSP_Project_Task__r.pse__Project__r.pse__Account__c,NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name, NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,  NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c FROM NSP_Termination_Form__c WHERE NSP_Client_Term_Date__c = LAST_N_DAYS:22 AND NSP_Status__c = '+ '\''+'Term Team Approved'+'\'' +' AND NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != '+'\''+'Complete'+'\'';
        return Database.getQueryLocator(query);   
    }
    public void execute(Database.BatchableContext bc, List<NSP_Termination_Form__c> terminationsList){
        try{
            Set<Id> relatedAccoutIdSet = new Set<Id>();   
            Set<String> emailIdSet = new Set<String>();     
            for(NSP_Termination_Form__c terminations : terminationsList){
                if(terminations.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null){
                    relatedAccoutIdSet.add(terminations.NSP_Project_Task__r.pse__Project__r.pse__Account__c);
                } 
            }
            if(relatedAccoutIdSet.size() > 0){
                for(NSP_Account_Team__c AccTeamMember : [SELECT Id, NSP_Role__c, NSP_Account__c, NSP_Email__c
                                                       FROM NSP_Account_Team__c 
                                                       WHERE NSP_Account__c IN: relatedAccoutIdSet AND
                                                       (NSP_Role__c = 'Manager,HR Services' OR
                                                        NSP_Role__c = 'Payroll Specialist' OR
                                                        NSP_Role__c = 'Client Liaison' OR
                                                        NSP_Role__c = 'HR Specialist' OR
                                                        NSP_Role__c = 'Renewal Coordinator')]){
                    if(AccTeamMember.NSP_Email__c != null){
                        emailIdSet.add(AccTeamMember.NSP_Email__c);
                    }
                }                 
            }
            ccEmailAddressList.addAll(emailIdSet);
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }  
  
    }
    public void finish(Database.BatchableContext BC){
        EmailTemplate emailTemplate = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'NSP_Termination_Form_Email_Template'];
        toEmailAddressList.add(System.Label.NSP_TerminationFormBatchGenericToAddress); 
            
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toEmailAddressList);
        email.setSaveAsActivity(false);
        email.setTemplateId(emailTemplate.Id);
        email.setTargetObjectId(userinfo.getUserId());
        email.setCcAddresses(ccEmailAddressList);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
}