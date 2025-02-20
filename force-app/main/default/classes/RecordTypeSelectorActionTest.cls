@IsTest
private class RecordTypeSelectorActionTest {

    @IsTest
    private static void testAction() {
        List<RecordTypeSelectorAction.Request> inputs = new List<RecordTypeSelectorAction.Request>();
        RecordTypeSelectorAction.Request input = new RecordTypeSelectorAction.Request();
        input.objectApiName = 'Case';
        inputs.add( input );
        Test.startTest();
        List<RecordTypeSelectorAction.Response> outputs = RecordTypeSelectorAction.getAccessibleRecordTypes( inputs );
        Test.stopTest();
        Assert.isNotNull( outputs , 'RecordTypeSelectorAction output should not be null.' );
    }

}
//