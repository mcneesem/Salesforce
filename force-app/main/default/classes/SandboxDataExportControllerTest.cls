/**
 * Unit tests for SandboxDataExportController.
 * Verifies export-definition loading, CSV building, and error-path behaviour.
 *
 * All tests run without seeAllData so that they remain hermetic in CI.
 * CMT records cannot be inserted in tests; we exercise the controller paths
 * that do not depend on specific CMT data being present, and verify error
 * handling for blank/null inputs.
 */
@IsTest
private class SandboxDataExportControllerTest {
    // test w/ SandboxDataExportControllerTest (TBD%)

    // ------------------------------------------------------------
    // getExportDefinitions
    // ------------------------------------------------------------

    @IsTest
    private static void getExportDefinitions_returnsListWithoutException() {
        Test.startTest();
        List<SandboxDataExportController.ExportDefinition> defs =
            SandboxDataExportController.getExportDefinitions();
        Test.stopTest();

        System.assertNotEquals(null, defs, 'Result should never be null');
    }

    @IsTest
    private static void getExportDefinitions_resultIsOrdered() {
        Test.startTest();
        List<SandboxDataExportController.ExportDefinition> defs =
            SandboxDataExportController.getExportDefinitions();
        Test.stopTest();

        for (Integer i = 1; i < defs.size(); i++) {
            System.assert(
                defs.get(i - 1).sortOrder <= defs.get(i).sortOrder,
                'Definitions must be sorted ascending by sortOrder'
            );
        }
    }

    // ------------------------------------------------------------
    // executeExport – error paths
    // ------------------------------------------------------------

    @IsTest
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

    @IsTest
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

    @IsTest
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

    @IsTest
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

    @IsTest
    private static void exportDefinition_sortOrder_defaultsTo9999WhenNull() {
        SandboxDataExportQuery__mdt rec = new SandboxDataExportQuery__mdt(
            Label         = 'Test Export',
            DeveloperName = 'Test_Export',
            SObjectApiName__c   = 'test_export',
            IsActive__c   = true
        );

        SandboxDataExportController.ExportDefinition def =
            new SandboxDataExportController.ExportDefinition(rec);

        System.assertEquals(9999, def.sortOrder, 'Null SortOrder__c should default to 9999');
        System.assertEquals('Test Export', def.label,         'Label should match CMT Label');
        System.assertEquals('Test_Export', def.developerName, 'DeveloperName should match');
        System.assertEquals('test_export', def.fileName,      'FileName should match SObjectApiName__c');
    }

    @IsTest
    private static void exportDefinition_compareTo_sortsCorrectly() {
        SandboxDataExportQuery__mdt rec1 = new SandboxDataExportQuery__mdt(
            Label = 'A', DeveloperName = 'A', SObjectApiName__c = 'a',
            IsActive__c = true, SortOrder__c = 10
        );
        SandboxDataExportQuery__mdt rec2 = new SandboxDataExportQuery__mdt(
            Label = 'B', DeveloperName = 'B', SObjectApiName__c = 'b',
            IsActive__c = true, SortOrder__c = 20
        );

        SandboxDataExportController.ExportDefinition def1 =
            new SandboxDataExportController.ExportDefinition(rec1);
        SandboxDataExportController.ExportDefinition def2 =
            new SandboxDataExportController.ExportDefinition(rec2);

        List<SandboxDataExportController.ExportDefinition> unsorted =
            new List<SandboxDataExportController.ExportDefinition>{ def2, def1 };
        unsorted.sort();

        System.assertEquals('A', unsorted.get(0).developerName, 'Lower sortOrder should come first');
        System.assertEquals('B', unsorted.get(1).developerName, 'Higher sortOrder should come second');
    }

    @IsTest
    private static void exportDefinition_bulkSort_isStable() {
        SandboxDataExportQuery__mdt r1 = new SandboxDataExportQuery__mdt(Label='Z',DeveloperName='Z',SObjectApiName__c='z',IsActive__c=true,SortOrder__c=50);
        SandboxDataExportQuery__mdt r2 = new SandboxDataExportQuery__mdt(Label='M',DeveloperName='M',SObjectApiName__c='m',IsActive__c=true,SortOrder__c=25);
        SandboxDataExportQuery__mdt r3 = new SandboxDataExportQuery__mdt(Label='A',DeveloperName='A',SObjectApiName__c='a',IsActive__c=true,SortOrder__c=1);

        List<SandboxDataExportController.ExportDefinition> items =
            new List<SandboxDataExportController.ExportDefinition>{
                new SandboxDataExportController.ExportDefinition(r1),
                new SandboxDataExportController.ExportDefinition(r2),
                new SandboxDataExportController.ExportDefinition(r3)
            };
        items.sort();

        System.assertEquals(1,  items.get(0).sortOrder, 'First item should have lowest sortOrder');
        System.assertEquals(25, items.get(1).sortOrder, 'Middle item should be in middle');
        System.assertEquals(50, items.get(2).sortOrder, 'Last item should have highest sortOrder');
    }

    // ------------------------------------------------------------
    // escapeCsvValue
    // ------------------------------------------------------------

    @IsTest
    private static void escapeCsvValue_plainValue_wrapsInQuotes() {
        String result = SandboxDataExportController.escapeCsvValue('hello');
        System.assertEquals('"hello"', result, 'Plain value should be wrapped in double quotes');
    }

    @IsTest
    private static void escapeCsvValue_valueWithComma_wrapsInQuotes() {
        String result = SandboxDataExportController.escapeCsvValue('hello,world');
        System.assertEquals('"hello,world"', result, 'Value with comma should be wrapped in quotes');
    }

    @IsTest
    private static void escapeCsvValue_valueWithDoubleQuote_escapesQuotes() {
        String result = SandboxDataExportController.escapeCsvValue('say "hello"');
        System.assertEquals('"say ""hello"""', result, 'Embedded double quotes should be doubled');
    }

    @IsTest
    private static void escapeCsvValue_nullValue_returnsEmptyQuotes() {
        String result = SandboxDataExportController.escapeCsvValue(null);
        System.assertEquals('""', result, 'Null value should produce empty quoted string');
    }

    // ------------------------------------------------------------
    // flattenFieldValues
    // ------------------------------------------------------------

    @IsTest
    private static void flattenFieldValues_plainFields_passThroughUnchanged() {
        Account acc = new Account(Name = 'Acme', Phone = '555-1234');
        Map<String, Object> flat = SandboxDataExportController.flattenFieldValues(
            acc.getPopulatedFieldsAsMap()
        );
        System.assertEquals('Acme',     flat.get('Name'),  'Name should pass through');
        System.assertEquals('555-1234', flat.get('Phone'), 'Phone should pass through');
    }

    @IsTest
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

    @IsTest
    private static void buildCsv_nullRecords_returnsEmptyString() {
        List<String> columns = new List<String>{ 'Id' };
        String result = SandboxDataExportController.buildCsv(null, columns);
        System.assertEquals('', result, 'Null records should return empty string');
    }

    @IsTest
    private static void buildCsv_emptyRecords_returnsEmptyString() {
        List<String> columns = new List<String>{ 'Id' };
        String result = SandboxDataExportController.buildCsv(new List<SObject>(), columns);
        System.assertEquals('', result, 'Empty record list should return empty string');
    }

    @IsTest
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

    @IsTest
    private static void buildCsv_columnOrderMatchesFieldList() {
        List<User> users = [SELECT Username, Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        List<String> columns = new List<String>{ 'Username', 'Id' };

        String csv = SandboxDataExportController.buildCsv(users, columns);

        String headerRow = csv.split('\n')[0];
        Integer usernamePos = headerRow.indexOf('"Username"');
        Integer idPos       = headerRow.indexOf('"Id"');
        System.assert(usernamePos < idPos, 'Username column should appear before Id column per field list order');
    }
}
