/* This class is responsible for initiating workflows by making REST Callouts to DocuSign CLM */
/* You can extend the searchForFolder method by invoking it from triggers / scheduled apex / batch jobs */
/* You can also create invocable actions by referencing the searchForFolder method and use it in Process Builders */
/* startInvoiceWorkflow method is used to start workflow in CLM */

public class NSP_DocuSignRESTUtility {
    // test w/ NSP_DocuSignInvoiceDocumentBatchTest (87%)
    private static String accessToken = null;
    private static final String CONTENT_TYPE = 'Content-type';
    private static final String APPLICATION_JSON = 'application/json';

    private NSP_DocuSignRESTUtility(){}
    //Get Rest Configuration Setings from Custom Metadata provided as a part of the installation source
    private static Map<String, DocuSignRESTSettings__mdt> settingsMap {
        //Getter Method
        get {
            //populate only if settingsMap is null
            if (settingsMap == null) {
                settingsMap = new Map<String, DocuSignRESTSettings__mdt>();
                //Query the Custom Metadata and add it to the Map
                //Query against Custom Metadata does not count against the SOQL query Limit
                for (DocuSignRESTSettings__mdt setting : [Select DeveloperName,MasterLabel, Value__c from DocuSignRESTSettings__mdt WHERE Id!=null]) {
                    settingsMap.put(setting.MasterLabel, setting);
                }
            }
            return settingsMap;
        }
        //Blank Setter Method
        set {
        }
    }

    //This method will call the DocuSignJWT class to obtain an access token from DocuSign
    public static String getAccessToken() {

        //Instantiate a request object
        HttpRequest req = new HttpRequest();
        //set the request METHOD
        req.setMethod('POST');

        //set the request endpoint
        String authendpoint = settingsMap.get('RequestAuthEndpoint').Value__c;
        req.setEndPoint(authendpoint);

        //set the request headers
        //1. Content -type
        String authRequestContentType = settingsMap.get('RequestAuthContentType').Value__c;
        req.setHeader(CONTENT_TYPE, authRequestContentType);

        //2. Host
        String authRequestDomain = settingsMap.get('RequestAuthDomain').Value__c;
        req.setHeader('Host', authRequestDomain);

        //Body of the request
        String alg = 'RS256';
        String iss = settingsMap.get('RequestIntegratorKey').Value__c;
        String pkey = settingsMap.get('RequestPrivateKey').Value__c;
        String scope = settingsMap.get('RequestScope').Value__c;
        DocuSignJWT jwtObject = new DocuSignJWT(alg, settingsMap.get('DSUserName').Value__c, iss, pkey, scope, authRequestDomain);

	//Set the request body
        String requestBody = settingsMap.get('RequestAuthBody').Value__c + jwtObject .issue();
        req.setBody(requestBody);

        //call the service
        Http http = new Http();
        HTTPResponse res = http.send(req);

	//Obtain the access token from the Response
        if (res.getStatusCode() == 200) {
            System.JSONParser parser = System.JSON.createParser(res.getBody());
            while (parser.nextToken() != null) {
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                    parser.nextToken();
                    NSP_DocuSignRESTUtility.accessToken = parser.getText();
                    break;
                }
            }
        }

        return NSP_DocuSignRESTUtility.accessToken;

    }

/* futureStartInvoiceWorkflow method is created by following above given structure by DocuSign */
/* Takes List of String - Invoice SF Ids 18 characters as parameter */
/* To call startInvoiceWorkflow from trigger context on demand basis */

          @future(callout=true)
    public static void futureStartInvoiceWorkflow(List<String> sfInvIds) {
        startInvoiceWorkflow(sfInvIds);
    }
/* futureStartInvoiceWorkflow method is created by following above given structure by DocuSign */
/* Takes List of String - Invoice SF Ids 18 characters as parameter */
/* To call startInvoiceWorkflow from trigger context on demand basis */

          //@future(callout=true)
    public static void evaluateInvoiceWorkflow(List<String> sfInvIds) {
        NSP_AutomationSetting__mdt batchGenerationDisabled = NSP_AutomationSetting__mdt.getInstance('NSP_Batch_DocuSign_Invoice_Generation');
        if(batchGenerationDisabled.NSP_Disable__c) {
        futureStartInvoiceWorkflow(sfInvIds);
        }
        else {
            Integer batchSizeVal = Integer.valueOf(System.label.NSP_DocuSign_Invoice_BatchSize);
            NSP_DocuSignInvoiceDocumentBatch dsInvGenBatch = new NSP_DocuSignInvoiceDocumentBatch(sfInvIds);
            Database.executeBatch(dsInvGenBatch, batchSizeVal);
        }
    }

/* startInvoiceWorkflow method is created by following above given structure by DocuSign */
/* Takes List of String - Invoice SF Ids 18 characters as parameter */

         // @future(callout=true)
	public static void startInvoiceWorkflow(List<String> sfInvIds) {
        // Get the access token
        NSP_DocuSignRESTUtility.getAccessToken();

        //Call CLM API if a non-empty access token is returned
        if (!String.isEmpty(NSP_DocuSignRESTUtility.accessToken)) {
            List<DocuSign_Log__c> logList = new List<DocuSign_Log__c>();
            DocuSign_Log__c logEntry;

            for (String singleInvId : sfInvIds) {
                try {
                    //instantiate an Http instance
                    Http httpProtocol = new Http();

                    //instantiate an HttpRequest instance
                    HttpRequest request = new HttpRequest();

                    String endpoint = settingsMap.get('CLMv2ApiEndpoint').Value__c + settingsMap.get('DSAccountID').Value__c + '/workflows';
                    request.setEndPoint(endpoint);

                    //set the POST method
                    request.setMethod('POST');

                    //set Authentication Header
                    request.setHeader('grant_type', 'Bearer');
                    request.setHeader('Authorization', 'Bearer ' + NSP_DocuSignRESTUtility.accessToken);

                    //set Accept Header
                    request.setHeader('Accept', APPLICATION_JSON);

                    //set Content Type Header
                    request.setHeader(CONTENT_TYPE, APPLICATION_JSON);
                    request.setTimeout(120000);

                    //set Empty Body
                    String workflowName = DocuSignRESTSettings__mdt.getInstance('NSP_Invoice_Workflow_Name').Value__c;
                    String reqBody = '{"name":"' + workflowName + '","params": "<root><SFInvId>' + singleInvId + '</SFInvId></root>"}';
                    request.setBody(reqBody);
                    logEntry = new DocuSign_Log__c();

                    // Make the request and capture the response
                    HttpResponse response = httpProtocol.send(request);

                    Map<String, String> requestHeaders = new Map<String, String>();
                    requestHeaders.put('grant_type', 'Bearer');
                    requestHeaders.put('Authorization', 'Bearer ' + accessToken);
                    requestHeaders.put('Accept', APPLICATION_JSON);
                    requestHeaders.put(CONTENT_TYPE, APPLICATION_JSON);
                    //create logEntry
                    logEntry = createLogEntry(JSON.serialize(requestHeaders), request, response, singleInvId );
                } catch (Exception e) {
                    logEntry.Description__c = SchemaController.safeText(
                        e.getMessage(),
                        sObjectType.DocuSign_Log__c.Fields.Description__c
                    );
                } finally {
                    logList.add(logEntry);
                }
            }
            try{
                if (!logList.isEmpty()) {
                    Database.SaveResult[] results = Database.insert(logList, false);
                    NSP_ErrorLogHandler.logResults(
                        NSP_DocuSignRESTUtility.class.getName() ,
                        'startInvoiceWorkflow:insert' ,
                        results
                    );
                }
            } catch ( Exception e ){
                    NSP_DocuSignRESTUtility.handleException( e, 'startInvoiceWorkflow' );
            }
        }
    }

    private static DocuSign_Log__c createLogEntry(
            String requestHeaders ,
            HttpRequest request ,
            HttpResponse response ,
            String recordId
            )
        {
        DocuSign_Log__c logEntry = new DocuSign_Log__c();

        // Capture Request details
        logEntry.Request_Headers__c = SchemaController.safeText(
            JSON.serialize(requestHeaders),
            sObjectType.DocuSign_Log__c.Fields.Request_Headers__c
        );
        logEntry.Record_Id__c = SchemaController.safeText(
            recordId,
            sObjectType.DocuSign_Log__c.Fields.Record_Id__c
        );
        logEntry.Endpoint__c = SchemaController.safeText(
            request.getEndpoint(),
            sObjectType.DocuSign_Log__c.Fields.Endpoint__c
        );
        logEntry.Request_Body__c = SchemaController.safeText(
            request.getBody(),
            sObjectType.DocuSign_Log__c.Fields.Request_Body__c
        );

        // Capture Response details
        if(response != null){
            Map<String, String> responseHeaders = new Map<String, String>();
            for (String headerKey : response.getHeaderKeys()) {
                responseHeaders.put(headerKey, response.getHeader(headerKey));
            }

            logEntry.Response_Code__c = SchemaController.safeInteger(
                response.getStatusCode(),
                sObjectType.DocuSign_Log__c.Fields.Response_Code__c
            );
            logEntry.Response_Body__c = SchemaController.safeText(
                response.getBody(),
                sObjectType.DocuSign_Log__c.Fields.Response_Body__c
            );
            logEntry.Response_Headers__c = SchemaController.safeText(
                JSON.serialize(responseHeaders),
                sObjectType.DocuSign_Log__c.Fields.Response_Headers__c
            );
            logEntry.Response_Status__c = SchemaController.safeText(
                response.getStatus(),
                sObjectType.DocuSign_Log__c.Fields.Response_Status__c
            );

            String message = '';
            if (response.getStatusCode() == 201) {
                message = 'Workflow initiated successfully';
            } else {
                message = 'Unexpected response: ' + String.valueOf(response.getStatusCode());
            }
            logEntry.Description__c = SchemaController.safeText(
                message,
                sObjectType.DocuSign_Log__c.Fields.Description__c
            );
        }

        return logEntry;
    }

    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_DocuSignRESTUtility.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_DocuSignRESTUtility.class.getName() ,
            methodName ,
            e
        );
    }

}