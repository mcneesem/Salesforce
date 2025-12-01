@isTest
private class CRMAnalyticsDashboardControllerTest {

    @testSetup
    private static void setup() {
        CRM_Analytics_Dashboard_Settings__c settings = CRM_Analytics_Dashboard_Settings__c.getOrgDefaults();
        settings.Dashboard_Id__c = 'dashboard-Id';
        upsert settings;
    }

    @isTest 
    private static void testDashboard() {
        CRM_Analytics_Dashboard_Settings__c result = CRMAnalyticsDashboardController.getDashboardSettings();
        String expected =  'dashboard-Id';
        System.Assert.areEqual(expected, result.Dashboard_Id__c);
    }

}