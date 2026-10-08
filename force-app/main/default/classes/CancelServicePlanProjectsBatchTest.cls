@isTest
private class CancelServicePlanProjectsBatchTest {

    @testSetup
    private static void setupTestData() {
        CancelServicePlanProjectsBatchSettings__c settings = CancelServicePlanProjectsBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 200;
        settings.StatusDaysMinimum__c = 14; // grace period
        settings.StatusDaysMaximum__c = 19;
        upsert settings;

        Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'Asset' ,
            NSP_ServiceConstants.WO_ASSET_RECORDTYPE
        );

        Account terminatedAccount = (Account)NSP_TestExtendedDataFactory.createSObject(
            new Account() ,
            'NSP_TestDataFactory.AccountDefaults' ,
            true
        );

        // WO Asset that qualifies: Terminated, Account Status Date 15 days ago (> 14).
        Asset woAsset = (Asset)NSP_TestDataFactory.createSObject(
            new Asset() ,
            'NSP_TestDataFactory.AssetDefaults' ,
            false
        );
        woAsset.RecordTypeId = woAssetRecordTypeId;
        woAsset.Name = 'Test WO Asset Client Terminated';
        woAsset.AccountId = terminatedAccount.Id;
        woAsset.NSP_Account_Status__c = NSP_ServiceConstants.TERMINATED;
        woAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        woAsset.NSP_Account_Status_Date__c = System.today().addDays( -15 );
        insert woAsset;

        //create project
        Id project_PEORTId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, NSP_ServiceConstants.PROJECT_PEO_RECORDTYPE);
        pse__proj__c project = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Name = 'BT Engagement Plan Test';
        project.recordTypeId = project_PEORTId ;
        project.pse__Project_Status__c = 'Active' ;
        project.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
        project.pse__Account__c = terminatedAccount.Id;
        project.TemplateName__c = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
        project.pse__Start_Date__c = System.today();
        insert project;
    }

    // Scope should include a WO Asset Terminated for 15 days and the batch should run to completion.
    @isTest
    private static void shouldProcessTerminatedAssets_WhenStatusDateOlderThanLag() {
        Test.startTest();
        Database.executeBatch( new CancelServicePlanProjectsBatch() , 200 );
        Test.stopTest();

        List<AsyncApexJob> batchJobs = [
            SELECT Id , Status , JobType
            FROM AsyncApexJob
            WHERE ( ApexClass.Name = 'CancelServicePlanProjectsBatch' )
            AND ( JobType = 'BatchApex' )
        ];
        Assert.areEqual(
            1 ,
            batchJobs.size() ,
            'Exactly one batch job should have been enqueued for the class'
        );
        Assert.areEqual(
            'Completed' ,
            batchJobs[0].Status ,
            'The batch job should complete without an uncaught failure'
        );
    }

       // The generic runner should enqueue the batch and return the job Id.
    @isTest
    private static void shouldQueueBatch_WhenRunInvoked() {
        CancelServicePlanProjectsBatch batch = new CancelServicePlanProjectsBatch();

        Test.startTest();
        Id jobId = (Id)batch.call( 'run' , null );
        Test.stopTest();

        Assert.isNotNull(
            jobId ,
            'call(run) should enqueue the batch and return an AsyncApexJob Id'
        );
    }

    // An empty chunk should be a safe no-op (no scope records selected).
    @isTest
    private static void shouldNoOp_WhenScopeEmpty() {
        CancelServicePlanProjectsBatch batch = new CancelServicePlanProjectsBatch();
        Integer dmlBefore = Limits.getDmlStatements();

        Test.startTest();
        batch.execute( null , new List<Asset>() );
        batch.finish( null );
        Test.stopTest();

        Assert.areEqual(
            dmlBefore ,
            Limits.getDmlStatements() ,
            'Processing an empty scope should perform no DML'
        );
    }

    // schedule() should register exactly one CronTrigger at 1 AM daily.
    @isTest
    private static void shouldRegisterCronJob_WhenScheduled() {
        Test.startTest();
        String cronId = CancelServicePlanProjectsBatch.schedule();
        Test.stopTest();

        List<CronTrigger> cronJobs = [
            SELECT Id , CronExpression
            FROM CronTrigger
            WHERE Id = :cronId
        ];
        Assert.areEqual(
            1 ,
            cronJobs.size() ,
            'schedule() should create exactly one CronTrigger'
        );
        Assert.areEqual(
            '0 0 1 ? * * *' ,
            cronJobs[0].CronExpression ,
            'The batch should be scheduled for 1 AM daily'
        );
    }

}
//
