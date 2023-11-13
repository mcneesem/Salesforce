/**
* @description  :  Helper class for Case Issue Trigger.
* @date 01/27/2022
* Author : Nischay Jindal
* Name : NSP_CaseIssueHelper
* test w/NSP_CaseIssuehelperTest(82%)
*/
public class NSP_CaseIssueHelper {
        
    /***********************************************************************************************
    * MethodName: beforeUpdateDirector
    * Description : Runs on Before Update
    * Params:       List<NSP_Case_Issue__c> caseIssueList , Map<Id,NSP_Case_Issue__c> oldCaseIssueMap
    * ********************************************************************************************/   
    public static void beforeUpdateDirector(List<NSP_Case_Issue__c> caseIssueList , Map<Id,NSP_Case_Issue__c> oldCaseIssueMap){
        try{
            Set<Id> caseIssueIdSet = new Set<Id>();
            Map<Id,Id> caseIssueEmailMessageIdMap = new Map<Id,Id>();
            // populating Case Issue Id Set
            for(NSP_Case_Issue__c caseIssue :caseIssueList){
                caseIssueIdSet.add(caseIssue.Id);
            }
            if(!caseIssueIdSet.isEmpty()){
                // searching for the Email Message associated with the Case Issue record
                for(EmailMessage emsg: [SELECT Id, TextBody, HtmlBody, Subject, RelatedToId FROM EmailMessage WHERE RelatedToId IN:caseIssueIdSet]){
                    caseIssueEmailMessageIdMap.put(emsg.RelatedToId, emsg.Id);
                }
                // Updating Notication Status on Case Issue 
                for(NSP_Case_Issue__c caseIssue :caseIssueList){
                    if(caseIssue.NSP_Status__c == NSP_ServiceConstants.ClosedCaseIssue && 
                       oldCaseIssueMap.get(caseIssue.Id).NSP_Status__c !=caseIssue.NSP_Status__c  &&
                       !caseIssueEmailMessageIdMap.containsKey(caseIssue.Id)){
                           caseIssue.addError(label.NSP_CaseIssueNotification);
                       }
                }
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_CaseIssueHelper', 'beforeUpdateDirector', ex.getMessage());
        } 
    }
            
    /***********************************************************************************************
    * MethodName: afterUpdateDirector
    * Description : Runs on after Update
    * Params:       List<NSP_Case_Issue__c> caseIssueList , Map<Id,NSP_Case_Issue__c> oldCaseIssueMap
    * ********************************************************************************************/   
    public static void afterUpdateDirector(List<NSP_Case_Issue__c> caseIssueList , Map<Id,NSP_Case_Issue__c> oldCaseIssueMap){
        Map<Id, String> closedIssueRatingMap = new Map<Id,String>();
        try{
            //iterating through case issue records
            for(NSP_Case_Issue__c caseIssue :caseIssueList){
                if(caseIssue.NSP_Status__c!= null && oldCaseIssueMap.get(caseIssue.Id).NSP_Status__c !=caseIssue.NSP_Status__c &&
                   caseIssue.NSP_Status__c == NSP_ServiceConstants.ClosedCaseIssue){
                       closedIssueRatingMap.put(caseIssue.Id,caseIssue.NSP_Rating__c);
                   }
            }
            if(!closedIssueRatingMap.keySet().isEmpty()){
                closedRelatedCases(closedIssueRatingMap);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_CaseIssueHelper', 'afterUpdateDirector', ex.getMessage());
        }
        
    }

    /***********************************************************************************************
    * MethodName: closedRelatedCases
    * Description : This method will close all the related cases
    * Params:      Map<Id,String> closedIssueRatingMap
    * ********************************************************************************************/      
    private static void closedRelatedCases(Map<Id,String> closedIssueRatingMap){
        List<Case> closeCaseList = new List<Case>();
        for(Case caseRecord: [SELECT Id , NSP_Rating__c, NSP_Case_Issue__c , Status FROM Case 
                                WHERE NSP_Case_Issue__c IN: closedIssueRatingMap.keySet() 
                                AND (Status !=:NSP_ServiceConstants.CASE_CLOSED_STATUS AND 
                                Status !=:NSP_ServiceConstants.CASE_CANCELLED_STATUS) ]){
            if(closedIssueRatingMap.containsKey(caseRecord.NSP_Case_Issue__c) && 
               closedIssueRatingMap.get(caseRecord.NSP_Case_Issue__c) != Null){
                   Case cs = updateCase(caseRecord.Id, closedIssueRatingMap.get(caseRecord.NSP_Case_Issue__c));
                   closeCaseList.add(cs);
               }
        }
        if(!closeCaseList.isEmpty()){
            List<Database.UpsertResult> upsertResults = Database.upsert(closeCaseList, false);
            sendEmailtoCaseContacts(closedIssueRatingMap);
            NSP_ErrorLogHandler.logUpsertResultsException('NSP_CaseIssueHelper', 'closedRelatedCases', upsertResults);
        }
    }
    /***********************************************************************************************
    * MethodName: sendEmailtoCaseContacts
    * Description : This method will send email to all closed cases
    * Params:      Map<Id,String> closedIssueRatingMap
    * ********************************************************************************************/ 
    private static void sendEmailtoCaseContacts(Map<Id,String> closedIssueRatingMap){
        Map<Id,EmailMessage> csIssueMessageMap = new  Map<Id,EmailMessage>();
        List<String>listOfTOAddresses = new List<String>();
        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>();
        for(EmailMessage emsg: [SELECT Id, RelatedToId, HtmlBody, TextBody, Subject, Name, FromName, FromAddress, ValidatedFromAddress, ToAddress, CcAddress, 
                                BccAddress, EmailTemplateId  FROM EmailMessage WHERE RelatedToId IN:closedIssueRatingMap.keySet() Limit 1]){
                                    String parentId = emsg.RelatedToId;
                                    csIssueMessageMap.put(parentId,emsg); 
                                }
        //sending emails to the list of to addresses
        for(Case cs:[Select Id , Status , ContactId , Contact.NSP_Work_email__c, NSP_Case_Issue__c FROM CASE 
                     WHERE NSP_Case_Issue__c IN : csIssueMessageMap.keyset() 
                     AND Status =:NSP_ServiceConstants.ClosedCaseIssue AND NSP_Case_Issue__r.NSP_Status__c =:NSP_ServiceConstants.ClosedCaseIssue]){
                         if(csIssueMessageMap.containsKey(cs.NSP_Case_Issue__c)){
                             if(cs.Contact.NSP_Work_email__c !=null && 
                                !listOfTOAddresses.contains(csIssueMessageMap.get(cs.NSP_Case_Issue__c).ToAddress) 
                                && !listOfTOAddresses.contains(csIssueMessageMap.get(cs.NSP_Case_Issue__c).BccAddress)
                                && !listOfTOAddresses.contains(csIssueMessageMap.get(cs.NSP_Case_Issue__c).CcAddress)
                               ){
                                   listOfTOAddresses.add(cs.Contact.NSP_Work_email__c);  
                               }
                             if(!listOfTOAddresses.isEmpty() && listOfTOAddresses.contains(cs.Contact.NSP_Work_email__c) ){
                                 Messaging.SingleEmailMessage email = NSP_GenericEmailUtility.generateSingleMessageWithTemplate(null,csIssueMessageMap.get(cs.NSP_Case_Issue__c).RelatedToId,
                                                                                                                                UserInfo.getUserId(),null, new List<String>{cs.Contact.NSP_Work_email__c} , null ,
                                                                                                                                csIssueMessageMap.get(cs.NSP_Case_Issue__c).Subject,null);
                                 email.setHtmlBody(csIssueMessageMap.get(cs.NSP_Case_Issue__c).HtmlBody);  
                                 emailMsgList.add(email);                                                                                                               
                             }
                         }
                     }  
        Messaging.sendEmail(emailMsgList); 
    }
    
    /***********************************************************************************************
    * MethodName: updateCase
    * Description : Private method to update the cases
    * Params:      Id caseId , String rating
    * ********************************************************************************************/ 
    private static Case updateCase(Id caseId , String rating){
        Case cs = new Case();
        cs.Id = caseId;
        cs.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS;
        cs.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_CLOSED_STATUS;//11/10/2023-Suhas Added -STY-234800
        cs.NSP_Rating__c = rating;
        return cs;
    }
}