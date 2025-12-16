@isTest
private class JobRunnerControllerTest {
    private static final String REQUESTED_CLASS_NAME = 'TestBatch';

    @testSetup
    private static void setup() {
        Account acct = NSP_TestHelper.createAccount(true);

        Email_Deliverability_Settings__c emailSetting = new Email_Deliverability_Settings__c();
        insert emailSetting;

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
        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];

        JobRunnerSettings__c settings =  JobRunnerSettings__c.getInstance( UserInfo.getUserId() );
        System.assertNotEquals( null , settings , 'Job Runner Settings should not be null.' );
        System.assertNotEquals( null , settings.SoqlDaysLimit__c , 'Job Runner Settings SOQL Days Limit should not be null.' );
        Integer soqlDaysLimit =  settings.SoqlDaysLimit__c.intValue();
        System.assertNotEquals( null , soqlDaysLimit , 'SOQL Days Limit should not be null.' );
        System.assert( ( soqlDaysLimit >= 0 ) , 'SOQL Days Limit should not be negative.' );
        
        System.runas( deploymentManager ) {
            Test.startTest();
            Database.executeBatch( new TestBatch() );
            List<AsyncApexJob> jobs = JobRunnerController.getBatchJobStatuses( JobRunnerControllerTest.REQUESTED_CLASS_NAME );
            Test.stopTest();
            //
            System.assertNotEquals( null , jobs , 'Job list should not be null.' );
            System.assertEquals( false , jobs.isEmpty() , 'Job list should not be empty.' );

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
    }

    @isTest
    private static void testHandleJobRequest() {
        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        
        System.runas( deploymentManager ) {
            JobRunnerSettings__c settings =  JobRunnerSettings__c.getInstance( UserInfo.getUserId() );
            settings.IsEnabled__c = true;
            upsert settings;

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
    }

    @isTest
    private static void testRequestJobExecution() {
        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        
        System.runas( deploymentManager ) {
            JobRunnerSettings__c settings =  JobRunnerSettings__c.getInstance( UserInfo.getUserId() );
            settings.IsEnabled__c = true;
            upsert settings;
            Test.startTest();
            try {
                JobRunnerController.requestJobExecution( JobRunnerControllerTest.REQUESTED_CLASS_NAME );
            } catch ( Exception e ) {
                System.debug( ' ~ CATCH ~ e=' + e );
            }
            Test.stopTest();
        }
    }

    @isTest
    private static void testPrepareEmailMessage() {
        try {
            Test.startTest();
            Messaging.SingleEmailMessage mail = JobRunnerController.prepareEmailMessage( 'test' );
            Test.stopTest();
            System.assertNotEquals( null , mail , 'mail should not be null.' );
        } catch (Exception ex) {
            System.assert(false, 'Unexpected exception while validating prepareEmailMessage expectations: ' + ex.getMessage());
        }
    }

}
//
