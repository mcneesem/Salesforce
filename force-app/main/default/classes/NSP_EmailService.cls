public with sharing class NSP_EmailService {
    // test w/ NSP_EmailServiceTest (93%)

    public static void sendEmail( Map<Id,Id> mRecordtoUser , String emailDeveloperName ) {
        if ( EmailDeliverabilityController.isEnabledOutbound
            && ( mRecordtoUser != null )
            && !mRecordtoUser.isEmpty()
            && String.isNotBlank( emailDeveloperName )
            )
        {
            List<EmailTemplate> templates = [
                SELECT Id
                FROM EmailTemplate
                WHERE ( DeveloperName = :emailDeveloperName )
            ];
            Id iEmailTemplate = null;
            if ( ( templates != null ) && !templates.isEmpty() ) {
                iEmailTemplate = templates[0].Id;
            }
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            if ( iEmailTemplate != null ) {
                for ( Id recordId : mRecordtoUser.keySet() ) {
                    Messaging.SingleEmailMessage message = Messaging.renderStoredEmailTemplate(
                        iEmailTemplate ,
                        mRecordtoUser.get( recordId ) ,
                        recordId
                    );
                    message.setTargetObjectId( mRecordtoUser.get( recordId ) );
                    message.setTemplateId( iEmailTemplate );
                    message.setSaveAsActivity( false );
                    if ( String.isNotBlank( Label.NSP_OrgWideEmail_Insperity ) && !Test.isRunningTest() ) {
                        message.setOrgWideEmailAddressId( Label.NSP_OrgWideEmail_Insperity );
                    }
                    messages.add( message );
                }
            }
            if ( !messages.isEmpty() ) {
                Messaging.SendEmailResult[] results = Messaging.sendEmail( messages );
            }
        }
    }

}
//