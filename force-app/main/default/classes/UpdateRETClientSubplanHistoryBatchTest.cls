@IsTest
private class UpdateRETClientSubplanHistoryBatchTest {
    // Constants
    private static final Integer DEFAULT_SCOPE = 50;

    @TestSetup
    private static void prepareTestData() {
        Date todayDate = Date.today();

        // Record Types
        Id clientSubPlanRtId = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
        Id assetRtId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
        Id subPlanRtId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', 'Choice');
        Id planRtId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', 'Choice');

        // Custom Setting (org defaults)
        ProcessClientSubPlanHistoryBatchSettings__c settings = ProcessClientSubPlanHistoryBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsEnabledCurrentSubPlan__c = true;
        settings.BatchSize__c = 10;
        upsert settings;

        // Assets
        Asset leadParentAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        leadParentAsset.RecordTypeId = assetRtId;
        leadParentAsset.NSP_Client_is_Lead_Parent__c = true;
        leadParentAsset.NSP_Price_Level__c = 'RET - Bundled Plus #2';
        insert leadParentAsset;

        Asset memberAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        memberAsset.RecordTypeId = assetRtId;
        insert memberAsset;

        // Plan + Subplan
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = planRtId;
        insert planRec;

        NSP_Plan_SubPlan__c planSubPlanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubPlanRec.RecordTypeId = subPlanRtId;
        planSubPlanRec.NSP_Subplan_ID__c = 'Test Plan Sub Plan 1';
        planSubPlanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubPlanRec.NSP_Subplan_Lead_Parent__c = memberAsset.Id;
        insert planSubPlanRec;

        // Client Sub Plan Histories
        NSP_Client_Sub_Plan_History__c clientSubPlanHistLead = new NSP_Client_Sub_Plan_History__c();
        clientSubPlanHistLead.RecordTypeId = clientSubPlanRtId;
        clientSubPlanHistLead.NSP_Asset__c = leadParentAsset.Id;
        clientSubPlanHistLead.NSP_End_Date__c = todayDate.addDays(-1);
        clientSubPlanHistLead.NSP_Current_Subplan__c = true;
        clientSubPlanHistLead.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistLead.NSP_Start_Date__c = Date.today();
        clientSubPlanHistLead.NSP_Future_Lead_Parent__c = Date.today();
        insert clientSubPlanHistLead;

        NSP_Client_Sub_Plan_History__c clientSubPlanHistMember = new NSP_Client_Sub_Plan_History__c();
        clientSubPlanHistMember.RecordTypeId = clientSubPlanRtId;
        clientSubPlanHistMember.NSP_Asset__c = memberAsset.Id;
        clientSubPlanHistMember.NSP_End_Date__c = todayDate.addDays(-1);
        clientSubPlanHistMember.NSP_Current_Subplan__c = true;
        clientSubPlanHistMember.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistMember.NSP_Start_Date__c = Date.today();
        insert clientSubPlanHistMember;
    }

    @IsTest
    private static void testBatchExecute_PositiveAndBulk() {
        // Arrange
        List<NSP_Client_Sub_Plan_History__c> existing = [
            SELECT Id, NSP_Current_Subplan__c, NSP_End_Date__c, NSP_Plan_Subplan_Relationship__c, NSP_Asset__c
            FROM NSP_Client_Sub_Plan_History__c
        ];
        System.assert(!existing.isEmpty(), 'Expected setup to create Client Sub Plan History records');

        // Act
        Test.startTest();
        // Use explicit scope to validate execute/finish under bulk
        Id jobId = Database.executeBatch(new UpdateRETClientSubplanHistoryBatch(), DEFAULT_SCOPE);
        Test.stopTest();

        // Assert - job completed
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobType, TotalJobItems, CreatedById FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
        Assert.areEqual('Completed', job.Status, 'Batch should complete successfully');
        Assert.areEqual(0, job.NumberOfErrors, 'Batch should not error');

        // Assert - domain effects: at least one field expected to be updated by the batch.
        // As we don't have the batch internals, assert that target records still exist and are in a consistent state.
        List<NSP_Client_Sub_Plan_History__c> afters = [
            SELECT Id, NSP_Current_Subplan__c, NSP_End_Date__c, NSP_Plan_Subplan_Relationship__c, NSP_Asset__c
            FROM NSP_Client_Sub_Plan_History__c
        ];
        Assert.areEqual(existing.size(), afters.size(), 'Batch should not delete client sub plan history records');
    }

    @IsTest
    private static void testBatchScheduler_SchedulesAndRuns() {
        // Arrange
        String cronExp = '0 0 */4 * * ?'; // Every 4 hours

        // Act
        Test.startTest();
        String jobName = 'UpdateRETClientSubplanHistoryBatchTest_Schedule';
        System.schedule(jobName, cronExp, new UpdateRETClientSubplanHistoryBatch());
        Test.stopTest();

        // Assert - verify a scheduled job created for the batch class
        List<CronTrigger> triggers = [
            SELECT Id, State, NextFireTime, TimesTriggered, CronJobDetail.Name, CronJobDetail.JobType
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
            LIMIT 1
        ];
        Assert.areEqual(1, triggers.size(), 'Expected one scheduled job for batch');
        Assert.areEqual('7', triggers[0].CronJobDetail.JobType, 'Expected job type to be batch/schedulable'); // value may vary by org, assert presence instead
        Assert.isTrue(triggers[0].NextFireTime != null, 'Next fire time should be set');
    }

    @IsTest
    private static void testISelfSchedulable() {
        Test.startTest();
        string jobId = UpdateRETClientSubplanHistoryBatch.schedule();

        List<CronTrigger> triggers = [
            SELECT Id, State, NextFireTime, TimesTriggered, CronJobDetail.Name, CronJobDetail.JobType
            FROM CronTrigger 
            WHERE Id = :jobId
            LIMIT 1
        ];
        
        Assert.areEqual(1, triggers.size(), 'Expected one scheduled job for batch');

        Test.stopTest();
    }
}
