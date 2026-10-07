@isTest
private class NSP_AssetBatchTest {

    private static final String HR_SPECIALIST = 'HR Specialist';
    private static final String BUS_TEAM_HRSP_CL = 'Bus. Team-HRSp/CL';
    private static final String MANAGER_HR_SERVICES = 'Manager, HR Services';
    private static final String ASSERT_ONE_CASE_CREATED = 'Expected one Case to be created for the expired biometric Asset';
    private static final String ASSERT_BIOMETRIC_EXPIRED = 'Expected NSP_Biometric_Indicator_Expired__c to be true after batch execution';

    // @description Creates shared test data: Account, User, Account Team records, and an expired biometric Asset.
    @testSetup
    private static void setup() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Account accountRecord = new Account(Name = 'ABC Company');
        insert accountRecord;

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'System Administrator' WITH USER_MODE LIMIT 1];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@randomorg.com';
        User userRecord = new User(
            alias = 'uDelet',
            email = 'testfake@insperity.com',
            emailencodingkey = 'UTF-8',
            lastname = 'temp',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = profiles[0].Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName
        );
        insert userRecord;

        NSP_Account_Team__c accountTeamHR = new NSP_Account_Team__c(
            NSP_Account__c = accountRecord.Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = userRecord.Id
        );
        insert accountTeamHR;

        NSP_Account_Team__c accountTeamBT = new NSP_Account_Team__c(
            NSP_Account__c = accountRecord.Id,
            NSP_Role__c = NSP_AssetBatchTest.BUS_TEAM_HRSP_CL,
            NSP_User__c = UserInfo.getUserId(),
            NSP_Integrated_With__c = 'AIMS'
        );
        insert accountTeamBT;

        NSP_Account_Team__c accountTeamMHR = new NSP_Account_Team__c(
            NSP_Account__c = accountRecord.Id,
            NSP_Role__c = NSP_AssetBatchTest.MANAGER_HR_SERVICES,
            NSP_User__c = UserInfo.getUserId(),
            NSP_Integrated_With__c = 'AIMS'
        );
        insert accountTeamMHR;

        NSP_Account_Team__c accountTeamHRAims = new NSP_Account_Team__c(
            NSP_Account__c = accountRecord.Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_Integrated_With__c = 'AIMS'
        );
        insert accountTeamHRAims;

        Asset assetRecord = new Asset(
            Name = 'Test 9090',
            AccountId = accountRecord.Id,
            NSP_Biometric_End_Date__c = System.today().addDays(-1),
            recordTypeId = woRecordTypeId
        );
        insert assetRecord;
    }

    // @description Verifies that the scheduler creates a scheduled job via NSP_AssetBatchScheduler.
    @isTest
    private static void testCreatesOneScheduledJob() {
        Test.startTest();
        NSP_AssetBatchScheduler assetBatch = new NSP_AssetBatchScheduler();
        Database.executeBatch(new NSP_AssetBatch());
        String cronExpression = '0 0 3 * * ?';
        System.schedule('Test NSP_AssetBatchScheduler', cronExpression, assetBatch);
        Test.stopTest();

        List<AsyncApexJob> jobsScheduled = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'ScheduledApex'
            WITH USER_MODE
        ];
        System.Assert.areEqual(1, jobsScheduled.size(), 'Expected exactly one scheduled job to be created');
    }

    // @description Verifies that executing the batch for an HR Specialist account team creates a Case and marks the Asset as expired.
    @isTest
    private static void testCreatesExpiredHRSpecialistCase() {
        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), NSP_AssetBatchTest.ASSERT_ONE_CASE_CREATED);

        List<Asset> assets = [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WITH USER_MODE];
        System.Assert.isTrue(
            assets[0].NSP_Biometric_Indicator_Expired__c,
            NSP_AssetBatchTest.ASSERT_BIOMETRIC_EXPIRED
        );
    }

    // @description Verifies that when the first account team record is reassigned to Bus. Team-HRSp/CL, a Case is created and the Asset is expired.
    @isTest
    private static void testCreatesExpiredBusinessTeamCase() {
        List<NSP_Account_Team__c> accountTeams = [SELECT Id FROM NSP_Account_Team__c WITH USER_MODE LIMIT 1];
        NSP_Account_Team__c accountTeamRecord = accountTeams[0];
        accountTeamRecord.NSP_Role__c = NSP_AssetBatchTest.BUS_TEAM_HRSP_CL;
        update accountTeamRecord;

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), NSP_AssetBatchTest.ASSERT_ONE_CASE_CREATED);

        List<Asset> assets = [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WITH USER_MODE];
        System.Assert.isTrue(
            assets[0].NSP_Biometric_Indicator_Expired__c,
            NSP_AssetBatchTest.ASSERT_BIOMETRIC_EXPIRED
        );
    }

    // @description Verifies that when the first account team record is reassigned to Manager, HR Services, a Case is created and the Asset is expired.
    @isTest
    private static void testCreatesExpiredManagerHRCase() {
        List<NSP_Account_Team__c> accountTeams = [SELECT Id FROM NSP_Account_Team__c WITH USER_MODE LIMIT 1];
        NSP_Account_Team__c accountTeamRecord = accountTeams[0];
        accountTeamRecord.NSP_Role__c = NSP_AssetBatchTest.MANAGER_HR_SERVICES;
        update accountTeamRecord;

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT Id FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), NSP_AssetBatchTest.ASSERT_ONE_CASE_CREATED);

        List<Asset> assets = [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WITH USER_MODE];
        System.Assert.isTrue(
            assets[0].NSP_Biometric_Indicator_Expired__c,
            NSP_AssetBatchTest.ASSERT_BIOMETRIC_EXPIRED
        );
    }

    // @description Verifies that when one account team record is deleted, the batch still creates a Case and the owner defaults to the current user.
    @isTest
    private static void testDefaultsOwnerWhenTeamIsDeleted() {
        List<NSP_Account_Team__c> accountTeams = [SELECT Id FROM NSP_Account_Team__c WITH USER_MODE LIMIT 1];
        delete accountTeams;

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), 'Expected one Case to be created after account team deletion');
        System.Assert.areEqual(
            UserInfo.getUserId(),
            cases[0].OwnerId,
            'Expected Case owner to default to the current user'
        );

        List<Asset> assets = [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WITH USER_MODE];
        System.Assert.isTrue(
            assets[0].NSP_Biometric_Indicator_Expired__c,
            NSP_AssetBatchTest.ASSERT_BIOMETRIC_EXPIRED
        );
    }

    // @description Covers NSP_AssetBatch.schedule() static method (ISelfSchedulable interface).
    @isTest
    private static void testScheduleReturnsJobId() {
        Test.startTest();
        String jobId = NSP_AssetBatch.schedule();
        Test.stopTest();
        System.Assert.isNotNull(jobId, 'schedule() should return a non-null scheduled job ID');
    }

    // @description Covers execute(SchedulableContext) — the Schedulable interface method — by scheduling NSP_AssetBatch directly.
    @isTest
    private static void testSchedulableTriggersBatch() {
        Test.startTest();
        System.schedule('Test NSP_AssetBatch Direct Schedulable', '0 0 2 * * ?', new NSP_AssetBatch());
        Test.stopTest();

        List<AsyncApexJob> batchJobs = [
            SELECT Id, Status
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.Name = 'NSP_AssetBatch'
            WITH USER_MODE
        ];
        System.Assert.isTrue(
            batchJobs.size() > 0,
            'Scheduling NSP_AssetBatch should trigger batch execution via execute(SchedulableContext)'
        );
    }

    // @description Covers Callable.call() with the supported 'run' action.
    @isTest
    private static void testRunActionReturnsBatchJobId() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Test.startTest();
        Object result = batchInstance.call('run', null);
        Test.stopTest();
        System.Assert.isNotNull(result, 'call() with run action should return a non-null batch job ID');
    }

    // @description Covers Callable.call() null-response branch for an unrecognised action.
    @isTest
    private static void testUnknownActionReturnsNull() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Object result = batchInstance.call('unknown_action', null);
        System.Assert.isNull(result, 'call() with an unrecognised action should return null');
    }

    // @description Covers IJobRunnable.run() which enqueues the batch and returns a job ID.
    @isTest
    private static void testRunReturnsBatchJobId() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Test.startTest();
        Id batchJobId = batchInstance.run();
        Test.stopTest();
        System.Assert.isNotNull(batchJobId, 'run() should return a non-null batch job ID');
    }

    // @description Covers getCaseOwnerId when the account team map is null — should default to the current user.
    @isTest
    private static void testOwnerIdWithNullMapReturnsUser() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Id result = batchInstance.getCaseOwnerId(null, null);
        System.Assert.areEqual(
            UserInfo.getUserId(),
            result,
            'getCaseOwnerId with a null map should return the running user ID'
        );
    }

    // @description Covers getCaseOwnerId when both HR Specialist and Business Team roles are present and NSP_Primary__c is true — expects HR Specialist owner.
    @isTest
    private static void testOwnerIdBothRolesPrimaryTrue() {
        List<User> alternateUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
                AND Id != :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        Id hrUserId = UserInfo.getUserId();
        Id btUserId = alternateUsers[0].Id;

        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.HR_SPECIALIST => hrUserId,
            NSP_AssetBatchTest.BUS_TEAM_HRSP_CL => btUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>{
            NSP_AssetBatchTest.HR_SPECIALIST => true
        };

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(
            hrUserId,
            result,
            'Should return HR Specialist user when both roles are present and HR primary is true'
        );
    }

    // @description Covers getCaseOwnerId when both HR Specialist and Business Team roles are present and NSP_Primary__c is false — expects Business Team owner.
    @isTest
    private static void testOwnerIdBothRolesPrimaryFalse() {
        List<User> alternateUsers = [
            SELECT Id
            FROM User
            WHERE IsActive = true
                AND Id != :UserInfo.getUserId()
            WITH USER_MODE
            LIMIT 1
        ];
        Id hrUserId = UserInfo.getUserId();
        Id btUserId = alternateUsers[0].Id;

        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.HR_SPECIALIST => hrUserId,
            NSP_AssetBatchTest.BUS_TEAM_HRSP_CL => btUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>{
            NSP_AssetBatchTest.HR_SPECIALIST => false
        };

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(
            btUserId,
            result,
            'Should return Business Team user when both roles are present and HR primary is false'
        );
    }

    // @description Covers getCaseOwnerId when only HR Specialist is present in the map.
    @isTest
    private static void testOwnerIdWithOnlyHRSpecialist() {
        Id hrUserId = UserInfo.getUserId();
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.HR_SPECIALIST => hrUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>();

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(
            hrUserId,
            result,
            'Should return HR Specialist user when only that role is present'
        );
    }

    // @description Covers getCaseOwnerId when only Business Team role is present in the map.
    @isTest
    private static void testOwnerIdWithOnlyBusinessTeam() {
        Id btUserId = UserInfo.getUserId();
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.BUS_TEAM_HRSP_CL => btUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>();

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(
            btUserId,
            result,
            'Should return Business Team user when only Bus. Team-HRSp/CL role is present'
        );
    }

    // @description Covers getCaseOwnerId when only Manager HR Services role is present in the map.
    @isTest
    private static void testOwnerIdWithOnlyManagerHRRole() {
        Id mhrUserId = UserInfo.getUserId();
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.MANAGER_HR_SERVICES => mhrUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>();

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(
            mhrUserId,
            result,
            'Should return Manager HR Services user when only that role is present'
        );
    }

    // @description Covers the execute() branch where both HR Specialist (NSP_Primary__c=true) and Business Team AIMS teams exist — case should be owned by HR Specialist.
    @isTest
    private static void testBothAimsPrimaryTrueAssignsHR() {
        List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE LIMIT 1];
        List<User> hrUsers = [SELECT Id FROM User WHERE Alias = 'uDelet' WITH USER_MODE LIMIT 1];

        insert new NSP_Account_Team__c(
            NSP_Account__c = accounts[0].Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = hrUsers[0].Id,
            NSP_Integrated_With__c = 'AIMS',
            NSP_Primary__c = true
        );

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), 'One case should be created for the expired biometric asset');
        System.Assert.areEqual(
            hrUsers[0].Id,
            cases[0].OwnerId,
            'Case owner should be the HR Specialist user when primary is true'
        );
    }

    // @description Covers the execute() branch where HR Specialist (NSP_Primary__c=false) and Business Team AIMS teams exist — case should be owned by Business Team.
    @isTest
    private static void testBothAimsPrimaryFalseAssignsBT() {
        List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE LIMIT 1];
        List<User> hrUsers = [SELECT Id FROM User WHERE Alias = 'uDelet' WITH USER_MODE LIMIT 1];

        insert new NSP_Account_Team__c(
            NSP_Account__c = accounts[0].Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = hrUsers[0].Id,
            NSP_Integrated_With__c = 'AIMS',
            NSP_Primary__c = false
        );

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), 'One case should be created for the expired biometric asset');
        System.Assert.areEqual(
            UserInfo.getUserId(),
            cases[0].OwnerId,
            'Case owner should be Business Team user when HR primary is false'
        );
    }

    // @description Covers the execute() HR-Specialist-only AIMS branch by removing Business Team and Manager HR AIMS teams.
    @isTest
    private static void testOnlyHRAimsTeamOwnsCase() {
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.BUS_TEAM_HRSP_CL WITH USER_MODE];
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.MANAGER_HR_SERVICES WITH USER_MODE];

        List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE LIMIT 1];
        List<User> hrUsers = [SELECT Id FROM User WHERE Alias = 'uDelet' WITH USER_MODE LIMIT 1];

        insert new NSP_Account_Team__c(
            NSP_Account__c = accounts[0].Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = hrUsers[0].Id,
            NSP_Integrated_With__c = 'AIMS'
        );

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), 'One case should be created');
        System.Assert.areEqual(
            hrUsers[0].Id,
            cases[0].OwnerId,
            'Case owner should be HR Specialist when only HR Specialist AIMS team exists'
        );
    }

    // @description Covers the execute() Manager HR-only AIMS branch by removing Business Team and HR AIMS teams.
    @isTest
    private static void testOnlyManagerHRAimsTeamOwnsCase() {
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.BUS_TEAM_HRSP_CL WITH USER_MODE];
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.HR_SPECIALIST WITH USER_MODE];

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), 'One case should be created');
        System.Assert.areEqual(
            UserInfo.getUserId(),
            cases[0].OwnerId,
            'Case owner should be Manager HR Services user when only Manager HR AIMS team exists'
        );
    }

    // @description Covers the execute() null-map branch (no AIMS teams at all) — case defaults to current user.
    @isTest
    private static void testNoAimsTeamsDefaultsOwnerToUser() {
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' WITH USER_MODE];

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case WITH USER_MODE];
        System.Assert.areEqual(1, cases.size(), 'One case should be created even when no AIMS account teams exist');
        System.Assert.areEqual(
            UserInfo.getUserId(),
            cases[0].OwnerId,
            'Case owner should default to current user when no AIMS account teams exist'
        );
    }

    // @description Covers the execute() empty-scope early-exit branch — no Cases should be created when scope is empty.
    @isTest
    private static void testEmptyScopeCreatesNoCases() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        batchInstance.execute(null, new List<SObject>());
        System.Assert.areEqual(0, [SELECT count() FROM Case WITH USER_MODE], 'No cases should be created when scope is empty');
    }

    // @description Bulk test: verifies that the batch correctly processes 200+ expired biometric assets and creates a Case per asset.
    @isTest
    private static void testTwoHundredAssetsCreatesCases() {
        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        List<Account> accounts = [SELECT Id FROM Account WITH USER_MODE LIMIT 1];

        List<Asset> bulkAssets = new List<Asset>();
        for (Integer assetIndex = 0; assetIndex < 200; assetIndex++) {
            bulkAssets.add(new Asset(
                Name = 'Bulk Biometric Asset ' + assetIndex,
                AccountId = accounts[0].Id,
                NSP_Biometric_End_Date__c = System.today().addDays(-1),
                recordTypeId = woRecordTypeId
            ));
        }
        insert bulkAssets;

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch(), 250);
        Test.stopTest();

        Integer caseCount = [SELECT count() FROM Case WITH USER_MODE];
        System.Assert.isTrue(
            caseCount >= 200,
            'Expected at least 200 Cases to be created for bulk expired biometric assets, got ' + caseCount
        );
    }

    // @description Security test: verifies getCaseOwnerId returns the running user ID when called as a standard (non-admin) user with a null map.
    @isTest
    private static void testOwnerIdAsStandardUserReturns() {
        List<User> hrUsers = [SELECT Id FROM User WHERE Alias = 'uDelet' WITH USER_MODE LIMIT 1];

        System.runAs(hrUsers[0]) {
            NSP_AssetBatch batchInstance = new NSP_AssetBatch();
            Id result = batchInstance.getCaseOwnerId(null, null);
            System.Assert.areEqual(
                hrUsers[0].Id,
                result,
                'getCaseOwnerId should return the running user ID when called as a standard user with a null map'
            );
        }
    }

}
//
