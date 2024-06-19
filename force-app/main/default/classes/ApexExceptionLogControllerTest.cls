@isTest private class ApexExceptionLogControllerTest {
    private static final String CLASS_NAME = ' ~ ApexExceptionLogControllerTest';
    private static final Boolean ENABLE_testApexExceptionLogControllerApexClass = True;
    private static final Boolean ENABLE_testApexExceptionLogControllerApexTrigger = True;
    private static final Boolean ENABLE_testApexExceptionLogControllerApexPage = True;

    @testSetup private static void upsertCustomSettings() {
        InboundEmailLogSettings__c settings = InboundEmailLogSettings__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        upsert settings;
    }

    @isTest private static void testApexExceptionLogControllerApexClass() {
        String METHOD_NAME = ' ~ testApexExceptionLogControllerApexClass';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testApexExceptionLogControllerApexClass ) {
            Test.startTest();
            List<InboundEmailLog__c> logs = new List<InboundEmailLog__c>();
            logs.add(
                new InboundEmailLog__c(
                    Subject__c='Developer script exception ' ,
                    PlainTextBody__c=''
                    + 'Apex script unhandled exception by user/organization: ' + UserInfo.getUserId() + '/' + [ SELECT Id FROM Organization ].Id + '\n'
                    + '\n'
                    + 'Organization: Insperity (' + URL.getOrgDomainURL().toExternalForm() + ').\n'
                    + 'User: ' + UserInfo.getUserName() + '.\n'
                    + 'Source organization: 00D4x000003x74T (null)\n'
                    + 'Custom Exception TEST\n'
                    + '\n'
                    + 'caused by: System.SObjectException: SObject row was retrieved via SOQL without querying the requested field: Lead.Name\n'
                    + '\n'
                    + 'Class.test.ApexExceptionLogController.testMethodName: line 1, column 1\n'
                    + 'Trigger.ApexExceptionLogTrigger: line 1, column 1\n'
                )
            );
            ApexExceptionLogController.insertApexExceptionLogs( logs );
            List<ApexExceptionLog__c> records = [ SELECT Id FROM ApexExceptionLog__c ];
            Assert.isNotNull( records , 'Null ApexExceptionLog__c query results.' );
            Assert.isTrue( ( records.size() > 0 ) , 'No ApexExceptionLog__c query results.' );
            Assert.isTrue( ( records.size() == 1 ) , 'Incorrect ApexExceptionLog__c query results.' );
            Test.stopTest();
        }
    }

    @isTest private static void testApexExceptionLogControllerApexTrigger() {
        String METHOD_NAME = ' ~ testApexExceptionLogControllerApexTrigger';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testApexExceptionLogControllerApexTrigger ) {
            Test.startTest();
            List<InboundEmailLog__c> logs = new List<InboundEmailLog__c>();
            logs.add(
                new InboundEmailLog__c(
                    Subject__c='Developer script exception ' ,
                    PlainTextBody__c=''
                    + 'Apex script unhandled trigger exception by user/organization: ' + UserInfo.getUserId() + '/' + [ SELECT Id FROM Organization ].Id + '\n'
                    + '\n'
                    + 'Organization: Insperity (' + URL.getOrgDomainURL().toExternalForm() + ').\n'
                    + 'User: ' + UserInfo.getUserName() + '.\n'
                    + 'Source organization: 00D4x000003x74T (null)\n'
                    + 'test.ApexExceptionLogTrigger: execution of AfterDelete\n'
                    + '\n'
                    + 'caused by: System.SObjectException: SObject row was retrieved via SOQL without querying the requested field: Lead.Name\n'
                    + '\n'
                    + 'Class.test.ApexExceptionLogController.testMethodName: line 1, column 1\n'
                    + 'Trigger.ApexExceptionLogTrigger: line 1, column 1\n'
                )
            );
            ApexExceptionLogController.insertApexExceptionLogs( logs );
            List<ApexExceptionLog__c> records = [ SELECT Id FROM ApexExceptionLog__c ];
            Assert.isNotNull( records , 'Null ApexExceptionLog__c query results.' );
            Assert.isTrue( ( records.size() > 0 ) , 'No ApexExceptionLog__c query results.' );
            Assert.isTrue( ( records.size() == 1 ) , 'Incorrect ApexExceptionLog__c query results.' );
            Test.stopTest();
        }
    }

    @isTest private static void testApexExceptionLogControllerApexPage() {
        String METHOD_NAME = ' ~ testApexExceptionLogControllerApexPage';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ null=' + null );
        if ( ENABLE_testApexExceptionLogControllerApexPage ) {
            Test.startTest();
            List<InboundEmailLog__c> logs = new List<InboundEmailLog__c>();
            logs.add(
                new InboundEmailLog__c(
                    Subject__c='Developer script exception ' ,
                    PlainTextBody__c=''
                    + 'Apex script unhandled exception by user/organization: ' + UserInfo.getUserId() + '/' + [ SELECT Id FROM Organization ].Id + '\n'
                    + '\n'
                    + 'Organization: Insperity (' + URL.getOrgDomainURL().toExternalForm() + ').\n'
                    + 'User: ' + UserInfo.getUserName() + '.\n'
                    + 'Source organization: 00D4x000003x74T (null)\n'
                    + 'Visualforce Page: /apex/SBQQ__sb\n'
                    + '\n'
                    + 'caused by: System.SObjectException: SObject row was retrieved via SOQL without querying the requested field: Lead.Name\n'
                    + '\n'
                    + '(System Code)\n'
                )
            );
            ApexExceptionLogController.insertApexExceptionLogs( logs );
            List<ApexExceptionLog__c> records = [ SELECT Id FROM ApexExceptionLog__c ];
            Assert.isNotNull( records , 'Null ApexExceptionLog__c query results.' );
            Assert.isTrue( ( records.size() > 0 ) , 'No ApexExceptionLog__c query results.' );
            Assert.isTrue( ( records.size() == 1 ) , 'Incorrect ApexExceptionLog__c query results.' );
            Test.stopTest();
        }
    }

}
//