public with sharing class NSP_EmailService {
    // test w/ NSP_ResourceRequestTriggerHelper (81%)
    
    public static void sendEmail( Map<Id,Id> mRecordtoUser , String emailDeveloperName ) {
        if ( EmailDeliverabilityController.IsEnabledOutbound ) {
            Id iEmailTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName =: emailDeveloperName]?.Id;
            if( iEmailTemplate == null ) {
                return;
            }
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
            for(Id recordId : mRecordtoUser.keySet() ) {
                Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(iEmailTemplate, mRecordtoUser.get(recordId), recordId);
                message.setTargetObjectId(mRecordtoUser.get(recordId));
                message.setTemplateId(iEmailTemplate);
                message.setSaveAsActivity(false);
                if( Label.NSP_OrgWideEmail_Insperity != null && !Test.isRunningTest() ) {
                    message.setOrgWideEmailAddressId(Label.NSP_OrgWideEmail_Insperity);
                }
                messages.add(message);
            }
            if( messages.size() == 0 ) {
                return;
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }
    }
}
