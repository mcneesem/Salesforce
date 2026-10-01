@isTest
private class NSP_AssetBatchTest {

    private static final String HR_SPECIALIST = 'HR Specialist';
    private static final String BUS_TEAM_HRSP_CL = 'Bus. Team-HRSp/CL';
    private static final String MANAGER_HR_SERVICES = 'Manager, HR Services';

    @testSetup
    private static void setupProjectTaskdata() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Account oAccount = new Account(Name = 'ABC Company');
        insert oAccount;
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = : 'System Administrator' LIMIT 1];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@randomorg.com';
        User userRec = new User(
            alias = 'uDelet',
            email = 'testfake@insperity.com',
            emailencodingkey = 'UTF-8',
            lastname = 'temp',
            languagelocalekey = 'en_US',
            localesidkey = 'en_US',
            profileid = profileRec.Id,
            timezonesidkey = 'America/Los_Angeles',
            username = uniqueUserName
        );
        insert userRec;
        NSP_Account_Team__c oAccountTeam = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id, NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST, NSP_User__c = userRec.Id);
        insert oAccountTeam;
        NSP_Account_Team__c oAccountTeam2 = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id, NSP_Role__c = NSP_AssetBatchTest.BUS_TEAM_HRSP_CL, NSP_User__c = UserInfo.getUserId(), NSP_Integrated_With__c = 'AIMS');
        insert oAccountTeam2;
        NSP_Account_Team__c oAccountTeam3 = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id, NSP_Role__c = NSP_AssetBatchTest.MANAGER_HR_SERVICES, NSP_User__c = UserInfo.getUserId(), NSP_Integrated_With__c = 'AIMS');
        insert oAccountTeam3;
        NSP_Account_Team__c oAccountTeam1 = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id, NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST, NSP_Integrated_With__c = 'AIMS');
        insert oAccountTeam1;
        Asset oAsset = new Asset(Name = 'Test 9090', AccountId = oAccount.Id, NSP_Biometric_End_Date__c = System.today().addDays(-1), recordTypeId = woRecordTypeId);
        insert oAsset;
    }

    @isTest
    private static void assetScheduleTest() {
        Test.startTest();
        NSP_AssetBatchScheduler assetBatch = new NSP_AssetBatchScheduler();
        Database.executeBatch(new NSP_AssetBatch());
        String chroneExp = '0 0 3 * * ?';
        system.schedule('Test NSP_AssetBatchScheduler', chroneExp, assetBatch);
        Test.stopTest();
        List<AsyncApexJob> jobsScheduled = [SELECT Id, ApexClassID, ApexClass.Name, Status, JobType FROM AsyncApexJob WHERE JobType = 'ScheduledApex'];
        System.assertEquals(1, jobsScheduled.size());
    }

    @isTest
    private static void assetBatchHRTest() {
        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(TRUE, [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    @isTest
    private static void assetBatchBTTest() {
        Test.startTest();
        NSP_Account_Team__c oAccountTeam = [SELECT ID from NSP_Account_Team__c WHERE Id != null LIMIT 1];
        oAccountTeam.NSP_Role__c = NSP_AssetBatchTest.BUS_TEAM_HRSP_CL;
        update oAccountTeam;
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(TRUE, [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    @isTest
    private static void assetBatchMHRTest() {
        Test.startTest();
        NSP_Account_Team__c oAccountTeam = [SELECT ID FROM NSP_Account_Team__c WHERE Id != null LIMIT 1];
        oAccountTeam.NSP_Role__c = NSP_AssetBatchTest.MANAGER_HR_SERVICES;
        update oAccountTeam;
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(TRUE, [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    @isTest
    private static void assetBatchAdminTest() {
        Test.startTest();
        delete [SELECT ID FROM NSP_Account_Team__c WHERE Id != null LIMIT 1];
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM CASE WHERE Id != null LIMIT 1].OwnerId);
        System.assertEquals(TRUE, [SELECT Id, NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    // @description Covers NSP_AssetBatch.schedule() static method (ISelfSchedulable interface).
    @isTest
    private static void testSchedule_Default_ReturnsScheduledJobId() {
        Test.startTest();
        String jobId = NSP_AssetBatch.schedule();
        Test.stopTest();
        System.Assert.isNotNull(jobId, 'schedule() should return a non-null scheduled job ID');
    }

    // @description Covers execute(SchedulableContext) — the Schedulable interface method — by scheduling NSP_AssetBatch directly.
    @isTest
    private static void testExecuteSchedulable_DirectSchedule_TriggersBatch() {
        Test.startTest();
        System.schedule('Test NSP_AssetBatch Direct Schedulable', '0 0 2 * * ?', new NSP_AssetBatch());
        Test.stopTest();
        List<AsyncApexJob> batchJobs = [
            SELECT Id, Status
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
                AND ApexClass.Name = 'NSP_AssetBatch'
        ];
        System.Assert.isTrue(batchJobs.size() > 0, 'Scheduling NSP_AssetBatch should trigger batch execution via execute(SchedulableContext)');
    }

    // @description Covers Callable.call() with the supported 'run' action.
    @isTest
    private static void testCall_RunAction_ReturnsBatchJobId() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Test.startTest();
        Object result = batchInstance.call('run', null);
        Test.stopTest();
        System.Assert.isNotNull(result, 'call() with run action should return a non-null batch job ID');
    }

    // @description Covers Callable.call() null-response branch for an unrecognised action.
    @isTest
    private static void testCall_InvalidAction_ReturnsNull() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Object result = batchInstance.call('unknown_action', null);
        System.Assert.isNull(result, 'call() with an unrecognised action should return null');
    }

    // @description Covers IJobRunnable.run() which enqueues the batch and returns a job ID.
    @isTest
    private static void testRun_Default_ReturnsBatchJobId() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Test.startTest();
        Id batchJobId = batchInstance.run();
        Test.stopTest();
        System.Assert.isNotNull(batchJobId, 'run() should return a non-null batch job ID');
    }

    // @description Covers getCaseOwnerId when the account team map is null — should default to the current user.
    @isTest
    private static void testGetCaseOwnerId_NullMap_ReturnsCurrentUser() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Id result = batchInstance.getCaseOwnerId(null, null);
        System.Assert.areEqual(UserInfo.getUserId(), result, 'getCaseOwnerId with a null map should return the running user ID');
    }

    // @description Covers getCaseOwnerId when both HR Specialist and Bus. Team-HRSp/CL are present and NSP_Primary__c is true — expects HR Specialist owner.
    @isTest
    private static void testGetCaseOwnerId_BothHRAndBT_PrimaryTrue_ReturnsHRUser() {
        User alternateUser = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId() LIMIT 1];
        Id hrUserId = UserInfo.getUserId();
        Id btUserId = alternateUser.Id;

        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.HR_SPECIALIST => hrUserId,
            NSP_AssetBatchTest.BUS_TEAM_HRSP_CL => btUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>{
            NSP_AssetBatchTest.HR_SPECIALIST => true
        };

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(hrUserId, result, 'Should return HR Specialist user when both roles are present and HR primary is true');
    }

    // @description Covers getCaseOwnerId when both HR Specialist and Bus. Team-HRSp/CL are present and NSP_Primary__c is false — expects BT owner.
    @isTest
    private static void testGetCaseOwnerId_BothHRAndBT_PrimaryFalse_ReturnsBTUser() {
        User alternateUser = [SELECT Id FROM User WHERE IsActive = true AND Id != :UserInfo.getUserId() LIMIT 1];
        Id hrUserId = UserInfo.getUserId();
        Id btUserId = alternateUser.Id;

        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.HR_SPECIALIST => hrUserId,
            NSP_AssetBatchTest.BUS_TEAM_HRSP_CL => btUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>{
            NSP_AssetBatchTest.HR_SPECIALIST => false
        };

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(btUserId, result, 'Should return BT user when both roles are present and HR primary is false');
    }

    // @description Covers getCaseOwnerId when only HR Specialist is present in the map.
    @isTest
    private static void testGetCaseOwnerId_OnlyHRSpecialist_ReturnsHRUser() {
        Id hrUserId = UserInfo.getUserId();
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.HR_SPECIALIST => hrUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>();

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(hrUserId, result, 'Should return HR Specialist user when only that role is present');
    }

    // @description Covers getCaseOwnerId when only Bus. Team-HRSp/CL is present in the map.
    @isTest
    private static void testGetCaseOwnerId_OnlyBT_ReturnsBTUser() {
        Id btUserId = UserInfo.getUserId();
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.BUS_TEAM_HRSP_CL => btUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>();

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(btUserId, result, 'Should return BT user when only Bus. Team-HRSp/CL role is present');
    }

    // @description Covers getCaseOwnerId when only Manager, HR Services is present in the map.
    @isTest
    private static void testGetCaseOwnerId_OnlyMHR_ReturnsMHRUser() {
        Id mhrUserId = UserInfo.getUserId();
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        Map<String, Id> userMap = new Map<String, Id>{
            NSP_AssetBatchTest.MANAGER_HR_SERVICES => mhrUserId
        };
        Map<String, Boolean> valueMap = new Map<String, Boolean>();

        Id result = batchInstance.getCaseOwnerId(userMap, valueMap);
        System.Assert.areEqual(mhrUserId, result, 'Should return Manager HR Services user when only that role is present');
    }

    // @description Covers the execute() branch where both HR Specialist (NSP_Primary__c=true) and BT AIMS teams exist — case should be owned by HR Specialist.
    @isTest
    private static void testBatch_BothHRAimsAndBT_PrimaryTrue_CaseOwnerIsHR() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        User hrUser = [SELECT Id FROM User WHERE Alias = 'uDelet' LIMIT 1];

        insert new NSP_Account_Team__c(
            NSP_Account__c = acct.Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = hrUser.Id,
            NSP_Integrated_With__c = 'AIMS',
            NSP_Primary__c = true
        );

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case];
        System.Assert.areEqual(1, cases.size(), 'One case should be created for the expired biometric asset');
        System.Assert.areEqual(hrUser.Id, cases[0].OwnerId, 'Case owner should be the HR Specialist user when primary is true');
    }

    // @description Covers the execute() branch where HR Specialist (NSP_Primary__c=false) and BT AIMS teams exist — case should be owned by BT.
    @isTest
    private static void testBatch_BothHRAimsAndBT_PrimaryFalse_CaseOwnerIsBT() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        User hrUser = [SELECT Id FROM User WHERE Alias = 'uDelet' LIMIT 1];

        insert new NSP_Account_Team__c(
            NSP_Account__c = acct.Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = hrUser.Id,
            NSP_Integrated_With__c = 'AIMS',
            NSP_Primary__c = false
        );

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case];
        System.Assert.areEqual(1, cases.size(), 'One case should be created for the expired biometric asset');
        System.Assert.areEqual(UserInfo.getUserId(), cases[0].OwnerId, 'Case owner should be BT user when HR primary is false');
    }

    // @description Covers the execute() HR-Specialist-only AIMS branch by removing BT and MHR AIMS teams.
    @isTest
    private static void testBatch_OnlyHRSpecialistAims_CaseOwnerIsHR() {
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.BUS_TEAM_HRSP_CL];
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.MANAGER_HR_SERVICES];

        Account acct = [SELECT Id FROM Account LIMIT 1];
        User hrUser = [SELECT Id FROM User WHERE Alias = 'uDelet' LIMIT 1];

        insert new NSP_Account_Team__c(
            NSP_Account__c = acct.Id,
            NSP_Role__c = NSP_AssetBatchTest.HR_SPECIALIST,
            NSP_User__c = hrUser.Id,
            NSP_Integrated_With__c = 'AIMS'
        );

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case];
        System.Assert.areEqual(1, cases.size(), 'One case should be created');
        System.Assert.areEqual(hrUser.Id, cases[0].OwnerId, 'Case owner should be HR Specialist when only HR Specialist AIMS team exists');
    }

    // @description Covers the execute() MHR-only AIMS branch by removing BT and HR AIMS teams.
    @isTest
    private static void testBatch_OnlyMHRAims_CaseOwnerIsMHR() {
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.BUS_TEAM_HRSP_CL];
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS' AND NSP_Role__c = :NSP_AssetBatchTest.HR_SPECIALIST];

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case];
        System.Assert.areEqual(1, cases.size(), 'One case should be created');
        System.Assert.areEqual(UserInfo.getUserId(), cases[0].OwnerId, 'Case owner should be Manager HR Services user when only MHR AIMS team exists');
    }

    // @description Covers the execute() null-map branch (no AIMS teams at all) — case defaults to current user.
    @isTest
    private static void testBatch_NoAimsAccountTeams_CaseOwnerIsCurrentUser() {
        delete [SELECT Id FROM NSP_Account_Team__c WHERE NSP_Integrated_With__c = 'AIMS'];

        Test.startTest();
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();

        List<Case> cases = [SELECT OwnerId FROM Case];
        System.Assert.areEqual(1, cases.size(), 'One case should be created even when no AIMS account teams exist');
        System.Assert.areEqual(UserInfo.getUserId(), cases[0].OwnerId, 'Case owner should default to current user when no AIMS account teams exist');
    }

    // @description Covers the execute() empty-scope early-exit branch (sAccountIds.size() == 0).
    @isTest
    private static void testExecute_EmptyScope_NoCasesCreated() {
        NSP_AssetBatch batchInstance = new NSP_AssetBatch();
        batchInstance.execute(null, new List<SObject>());
        System.Assert.areEqual(0, [SELECT count() FROM Case], 'No cases should be created when scope is empty');
    }

}
//
