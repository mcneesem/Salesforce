@isTest
private class JobRunnerEmailHandlerTest {

    @isTest
    private static void testJobRunnerEmailHandler() {
        Test.startTest();
        JobRunnerEmailHandler handler = new JobRunnerEmailHandler();
        Assert.isNotNull( handler , 'JobRunnerEmailHandler was not constructed.' );
        Messaging.InboundEmailResult result = handler.handleInboundEmail( null , null );
        Assert.isNotNull( result , 'Messaging.InboundEmailResult was not returned.' );
        Test.stopTest();
    }

}
//