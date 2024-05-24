@isTest private class ApexExceptionEmailHandlerTest {
    private static final String CLASS_NAME = ' ~ ApexExceptionEmailHandlerTest';
    private static final Boolean ENABLE_testApexExceptionEmailHandler = True;

    @isTest private static void testApexExceptionEmailHandler() {
        String METHOD_NAME = ' ~ testApexExceptionEmailHandler';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testApexExceptionEmailHandler ) {
            Test.startTest();
            ApexExceptionEmailHandler handler = new ApexExceptionEmailHandler();
            Assert.isNotNull( handler , 'ApexExceptionEmailHandler was not constructed.' );
            Messaging.InboundEmailResult result = handler.handleInboundEmail( null , null );
            Assert.isNotNull( result , 'Messaging.InboundEmailResult was not returned.' );
            Test.stopTest();
        }
    }

}
//