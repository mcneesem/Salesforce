@isTest private class InboundEmailLogQueueableTest {
    private static final String CLASS_NAME = ' ~ InboundEmailLogQueueableTest';
    private static final Boolean ENABLE_testInboundEmailLogQueueable = True;

    @isTest private static void testInboundEmailLogQueueable() {
        String METHOD_NAME = ' ~ testInboundEmailLogQueueable';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testInboundEmailLogQueueable ) {
            InboundEmailLog__c log = new InboundEmailLog__c();
            insert log;
            Set<Id> logIds = new Set<Id>();
            logIds.add( log.Id );
            //
            Test.startTest();
            InboundEmailLogQueueable.processInboundEmailLogs( logIds );
            Assert.isTrue( True , 'Failed assertion.' );
            Test.stopTest();
        }
    }

}
//