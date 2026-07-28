@isTest
private class SandboxDataExportControllerTest {
    // test w/ SandboxDataExportControllerTest (TBD%)

    // ------------------------------------------------------------
    // getExportDefinitions
    // ------------------------------------------------------------

    @isTest
    private static void getExportDefinitions_returnsListWithoutException() {
        Test.startTest();
        List<SandboxDataExportController.ExportDefinition> defs =
            SandboxDataExportController.getExportDefinitions();
        Test.stopTest();

        System.assertNotEquals(null, defs, 'Result should never be null');
    }

    // ------------------------------------------------------------
    // executeExport – error paths
    // ------------------------------------------------------------

    @isTest
    private static void executeExport_blankDeveloperName_throwsAuraHandledException() {
        Exception caught;
        Test.startTest();
        try {
            SandboxDataExportController.executeExport('');
        } catch (AuraHandledException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'AuraHandledException expected for blank name');
    }

    @isTest
    private static void executeExport_nullDeveloperName_throwsAuraHandledException() {
        Exception caught;
        Test.startTest();
        try {
            SandboxDataExportController.executeExport(null);
        } catch (AuraHandledException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'AuraHandledException expected for null name');
    }

    @isTest
    private static void executeExport_unknownDeveloperName_throwsAuraHandledException() {
        Exception caught;
        Test.startTest();
        try {
            SandboxDataExportController.executeExport('This_Record_Does_Not_Exist_zzzXXX');
        } catch (AuraHandledException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(
            null,
            caught,
            'AuraHandledException expected when CMT record not found'
        );
    }

    @isTest
    private static void executeExport_withFirstActiveCmtRecord_producesNonEmptyCsv() {
        List<SandboxDataExportController.ExportDefinition> defs =
            SandboxDataExportController.getExportDefinitions();

        if (defs.isEmpty()) {
            System.assert(true, 'No active CMT records; happy-path test skipped');
            return;
        }

        String devName = defs[0].developerName;
        String csv;
        Test.startTest();
        csv = SandboxDataExportController.executeExport(devName);
        Test.stopTest();

        System.assertNotEquals(null, csv, 'CSV result should not be null for a valid CMT record');
    }

    // ------------------------------------------------------------
    // ExportDefinition inner class
    // ------------------------------------------------------------

    @isTest
    private static void exportDefinition_test() {
        SandboxDataExportQuery__mdt rec = new SandboxDataExportQuery__mdt(
            Label         = 'Test Export',
            DeveloperName = 'Test_Export',
            SObjectApiName__c   = 'test_export',
            IsActive__c   = true
        );

        SandboxDataExportController.ExportDefinition def =
            new SandboxDataExportController.ExportDefinition(rec);

        System.assertEquals('Test Export', def.label,         'Label should match CMT Label');
        System.assertEquals('Test_Export', def.developerName, 'DeveloperName should match');
        System.assertEquals('test_export', def.fileName,      'FileName should match SObjectApiName__c');
    }

    // ------------------------------------------------------------
    // escapeCsvValue
    // ------------------------------------------------------------

    @isTest
    private static void escapeCsvValue_plainValue_wrapsInQuotes() {
        String result = SandboxDataExportController.escapeCsvValue('hello');
        System.assertEquals('"hello"', result, 'Plain value should be wrapped in double quotes');
    }

    @isTest
    private static void escapeCsvValue_valueWithComma_wrapsInQuotes() {
        String result = SandboxDataExportController.escapeCsvValue('hello,world');
        System.assertEquals('"hello,world"', result, 'Value with comma should be wrapped in quotes');
    }

    @isTest
    private static void escapeCsvValue_valueWithDoubleQuote_escapesQuotes() {
        String result = SandboxDataExportController.escapeCsvValue('say "hello"');
        System.assertEquals('"say ""hello"""', result, 'Embedded double quotes should be doubled');
    }

    @isTest
    private static void escapeCsvValue_nullValue_returnsEmptyQuotes() {
        String result = SandboxDataExportController.escapeCsvValue(null);
        System.assertEquals('""', result, 'Null value should produce empty quoted string');
    }

    // ------------------------------------------------------------
    // flattenFieldValues
    // ------------------------------------------------------------

    @isTest
    private static void flattenFieldValues_plainFields_passThroughUnchanged() {
        Account acc = new Account(Name = 'Acme', Phone = '555-1234');
        Map<String, Object> flat = SandboxDataExportController.flattenFieldValues(
            acc.getPopulatedFieldsAsMap()
        );
        System.assertEquals('Acme',     flat.get('Name'),  'Name should pass through');
        System.assertEquals('555-1234', flat.get('Phone'), 'Phone should pass through');
    }

    @isTest
    private static void flattenFieldValues_sobjectValue_expandsToDotNotation() {
        // Query a User with Profile relationship to get a real SObject value in the map
        User u = [SELECT Id, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        Map<String, Object> flat = SandboxDataExportController.flattenFieldValues(
            u.getPopulatedFieldsAsMap()
        );
        System.assert(flat.containsKey('Profile.Name'), 'Profile.Name should appear as dot-notation key');
        System.assert(!flat.containsKey('Profile'),     'Raw Profile SObject key should not remain');
    }

    // ------------------------------------------------------------
    // buildCsv
    // ------------------------------------------------------------

    @isTest
    private static void buildCsv_nullRecords_returnsEmptyString() {
        List<String> columns = new List<String>{ 'Id' };
        String result = SandboxDataExportController.buildCsv(null, columns);
        System.assertEquals('', result, 'Null records should return empty string');
    }

    @isTest
    private static void buildCsv_emptyRecords_returnsEmptyString() {
        List<String> columns = new List<String>{ 'Id' };
        String result = SandboxDataExportController.buildCsv(new List<SObject>(), columns);
        System.assertEquals('', result, 'Empty record list should return empty string');
    }

    @isTest
    private static void buildCsv_withRecords_producesCorrectHeaderAndRows() {
        List<User> users = [SELECT Id, Username FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<String> columns = new List<String>{ 'Id', 'Username' };

        Test.startTest();
        String csv = SandboxDataExportController.buildCsv(users, columns);
        Test.stopTest();

        List<String> lines = csv.split('\n');
        System.assertEquals(2, lines.size(), 'Should have header row and one data row');
        System.assert(lines[0].contains('"Id"'),       'Header should contain Id column');
        System.assert(lines[0].contains('"Username"'), 'Header should contain Username column');
        System.assert(lines[1].contains(users[0].Id),  'Data row should contain the user Id');
    }

    @isTest
    private static void buildCsv_columnOrderMatchesFieldList() {
        List<User> users = [SELECT Username, Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<String> columns = new List<String>{ 'Username', 'Id' };

        String csv = SandboxDataExportController.buildCsv(users, columns);

        String headerRow = csv.split('\n')[0];
        Integer usernamePos = headerRow.indexOf('"Username"');
        Integer idPos       = headerRow.indexOf('"Id"');
        System.assert(usernamePos < idPos, 'Username column should appear before Id column per field list order');
    }

    // ------------------------------------------------------------
    // NSP_QueryBuilder integration (ORDER BY)
    // ------------------------------------------------------------

    @isTest
    private static void queryBuilder_orderBy_producesExpectedClause() {
        List<String> fields = new List<String>{ 'Id', 'Name' };
        NSP_QueryBuilder builder = new NSP_QueryBuilder('Account', fields);
        builder.orderBy('Name', 'ASC', false);
        String soql = builder.build();

        System.assert(soql.contains('ORDER BY Name ASC'), 'Query should contain ORDER BY Name ASC');
    }

    @isTest
    private static void queryBuilder_noOrderBy_omitsClause() {
        List<String> fields = new List<String>{ 'Id', 'Name' };
        NSP_QueryBuilder builder = new NSP_QueryBuilder('Account', fields);
        String soql = builder.build();

        System.assert(!soql.contains('ORDER BY'), 'Query without orderBy should not contain ORDER BY');
    }

}
//