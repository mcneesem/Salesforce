@isTest private class UserOnboardingQueuableTest {

    @testSetup private static void setupTestData() {
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
            CompanyName = 'TESTHACK',
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

    @isTest private static void insertTest() {
        test.startTest();
        List<user> userList = [SELECT ID from User Where CompanyName = 'TESTHACK'];
		System.enqueueJob(new UserOnboardingQueuable(userlist , null , null, 'afterinsert'));
        test.stopTest();
    }
    
    @isTest private static void updateTest() {
        test.startTest();
        List<user> userList = [SELECT ID from User Where CompanyName = 'TESTHACK'];
		System.enqueueJob(new UserOnboardingQueuable(userlist , null , null, 'afterupdate'));
        test.stopTest();
    }
    
    @isTest private static void createErrorLogTest() {
        test.startTest();
        UserOnboardingQueuable.createErrorLog('ClassName', 'MethodName' , 'Description');
        test.stopTest();
    }

}
//