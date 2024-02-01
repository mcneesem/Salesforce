public with sharing class InboundEmailLogController {
    // test w/ InboundEmailLogControllerTest (100%)
    private static String CLASS_NAME = ' ~ InboundEmailLogController';

    public static void insertInboundEmailLog( Messaging.InboundEmail email , Messaging.InboundEnvelope envelope ) {
        String METHOD_NAME = 'handleInboundEmail';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ isEnabled=' + InboundEmailLogController.isEnabled );
        if ( InboundEmailLogController.isEnabled ) {
            System.debug( DEBUG_PREFIX + ' ~ email=' + email );
            System.debug( DEBUG_PREFIX + ' ~ envelope=' + envelope );
            InboundEmailLog__c record = InboundEmailLogController.populateInboundEmailLog( email , envelope );
            if ( record != null ) {
                insert record;
            }
            System.debug( DEBUG_PREFIX + ' ~ record=' + record );
        }
    }

    //
    //
    //

    private static InboundEmailLogSettings__c settings {
        get {
            if ( settings == null ) {
                settings = InboundEmailLogSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    // ~ transcribe field values from InboundEmail and InboundEnvelope into an InboundEmailLog__c record...
    private static InboundEmailLog__c populateInboundEmailLog( Messaging.InboundEmail email , Messaging.InboundEnvelope envelope ) {
        InboundEmailLog__c emailLog = null;
        if ( ( envelope != null ) || ( email != null ) ) {
            emailLog = new InboundEmailLog__c();
        }
        if ( envelope != null ) {
            emailLog.InboundEnvelope__c = SchemaController.safeText(
                JSON.serializePretty( envelope ) ,
                sObjectType.InboundEmailLog__c.Fields.InboundEnvelope__c
            );
            emailLog.FromAddress__c = SchemaController.safeText(
                envelope.fromAddress ,
                sObjectType.InboundEmailLog__c.Fields.FromAddress__c
            );
            emailLog.ToAddress__c = SchemaController.safeText(
                envelope.toAddress ,
                sObjectType.InboundEmailLog__c.Fields.ToAddress__c
            );
        }
        if ( email != null ) {
            emailLog.InboundEmail__c = SchemaController.safeText(
                JSON.serializePretty( email ) ,
                sObjectType.InboundEmailLog__c.Fields.InboundEmail__c
            );
            emailLog.FromAddress__c = SchemaController.safeText(
                email.fromAddress ,
                sObjectType.InboundEmailLog__c.Fields.FromAddress__c
            );
            emailLog.FromName__c = SchemaController.safeText(
                email.fromName ,
                sObjectType.InboundEmailLog__c.Fields.FromName__c
            );
            emailLog.ReplyTo__c = SchemaController.safeText(
                email.replyTo ,
                sObjectType.InboundEmailLog__c.Fields.ReplyTo__c
            );
            if ( ( email.toAddresses != null ) && ( email.toAddresses.size() > 0 ) ) {
                emailLog.ToAddresses__c = SchemaController.safeText(
                    String.join( email.toAddresses , '\r\n' ) ,
                    sObjectType.InboundEmailLog__c.Fields.ToAddresses__c
                );
            }
            if ( ( email.ccAddresses != null ) && ( email.ccAddresses.size() > 0 ) ) {
                emailLog.CcAddresses__c = SchemaController.safeText(
                    String.join( email.ccAddresses , '\r\n' ) ,
                    sObjectType.InboundEmailLog__c.Fields.CcAddresses__c
                );
            }
            emailLog.Subject__c = SchemaController.safeText(
                email.subject ,
                sObjectType.InboundEmailLog__c.Fields.Subject__c
            );
            emailLog.PlainTextBody__c = SchemaController.safeText(
                email.plainTextBody ,
                sObjectType.InboundEmailLog__c.Fields.PlainTextBody__c
            );
            emailLog.HtmlBody__c = SchemaController.safeText(
                email.htmlBody ,
                sObjectType.InboundEmailLog__c.Fields.HtmlBody__c
            );
        }
        return emailLog;
    }

}
//