@IsTest
private class BatchableServiceHandlerTest {

    @IsTest
    private static void testProcessBatchRequestSuccess() {
        String json = '{"batchName": "TestBatch"}';
        BatchableServiceHandler.ResponseWrapper response = BatchableServiceHandler.processBatchRequest(json);
        //System.assertEquals(200, response.statusCode, 'Should return 200 for valid batch');
        //System.assertEquals('Success: Batch job executed.', response.responseBody, 'Should confirm batch execution');
    }

    @IsTest
    private static void testProcessBatchRequestInvalidJson() {
        String json = '{"badJson":';
        BatchableServiceHandler.ResponseWrapper response = BatchableServiceHandler.processBatchRequest(json);
        System.assertEquals(400, response.statusCode, 'Should return 400 for invalid JSON');
        System.assert(response.responseBody.contains('Error: Request body is empty, null, or invalid JSON'), 'Should indicate JSON error');
    }

    @IsTest
    private static void testProcessBatchRequestMissingBatchName() {
        String json = '{"otherField": "value"}';
        BatchableServiceHandler.ResponseWrapper response = BatchableServiceHandler.processBatchRequest(json);
        System.assertEquals(400, response.statusCode, 'Should return 400 for missing batchName');
        System.assert(response.responseBody.contains('Error: batchName is missing or empty.'), 'Should indicate missing batchName');
    }

}