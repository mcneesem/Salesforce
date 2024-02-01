global class ApexExceptionEmailHandler implements Messaging.InboundEmailHandler {
    // test w/ ApexExceptionEmailHandlerTest (87%)
    private static String CLASS_NAME = ' ~ ApexExceptionEmailHandler';

    // apex.exception@XXXXX.com.invalid;apexexceptionemailservice@XXXXX.XXXXX.apex.salesforce.com

    // Apex Developer Guide: Using the InboundEmail Object
    // ~ https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_email_inbound_using.htm
    // ~ Setup > Custom Code > Email Services
    //  ~ New Email Service > Apex Class: ApexExceptionEmailHandler
    //  ~ New Email Address > Context User: <active-user>
    //  ~ ApexExceptionEmailHandler executes as Context User

    global Messaging.InboundEmailResult handleInboundEmail( Messaging.InboundEmail email , Messaging.InboundEnvelope envelope ) {
        String METHOD_NAME = 'handleInboundEmail';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        try {
            // inbound email logging forms the backbone of record-keeping for Apex Exception Emails...
            InboundEmailLogController.insertInboundEmailLog( email , envelope );
        } catch ( Exception e ) {
            // ensure inbound email logging does not produce any unhandled exceptions...
            System.debug( DEBUG_PREFIX + ' ~ CATCH ~ e=' + e );
        }
        // always return successful result...
        // ~ InboundEmailResult:[message=null, success=true]
        return new Messaging.InboundEmailresult();
    }

}
//