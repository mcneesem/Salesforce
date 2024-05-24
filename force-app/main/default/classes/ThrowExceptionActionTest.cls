@isTest private class ThrowExceptionActionTest {
    private static final String CLASS_NAME = ' ~ ThrowExceptionActionTest';
    private static final Boolean ENABLE_testThrowExceptionAction = True;

    @isTest private static void testThrowExceptionAction() {
        String METHOD_NAME = ' ~ testThrowExceptionAction';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testThrowExceptionAction ) {
            Test.startTest();
            ThrowExceptionAction.Request request = new ThrowExceptionAction.Request();
            request.isFuture = False;
            System.debug( DEBUG_PREFIX + ' ~ request=' + request );
            List<ThrowExceptionAction.Request> requests = new List<ThrowExceptionAction.Request>();
            requests.add( request );
            System.debug( DEBUG_PREFIX + ' ~ requests=' + requests );
            Exception exceptionThrown = null;
            try {
                ThrowExceptionAction.throwAction( requests );
            } catch ( Exception e ) {
                System.debug( DEBUG_PREFIX + ' ~ e=' + e );
                exceptionThrown = e;
            }
            Assert.isNotNull( exceptionThrown , 'Exception was not thrown.' );
            Test.stopTest();
        }
    }

}
//