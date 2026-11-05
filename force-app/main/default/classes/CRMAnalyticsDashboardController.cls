public with sharing class CRMAnalyticsDashboardController {
    // test w/ CRMAnalyticsDashboardControllerTest (100%)

    @AuraEnabled(cacheable=true)
    public static CRM_Analytics_Dashboard_Settings__c getDashboardSettings() {
        return CRM_Analytics_Dashboard_Settings__c.getInstance( UserInfo.getUserId() );
    }

}
//
