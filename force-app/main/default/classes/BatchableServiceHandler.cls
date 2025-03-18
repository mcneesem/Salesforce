public with sharing class BatchableServiceHandler {
    // test w/ BatchableServiceHandlerTest (87%)

    public static ResponseWrapper processBatchRequest(String requestBody) {
        ResponseWrapper response = new ResponseWrapper(500, 'Error: Failed to execute batch - An unexpected error occurred');
        try {
            response = validateAndProcessRequest(requestBody);
        } catch (Exception e) {
            response = new ResponseWrapper(500, 'Error:' + e.getMessage());
        }
        return response;
    }

    private static ResponseWrapper validateAndProcessRequest(String requestBody) {
        Boolean hasError = false;
        ResponseWrapper response = null;
        Map<String,Object> requestData = validateRequestAndParseJson(requestBody, hasError);
        if (requestData == null) {
            hasError = true;
            response = new ResponseWrapper(400, 'Error: Request body is empty, null, or invalid JSON');
        }
        if (!hasError) {
            response = processBatchRequestData(requestData, hasError);
        }
        return response != null ? response : new ResponseWrapper(500, 'Error: An unexpected error occurred');
    }

    private static Map<String,Object> validateRequestAndParseJson(String requestBody, Boolean hasError) {
        Map<String,Object> requestData = null;
        if (!hasError && String.isBlank(requestBody)) {
            hasError = true;
        }
        if (!hasError) {
            try {
                requestData = (Map<String,Object>) JSON.deserializeUntyped(requestBody);
            } catch (JSONException e) {
                hasError = true;
            }
        }
        return hasError ? null : requestData;
    }

    private static ResponseWrapper processBatchRequestData(Map<String,Object> requestData, Boolean hasError) {
        ResponseWrapper response = null;
        String batchClassName = null;
        Type batchType = null;
        if (!hasError) {
            batchClassName = (String) requestData.get('batchName');
            if (String.isBlank(batchClassName)) {
                hasError = true;
                response = new ResponseWrapper(400, 'Error: batchName is missing or empty.');
            }
        }
        if (!hasError) {
            batchType = Type.forName(batchClassName);
            if (batchType == null) {
                hasError = true;
                response = new ResponseWrapper(404, 'Error: "' + batchClassName + '" is not found.');
            } else if (!(batchType.newInstance() instanceof Database.Batchable<SObject>)) {
                hasError = true;
                response = new ResponseWrapper(400, 'Error: "' + batchClassName + '" is not a valid Batchable class.');
            }
        }
        if (!hasError) {
            executeBatch(batchClassName);
            response = new ResponseWrapper(200, 'Success: Batch job executed.');
        }
        return response;
    }

    private static void executeBatch(String batchClassName) {
        Type batchType = Type.forName(batchClassName);
        Database.executeBatch((Database.Batchable<SObject>) batchType.newInstance());
    }

    public class ResponseWrapper {
        public Integer statusCode;
        public String responseBody;

        public ResponseWrapper(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
    }

}