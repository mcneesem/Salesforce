@isTest
private class NSP_EmailImageControllerTest {

    @isTest private static void getURLsTest(){
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

    @isTest private static void getIDsTest() {
        Test.startTest();
        Id nSP_HR_Id = new NSP_EmailImageController().getResourceId('Insperity_HR');
        Id nSP_Footer_Id = new NSP_EmailImageController().getResourceId('Insperity_Footer_Logo');
        Id nSP_Svc_Ops_Id = new NSP_EmailImageController().getResourceId('Insperity_Service_Operations');
        Id nSP_Copy_Id = new NSP_EmailImageController().getResourceId('Insperity_Copyright_Logo');
        Id nSP_HR_Logo_Id = new NSP_EmailImageController().getResourceId('Insperity_HR_Logo');
        Id nSP_bad_Id = new NSP_EmailImageController().getResourceId('Insperity_Copy_Write_Logo');
        System.assert(nSP_HR_Id != null);
        System.assert(nSP_Footer_Id != null);
        System.assert(nSP_Svc_Ops_Id != null);
        System.assert(nSP_Copy_Id != null);
        System.assert(nSP_HR_Logo_Id != null);
        System.assert(nSP_bad_Id == null);
        Test.stopTest();
    }
}
//