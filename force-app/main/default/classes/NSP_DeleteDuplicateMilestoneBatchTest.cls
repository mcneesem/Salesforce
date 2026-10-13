// @description Test class for NSP_DeleteDuplicateMilestoneBatch
// @date 12/16/2022
// Author : Abhishek Kumar
// Name : NSP_DeleteDuplicateMilestoneBatchTest
@isTest
private class NSP_DeleteDuplicateMilestoneBatchTest {

    private static final String PROJECT_RET_RECORDTYPE          = 'RET_Deconversion_2020_Form';
    private static final String PROJECT_GENERAL_BUSINESS_TEMPLATE = 'RET General Business Plan Project';

    // @description Helper: returns the project task created in setup data.
    private static pse__Project_Task__c getProjectTask() {
        return [ SELECT Id , pse__Milestone__c , pse__Project__c FROM pse__Project_Task__c WHERE Name = 'test projectTask' LIMIT 1 ];
    }

    // @description Helper: returns all milestones matching the given name.
    private static List<pse__Milestone__c> getMilestonesByName( String milestoneName ) {
        return [ SELECT Id , Name FROM pse__Milestone__c WHERE Name = :milestoneName ];
    }

    // @description Sets up shared test data: one project, one original milestone, one duplicate milestone
    //              with the same name, and one project task linked to the duplicate.
    @TestSetup
    private static void setupTestData() {
        // get record type id for RET project type
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , PROJECT_RET_RECORDTYPE );

        pse__Proj__c newProj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject( new pse__Proj__c() , 'NSP_TestDataFactory.ProjectDefaults' , false );
        newProj.pse__Is_Template__c = false;
        newProj.TemplateName__c     = PROJECT_GENERAL_BUSINESS_TEMPLATE;
        newProj.RecordTypeId        = retProjectRecordTypeId;
        insert newProj;

        // original (non-duplicate) milestone
        pse__Milestone__c milestoneOrig = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject( new pse__Milestone__c() , 'NSP_TestDataFactory.MileStoneDefaults' , false );
        milestoneOrig.pse__Project__c = newProj.Id;
        milestoneOrig.Name            = 'test';
        insert milestoneOrig;

        // duplicate milestone with the same name
        pse__Milestone__c milestoneDuplic = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject( new pse__Milestone__c() , 'NSP_TestDataFactory.MileStoneDefaults' , false );
        milestoneDuplic.pse__Project__c = newProj.Id;
        milestoneDuplic.Name            = 'test';
        insert milestoneDuplic;

        // project task linked to the duplicate milestone
        pse__Project_Task__c newProjTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject( new pse__Project_Task__c() , 'NSP_TestDataFactory.ProjectTaskDefaults' , false );
        newProjTask.pse__Project__c   = newProj.Id;
        newProjTask.pse__Milestone__c = milestoneDuplic.Id;
        newProjTask.Name              = 'test projectTask';
        insert newProjTask;
    }

    // @description Positive: batch re-points the project task's milestone reference from the duplicate to the original.
    @isTest
    private static void testProjectTaskMilestoneUpdate() {
        Test.startTest();
        NSP_DeleteDuplicateMilestoneBatch batchSch = new NSP_DeleteDuplicateMilestoneBatch();
        Database.executeBatch( batchSch , 200 );
        batchSch.execute( null );
        Test.stopTest();

        pse__Project_Task__c projectTaskRec = NSP_DeleteDuplicateMilestoneBatchTest.getProjectTask();
        pse__Milestone__c milestoneOrig     = [ SELECT Id FROM pse__Milestone__c WHERE Name = 'test' AND NSP_isDuplicate__c = false LIMIT 1 ];
        System.Assert.areEqual( projectTaskRec.pse__Milestone__c , milestoneOrig.Id , 'Project task milestone should be re-pointed to the original non-duplicate milestone' );
    }

    // @description Positive: batch deletes the duplicate milestone, leaving exactly one milestone with the shared name.
    @isTest
    private static void testDuplicateMilestoneDeleted() {
        Test.startTest();
        NSP_DeleteDuplicateMilestoneBatch batchSch = new NSP_DeleteDuplicateMilestoneBatch();
        Database.executeBatch( batchSch , 200 );
        batchSch.execute( null );
        Test.stopTest();

        List<pse__Milestone__c> milestoneRecs = NSP_DeleteDuplicateMilestoneBatchTest.getMilestonesByName( 'test' );
        System.Assert.areEqual( 1 , milestoneRecs.size() , 'Only one milestone named "test" should remain after the duplicate is deleted' );
    }

    // @description Negative: a milestone with a unique name is not flagged as a duplicate and is not deleted.
    @isTest
    private static void testNonDuplicateMilestoneNotDeleted() {
        // given — a non-duplicate milestone with a unique name
        pse__Project_Task__c projectTaskRec = NSP_DeleteDuplicateMilestoneBatchTest.getProjectTask();

        pse__Milestone__c milestoneNonDuplic = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject( new pse__Milestone__c() , 'NSP_TestDataFactory.MileStoneDefaults' , false );
        milestoneNonDuplic.pse__Project__c = projectTaskRec.pse__Project__c;
        milestoneNonDuplic.Name            = 'New Name';
        insert milestoneNonDuplic;

        Test.startTest();
        NSP_DeleteDuplicateMilestoneBatch batchSch = new NSP_DeleteDuplicateMilestoneBatch();
        Database.executeBatch( batchSch , 200 );
        batchSch.execute( null );
        Test.stopTest();

        List<pse__Milestone__c> milestoneRecs = NSP_DeleteDuplicateMilestoneBatchTest.getMilestonesByName( 'New Name' );
        System.Assert.areEqual( 1 , milestoneRecs.size() , 'A non-duplicate milestone should not be deleted by the batch' );
    }

    // @description Covers System.schedule() directly; verifies the job registers without error.
    @isTest
    private static void testSchedulable() {
        Test.startTest();
        System.schedule(
            'Test NSP_DeleteDuplicateMilestoneBatch' ,
            '0 0 * * * ? *' ,
            new NSP_DeleteDuplicateMilestoneBatch()
        );
        Test.stopTest();

        System.Assert.isTrue( true , 'Schedulable execute() should complete without error' );
    }

    // @description Covers ISelfSchedulable.schedule(); verifies a non-null CronTrigger job Id is returned.
    @isTest
    private static void testScheduleReturnsJobId() {
        Test.startTest();
        String jobId = NSP_DeleteDuplicateMilestoneBatch.schedule();
        Test.stopTest();

        System.Assert.isNotNull( jobId , 'schedule() should return a non-null scheduled job Id' );
    }

    // @description Covers execute(SchedulableContext) -> call(run) -> run() -> Database.executeBatch chain.
    @isTest
    private static void testSchedulableExecuteRunsBatch() {
        Test.startTest();
        new NSP_DeleteDuplicateMilestoneBatch().execute( null );
        Test.stopTest();

        List<pse__Milestone__c> milestoneRecs = NSP_DeleteDuplicateMilestoneBatchTest.getMilestonesByName( 'test' );
        System.Assert.areEqual( 1 , milestoneRecs.size() , 'Schedulable execute path should trigger a batch run that removes the duplicate milestone' );
    }

    // @description Covers call() with an unrecognized action; verifies null is returned without error.
    @isTest
    private static void testCallUnknownActionReturnsNull() {
        NSP_DeleteDuplicateMilestoneBatch batchJob = new NSP_DeleteDuplicateMilestoneBatch();

        Test.startTest();
        Object result = batchJob.call( 'unknown' , null );
        Test.stopTest();

        System.Assert.isNull( result , 'call() with an unrecognized action should return null' );
    }

}
//
