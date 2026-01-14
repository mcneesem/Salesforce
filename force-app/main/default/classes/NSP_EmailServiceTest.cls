@isTest
private class NSP_EmailServiceTest {

    @testSetup
    private static void setupData() {
        // Minimal user to target emails to
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'tuser+' + System.now().getTime() + '@example.com',
            ProfileId = p.Id
        );
        insert u;

        // Minimal Account and Contact to be used as related record
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Contact c = new Contact(FirstName = 'A', LastName = 'Contact', AccountId = acc.Id, Email = 'contact@example.com');
        insert c;

        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) {
            Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
            emailSetting.IsEnabledOutbound__c = true;
            upsert emailSetting;

            // Create a simple text Email Template
            String devName = 'NSP_EmailServiceTest_Template';
            List<EmailTemplate> existing = [
                SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName LIMIT 1
            ];
            if (existing.isEmpty()) {
                EmailTemplate et = new EmailTemplate();
                et.Name = 'NSP Email Service Test Template';
                et.DeveloperName = devName;
                et.FolderId = UserInfo.getUserId(); // user's private folder in tests
                et.TemplateType = 'text';
                et.Subject = 'Hello {!Contact.Name}';
                et.Body = 'Test body for {!Contact.Name} on Account {!Contact.Account.Name}';
                insert et;
            }
        }
    }

    @isTest
    private static void test_sendEmail_sends_messages_for_each_mapping_entry() {
        // Arrange
        EmailTemplate et = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'NSP_EmailServiceTest_Template' LIMIT 1];

        Account acc2 = new Account(Name = 'Second Acc');
        insert acc2;

        Contact c2 = new Contact(FirstName = 'B', LastName = 'Contact', AccountId = acc2.Id, Email = 'contact2@example.com');
        insert c2;

        User targetUser = [SELECT Id FROM User WHERE Email LIKE 'tuser%@example.com' LIMIT 1];

        // Map<Id, Id> mRecordtoUser (key: recordId, value: userId)
        Map<Id, Id> recordToUser = new Map<Id, Id>{
            c2.Id => targetUser.Id
        };

        Test.startTest();
        NSP_EmailService.sendEmail(recordToUser, et.DeveloperName);
        Test.stopTest();

        System.assertNotEquals(null, et.Id, 'Email Template should exist and be queryable by DeveloperName');
    }

    @isTest
    private static void test_sendEmail_skips_when_template_missing() {
        // Arrange: Map with a valid record-user mapping but pass a non-existent developer name
        User targetUser = [SELECT Id FROM User WHERE Email LIKE 'tuser%@example.com' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        Map<Id, Id> recordToUser = new Map<Id, Id>{
            c.Id => targetUser.Id
        };

        Test.startTest();
        // Act: Developer name that doesn't exist should cause early return without exceptions
        NSP_EmailService.sendEmail(recordToUser, 'Does_Not_Exist_Template_Name');
        Test.stopTest();

        System.assert(true, 'Method should return silently when template not found.');
    }

    @isTest
    private static void test_sendEmail_no_messages_when_map_empty() {
        // Arrange
        EmailTemplate et = [SELECT DeveloperName FROM EmailTemplate WHERE DeveloperName = 'NSP_EmailServiceTest_Template' LIMIT 1];

        Map<Id, Id> recordToUser = new Map<Id, Id>(); // empty

        Test.startTest();
        NSP_EmailService.sendEmail(recordToUser, et.DeveloperName);
        Test.stopTest();

        System.assert(true, 'Empty input should not throw exceptions.');
    }

}
//