@isTest
private class NSP_GuidanceForSuccessControllerTest {

    @isTest
    private static void getGuidanceForSuccessMessagesTest() {
        Test.startTest();
        String message1 = NSP_GuidanceForSuccessController.getMessage('Discovery', 'WS', null);
        String message2 = NSP_GuidanceForSuccessController.getMessage('Discovery', '', null);
        String message3 = NSP_GuidanceForSuccessController.getMessage('Analysis', '', null);
        Test.stopTest();
        system.assert(message1.length() > 0); 
        system.assert(message2.length() > 0);
        system.assert(message3.length() > 0); 
    }

}
//