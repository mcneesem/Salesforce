@isTest
private class JobRunnerControllerTest {
    @TestSetup
    private static void setup() {
        Test.startTest();
        Database.executeBatch(new TestBatch());
        Test.stopTest();
    }

    @isTest
    private static void testExecuteBatchSuccess() {
        Test.startTest();
        JobRunnerController.executeBatch('TestBatch');
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, Status 
                                 FROM AsyncApexJob 
                                 WHERE ApexClass.Name = 'TestBatch' 
                                 ORDER BY CreatedDate DESC 
                                 LIMIT 1];
        
        System.assertNotEquals(0, jobs.size(), 'A batch job should have been created');
        AsyncApexJob job = jobs[0];
        System.assertNotEquals(null, job.Id, 'Batch job ID should not be null');
        System.assert(job.Status == 'Queued' || job.Status == 'Preparing' || job.Status == 'Completed', 
            'Batch job should be in Queued, Preparing, or Completed status, actual: ' + job.Status);
    }

    @isTest
    private static void testExecuteBatchInvalidClass() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            JobRunnerController.executeBatch('InvalidClassName');
        } catch (Exception e) {
            exceptionThrown = true;
            System.debug('Caught expected exception: ' + e.getMessage());
        }
        Test.stopTest();
    
        System.assert(exceptionThrown, 'Expected an exception when passing an invalid class name');
    }

    @isTest
    private static void testExecuteBatchBadResponse() {
        Test.startTest();
        try {
            JobRunnerController.executeBatch('TestBatch'); 
        } catch (AuraHandledException e) {
            System.debug('Caught expected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    private static void testGetBatchJobStatuses() {
        Test.startTest();
        List<AsyncApexJob> jobs = JobRunnerController.getBatchJobStatuses('TestBatch');
        Test.stopTest();
        
        System.assertNotEquals(null, jobs, 'Job list should not be null');
        System.assert(jobs.size() > 0, 'There should be at least one job from TestSetup');
        for (AsyncApexJob job : jobs) {
            System.assertEquals('TestBatch', job.ApexClass.Name, 
                'Job should match the batch class name');
            System.assert(job.CreatedDate >= DateTime.now().addDays(-7), 
                'Job should be within the last 7 days');
        }
    }

    @isTest
    private static void testGetRecentBatchClasses() {
        Test.startTest();
        JobRunnerController.executeBatch('TestBatch');
        List<Map<String, String>> batchClasses = JobRunnerController.getRecentBatchClasses();
        Test.stopTest();
        
        List<AsyncApexJob> jobs = [SELECT Id, ApexClass.Name, CreatedDate, Status 
                                 FROM AsyncApexJob 
                                 WHERE ApexClass.Name = 'TestBatch' 
                                 ORDER BY CreatedDate DESC];
        
        System.assertNotEquals(null, batchClasses, 'Batch class list should not be null');
    }
}