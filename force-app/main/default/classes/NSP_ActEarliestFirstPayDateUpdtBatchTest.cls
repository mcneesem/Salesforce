@isTest
private class NSP_ActEarliestFirstPayDateUpdtBatchTest {

    private static final String TEST_ACCOUNT_NAME = 'nsp_focus_item__c';
    private static final Id WO_ASSET_RECORD_TYPE_ID = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');

    @TestSetup
    private static void testDataSetup() {
        User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);

        Account testAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        testAccount.Name = NSP_ActEarliestFirstPayDateUpdtBatchTest.TEST_ACCOUNT_NAME;
        insert testAccount;

        Contact testContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);
        testContact.AccountId = testAccount.Id;
        testContact.lastName = 'Test';
        testContact.pse__Salesforce_User__c = testUser.Id;
        update testContact;

        List<Asset> woAssets = new List<Asset>();

        Asset firstAsset = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        firstAsset.AccountId = testAccount.Id;
        firstAsset.ContactId = testContact.Id;
        firstAsset.Name = 'assetLinked';
        firstAsset.Status = 'Active';
        firstAsset.NSP_First_Pay_Date__c = Date.today();
        firstAsset.NSP_AIMS_First_Pay_Date__c = Date.today();
        firstAsset.RecordTypeId = NSP_ActEarliestFirstPayDateUpdtBatchTest.WO_ASSET_RECORD_TYPE_ID;
        woAssets.add(firstAsset);

        Asset secondAsset = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        secondAsset.AccountId = testAccount.Id;
        secondAsset.ContactId = testContact.Id;
        secondAsset.Name = 'assetLinked1';
        secondAsset.Status = 'Active';
        secondAsset.NSP_First_Pay_Date__c = Date.today();
        secondAsset.NSP_AIMS_First_Pay_Date__c = Date.today();
        secondAsset.RecordTypeId = NSP_ActEarliestFirstPayDateUpdtBatchTest.WO_ASSET_RECORD_TYPE_ID;
        woAssets.add(secondAsset);

        Database.insert(woAssets);
    }

    // @description Returns the test account from setup data for assertion use.
    private static Account getTestAccount() {
        List<Account> accounts = [
            SELECT Id,
                   NSP_Product_First_Pay_Date__c
            FROM Account
            WHERE Name = :NSP_ActEarliestFirstPayDateUpdtBatchTest.TEST_ACCOUNT_NAME
            LIMIT 1
        ];
        return accounts.isEmpty() ? null : accounts[0];
    }

    // @description Positive: batch processes WO assets and sets account first pay date from AIMS date.
    @isTest
    private static void testUpdatesAccountFirstPayDate() {
        Test.startTest();
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today(),
            result.NSP_Product_First_Pay_Date__c,
            'Account first pay date should be set to today when WO assets have today as their AIMS date'
        );
    }

    // @description Negative: null first pay date asset is skipped; account date still set from valid assets.
    @isTest
    private static void testSkipsNullFirstPayDate() {
        Account testAccount = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();

        Asset nullDateAsset = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        nullDateAsset.AccountId = testAccount.Id;
        nullDateAsset.Name = 'assetNullDate';
        nullDateAsset.Status = 'Active';
        nullDateAsset.NSP_First_Pay_Date__c = null;
        nullDateAsset.NSP_AIMS_First_Pay_Date__c = null;
        nullDateAsset.RecordTypeId = NSP_ActEarliestFirstPayDateUpdtBatchTest.WO_ASSET_RECORD_TYPE_ID;
        insert nullDateAsset;

        Test.startTest();
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today(),
            result.NSP_Product_First_Pay_Date__c,
            'Account first pay date should be set from valid assets even when a null-date asset is present'
        );
    }

    // @description Covers schedule() static method; verifies a non-null job Id is returned.
    @isTest
    private static void testScheduleReturnsJobId() {
        Test.startTest();
        String jobId = NSP_AcntEarliestFirstPayDateUpdateBatch.schedule();
        Test.stopTest();

        System.Assert.isNotNull(jobId, 'schedule() should return a non-null scheduled job Id');
    }

    // @description Covers execute(SchedulableContext) -> call(run) -> run() -> Database.executeBatch chain.
    @isTest
    private static void testSchedulableExecuteRunsBatch() {
        Test.startTest();
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
        batchJob.execute(null);
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today(),
            result.NSP_Product_First_Pay_Date__c,
            'Schedulable execute path should trigger a batch run and update account first pay date'
        );
    }

    // @description Covers call() with an unrecognized action; verifies null is returned without error.
    @isTest
    private static void testCallUnknownActionReturnsNull() {
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();

        Test.startTest();
        Object result = batchJob.call('unknown', null);
        Test.stopTest();

        System.Assert.isNull(result, 'call() with an unrecognized action should return null');
    }

    // @description Branch: else-if fires when a later-inserted asset has an earlier date than the current map entry.
    @isTest
    private static void testUsesEarliestPayDate() {
        Account testAccount = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();

        Asset earlierAsset1 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        earlierAsset1.AccountId = testAccount.Id;
        earlierAsset1.Name = 'assetEarlier1';
        earlierAsset1.Status = 'Active';
        earlierAsset1.NSP_First_Pay_Date__c = Date.today().addDays(-5);
        earlierAsset1.NSP_AIMS_First_Pay_Date__c = Date.today().addDays(-5);
        earlierAsset1.RecordTypeId = NSP_ActEarliestFirstPayDateUpdtBatchTest.WO_ASSET_RECORD_TYPE_ID;

        Asset earlierAsset2 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        earlierAsset2.AccountId = testAccount.Id;
        earlierAsset2.Name = 'assetEarlier2';
        earlierAsset2.Status = 'Active';
        earlierAsset2.NSP_First_Pay_Date__c = Date.today().addDays(-10);
        earlierAsset2.NSP_AIMS_First_Pay_Date__c = Date.today().addDays(-10);
        earlierAsset2.RecordTypeId = NSP_ActEarliestFirstPayDateUpdtBatchTest.WO_ASSET_RECORD_TYPE_ID;

        insert new List<Asset>{ earlierAsset1, earlierAsset2 };

        Test.startTest();
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today().addDays(-10),
            result.NSP_Product_First_Pay_Date__c,
            'Account first pay date should be updated to the earliest date across all assets'
        );
    }

    // @description Branch: || second condition fires when account already has a future date the batch replaces.
    @isTest
    private static void testReplacesFuturePayDate() {
        Account testAccount = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        testAccount.NSP_Product_First_Pay_Date__c = Date.today().addDays(30);
        update testAccount;

        Test.startTest();
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
        Database.executeBatch(batchJob, 200);
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today(),
            result.NSP_Product_First_Pay_Date__c,
            'Batch should replace a future account first pay date with the earlier date found on assets'
        );
    }

    // @description Bulk: 200+ assets process correctly without hitting governor limits.
    @isTest
    private static void testProcessesBulkAssets() {
        Account testAccount = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();

        List<Asset> bulkAssets = new List<Asset>();
        for (Integer assetIndex = 0; assetIndex < 200; assetIndex++) {
            Asset bulkAsset = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
            bulkAsset.AccountId = testAccount.Id;
            bulkAsset.Name = 'bulkAsset' + assetIndex;
            bulkAsset.Status = 'Active';
            bulkAsset.NSP_First_Pay_Date__c = Date.today().addDays(-assetIndex);
            bulkAsset.NSP_AIMS_First_Pay_Date__c = Date.today().addDays(-assetIndex);
            bulkAsset.RecordTypeId = NSP_ActEarliestFirstPayDateUpdtBatchTest.WO_ASSET_RECORD_TYPE_ID;
            bulkAssets.add(bulkAsset);
        }
        insert bulkAssets;

        // batch size must exceed total asset count (200 bulk + 2 from setup = 202) to keep execution to one chunk
        Test.startTest();
        NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
        Database.executeBatch(batchJob, 250);
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today().addDays(-199),
            result.NSP_Product_First_Pay_Date__c,
            'Account first pay date should be the earliest date across all 200 bulk assets'
        );
    }

    // @description Security: batch processes correctly when run under a specific user context via System.runAs().
    @isTest
    private static void testRunsAsSpecificUser() {
        User runningUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Test.startTest();
        System.runAs(runningUser) {
            NSP_AcntEarliestFirstPayDateUpdateBatch batchJob = new NSP_AcntEarliestFirstPayDateUpdateBatch();
            Database.executeBatch(batchJob, 200);
        }
        Test.stopTest();

        Account result = NSP_ActEarliestFirstPayDateUpdtBatchTest.getTestAccount();
        System.Assert.areEqual(
            Date.today(),
            result.NSP_Product_First_Pay_Date__c,
            'Batch should correctly update account first pay date when run under a specific user context'
        );
    }
}
