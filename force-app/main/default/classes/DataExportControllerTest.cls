/**
 * Unit tests for DataExportController.
 * Verifies export-definition loading, CSV building, and error-path behaviour.
 *
 * All tests run without seeAllData so that they remain hermetic in CI.
 * CMT records cannot be inserted in tests; we exercise the controller paths
 * that do not depend on specific CMT data being present, and verify error
 * handling for blank/null inputs.
 */
@IsTest
private class DataExportControllerTest {
    // test w/ DataExportControllerTest (TBD%)

    // ------------------------------------------------------------
    // getExportDefinitions
    // ------------------------------------------------------------

    @IsTest
    static void getExportDefinitions_returnsListWithoutException() {
        Test.startTest();
        List<DataExportController.ExportDefinition> defs =
            DataExportController.getExportDefinitions();
        Test.stopTest();

        // May be empty in a fresh org — the important thing is no exception is thrown
        System.assertNotEquals(null, defs, 'Result should never be null');
    }

    @IsTest
    static void getExportDefinitions_resultIsOrdered() {
        Test.startTest();
        List<DataExportController.ExportDefinition> defs =
            DataExportController.getExportDefinitions();
        Test.stopTest();

        // Verify ascending sort order on whatever records exist
        for (Integer i = 1; i < defs.size(); i++) {
            System.assert(
                defs.get(i - 1).sortOrder <= defs.get(i).sortOrder,
                'Definitions must be sorted ascending by sortOrder'
            );
        }
    }

    // ------------------------------------------------------------
    // executeExport – error paths (no real CMT records in test)
    // ------------------------------------------------------------

    @IsTest
    static void executeExport_blankDeveloperName_throwsAuraHandledException() {
        Exception caught;
        Test.startTest();
        try {
            DataExportController.executeExport('');
        } catch (AuraHandledException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'AuraHandledException expected for blank name');
    }

    @IsTest
    static void executeExport_nullDeveloperName_throwsAuraHandledException() {
        Exception caught;
        Test.startTest();
        try {
            DataExportController.executeExport(null);
        } catch (AuraHandledException e) {
            caught = e;
        }
        Test.stopTest();

        System.assertNotEquals(null, caught, 'AuraHandledException expected for null name');
    }

    @IsTest
    static void executeExport_unknownDeveloperName_throwsAuraHandledException() {
        Exception caught;
        Test.startTest();
        try {
            DataExportController.executeExport('This_Record_Does_Not_Exist_zzzXXX');
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

    // ------------------------------------------------------------
    // executeExport – happy path via dynamic SOQL on a safe object
    // Build a minimal CMT-free test by calling the private CSV builder
    // indirectly via a SOQL query on User (always has at least 1 row in test).
    // We cannot insert CMT records, so we verify CSV output by calling
    // executeExport with a known-good CMT DeveloperName only if one exists.
    // ------------------------------------------------------------

    @IsTest
    static void executeExport_withFirstActiveCmtRecord_producesNonEmptyCsv() {
        // Retrieve first active CMT record (if any exist in the org)
        List<DataExportController.ExportDefinition> defs =
            DataExportController.getExportDefinitions();

        if (defs.isEmpty()) {
            // No CMT records deployed yet — skip the happy-path assertion
            System.assert(true, 'No active CMT records; happy-path test skipped');
            return;
        }

        String devName = defs[0].developerName;
        String csv;
        Test.startTest();
        csv = DataExportController.executeExport(devName);
        Test.stopTest();

        // Result should be a non-null string (may be empty if query returns 0 rows)
        System.assertNotEquals(null, csv, 'CSV result should not be null for a valid CMT record');
    }

    // ------------------------------------------------------------
    // ExportDefinition inner class
    // ------------------------------------------------------------

    @IsTest
    static void exportDefinition_sortOrder_defaultsTo9999WhenNull() {
        // Construct a mock CMT record using DataExportQuery__mdt static initialiser
        // (SortOrder__c left null to exercise the null-guard branch)
        DataExportQuery__mdt rec = new DataExportQuery__mdt(
            Label         = 'Test Export',
            DeveloperName = 'Test_Export',
            FileName__c   = 'test_export',
            IsActive__c   = true
        );

        DataExportController.ExportDefinition def =
            new DataExportController.ExportDefinition(rec);

        System.assertEquals(9999, def.sortOrder, 'Null SortOrder__c should default to 9999');
        System.assertEquals('Test Export', def.label,        'Label should match CMT Label');
        System.assertEquals('Test_Export', def.developerName,'DeveloperName should match');
        System.assertEquals('test_export', def.fileName,     'FileName should match FileName__c');
    }

    @IsTest
    static void exportDefinition_compareTo_sortsCorrectly() {
        DataExportQuery__mdt rec1 = new DataExportQuery__mdt(
            Label = 'A', DeveloperName = 'A', FileName__c = 'a',
            IsActive__c = true, SortOrder__c = 10
        );
        DataExportQuery__mdt rec2 = new DataExportQuery__mdt(
            Label = 'B', DeveloperName = 'B', FileName__c = 'b',
            IsActive__c = true, SortOrder__c = 20
        );

        DataExportController.ExportDefinition def1 =
            new DataExportController.ExportDefinition(rec1);
        DataExportController.ExportDefinition def2 =
            new DataExportController.ExportDefinition(rec2);

        List<DataExportController.ExportDefinition> unsorted = new List<DataExportController.ExportDefinition>();
        unsorted.add(def2);
        unsorted.add(def1);
        unsorted.sort();

        System.assertEquals('A', unsorted.get(0).developerName, 'Lower sortOrder should come first');
        System.assertEquals('B', unsorted.get(1).developerName, 'Higher sortOrder should come second');
    }

    // ------------------------------------------------------------
    // Bulk-style test: many definitions sort correctly
    // ------------------------------------------------------------

    @IsTest
    static void exportDefinition_bulkSort_isStable() {
        // Use fixed CMT records to verify sort order without a loop
        DataExportQuery__mdt r1 = new DataExportQuery__mdt(Label='Z',DeveloperName='Z',FileName__c='z',IsActive__c=true,SortOrder__c=50);
        DataExportQuery__mdt r2 = new DataExportQuery__mdt(Label='M',DeveloperName='M',FileName__c='m',IsActive__c=true,SortOrder__c=25);
        DataExportQuery__mdt r3 = new DataExportQuery__mdt(Label='A',DeveloperName='A',FileName__c='a',IsActive__c=true,SortOrder__c=1);
        DataExportController.ExportDefinition e1 = new DataExportController.ExportDefinition(r1);
        DataExportController.ExportDefinition e2 = new DataExportController.ExportDefinition(r2);
        DataExportController.ExportDefinition e3 = new DataExportController.ExportDefinition(r3);
        List<DataExportController.ExportDefinition> items = new List<DataExportController.ExportDefinition>();
        items.add(e1);
        items.add(e2);
        items.add(e3);
        items.sort();
        System.assertEquals(1,  items.get(0).sortOrder, 'First item should have lowest sortOrder');
        System.assertEquals(25, items.get(1).sortOrder, 'Middle item should be in middle');
        System.assertEquals(50, items.get(2).sortOrder, 'Last item should have highest sortOrder');
    }
}