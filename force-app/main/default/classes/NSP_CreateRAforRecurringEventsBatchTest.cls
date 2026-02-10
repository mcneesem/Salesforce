@isTest
private class NSP_CreateRAforRecurringEventsBatchTest {

    @testSetup
    private static void setupTestData() {
        CreateResourceAbsencesBatchSettings__c settings = CreateResourceAbsencesBatchSettings__c.getOrgDefaults();
        settings.EventRecordTypeId__c = NSP_GenericRecordType.getRecordTypeId( 'Event' , 'Core_Serv_Event_RT' );
        upsert settings;

        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Phone = '(112)6475261 ext415';
        tUser.Username = 'jsmith@test.com.abc'+System.currentTimeMillis();
        tUser.NSP_Service_Region__c = 'MMSO - Southeast';
        tUser.NSP_Salesforce_Field_Service__c = NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE;
        tUser.NSP_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        insert tUser;
        Event newEvent = new Event();
        newEvent.OwnerId = tUser.Id;
        newEvent.Subject = 'Test Subject For Event';
        newEvent.DurationInMinutes = 60;
        newEvent.ActivityDateTime = system.today();
        newEvent.StartDateTime = system.today();
        newEvent.IsRecurrence = true;
        newEvent.RecurrenceStartDateTime = system.today();
        newEvent.RecurrenceEndDateOnly = System.today()+30;
        newEvent.RecurrenceType = 'RecursDaily';
        newEvent.RecurrenceInterval = 2; // This means that the event will wait 1 day before recurring again
        newEvent.IsAllDayEvent =false;
        newEvent.DurationInMinutes =60;
        Test.startTest();
        system.runAs(tUser){
            insert newEvent;
        }
        Test.stopTest();
        Datetime yesterday = Datetime.now().addDays(-1);
        Test.setCreatedDate(newEvent.Id, yesterday);
    }

    @isTest
    private static void terminateAccount() {
        try{
            List<String> RA_FIELD = new List<String>{'Id', 'Event_Id__c','Type'};
            test.startTest();
            NSP_CreateRAforRecurringEventsBatch.schedule();
            test.stopTest();
            String query = new NSP_QueryBuilder('ResourceAbsence', RA_FIELD)
                .addFilter('Type', 'Test Subject For Event').addLimit(1).build();
            ResourceAbsence RARec = Database.query(query);
            System.assertNotEquals(RARec, null);
        } catch(Exception ex) {
            System.debug(' ~ ex=' + ex);
        }
    }

    // Covers Database.Batchable.start & execute
    @isTest
    private static void testExecuteBatchDirectly() {
        Test.startTest();
        Database.executeBatch(
            new NSP_CreateRAforRecurringEventsBatch(),
            100
        );
        Test.stopTest();
        System.assert(
            [SELECT COUNT() FROM ResourceAbsence] > 0,
            'ResourceAbsence should be created by batch execution'
        );
    }

    // Covers Schedulable.execute()
    @isTest
    private static void testSchedulableExecute() {
        Test.startTest();
        NSP_CreateRAforRecurringEventsBatch batch = new NSP_CreateRAforRecurringEventsBatch();
        batch.execute((SchedulableContext)null);
        Test.stopTest();
        System.assert(
            [SELECT COUNT() FROM ResourceAbsence] > 0,
            'RA should be created via schedulable execution'
        );
    }

    // Covers ISelfSchedulable.run()
    @isTest
    private static void testRunMethod() {
        Test.startTest();
        Id jobId = new NSP_CreateRAforRecurringEventsBatch().run();
        Test.stopTest();
        System.assertNotEquals(
            null,
            jobId,
            'run() should return a valid batch job id'
        );
    }

    // Covers Callable.call()
    @isTest
    private static void testCallableRunBatch() {
        Test.startTest();
        Object result = new NSP_CreateRAforRecurringEventsBatch().call('run', new Map<String, Object>());
        Test.stopTest();
        System.assertNotEquals(
            null,
            result,
            'Callable runBatch should return a job id'
        );
    }

}
//