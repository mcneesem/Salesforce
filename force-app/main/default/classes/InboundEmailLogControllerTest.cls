@isTest private class InboundEmailLogControllerTest {
    private static final String CLASS_NAME = ' ~ InboundEmailLogControllerTest';
    private static final Boolean ENABLE_testInboundEmailLogController = True;

    @testSetup private static void upsertCustomSettings() {
        InboundEmailLogSettings__c settings = InboundEmailLogSettings__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        upsert settings;
    }

    @isTest private static void testInboundEmailLogController() {
        String METHOD_NAME = ' ~ testInboundEmailLogController';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testInboundEmailLogController ) {
            Test.startTest();
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            email.toAddresses = new List<String>();
            email.toAddresses.add( 'to@test.com.invalid' );
            email.ccAddresses = new List<String>();
            email.ccAddresses.add( 'cc@test.com.invalid' );
            InboundEmailLogController.insertInboundEmailLog(
                email ,
                new Messaging.InboundEnvelope()
            );
            List<InboundEmailLog__c> records = [ SELECT Id FROM InboundEmailLog__c ];
            Assert.isNotNull( records , 'Null InboundEmailLog__c query results.' );
            Assert.isTrue( ( records.size() > 0 ) , 'No InboundEmailLog__c query results.' );
            Assert.isTrue( ( records.size() == 1 ) , 'Incorrect InboundEmailLog__c query results.' );
            Test.stopTest();
        }
    }

}
//