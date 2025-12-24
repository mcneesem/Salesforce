@isTest
private class NSP_UserTriggerHelper_Test {
    public static final String ACCOUNTTEST1 = 'AccountTest';
    private static final List<String> USER_FIELDS = new List<String>{'Id', 'NSP_Profile_Name__c'};
    private static final String phonenumber = '(112)6475261 ext415';

    @testSetup
    private static void setupTestData() {
        UserTriggerSettings__c settings = UserTriggerSettings__c.getOrgDefaults();
        settings.AllowedAdmins__c = UserInfo.getUserId();
        settings.BccAddresses__c = UserInfo.getUserEmail();
        upsert settings;
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
        
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc.Name = 'Test Acc';
        insert acc;

        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Phone = NSP_UserTriggerHelper_Test.phonenumber;
        tUser.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER;
        tUser.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser;

        User t1User =  NSP_TestHelper.createUser(false);
        t1User.Phone = NSP_UserTriggerHelper_Test.phonenumber;
        t1User.NSP_Financial_Force_User__c = 'Full Access';
        t1User.Username = 'testuser@test.com' + System.currentTimeMillis();
        insert t1User;

        ServiceResource sr  =  new ServiceResource();
        sr.Name = 'Service Resource';
        sr.RelatedRecordId = tUser.Id;
        insert  sr;

        Id woRecord = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );

        Asset asset = new Asset();
        Asset.Name = 'Test Asset';
        asset.RecordTypeId = woRecord;
        asset.AccountId = acc.Id;
        asset.NSP_Account_Status__c = 'Active';
        insert asset;

        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = acc.Id;
        accTeam.NSP_User__c = tUser.Id;
        accTeam.NSP_Role__c = 'Manager, HR Services';
        Insert accTeam;
    }

    private static testMethod void updatePhoneNumberTest() {
        Test.startTest();
        User users = [Select Id, Name,Phone from User WHERE Username =: NSP_TestHelper.DEFAULT_USERNAME LIMIT 1]; //Added WHERE Condition as part of code fix
        users.Phone = NSP_UserTriggerHelper_Test.phonenumber;
        update users;
        users.Phone = '(122)6475261 ext415';
        update users;
        users.Phone = '(122)6475261 x415';
        update users;
        Test.stopTest();
        system.assertEquals(users.Phone, '(122)6475261 x415');
    }

    private static testMethod void updatePhoneNumberTest1() {
        Test.startTest();
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Username = 'updatePTest39@user.com';
        tUser.Email = 'updatePTest39@insperity.com';
        tUser.Phone = '(312)6475261 ext415';
        insert tUser;
        Test.stopTest();
        system.assertEquals(tUser.Phone, '(312)6475261 ext415');
    }

    @isTest
    private static void salesOfficeTest() {
        NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;

       NSP_Sales_Office_Mapping__c office1Mapping = new NSP_Sales_Office_Mapping__c();
        office1Mapping.NSP_Sales_Office__c = '301';
        office1Mapping.NSP_Sales_Division__c = 'Central';
        office1Mapping.NSP_Sales_Region__c = 'Central 1';
        office1Mapping.NSP_Start_Date__c = system.today()-1;
        office1Mapping.NSP_End_Date__c = system.today()+200;
        insert office1Mapping;

        Test.startTest();
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Username = 'Testsalesoffic@user.com';
        tUser.Email = 'Test1239@insperity.com';
        tUser.Phone = '(313)6475261 ext415';
        tUser.NSP_Sales_Office__c = '301';
        tUser.NSP_Sales_Office_Membership__c = '301';
        insert tUser;

        Account accoutObject = new Account();
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
            accoutObject.Name = ACCOUNTTEST1;
            accoutObject.recordTypeId=partnerRecordTypeId;
            accoutObject.DNB_Connect_DUNS_Number__c = '876543987';
            accoutObject.OwnerId = tUser.Id;
            insert accoutObject;

        System.runAs (tUser) {
            List<PermissionSet> pSets = [Select Id FROM PermissionSet WHERE Name = 'User_Share_SO_Update' Limit 1];
            if( pSets != null && !pSets.isEmpty() ){
                PermissionSetAssignment assignment = new PermissionSetAssignment(
                    PermissionSetId = pSets[0].Id,
                    AssigneeId = tUser.Id);
                insert assignment;
            }
            tUser.NSP_Sales_Office__c = '1081';
            tUser.NSP_Sales_Office_Membership__c = '1081';
            Update tUser;
        }
        System.assert(tUser.NSP_Sales_Office__c == '1081');
        Test.stopTest();
    }

    @isTest
    private static void updateAssetServiceRegionTest() {
        Test.startTest();
        User user = [SELECT Id, Phone, NSP_Service_Region__c  FROM User WHERE Phone = :NSP_UserTriggerHelper_Test.phonenumber LIMIT 1];
        user.NSP_Service_Region__c = 'MMSO - Southwest';
        update user;
        System.assert(user.NSP_Service_Region__c == 'MMSO - Southwest');
        Test.stopTest();
    }

    @isTest
    private static void processUserPermissionsNegativeTest() {
        Test.startTest();
        User user = [SELECT Id, Phone, NSP_Service_Region__c  FROM User WHERE Phone = :NSP_UserTriggerHelper_Test.phonenumber LIMIT 1];
        user.Phone = '12345676';
        update user;

        Test.stopTest();

        Set<String> setPermissionSetName = new Set<String>();
        for(PermissionSetAssignment psa : [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :user.Id]){
            setPermissionSetName.add(psa.PermissionSet.Name);
        }

        system.assert(!setPermissionSetName.contains('FSL_Resource_License'));
        system.assert(!setPermissionSetName.contains('EinsteinActivityCaptureIncluded'));
        system.assert(!setPermissionSetName.contains('FSL_Resource_Permissions_Read_Only'));
    }

    @isTest
    private static void processUserPermissions_Test() {
        Test.startTest();
        User user = [SELECT Id, Phone, NSP_Service_Region__c  FROM User WHERE Phone = :NSP_UserTriggerHelper_Test.phonenumber LIMIT 1];
        user.NSP_Salesforce_Field_service__c = 'Resource';
        user.NSP_Dispatch_Region__c = 'Central';
        update user;

        Test.stopTest();

        Set<String> setPermissionSetName = new Set<String>();
        for(PermissionSetAssignment psa : [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :user.Id]){
            setPermissionSetName.add(psa.PermissionSet.Name);
        }

        system.assertNotEquals(setPermissionSetName, null);
    }

    @isTest
    private static void addtoServiceProfilePublicGroupTest() {
        List<String> profileFields = new List<String>{'Id', 'Name'};
        Profile peoProfileId =  Database.query(new NSP_QueryBuilder('Profile', profileFields).addFilter('Name', NSP_ServiceConstants.PEOSERVICE).addLimit(1).setSecurityEnforce(false).build());
        Profile integrationUserId =  Database.query(new NSP_QueryBuilder('Profile', profileFields).addFilter('Name', NSP_ServiceConstants.INTEGRATION_USER).addLimit(1).setSecurityEnforce(false).build());
        User peoUser = new User(
            ProfileId = peoProfileId.Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert peoUser;


        // Query PEO User
        String userQuery = new NSP_QueryBuilder('User', USER_FIELDS).addFilter('NSP_User_Profile_Name__c', NSP_ServiceConstants.PEOSERVICE).addLimit(1).setSecurityEnforce(false).build();
        User getPeoUser =  Database.query(userQuery);

        Test.startTest();
        getPeoUser.ProfileId = integrationUserId.Id;
        update getPeoUser;
        Test.stopTest();
    }

    @isTest
    private static void assignPSAPermissionTest() {
        List<String> userFields = new List<String>{
            'Id',
                'NSP_Financial_Force_User__c',
                'NSP_Service_Region__c',
                'Name'
                };
                    String queryUser = new NSP_QueryBuilder('User', userFields)
                    .addFilter('NSP_Service_Region__c', 'MMSO - Southeast').addLimit(1).setSecurityEnforce(false).build();
        User user = Database.query(queryUser);
        // Start Test
        System.runAs (user) {
            Test.startTest();
            update user;
            Test.stopTest();
        }
        List<PermissionSetAssignment> psa = [SELECT Id ,AssigneeId ,PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =:user.Id  ];
        System.assertNotEquals(psa.size(), 0 );
    }

    @isTest
    private static void assignPSAPermissionReadTest() {
        List<String> userFields = new List<String>{
            'Id',
                'NSP_Financial_Force_User__c',
                'Name'
                };
                    String queryUser = new NSP_QueryBuilder('User', userFields)
                    .addFilter('NSP_Financial_Force_User__c' , 'Full Access').addLimit(1).setSecurityEnforce(false).build();
        User user = Database.query(queryUser);
        user.NSP_Financial_Force_User__c = 'Read Only';
        // Start Test
        System.runAs (user) {
            Test.startTest();
            update user;
            System.assert(user.NSP_Financial_Force_User__c == 'Read Only');
            Test.stopTest();
        }
    }

    @isTest
    private static void testValidateProfileChanges() {
        Test.startTest();
        User record = new User(
            Id=UserInfo.getUserId() ,
            Email=UserInfo.getUserEmail() ,
            FirstName=UserInfo.getFirstName() ,
            ProfileId='00e4x000001r0zsAAA' // System Administrator
        );
        User oldRecord = new User(
            Id=UserInfo.getUserId() ,
            Email=UserInfo.getUserEmail() ,
            FirstName=UserInfo.getFirstName() ,
            ProfileId='00e4x000001dm3lAAA' // System Admin Lite
        );
        NSP_UserTriggerHelper helper = new NSP_UserTriggerHelper();
        helper.testValidateProfileChanges( record , oldRecord );
        Test.stopTest();
    }

}
//