@isTest
private class JobRunnerControllerTest {
    @TestSetup
    static void setup() {
        Test.startTest();
        Id jobId = Database.executeBatch(new TestBatch());
        Test.stopTest();
    }

    @isTest
    static void testExecuteBatchSuccess() {
        Test.startTest();
        Id jobId = JobRunnerController.executeBatch('TestBatch');
        Test.stopTest();
        
        System.assertNotEquals(null, jobId, 'Batch job ID should not be null');
       
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
        
        System.assert(job.Status == 'Queued' || job.Status == 'Completed', 
            'Batch job should be in Queued or Completed status, actual: ' + job.Status);
    }

    @isTest
    static void testExecuteBatchInvalidClass() {
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
    static void testExecuteBatchBadResponse() {
        Test.startTest();
        try {
            JobRunnerController.executeBatch('TestBatch'); 
        } catch (AuraHandledException e) {
            System.debug('Caught expected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testGetBatchJobStatuses() {
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
    static void testGetRecentBatchClasses() {
        Test.startTest();
        List<Map<String, String>> batchClasses = JobRunnerController.getRecentBatchClasses();
        Test.stopTest();
        
        System.assertNotEquals(null, batchClasses, 'Batch class list should not be null');
        System.assert(batchClasses.size() > 0, 'There should be at least one batch class from TestSetup');
        Boolean foundTestBatch = false;
        for (Map<String, String> option : batchClasses) {
            if (option.get('value') == 'TestBatch') {
                foundTestBatch = true;
                System.assertEquals('TestBatch', option.get('label'), 
                    'Label should match value');
            }
        }
        System.assert(foundTestBatch, 'TestBatch class should be in the recent batch classes');
    }
}