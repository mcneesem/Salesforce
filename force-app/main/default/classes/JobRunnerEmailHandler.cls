global class JobRunnerEmailHandler implements Messaging.InboundEmailHandler {
    // test w/ JobRunnerEmailHandlerTest (87%)
    private static String CLASS_NAME = ' ~ JobRunnerEmailHandler';

    global Messaging.InboundEmailResult handleInboundEmail( Messaging.InboundEmail email , Messaging.InboundEnvelope envelope ) {
        String METHOD_NAME = 'handleInboundEmail';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        try {
            // job requests form the backbone of job-execution for the Job Runner LWC (c-job-runner)...
            JobRunnerController.handleJobRequest( email , envelope );
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