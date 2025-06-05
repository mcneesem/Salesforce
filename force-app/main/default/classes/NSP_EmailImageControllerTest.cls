@isTest
private class NSP_EmailImageControllerTest {

    @isTest private static void getURLsTest() {
        Test.startTest();
        NSP_EmailImageController emailController = new NSP_EmailImageController();
        String footLogoUrl = emailController.getFooterLogoUrl();
        String headLogoUrl = emailController.getHeaderLogoUrl();
        String servicelogoUrl = emailController.getServiceOperationsLogoUrl();
        String copywriteUrl = emailController.getCopyWriteLogoUrl();
        String hrLogoUrl = emailController.getHRLogoLogoUrl();
        System.assert(footLogoUrl != '');
        System.assert(headLogoUrl != '');
        System.assert(servicelogoUrl != '');
        System.assert(copywriteUrl != '');
        System.assert(hrLogoUrl != '');
        Test.stopTest();
    }
}
//