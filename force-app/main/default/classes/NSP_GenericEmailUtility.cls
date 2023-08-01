/**
* @description  : Generic EMail Utility Class. Contains methods to populate and send emails from Apex.
* @author Rakesh Das
* @date 09/20/2022
* Name : NSP_GenericEmailUtility
*/

public class NSP_GenericEmailUtility {
    
    static final string CLASS_NAME = 'NSP_GenericEmailUtility';
/**
* Method to send emails.
* @param  Email Messages - Type List of Messaging.SingleEmailMessage
* @return Integer - Count of emails sent
* @Author Rakesh Das
* @Since September 2022
*/
    public static Integer sendSingleEmailMessages (Messaging.SingleEmailMessage[] emailMessages, Boolean allOrNone) {
        
        Messaging.SendEmailResult[] results;
        boolean isEmailSent=false;
        Integer emailSentCount = 0;
        try{ 
            results = Messaging.sendEmail(emailMessages, allOrNone);
            isEmailSent=true;
            for(Messaging.SendEmailResult res : results) {
                if(res.isSuccess()) {
                    emailSentCount+=1;
                }
            }
        }catch(System.EmailException ex){
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME,'sendSingleEmailMessages',ex.getMessage());
            return emailSentCount;
        }
        
        return emailSentCount;
    }
    
    
    /**
* Method to generate emails.
* @param  Email Messages Parameters - Subject, Body, TemplateId, OrgWideEmailId, recordId, TargetObjId, ToAddressList, CCAddressList
* @return List of Email Messages - List of Messaging.SingleEmailMessage objects
* @Author Rakesh Das
* @Since September 2022
*/  
    
    public static Messaging.SingleEmailMessage generateSingleMessageWithTemplate (String templateId, String recordId, String targetObjId, String orgWideEmailId, List<String> toAddressList, List<String> ccAddressList, String subject, String plainTextBody) {
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        try{
            mail.setWhatId(recordId);
            if(templateId!=null){
                mail.setTemplateId(templateId);
                mail.setTargetObjectId(targetObjId);
            }
            else {
                mail.setSubject(subject);
                mail.setPlainTextBody(plainTextBody);
            }
            if(orgWideEmailId!=null) {
                mail.setOrgWideEmailAddressId(orgWideEmailId);
            }
            if(toAddressList!=null){
                mail.setToAddresses(toAddressList);
            }
            if(toAddressList!=null){
                mail.setCcAddresses(ccAddressList);
            }
            
        }
        catch (Exception ex){
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME,'generateSingleMessageWithTemplate',ex.getMessage());
            return null;
        }
        return mail;
    }
    
    /**
* Method to get Template Id from Template Developer Name stored in Org.
* @param  String templateDevName - Template Developer Name
* @return String TemplateId
* @Author Rakesh Das
* @Since September 2022
*/ 
    
    public static String getTemplateIdFromDevName (String templateDevName) {
        
        String templateId;
        if(templateDevName !=null){
            try{
                EmailTemplate emailTemplateStored = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName =:templateDevName LIMIT 1];
                templateId = emailTemplateStored.Id;
            }
            catch (Exception ex){
                NSP_ErrorLogHandler.logSaveException(CLASS_NAME,'getTemplateIdFromDevName',ex.getMessage());
                
            }
        }
        return templateId;
    }
    
    /**
* Method to get TOrg Wide Address.
* @param  String displayName 
* @return String orgWidAddress
* @Author Rakesh Das
* @Since January 2023
*/ 
    public static OrgWideEmailAddress getOrgWideAddress ( String displayName) {
        OrgWideEmailAddress orgWidAddress;
        try {
            orgWidAddress = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE DisplayName=:displayName LIMIT 1];
         }
        catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(CLASS_NAME,'getOrgWideAddress',ex.getMessage());
        }
        return orgWidAddress;
    }


}