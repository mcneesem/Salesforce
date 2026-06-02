@isTest
private class FinanceLogHandlerTest {

    // Test logging a single platform event with all fields populated
    @isTest
    private static void testLogPlatformEvents_SingleEvent() {
        Process_Billing_Event__e event = createTestEvent(
            'PROJECT_UPDATE_ORDER',
            'a0X1234567890ABCD',
            Date.today(),
            true
        );
        List<Process_Billing_Event__e> events = new List<Process_Billing_Event__e>{ event };

        Test.startTest();
        FinanceLogHandler.logPlatformEvents('TestClass', 'testMethod', events);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Class__c, Method__c, Object__c, Project_ID__c, Description__c
                                       FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create exactly 1 log record');
        System.assertEquals('TestClass', logs[0].Class__c);
        System.assertEquals('testMethod', logs[0].Method__c);
        System.assertEquals('Process_Billing_Event__e', logs[0].Object__c);
        System.assertEquals('a0X1234567890ABCD', logs[0].Project_ID__c);
        System.assert(logs[0].Description__c.contains('Action: PROJECT_UPDATE_ORDER'));
        System.assert(logs[0].Description__c.contains('Project ID: a0X1234567890ABCD'));
        System.assert(logs[0].Description__c.contains('Invoice Ready: true'));
    }


    // Test logging bulk platform events (200 records)
    @isTest
    private static void testLogPlatformEvents_BulkEvents() {
        List<Process_Billing_Event__e> events = createBulkTestEvents(200);

        Test.startTest();
        FinanceLogHandler.logPlatformEvents('BulkTestClass', 'bulkMethod', events);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id FROM Finance_Log__c];
        System.assertEquals(200, logs.size(), 'Should create 200 log records for bulk operation');
    }

    // Test logging with null event list
    @isTest
    private static void testLogPlatformEvents_NullEvent() {
        Test.startTest();
        FinanceLogHandler.logPlatformEvents('TestClass', 'testMethod', null);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id FROM Finance_Log__c];
        System.assertEquals(0, logs.size(), 'Should not create any logs for null input');
    }

    // Test logging with empty event list
    @isTest
    private static void testLogPlatformEvents_EmptyEvent() {
        List<Process_Billing_Event__e> events = new List<Process_Billing_Event__e>();

        Test.startTest();
        FinanceLogHandler.logPlatformEvents('TestClass', 'testMethod', events);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id FROM Finance_Log__c];
        System.assertEquals(0, logs.size(), 'Should not create any logs for empty list');
    }

    // Test logging event with partial data
    @isTest
    private static void testLogPlatformEvents_PartialData() {
        Process_Billing_Event__e event = new Process_Billing_Event__e(
            NSP_Action__c = 'PROJECT_UPDATE',
            NSP_Project_SF_Id__c = 'a0X9876543210ZYXW'
        );
        List<Process_Billing_Event__e> events = new List<Process_Billing_Event__e>{ event };

        Test.startTest();
        FinanceLogHandler.logPlatformEvents('TestClass', 'testMethod', events);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create log with partial data');
        System.assert(logs[0].Description__c.contains('Action: PROJECT_UPDATE'));
        System.assert(logs[0].Description__c.contains('Project ID: a0X9876543210ZYXW'));
    }

    // Test logging all successful SaveResults
    @isTest
    private static void testlogResults_AllSuccess() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        List<Database.SaveResult> results = Database.update(accounts, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Class__c, Method__c, Object__c, Description__c
                                       FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assertEquals('TestClass', logs[0].Class__c);
        System.assertEquals('testMethod', logs[0].Method__c);
        System.assertEquals('Account', logs[0].Object__c);
        System.assert(logs[0].Description__c.contains('Successfully updated 5'), 'Should show 5 successes');
        System.assert(logs[0].Description__c.contains('Record IDs:'), 'Should include record IDs');
    }

    // Test logging all failed SaveResults
    @isTest
    private static void testlogResults_AllFailures() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account()); // Missing required Name field
        }

        List<Database.SaveResult> results = Database.insert(accounts, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assert(logs[0].Description__c.contains('REQUIRED_FIELD_MISSING') ||
                      logs[0].Description__c.contains('Required fields are missing'),
                      'Should contain error details');
    }

    // Test logging mixed success and failure SaveResults
    @isTest
    private static void testlogResults_MixedResults() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'Valid Account 1'));
        accounts.add(new Account()); // Invalid - no name
        accounts.add(new Account(Name = 'Valid Account 2'));

        List<Database.SaveResult> results = Database.insert(accounts, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assert(logs[0].Description__c.contains('Successfully updated 2'), 'Should show 2 successes');
        System.assert(logs[0].Description__c.contains('REQUIRED_FIELD_MISSING') ||
                      logs[0].Description__c.contains('Required fields are missing'),
                      'Should also contain error details');
    }

    // Test logging with null SaveResults
    @isTest
    private static void testlogResults_NullResults() {
        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', null);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id FROM Finance_Log__c];
        System.assertEquals(0, logs.size(), 'Should not create log for null results');
    }

    // Test logging with empty SaveResults list
    @isTest
    private static void testlogResults_EmptyResults() {
        List<Database.SaveResult> results = new List<Database.SaveResult>();

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id FROM Finance_Log__c];
        System.assertEquals(0, logs.size(), 'Should not create log for empty results');
    }

    // Test logging single successful record (singular form)
    @isTest
    private static void testlogResults_SingleSuccess() {
        Account acc = new Account(Name = 'Single Test Account');
        insert acc;

        List<Database.SaveResult> results = Database.update(new List<Account>{ acc }, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assert(logs[0].Description__c.contains('Successfully updated 1 '), 'Should use singular form');
        System.assert(!logs[0].Description__c.contains('1 s'), 'Should not pluralize for single record');
    }

    // Test logging when all results are failures (no success IDs)
    @isTest
    private static void testlogResults_OnlyFailures_NoSuccessIds() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account()); // All invalid
        }

        List<Database.SaveResult> results = Database.insert(accounts, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assert(!logs[0].Description__c.contains('Successfully updated'), 'Should not show success message');
        System.assert(logs[0].Description__c.contains('REQUIRED_FIELD_MISSING') ||
                      logs[0].Description__c.contains('Required fields are missing'),
                      'Should only contain error messages');
    }

    // Test with different object types
    @isTest
    private static void testlogResults_DifferentObjectTypes() {
        Contact con = new Contact(LastName = 'Test Contact');
        insert con;

        List<Database.SaveResult> results = Database.update(new List<Contact>{ con }, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Object__c, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assertEquals('Contact', logs[0].Object__c, 'Should auto-derive correct object name');
        System.assert(logs[0].Description__c.contains('Successfully updated 1'), 'Should show success');
    }

    // Test exception handling in insertDMLLog
    @isTest
    private static void testlogResults_ExceptionHandling() {
        // Create a valid scenario that will succeed
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<Database.SaveResult> results = Database.update(new List<Account>{ acc }, false);

        Test.startTest();
        // Call with valid data - should not throw exception
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        // Verify log was created despite any potential exceptions
        List<Finance_Log__c> logs = [SELECT Id FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create log record without throwing exception');
    }

    // Test auto-derived objectName from SaveResult recordId for Account
    @isTest
    private static void testlogResults_AutoDerivedObjectName_Account() {
        Account acc = new Account(Name = 'Auto-Derive Test Account');
        insert acc;
        List<Database.SaveResult> accountResults = Database.update(new List<Account>{ acc }, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', accountResults);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Object__c FROM Finance_Log__c WHERE Class__c = 'TestClass'];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assertEquals('Account', logs[0].Object__c, 'Should auto-derive Account as object name');
    }

    // Test auto-derived objectName from SaveResult recordId for Contact
    @isTest
    private static void testlogResults_AutoDerivedObjectName_Contact() {
        Contact con = new Contact(LastName = 'Auto-Derive Test Contact');
        insert con;
        List<Database.SaveResult> contactResults = Database.update(new List<Contact>{ con }, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethodContact', contactResults);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Object__c FROM Finance_Log__c WHERE Method__c = 'testMethodContact'];
        System.assertEquals(1, logs.size(), 'Should create 1 log record for Contact');
        System.assertEquals('Contact', logs[0].Object__c, 'Should auto-derive Contact as object name');
    }

    // Test handling of scenarios where objectName cannot be derived
    @isTest
    private static void testlogResults_NullObjectNameHandling() {
        // Test with all failures (no successful recordIds to derive from)
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account()); // All invalid
        }
        List<Database.SaveResult> results = Database.insert(accounts, false);

        Test.startTest();
        FinanceLogHandler.logResults('TestClass', 'testMethod', results);
        Test.stopTest();

        List<Finance_Log__c> logs = [SELECT Id, Object__c, Description__c FROM Finance_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 log record');
        System.assertEquals(null, logs[0].Object__c, 'Object name should be null when no successful recordId exists');
        System.assert(logs[0].Description__c.contains('REQUIRED_FIELD_MISSING') ||
                      logs[0].Description__c.contains('Required fields are missing'),
                      'Should still log error details');
    }

    //
    // HELPER METHODS
    //

    // Create a test platform event with specified values
    private static Process_Billing_Event__e createTestEvent(
        String action,
        String projectId,
        Date goLiveDate,
        Boolean invoiceReady
        )
    {
        Process_Billing_Event__e event = new Process_Billing_Event__e();
        event.NSP_Action__c = action;
        event.NSP_Project_SF_Id__c = projectId;
        event.NSP_Project_Go_Live_Date__c = goLiveDate;
        event.NSP_Invoice_Ready__c = invoiceReady;
        return event;
    }

    // Create bulk test platform events
    private static List<Process_Billing_Event__e> createBulkTestEvents(Integer count) {
        List<Process_Billing_Event__e> events = new List<Process_Billing_Event__e>();
        for (Integer i = 0; i < count; i++) {
            events.add(createTestEvent(
                'PROJECT_UPDATE_ORDER',
                'a0X' + String.valueOf(i).leftPad(15, '0'),
                Date.today(),
                Math.mod(i, 2) == 0
            ));
        }
        return events;
    }

}
//