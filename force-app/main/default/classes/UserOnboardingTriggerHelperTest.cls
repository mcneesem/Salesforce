@isTest
private class UserOnboardingTriggerHelperTest {

    @testSetup
    private static void setupData() {
        UserOnboardingToolSettings__c settings = UserOnboardingToolSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsEnabledRemoval__c = true;
        upsert settings;
        //
        User u = new User(
         ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'].Id,
            LastName = 'Test',
            Email = 'hackathon@insperity.com',
            Username = 'hackathon@insperity.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            isActive = TRUE,
            UserPermissionsKnowledgeUser = TRUE,
            UserPermissionsMarketingUser = TRUE,
            UserPermissionsSupportUser = TRUE,
            UserPermissionsInteractionUser = TRUE,
            Business_Title__c = 'Contact Center Agent'
        );
        insert u;
    }

    @isTest
    private static void beforeInsertUserTest() {
        Test.startTest();
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'].Id,
            LastName = 'Test2',
            Email = 'hackathon2@insperity.com',
            Username = 'hackathon2@insperity.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            isActive = TRUE,
            UserPermissionsKnowledgeUser = TRUE,
            UserPermissionsMarketingUser = TRUE,
            UserPermissionsSupportUser = TRUE,
            UserPermissionsInteractionUser = TRUE,
            Business_Title__c = 'Contact Center Agent'
        );
        insert u;
        Test.stopTest();
    }

    @isTest
    private static void beforeUpdateUserTest() {
        User userTest = [SELECT Id FROM User WHERE email = 'hackathon@insperity.com'];
        Test.startTest();
        userTest.Business_Title__c = 'Contact Center Manager';
        update userTest;
        Test.stopTest();
    }

}
//