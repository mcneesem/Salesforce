@isTest
private class JobRunnerControllerTest {
    private static final String REQUESTED_CLASS_NAME = 'TestBatch';

    @testSetup
    private static void setup() {
        JobRunnerSettings__c settings =  JobRunnerSettings__c.getInstance( UserInfo.getUserId() );
        settings.IsEnabled__c = true;
        settings.SoqlDaysLimit__c = 7;
        settings.ServiceAddress__c = UserInfo.getUserEmail();
        settings.BccAddresses__c = UserInfo.getUserEmail();
        settings.BatchSize__c = 200;
        settings.JobWaitingMinutes__c = 10;
        settings.ClickWaitingSeconds__c = 7;
        settings.PageSize__c = 20;
        upsert settings;
    }

    @isTest
    private static void testWireMethods() {
        Test.startTest();
        Boolean isAccessible = JobRunnerController.isAccessible();
        Integer pageSize = JobRunnerController.getPageSize();
        Integer clickWitingSeconds = JobRunnerController.getClickWaitingSeconds();
        List<Map<String,String>> batchClasses = JobRunnerController.getBatchClassOptions();
        Test.stopTest();
        //
        System.assertNotEquals( null , batchClasses , 'Batch class options should not be null.' );
    }

    @isTest
    private static void testGetBatchJobStatuses() {
        Test.startTest();
        Database.executeBatch( new TestBatch() );
        List<AsyncApexJob> jobs = JobRunnerController.getBatchJobStatuses( JobRunnerControllerTest.REQUESTED_CLASS_NAME );
        Test.stopTest();
        //
        System.assertNotEquals( null , jobs , 'Job list should not be null.' );
        System.assertEquals( false , jobs.isEmpty() , 'Job list should not be empty.' );

        JobRunnerSettings__c settings =  JobRunnerSettings__c.getInstance( UserInfo.getUserId() );
        System.assertNotEquals( null , settings , 'Job Runner Settings should not be null.' );
        System.assertNotEquals( null , settings.SoqlDaysLimit__c , 'Job Runner Settings SOQL Days Limit should not be null.' );
        Integer soqlDaysLimit =  settings.SoqlDaysLimit__c.intValue();
        System.assertNotEquals( null , soqlDaysLimit , 'SOQL Days Limit should not be null.' );
        System.assert( ( soqlDaysLimit >= 0 ) , 'SOQL Days Limit should not be negative.' );

        for ( AsyncApexJob job : jobs ) {
            System.assertEquals(
                JobRunnerControllerTest.REQUESTED_CLASS_NAME ,
                job.ApexClass.Name ,
                'Job should match the requested class name.'
            );
            System.assert(
                ( job.CreatedDate >= DateTime.now().addDays( -1 * soqlDaysLimit ) ) ,
                'Job should be created within the last ' + soqlDaysLimit + ' days.'
            );
        }
    }

    @isTest
    private static void testHandleJobRequest() {
        Test.startTest();
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.Subject = JobRunnerControllerTest.REQUESTED_CLASS_NAME;
        JobRunnerController.handleJobRequest( email , null );
        Test.stopTest();
        //
        List<AsyncApexJob> jobs = [
            SELECT Id , Status
            FROM AsyncApexJob
            WHERE ( ApexClass.Name = :JobRunnerControllerTest.REQUESTED_CLASS_NAME )
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals( null , jobs , 'Job list should not be null.' );
        System.assertEquals( false , jobs.isEmpty() , 'Job list should not be empty.' );
        AsyncApexJob job = jobs[0];
        System.assertNotEquals( null , job.Id , 'Job Id should not be null.' );
        System.assert(
            (
                ( job.Status == 'Queued' )
                || ( job.Status == 'Preparing' )
                || ( job.Status == 'Completed' )
            ) ,
            'Job Status should be in Queued, Preparing, OR Completed. Actual: ' + job.Status
        );
    }

    @isTest
    private static void testRequestJobExecution() {
        Test.startTest();
        try {
            JobRunnerController.requestJobExecution( JobRunnerControllerTest.REQUESTED_CLASS_NAME );
        } catch ( Exception e ) {
            System.debug( ' ~ CATCH ~ e=' + e );
        }
        Test.stopTest();
    }

}
//