@isTest
private class NSP_PaperlessBatchDateBatchTest {

    private static final String ASSERT_ONE_ASSET_IN_SETUP = 'Expected one Asset in test data';
    private static final String ASSERT_ONE_SUBCLIENT_IN_SETUP = 'Expected one SubClient in test data';
    private static final String ASSERT_ONE_SUBCONTACT_IN_SETUP = 'Expected one SubClientContact in test data';
    private static final String ASSERT_ONE_ASSET_AFTER_BATCH = 'Expected one Asset after batch execution';

    @TestSetup
    private static void setupTestData() {
        Account acc = (Account) NSP_TestDataFactory.createSObject(new Account(), true);

        Contact con = new Contact(
            LastName = 'TestContact',
            AccountId = acc.Id
        );
        insert con;

        Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('WO').getRecordTypeId();
        Asset asset = (Asset) NSP_TestDataFactory.createSObject(
            new Asset(
                AccountId = acc.Id,
                ContactId = con.Id,
                RecordTypeId = woRecordTypeId,
                Status = 'Terminated',
                NSP_Service_Package__c = 'WO - Full BUndle',
                NSP_Paperless_Batch_Date__c = System.today() - 1,
                NSP_AIMS_First_Pay_Date__c = System.today() - 1
            ),
            'NSP_TestDataFactory.AssetDefaults',
            true
        );

        NSP_Sub_Client__c subClient = (NSP_Sub_Client__c) NSP_TestDataFactory.createSObject(
            new NSP_Sub_Client__c(
                NSP_Account__c = acc.Id,
                NSP_Asset__c = asset.Id,
                NSP_Paperless_Batch_Date__c = System.today() - 1
            ),
            'NSP_TestDataFactory.SubClientDefaults',
            true
        );

        NSP_TestDataFactory.createSObject(
            new NSP_Sub_Client_Contact__c(
                NSP_Sub_Client__c = subClient.Id,
                NSP_Work_Phone__c = '55667788',
                NSP_Employee_Status__c = 'FMLA',
                NSP_Paid_Non_Paid__c = 'Paid WSEE',
                NSP_IsPaperless__c = true,
                NSP_Paperless_Batch_Date__c = System.today() - 1
            ),
            'NSP_TestDataFactory.SubClientContactDefaults',
            true
        );
    }

    @isTest
    private static void shouldSetPaperlessFalse_WhenAssetIsTerminated() {
        // Given - @TestSetup creates asset with Status=Terminated and all batch dates as yesterday

        // When
        Test.startTest();
        Database.executeBatch(new NSP_PaperlessBatchDateBatch(), 200);
        Test.stopTest();

        // Then
        List<Asset> updatedAssets = [SELECT Id, NSP_Paperless__c FROM Asset LIMIT 1];
        Assert.areEqual(1, updatedAssets.size(), 'Expected one Asset to be returned');
        Assert.isFalse(updatedAssets[0].NSP_Paperless__c, 'NSP_Paperless__c should be false when asset is terminated');
    }

    @isTest
    private static void shouldSetPaperlessFalse_WhenSubClientIsInactive() {
        // Given
        List<Asset> assets = [SELECT Id, Status, NSP_Paperless_Batch_Date__c FROM Asset LIMIT 1];
        Assert.areEqual(1, assets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_IN_SETUP);
        List<NSP_Sub_Client__c> subClients = [SELECT Id, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client__c LIMIT 1];
        Assert.areEqual(1, subClients.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCLIENT_IN_SETUP);
        List<NSP_Sub_Client_Contact__c> subClientContacts = [SELECT Id, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client_Contact__c LIMIT 1];
        Assert.areEqual(1, subClientContacts.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCONTACT_IN_SETUP);

        assets[0].Status = 'Active';
        assets[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClients[0].NSP_Account_Status__c = 'Inactive';
        subClients[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClientContacts[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        update assets;
        update subClients;
        update subClientContacts;

        // When
        Test.startTest();
        Database.executeBatch(new NSP_PaperlessBatchDateBatch(), 200);
        Test.stopTest();

        // Then
        List<Asset> updatedAssets = [SELECT Id, NSP_Paperless__c FROM Asset LIMIT 1];
        Assert.areEqual(1, updatedAssets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_AFTER_BATCH);
        Assert.isFalse(updatedAssets[0].NSP_Paperless__c, 'NSP_Paperless__c should be false when sub client is inactive');
    }

    @isTest
    private static void shouldSetPaperlessTrue_WhenPaidUserWithActiveSubClient() {
        // Given
        List<Asset> assets = [SELECT Id, Status, NSP_Paperless_Batch_Date__c FROM Asset LIMIT 1];
        Assert.areEqual(1, assets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_IN_SETUP);
        List<NSP_Sub_Client__c> subClients = [SELECT Id, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client__c LIMIT 1];
        Assert.areEqual(1, subClients.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCLIENT_IN_SETUP);
        List<NSP_Sub_Client_Contact__c> subClientContacts = [SELECT Id, NSP_Paid_Non_Paid__c, NSP_Employee_Status__c, NSP_IsPaperless__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client_Contact__c LIMIT 1];
        Assert.areEqual(1, subClientContacts.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCONTACT_IN_SETUP);

        assets[0].Status = 'Active';
        assets[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClients[0].NSP_Account_Status__c = 'Active';
        subClients[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClientContacts[0].NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientContacts[0].NSP_Employee_Status__c = 'PRIMED';
        subClientContacts[0].NSP_IsPaperless__c = true;
        subClientContacts[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        update assets;
        update subClients;
        update subClientContacts;

        // When
        Test.startTest();
        Database.executeBatch(new NSP_PaperlessBatchDateBatch(), 200);
        Test.stopTest();

        // Then
        List<Asset> updatedAssets = [SELECT Id, NSP_Paperless__c FROM Asset LIMIT 1];
        Assert.areEqual(1, updatedAssets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_AFTER_BATCH);
        Assert.isTrue(updatedAssets[0].NSP_Paperless__c, 'NSP_Paperless__c should be true for active paid user with active sub client');
    }

    @isTest
    private static void shouldSetPaperlessTrue_WhenNonPaidUserIsPaperless() {
        // Given
        List<Asset> assets = [SELECT Id, Status, NSP_Paperless_Batch_Date__c FROM Asset LIMIT 1];
        Assert.areEqual(1, assets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_IN_SETUP);
        List<NSP_Sub_Client__c> subClients = [SELECT Id, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client__c LIMIT 1];
        Assert.areEqual(1, subClients.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCLIENT_IN_SETUP);
        List<NSP_Sub_Client_Contact__c> subClientContacts = [SELECT Id, NSP_Paid_Non_Paid__c, NSP_IsPaperless__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client_Contact__c LIMIT 1];
        Assert.areEqual(1, subClientContacts.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCONTACT_IN_SETUP);

        assets[0].Status = 'Active';
        assets[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClients[0].NSP_Account_Status__c = 'Active';
        subClients[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClientContacts[0].NSP_Paid_Non_Paid__c = 'Active Non-Paid User';
        subClientContacts[0].NSP_IsPaperless__c = true;
        subClientContacts[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        update assets;
        update subClients;
        update subClientContacts;

        // When
        Test.startTest();
        Database.executeBatch(new NSP_PaperlessBatchDateBatch(), 200);
        Test.stopTest();

        // Then
        List<Asset> updatedAssets = [SELECT Id, NSP_Paperless__c FROM Asset LIMIT 1];
        Assert.areEqual(1, updatedAssets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_AFTER_BATCH);
        Assert.isTrue(updatedAssets[0].NSP_Paperless__c, 'NSP_Paperless__c should be true for non-paid user who is paperless');
    }

    @isTest
    private static void shouldSetPaperlessFalse_WhenNonPaidUserIsNotPaperless() {
        // Given
        List<Asset> assets = [SELECT Id, Status, NSP_Paperless_Batch_Date__c FROM Asset LIMIT 1];
        Assert.areEqual(1, assets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_IN_SETUP);
        List<NSP_Sub_Client__c> subClients = [SELECT Id, NSP_Account_Status__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client__c LIMIT 1];
        Assert.areEqual(1, subClients.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCLIENT_IN_SETUP);
        List<NSP_Sub_Client_Contact__c> subClientContacts = [SELECT Id, NSP_Paid_Non_Paid__c, NSP_IsPaperless__c, NSP_Paperless_Batch_Date__c FROM NSP_Sub_Client_Contact__c LIMIT 1];
        Assert.areEqual(1, subClientContacts.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_SUBCONTACT_IN_SETUP);

        assets[0].Status = 'Active';
        assets[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClients[0].NSP_Account_Status__c = 'Active';
        subClients[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        subClientContacts[0].NSP_Paid_Non_Paid__c = 'Active Non-Paid User';
        subClientContacts[0].NSP_IsPaperless__c = false;
        subClientContacts[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        update assets;
        update subClients;
        update subClientContacts;

        // When
        Test.startTest();
        Database.executeBatch(new NSP_PaperlessBatchDateBatch(), 200);
        Test.stopTest();

        // Then
        List<Asset> updatedAssets = [SELECT Id, NSP_Paperless__c FROM Asset LIMIT 1];
        Assert.areEqual(1, updatedAssets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_AFTER_BATCH);
        Assert.isFalse(updatedAssets[0].NSP_Paperless__c, 'NSP_Paperless__c should be false for non-paid user who is not paperless');
    }

    @isTest
    private static void shouldSetPaperlessFalse_WhenOnlyAssetBatchDateIsYesterday() {
        // Given
        List<Asset> assets = [SELECT Id, Status, NSP_Paperless_Batch_Date__c FROM Asset LIMIT 1];
        Assert.areEqual(1, assets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_IN_SETUP);

        assets[0].Status = 'Terminated';
        assets[0].NSP_Paperless_Batch_Date__c = System.today() - 1;
        update assets[0];

        // When
        Test.startTest();
        Database.executeBatch(new NSP_PaperlessBatchDateBatch(), 200);
        Test.stopTest();

        // Then
        List<Asset> updatedAssets = [SELECT Id, NSP_Paperless__c FROM Asset LIMIT 1];
        Assert.areEqual(1, updatedAssets.size(), NSP_PaperlessBatchDateBatchTest.ASSERT_ONE_ASSET_AFTER_BATCH);
        Assert.isFalse(updatedAssets[0].NSP_Paperless__c, 'NSP_Paperless__c should be false for a terminated asset');
    }

    @isTest
    private static void shouldRegisterScheduledJob_WhenSystemScheduleInvoked() {
        // When
        Test.startTest();
        String cronExpression = '0 0 2 * * ?';
        String jobId = System.schedule('Test Paperless Batch Scheduler', cronExpression, new NSP_PaperlessBatchDateBatch());
        Test.stopTest();

        // Then
        List<CronTrigger> cronTriggers = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(1, cronTriggers.size(), 'Expected one CronTrigger to be created');
        Assert.areEqual(cronExpression, cronTriggers[0].CronExpression, 'CronExpression should match the provided schedule');
        Assert.areEqual(0, cronTriggers[0].TimesTriggered, 'TimesTriggered should be 0 for a newly scheduled job');
    }

    @isTest
    private static void shouldReturnJobId_WhenStaticScheduleMethodInvoked() {
        // When
        Test.startTest();
        String jobId = NSP_PaperlessBatchDateBatch.schedule();
        Test.stopTest();

        // Then
        Assert.isNotNull(jobId, 'schedule() should return a non-null job Id');
        List<CronTrigger> cronTriggers = [SELECT Id, CronExpression, TimesTriggered FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(1, cronTriggers.size(), 'Expected one CronTrigger to be created');
        Assert.areEqual('0 0 2 ? * * *', cronTriggers[0].CronExpression, 'CronExpression should match the batch class schedule');
        Assert.areEqual(0, cronTriggers[0].TimesTriggered, 'TimesTriggered should be 0 for a newly scheduled job');
    }
}
