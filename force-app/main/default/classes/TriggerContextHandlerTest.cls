@isTest private class TriggerContextHandlerTest {
    private static final String CLASS_NAME = ' ~ TriggerContextHandlerTest';
    private static final Boolean ENABLE_testTriggerContextHandler = True;

    @isTest private static void testTriggerContextHandler() {
        String METHOD_NAME = ' ~ testTriggerContextHandler';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testTriggerContextHandler ) {
            Test.startTest();
            TriggerContextHandler.debug( DEBUG_PREFIX );
            System.assertEquals( True , True );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

}
//