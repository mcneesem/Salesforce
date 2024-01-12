public without sharing class NSP_IP_MM_EmailAutomationsController {
    //Prepare email Message for each template
    public static Messaging.SingleEmailMessage sendMail(EmailTemplate et, Implementation_Profile__c ipRec, String[] toAddresses,Boolean isReRun ){
        //set template structure for the email template      
        String Subject;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(!test.isRunningTest()){
            email= Messaging.renderStoredEmailTemplate(et.Id, null ,ipRec.id);
        }
        if(isReRun){
            Subject= NSP_ServiceConstants.UpdateEmailSubject+ email.Subject;
        }      
        else {
            Subject=  email.Subject;
        }
        email.setTemplateId(et.Id);
        email.setSubject(Subject);
        email.setToAddresses(toAddresses);
        email.setWhatId(ipRec.id);
        email.setSaveAsActivity(false);
        email.setUseSignature(false);
        email.setTargetObjectId(userInfo.getUserId());
        if(Label.NSP_OrgWideEmail_Insperity != null){
            email.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
        }
        return email;
    } 
    
    //check for the Regulated States
    public static List<String> getRegulatedAreaStates(){
        List<String> stateList = new List<String>();
        for(NSP_Regulated_Area__c regArea :[SELECT Id, NSP_State__c,  NSP_Regulation_Type__c 
                                            FROM NSP_Regulated_Area__c 
                                            WHERE NSP_State__c != null 
                                            AND NSP_Regulation_Type__c =: NSP_ServiceConstants.STATE_RET_PLAN ]){
                                                stateList.add(regArea.NSP_State__c);
                                            }
        return stateList;
    }
    
    
    
    public static Messaging.SingleEmailMessage getMailObject(Implementation_Profile__c ipRec, list<String> listOfTOAddresses,  List<Messaging.EmailFileAttachment> emailAttachments,  list<String> listOfCCAddresses,  Id templateId , Boolean isReRun){
        String Subject;
        //set template structure for the email template                            
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(!test.isRunningTest()){
            email= Messaging.renderStoredEmailTemplate(templateId, null ,ipRec.id);
        }
        if(isReRun){
            Subject = NSP_ServiceConstants.UpdateEmailSubject+ email.Subject;
        }      
        else {
            Subject =  email.Subject;
        }
        email.setSubject(Subject);
        if(listOfTOAddresses!=null && listOfTOAddresses.size()>0){
            email.setToAddresses(listOfTOAddresses);
        }
        
        if(listOfCCAddresses!=null && listOfCCAddresses.size()>0){
            email.setCcAddresses(listOfCCAddresses);
        }                                     
              
        if(emailAttachments!=null && emailAttachments.size()>0){
            email.setFileAttachments(emailAttachments);
        }
        email.setTargetObjectId(userInfo.getUserId());
        
        if(templateId!=null && !String.isBlank(templateId)){
            email.setTemplateId(templateId);
        }
        email.setSaveAsActivity(false);
        if(Label.NSP_OrgWideEmail_Insperity!=null){
            email.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
        }
        email.setWhatId(ipRec.id);
        return email;        
    }    
       
}