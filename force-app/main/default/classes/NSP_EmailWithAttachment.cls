/**
* @description  :  class for sending Email Template with attachments
* @date 03/21/2022
* Author : Nischay Jindal
* Name : NSP_EmailWithAttachment
*/
    /***********************************************************************************************
    * Customlabels: 
        1) NSP_OpportunityTeamMemberRoles : created to store the Roles Of opportunity team Members to send email notification for Closed Opp
        2) NSP_Opportunity_Closed_Won_AlertAdditionalEmails: It will store the comma separated values of Additional Emails
        3) NSP_OpportunityWXAttachmentName : It is created to match the name of WX Attachments 
        4) NSP_OpportunityWAAttachmentName :It is created to match the name of WA Attachments 

    * ********************************************************************************************/

    public class NSP_EmailWithAttachment {
        private static final string NSP_EmailWithAttachment = 'NSP_EmailWithAttachment';
        private static final string sendClosedWonEmailNotifications = 'sendClosedWonEmailNotifications';
        /***********************************************************************************************
        * MethodName: sendClosedWonEmailNotifications
        * Description : This method will send an email notification with attachment for closed won opportunity
        * Params:      String OppId
        * ********************************************************************************************/
        public static void sendClosedWonEmailNotifications(String recordId,Opportunity Opp){  
            try{
                Set<String>RecipientEmails= new Set<String>();
                String OwnerEmail=[SELECT Email from USER WHERE Id=:opp.ownerId].Email;
                // Adding Opportunity Owner as the recipient
                RecipientEmails.add(OwnerEmail);
                List<String> oppTeamMembers=System.Label.NSP_OpportunityTeamMemberRoles.split(',');
                Set<String>OpportunityTeamMembers= new Set<String>();
                OpportunityTeamMembers.addAll(oppTeamMembers);
                if(!OpportunityTeamMembers.isEmpty()){
                    // Quering Opportunity Team Members 
                    List<OpportunityTeamMember> oppTeamList=[SELECT Id, User.Email FROM OpportunityTeamMember WHERE OpportunityId =:recordId 
                                                                AND TeamMemberRole IN:OpportunityTeamMembers] ;
    
                    //Adding Opportunity Team Members email Ids 
                    for(OpportunityTeamMember oppTeam:oppTeamList){
                        RecipientEmails.add(oppTeam.User.Email);
                    }
                }
                List<ContentDocumentLink> contentdocLinkList= [SELECT Id , ContentDocumentId FROM  
                                                               ContentDocumentLink WHERE LinkedEntityId=:recordId ORDER BY SystemModstamp ASC ];
                Set<Id> contentDocumentIds = new Set<Id>();
                for(ContentDocumentLink cdl:contentdocLinkList){
                    contentDocumentIds.add(cdl.ContentDocumentId);
                }
                
                List<ContentVersion> contentversionList=[SELECT Id, Title, FileType,versiondata  FROM contentversion
                                                         WHERE ContentDocumentId IN: contentDocumentIds And IsLatest = true];
                
                //Adding Additions email Ids from Custom Labels 
                List<String>OpportunityNotificationEmails=System.Label.NSP_Opportunity_Closed_Won_AlertAdditionalEmails.split(',');
                if(!OpportunityNotificationEmails.isEmpty()){
                    RecipientEmails.addAll(OpportunityNotificationEmails);
                }
                // creating a list of Recipients Emails
                List<String> recipientEmailIdList= new  List<String>();
                recipientEmailIdList.addAll(RecipientEmails);
                List<Messaging.SingleEmailMessage> lstMsgs = new List<Messaging.SingleEmailMessage>();
                
                EmailTemplate EmailTemplates = [SELECT Id, Body,htmlValue, Subject from EmailTemplate WHERE
                                                DeveloperName =:label.NSP_OpportunityEmailTemplate];
                
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                List<Messaging.EmailFileAttachment> emailattachments = new List<Messaging.EmailFileAttachment>();
                
                mail.setTemplateId(EmailTemplates.Id);
                mail.setSaveAsActivity(false);
                mail.setToAddresses(recipientEmailIdList);
                mail.setWhatId(recordId);
                mail.setPlainTextBody(EmailTemplates.Body);
                mail.setHTMLBody(EmailTemplates.htmlValue);
                mail.setSubject(EmailTemplates.subject);
                mail.setTreatBodiesAsTemplate(True);
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
                    mail.setFileAttachments(emailattachments);
                }
                Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
           }catch(Exception ex){
                NSP_ErrorLogHandler.logSaveException(NSP_EmailWithAttachment,sendClosedWonEmailNotifications,ex.getMessage());
            }
            
        }
    }