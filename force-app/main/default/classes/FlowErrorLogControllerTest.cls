@isTest private class FlowErrorLogControllerTest {
    private static final String CLASS_NAME = ' ~ FlowErrorLogControllerTest';
    private static final Boolean ENABLE_testFlowErrorLogController = True;

    @testSetup private static void upsertCustomSettings() {
        InboundEmailLogSettings__c settings = InboundEmailLogSettings__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        upsert settings;
    }

    @isTest private static void testFlowErrorLogController() {
        String METHOD_NAME = ' ~ testFlowErrorLogController';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testFlowErrorLogController ) {
            Test.startTest();
            List<InboundEmailLog__c> logs = new List<InboundEmailLog__c>();
            logs.add(
                new InboundEmailLog__c(
                    Subject__c='An error occurred with your ' ,
                    HtmlBody__c=''
                    + 'Error element XXXXX_XXXXX_XXXXX (FlowXXXXX). You can look up ExceptionCode\r\n'
                    + 'An Apex error occurred.. You can look up ExceptionCode\r\n'
                    + 'Flow API Name: XXXXX_XXXXX_XXXXX\r\n'
                    + 'Type: Screen Flow\r\n'
                    + 'Version: 1\r\n'
                    + 'Org: XXXXX (00DXXX000XXXXXX)\r\n'
                    + 'Interview GUID: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXX\r\n'
                    + 'Interview Label: XXXXX XXXXX XXXXX MM/DD/YYYY HH:MM XM\r\n'
                    + 'Start time: MM/DD/YYYY HH:MM XM\r\n'
                    + 'Duration: # seconds\r\n'
                    + 'Current User: XXXXX XXXXX (' + UserInfo.getUserId() + ')\r\n'
                    + 'API Version for Running the Flow: 56\r\n'
                )
            );
            FlowErrorLogController.insertFlowErrorLogs( logs );
            List<FlowErrorLog__c> records = [ SELECT Id FROM FlowErrorLog__c ];
            Assert.isNotNull( records , 'Null FlowErrorLog__c query results.' );
            Assert.isTrue( ( records.size() > 0 ) , 'No FlowErrorLog__c query results.' );
            Assert.isTrue( ( records.size() == 1 ) , 'Incorrect FlowErrorLog__c query results.' );
            Test.stopTest();
        }
    }

}
//