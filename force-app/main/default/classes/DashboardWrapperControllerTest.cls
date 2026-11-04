@isTest
private class DashboardWrapperControllerTest {

    @testSetup
    private static void setup() {
        Dashboard_Wrapper_Settings__c settings = Dashboard_Wrapper_Settings__c.getOrgDefaults();
        settings.SDR_BDR_Dashboard_Developer_Name__c = 'test-dashboard-dev-name';
        upsert settings;
    }

    @isTest
    private static void testGetDashboardWrapperSettings() {
        Dashboard_Wrapper_Settings__c result = DashboardWrapperController.getDashboardWrapperSettings();
        System.Assert.areEqual('test-dashboard-dev-name', result.SDR_BDR_Dashboard_Developer_Name__c);
    }

}
