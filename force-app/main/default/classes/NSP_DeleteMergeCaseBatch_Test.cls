@isTest
private class NSP_DeleteMergeCaseBatch_Test {
    // @description Test class for NSP_DeleteMergeCaseBatch covering batch execution, scheduling, callable, and runnable paths.

    private static final String ACCOUNT_DEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASE_DEFAULTS    = 'NSP_TestDataFactory.CaseDefaults';

    @testSetup
    static void setupDataForMergeBatch() {
        Account newAccount = (Account) NSP_TestExtendedDataFactory.createSObject( new Account(), ACCOUNT_DEFAULTS, true );
        Case caseRecord    = (Case)    NSP_TestExtendedDataFactory.createSObject( new Case(),    CASE_DEFAULTS,    true );
    }

    @isTest
    private static void testDeleteMergeCasesBatch_MergedStatus_CaseDeleted() {
        Case caseRecord = [ SELECT Id, Status, CaseNumber FROM Case WHERE Id != null LIMIT 1 ];
        String caseRecordNumber = caseRecord.CaseNumber;
        Test.startTest();
        caseRecord.Status = 'Merged';
        update caseRecord;
        Database.executeBatch( new NSP_DeleteMergeCaseBatch() );
        Test.stopTest();
        Assert.areEqual(
            0,
            [ SELECT count() FROM Case WHERE CaseNumber =: caseRecordNumber ],
            'Merged case should have been deleted by the batch'
        );
    }

    @isTest
    private static void testSchedule_ValidCron_ReturnsJobId() {
        Test.startTest();
        String jobId = NSP_DeleteMergeCaseBatch.schedule();
        Test.stopTest();
        Assert.isNotNull( jobId, 'schedule() should return a valid scheduled job Id' );
    }

    @isTest
    private static void testCallable_RunAction_ReturnsBatchJobId() {
        Test.startTest();
        NSP_DeleteMergeCaseBatch batchInstance = new NSP_DeleteMergeCaseBatch();
        Object result = batchInstance.call( 'run', null );
        Test.stopTest();
        Assert.isNotNull( result, 'call() with run action should return a batch job Id' );
    }

    @isTest
    private static void testCallable_UnknownAction_ReturnsNull() {
        Test.startTest();
        NSP_DeleteMergeCaseBatch batchInstance = new NSP_DeleteMergeCaseBatch();
        Object result = batchInstance.call( 'unknown', null );
        Test.stopTest();
        Assert.isNull( result, 'call() with an unknown action should return null' );
    }

    @isTest
    private static void testSchedulableExecute_DispatchesRun() {
        Test.startTest();
        System.schedule(
            'testSchedulableExecute',
            '3 3 3 * * ?',
            new NSP_DeleteMergeCaseBatch()
        );
        Test.stopTest();
    }

}
