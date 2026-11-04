public with sharing class DashboardWrapperController {
    // test w/ DashboardWrapperControllerTest (100%)

    @AuraEnabled(cacheable=true)
    public static Dashboard_Wrapper_Settings__c getDashboardWrapperSettings() {
        return Dashboard_Wrapper_Settings__c.getInstance( UserInfo.getUserId() );
    }
}
