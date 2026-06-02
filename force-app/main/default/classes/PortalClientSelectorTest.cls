@isTest
private class PortalClientSelectorTest {

    @isTest
    private static void testGetPortalClients() {
        Test.startTest();
        PortalClientSelector.getPortalClients();
        Test.stopTest();
    }

    @isTest
    private static void testIsCommunityContext() {
        Test.startTest();
        PortalClientSelector.isCommunityContext();
        Test.stopTest();
    }

    @isTest
    private static void testGetPortalLinks() {
        Test.startTest();
        PortalClientSelector.getPortalLinks( UserInfo.getUserId() );
        Test.stopTest();
    }

    @isTest
    private static void testLogInfo() {
        Test.startTest();
        PortalClientSelector.logInfo( 'class' , 'method' , 'info' );
        PortalClientSelector.testHandleException( null , 'test' );
        Test.stopTest();
    }

}
//