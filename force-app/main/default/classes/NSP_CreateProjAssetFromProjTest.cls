// @description  Test class for NSP_CreateProjAssetFromProjBatch
// @date         01/09/2023
// @author       Ramya Ravi
// @story        STY-03641 - Batch Class to create project asset records from project records
@isTest
private class NSP_CreateProjAssetFromProjTest {

    private static final String AIMS_STATUS         = 'Active';
    private static final String RET_CHOICE_ASSET_RT = 'RET_Choice';

    private static final Id RET_CHOICE_RT_ID = NSP_GenericRecordType.getRecordTypeId(
        'Asset', RET_CHOICE_ASSET_RT
    );

    @testSetup
    private static void setupData() {
        // Disable the project trigger to prevent NSP_ProjectTriggerHelper.updateAssetTypeProject()
        // from overwriting NSP_Asset_Type__c to null when TemplateName__c is blank on insert
        insert new NSP_Trigger_Switch__c(ProjectTrigger__c = true);

        Account accountA1 = (Account) NSP_TestExtendedDataFactory.createSObject(
            new Account(), 'NSP_TestDataFactory.AccountDefaults', true
        );
        Account accountA2 = new Account(Name = 'Test Account A2');
        insert accountA2;

        // Active asset on accountA1 — matched by the batch execute path
        Asset assetA1Active = (Asset) NSP_TestDataFactory.createSObject(
            new Asset(), 'NSP_TestDataFactory.AssetDefaults', false
        );
        assetA1Active.AccountId             = accountA1.Id;
        assetA1Active.NSP_Account_Status__c = AIMS_STATUS;
        assetA1Active.RecordTypeId          = RET_CHOICE_RT_ID;
        insert assetA1Active;

        // Active asset on accountA2 — matched via the Project_Account__c path
        Asset assetA2Active = (Asset) NSP_TestDataFactory.createSObject(
            new Asset(), 'NSP_TestDataFactory.AssetDefaults', false
        );
        assetA2Active.Name                  = 'Asset A2 Active';
        assetA2Active.AccountId             = accountA2.Id;
        assetA2Active.NSP_Account_Status__c = AIMS_STATUS;
        assetA2Active.RecordTypeId          = RET_CHOICE_RT_ID;
        insert assetA2Active;

        // Inactive asset on accountA1 — must be excluded from matching
        Asset assetA1Inactive = (Asset) NSP_TestDataFactory.createSObject(
            new Asset(), 'NSP_TestDataFactory.AssetDefaults', false
        );
        assetA1Inactive.Name                  = 'Asset A1 Inactive';
        assetA1Inactive.AccountId             = accountA1.Id;
        assetA1Inactive.RecordTypeId          = RET_CHOICE_RT_ID;
        assetA1Inactive.NSP_Account_Status__c = 'Inactive';
        insert assetA1Inactive;

        // projectP1 — unprocessed, should be picked up by the batch
        pse__Proj__c projectP1 = (pse__Proj__c) NSP_TestExtendedDataFactory.createSObject(
            new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false
        );
        projectP1.NSP_Is_Project_Asset_Created__c = false;
        projectP1.pse__Is_Template__c             = false;
        projectP1.NSP_Asset_Type__c               = RET_CHOICE_ASSET_RT;
        projectP1.pse__Account__c                 = accountA1.Id;
        insert projectP1;

        // projectP2 — already processed, should be skipped by the batch execute path
        pse__Proj__c projectP2 = new pse__Proj__c(
            Name                            = 'Test Project P2',
            pse__Is_Active__c               = true,
            pse__Account__c                 = accountA1.Id,
            NSP_Is_Project_Asset_Created__c = true,
            pse__Is_Template__c             = false,
            NSP_Asset_Type__c               = RET_CHOICE_ASSET_RT
        );
        insert projectP2;

        // Links projectP1 to accountA2 so the Project_Account__c path can be exercised
        insert new Project_Account__c(
            Project__c = projectP1.Id,
            Account__c = accountA2.Id
        );
    }

    // Verifies that the batch creates a Project_Asset__c and sets NSP_Is_Project_Asset_Created__c = true
    // when a project with NSP_Is_Project_Asset_Created__c = false has a matching active asset
    @isTest
    private static void testProjectWithMatchingAsset() {
        // Given
        List<pse__Proj__c> sourceProjects = [
            SELECT Id, pse__Account__c
            FROM pse__Proj__c
            WHERE NSP_Is_Project_Asset_Created__c = false
            LIMIT 1
        ];
        Assert.areEqual(1, sourceProjects.size(), 'Expected one unprocessed project in test setup');
        Id projectId     = sourceProjects[0].Id;
        Id projectAcctId = sourceProjects[0].pse__Account__c;

        List<Asset> expectedAssets = [
            SELECT Id
            FROM Asset
            WHERE AccountId             = :projectAcctId
            AND NSP_Account_Status__c = :AIMS_STATUS
            LIMIT 1
        ];
        Assert.areEqual(1, expectedAssets.size(), 'Expected one active asset on the project account');

        // When
        Test.startTest();
        Database.executeBatch(new NSP_CreateProjAssetFromProjBatch(), 200);
        Test.stopTest();

        // Then — Project_Asset__c is created linking the project to the active asset
        List<Project_Asset__c> projectAssets = [
            SELECT Id
            FROM Project_Asset__c
            WHERE Project__c = :projectId
            AND Asset__c   = :expectedAssets[0].Id
        ];
        Assert.areEqual(
            1,
            projectAssets.size(),
            'Expected exactly one Project_Asset__c for the project and its active asset'
        );

        // Then — NSP_Is_Project_Asset_Created__c is flipped to true
        List<pse__Proj__c> updatedProjects = [
            SELECT Id, NSP_Is_Project_Asset_Created__c
            FROM pse__Proj__c
            WHERE Id = :projectId
        ];
        Assert.areEqual(1, updatedProjects.size(), 'Expected project record to exist after batch');
        Assert.areEqual(
            true,
            updatedProjects[0].NSP_Is_Project_Asset_Created__c,
            'NSP_Is_Project_Asset_Created__c should be true after the batch processes the project'
        );
    }

    // Verifies that NSP_CreateProjAssetFromProjBatch can be scheduled via System.schedule() without error
    @isTest
    private static void testSchedulable() {
        Test.startTest();
        System.schedule(
            'Test NSP_CreateProjAssetBatch',
            '0 0 4 * * ? *',
            new NSP_CreateProjAssetFromProjBatch()
        );
        Test.stopTest();
        Assert.isTrue(true, 'Schedulable execute() should complete without error');
    }

    // Verifies that the static schedule() helper returns a non-null CronTrigger job ID
    @isTest
    private static void testSchedule() {
        Test.startTest();
        String jobId = NSP_CreateProjAssetFromProjBatch.schedule();
        Test.stopTest();
        Assert.isNotNull(jobId, 'schedule() should return a non-null job ID');
    }
}
