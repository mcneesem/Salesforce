@isTest
private class NSP_AssetBatchTest {

    @testSetup
    private static void setupProjectTaskdata() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        //Test Setup
        Account oAccount = new Account(Name = 'ABC Company');
        insert oAccount;
        Profile profileRec = [SELECT Id FROM Profile WHERE Name = : 'System Administrator' LIMIT 1];
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@randomorg.com';
        User userRec = new User(alias = 'uDelet', email='testfake@insperity.com',
                          emailencodingkey='UTF-8', lastname='temp',
                          languagelocalekey='en_US',
                          localesidkey='en_US', profileid = profileRec.Id,
                          timezonesidkey='America/Los_Angeles',
                          username=uniqueUserName);
        insert userRec;
        NSP_Account_Team__c oAccountTeam = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id,NSP_Role__c = 'HR Specialist',NSP_User__c = userRec.Id);
        insert oAccountTeam;
        NSP_Account_Team__c oAccountTeam2 = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id,NSP_Role__c = 'Bus. Team-HRSp/CL',NSP_User__c = UserInfo.getUserId(), NSP_Integrated_With__c = 'AIMS');
        insert oAccountTeam2;
        NSP_Account_Team__c oAccountTeam3 = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id,NSP_Role__c = 'Manager, HR Services',NSP_User__c = UserInfo.getUserId(), NSP_Integrated_With__c = 'AIMS');
        insert oAccountTeam3;
        NSP_Account_Team__c oAccountTeam1 = new NSP_Account_Team__c(NSP_Account__c = oAccount.Id,NSP_Role__c = 'HR Specialist', NSP_Integrated_With__c = 'AIMS');
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
        System.assertEquals(TRUE, [SELECT Id,NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    @isTest
    private static void assetBatchBTTest() {
        Test.startTest();
        NSP_Account_Team__c oAccountTeam = [SELECT ID from NSP_Account_Team__c WHERE Id != null LIMIT 1];
        oAccountTeam.NSP_Role__c = 'Bus. Team-HRSp/CL';
        update oAccountTeam;
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(TRUE, [SELECT Id,NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    @isTest
    private static void assetBatchMHRTest() {
        Test.startTest();
        NSP_Account_Team__c oAccountTeam = [SELECT ID FROM NSP_Account_Team__c WHERE Id != null LIMIT 1];
        oAccountTeam.NSP_Role__c = 'Manager, HR Services';
        update oAccountTeam;
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(TRUE, [SELECT Id,NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

    @isTest
    private static void assetBatchAdminTest() {
        Test.startTest();
        delete [SELECT ID FROM NSP_Account_Team__c WHERE Id != null LIMIT 1];
        Database.executeBatch(new NSP_AssetBatch());
        Test.stopTest();
        System.assertEquals(1, [SELECT count() FROM Case WHERE Id != null]);
        System.assertEquals(UserInfo.getUserId(), [SELECT OwnerId FROM CASE WHERE Id != null LIMIT 1].OwnerId);
        System.assertEquals(TRUE, [SELECT Id,NSP_Biometric_Indicator_Expired__c FROM Asset WHERE Id != null].NSP_Biometric_Indicator_Expired__c);
    }

}
//