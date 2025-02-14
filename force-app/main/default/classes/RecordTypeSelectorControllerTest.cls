@IsTest
private class RecordTypeSelectorControllerTest {

    @IsTest
    private static void testGetRecordTypes() {
        // Start the test execution
        Test.startTest();
        List<RecordType> result = RecordTypeSelectorController.getAccessibleRecordTypes('Case');
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 0, 'Result list should be initialized and can be empty but not null');

        if (!result.isEmpty()) {
            for (RecordType rt : result) {
                System.assertNotEquals(null, rt.Id, 'RecordType Id should not be null');
                System.assertNotEquals(null, rt.Name, 'RecordType Name should not be null');
            }
        }
    }
    
}
//