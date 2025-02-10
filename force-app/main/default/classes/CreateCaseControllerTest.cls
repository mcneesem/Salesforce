@IsTest
public class CreateCaseControllerTest {
    @IsTest
    static void testGetRecordTypes() {
        // Run the method and verify the results
        Test.startTest();
        List<RecordType> result = CreateCaseController.getRecordTypes();
        Test.stopTest();
    }

}