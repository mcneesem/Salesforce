@isTest
private class CRMAnalyticsDashboardControllerTest {

    @testSetup
    private static void setup() {
        CRM_Analytics_Dashboard_Settings__c settings = CRM_Analytics_Dashboard_Settings__c.getOrgDefaults();
        settings.Sales_Links_Dashboard_Id__c = 'linksdashboard-Id';
        settings.SDR_BDR_Dashboard_Id__c = 'sdrbdrdashboard-Id';
        upsert settings;
    }

    @isTest
    private static void testDashboard() {
        CRM_Analytics_Dashboard_Settings__c result = CRMAnalyticsDashboardController.getDashboardSettings();
        String expected =  'linksdashboard-Id';
        String expectedSDR = 'sdrbdrdashboard-Id';
        System.Assert.areEqual(expected, result.Sales_Links_Dashboard_Id__c);
        System.Assert.areEqual(expectedSDR, result.SDR_BDR_Dashboard_Id__c);
    }

}