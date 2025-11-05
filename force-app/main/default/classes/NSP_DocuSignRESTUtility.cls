// This class is responsible for initiating workflows by making REST Callouts to DocuSign CLM
// You can extend the searchForFolder method by invoking it from triggers / scheduled apex / batch jobs
// You can also create invocable actions by referencing the searchForFolder method and use it in Process Builders
// startInvoiceWorkflow method is used to start workflow in CLM
public class NSP_DocuSignRESTUtility {
    // test w/ NSP_DocuSignInvoiceDocumentBatchTest (87%)

    private static final String CONTENT_TYPE = 'Content-type';
    private static final String APPLICATION_JSON = 'application/json';

    private NSP_DocuSignRESTUtility() {
    }

    //Get Rest Configuration Setings from Custom Metadata provided as a part of the installation source
    private static Map<String,DocuSignRESTSettings__mdt> settingsMap {
        private get {
            if ( settingsMap == null ) {
                settingsMap = new Map<String,DocuSignRESTSettings__mdt>();
                for ( DocuSignRESTSettings__mdt setting : [
                            SELECT DeveloperName , MasterLabel , Value__c
                            FROM DocuSignRESTSettings__mdt
                            WHERE ( Id != null )
                        ]
                    )
                {
                    settingsMap.put( setting.MasterLabel , setting );
                }
            }
            return settingsMap;
        }
        private set;
    }

    private static String accessToken {
        private get {
            if ( accessToken == null ) {
                String local = null;
                if ( NSP_DocuSignRESTUtility.tokenRequest != null ) {
                    local = NSP_DocuSignRESTUtility.tokenRequest.Access_Token;
                }
                accessToken = local;
            }
            return accessToken;
        }
        private set;
    }

    public static String getAccessToken() {
        return NSP_DocuSignRESTUtility.accessToken;
    }

    private static CLMTokenRequest tokenRequest {
        private get {
            if ( tokenRequest == null ) {
                tokenRequest = NSP_DocuSignRESTUtility.getTokenRequest();
            }
            return tokenRequest;
        }
        private set;
    }

    //This method will call the DocuSignJWT class to obtain an access token from DocuSign
    private static CLMTokenRequest getTokenRequest() {

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
        req.setHeader(NSP_DocuSignRESTUtility.CONTENT_TYPE, authRequestContentType);

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
        CLMTokenRequest token = null;
        if (res.getStatusCode() == 200) {
            token = (CLMTokenRequest)JSON.deserialize( res.getBody() , CLMTokenRequest.class );
        }
        return token;
    }

    // futureStartInvoiceWorkflow method is created by following above given structure by DocuSign
    // Takes List of String - Invoice SF Ids 18 characters as parameter
    // To call startInvoiceWorkflow from trigger context on demand basis
    @future(callout=true)
    public static void futureStartInvoiceWorkflow( List<String> sfInvIds ) {
        startInvoiceWorkflow( sfInvIds );
    }

    // futureStartInvoiceWorkflow method is created by following above given structure by DocuSign
    // Takes List of String - Invoice SF Ids 18 characters as parameter
    // To call startInvoiceWorkflow from trigger context on demand basis
    public static void evaluateInvoiceWorkflow( List<String> sfInvIds ) {
        NSP_AutomationSetting__mdt batchGenerationDisabled = NSP_AutomationSetting__mdt.getInstance( 'NSP_Batch_DocuSign_Invoice_Generation' );
        if ( batchGenerationDisabled.NSP_Disable__c ) {
            futureStartInvoiceWorkflow( sfInvIds );
        } else {
            Integer batchSizeVal = Integer.valueOf( System.label.NSP_DocuSign_Invoice_BatchSize );
            NSP_DocuSignInvoiceDocumentBatch dsInvGenBatch = new NSP_DocuSignInvoiceDocumentBatch( sfInvIds );
            Database.executeBatch( dsInvGenBatch , batchSizeVal );
        }
    }

    // startInvoiceWorkflow method is created by following above given structure by DocuSign
    // Takes List of String - Invoice SF Ids 18 characters as parameter
    public static void startInvoiceWorkflow( List<String> sfInvIds ) {
        //Call CLM API if a non-empty access token is returned
        if ( String.isNotBlank( NSP_DocuSignRESTUtility.accessToken ) ) {
            List<DocuSign_Log__c> logList = new List<DocuSign_Log__c>();
            for ( String singleInvId : sfInvIds ) {
                DocuSign_Log__c logEntry = new DocuSign_Log__c();
                try {
                    //instantiate an HttpRequest instance
                    HttpRequest request = new HttpRequest();

                    // set request endpoint...
                    String endpoint = ''
                        + settingsMap.get( 'CLMv2ApiEndpoint' ).Value__c
                        + settingsMap.get( 'DSAccountID' ).Value__c
                        + '/workflows'
                        ;
                    request.setEndPoint( endpoint );

                    // set the POST method
                    request.setMethod( 'POST' );
                    request.setTimeout( 120000 );

                    // set request headers... and prepare request headers for logging...
                    Map<String,String> requestHeaders = new Map<String,String>();
                    request.setHeader( 'grant_type' , 'Bearer' );
                    requestHeaders.put( 'grant_type' , 'Bearer' );
                    request.setHeader( 'Authorization' , 'Bearer ' + NSP_DocuSignRESTUtility.accessToken );
                    requestHeaders.put( 'Authorization' , 'Bearer ' + NSP_DocuSignRESTUtility.accessToken );
                    request.setHeader( 'Accept' , NSP_DocuSignRESTUtility.APPLICATION_JSON );
                    requestHeaders.put( 'Accept' , NSP_DocuSignRESTUtility.APPLICATION_JSON );
                    request.setHeader( NSP_DocuSignRESTUtility.CONTENT_TYPE , NSP_DocuSignRESTUtility.APPLICATION_JSON );
                    requestHeaders.put( NSP_DocuSignRESTUtility.CONTENT_TYPE , NSP_DocuSignRESTUtility.APPLICATION_JSON );

                    // set Empty Body
                    String workflowName = DocuSignRESTSettings__mdt.getInstance( 'NSP_Invoice_Workflow_Name' ).Value__c;
                    String reqBody = ''
                        + '{'
                        + '"name":"' + workflowName + '",'
                        + '"params": "<root><SFInvId>' + singleInvId + '</SFInvId></root>"'
                        + '}'
                        ;
                    request.setBody( reqBody );

                    // send the request and capture the response
                    Http httpProtocol = new Http();
                    HttpResponse response = httpProtocol.send( request );

                    // build log...
                    logEntry = NSP_DocuSignRESTUtility.buildLogEntry(
                        JSON.serialize( requestHeaders ) ,
                        request ,
                        response ,
                        singleInvId
                    );
                } catch ( Exception e ) {
                    logEntry.Description__c = SchemaController.safeText(
                        e.getMessage(),
                        sObjectType.DocuSign_Log__c.Fields.Description__c
                    );
                } finally {
                    logList.add( logEntry );
                }
            }
            try {
                if ( !logList.isEmpty() ) {
                    Database.SaveResult[] results = Database.insert( logList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_DocuSignRESTUtility.class.getName() ,
                        'startInvoiceWorkflow:insert' ,
                        results
                    );
                }
            } catch ( Exception e ){
                NSP_DocuSignRESTUtility.handleException( e , 'startInvoiceWorkflow' );
            }
        }
    }

    private static DocuSign_Log__c buildLogEntry(
        String requestHeaders ,
        HttpRequest request ,
        HttpResponse response ,
        String recordId
        )
    {
        DocuSign_Log__c logEntry = new DocuSign_Log__c();
        // Capture Request details
        if ( String.isNotBlank( requestHeaders ) ) {
            if ( String.isNotBlank( NSP_DocuSignRESTUtility.accessToken ) ) {
                requestHeaders = requestHeaders.replace( NSP_DocuSignRESTUtility.accessToken , 'XXX_ACCESS_TOKEN_REMOVED_XXX' );
            }
            logEntry.Request_Headers__c = SchemaController.safeText(
                requestHeaders ,
                sObjectType.DocuSign_Log__c.Fields.Request_Headers__c
            );
        }
        logEntry.Record_Id__c = SchemaController.safeText(
            recordId ,
            sObjectType.DocuSign_Log__c.Fields.Record_Id__c
        );
        if ( request != null ) {
            logEntry.Endpoint__c = SchemaController.safeText(
                request.getEndpoint() ,
                sObjectType.DocuSign_Log__c.Fields.Endpoint__c
            );
            logEntry.Request_Body__c = SchemaController.safeText(
                request.getBody() ,
                sObjectType.DocuSign_Log__c.Fields.Request_Body__c
            );
        }
        // Capture Response details
        if ( response != null ) {
            Map<String,String> responseHeaders = new Map<String,String>();
            for ( String headerKey : response.getHeaderKeys() ) {
                responseHeaders.put(
                    headerKey ,
                    response.getHeader( headerKey )
                );
            }
            logEntry.Response_Code__c = SchemaController.safeInteger(
                response.getStatusCode() ,
                sObjectType.DocuSign_Log__c.Fields.Response_Code__c
            );
            logEntry.Response_Body__c = SchemaController.safeText(
                response.getBody() ,
                sObjectType.DocuSign_Log__c.Fields.Response_Body__c
            );
            logEntry.Response_Headers__c = SchemaController.safeText(
                JSON.serialize( responseHeaders ) ,
                sObjectType.DocuSign_Log__c.Fields.Response_Headers__c
            );
            logEntry.Response_Status__c = SchemaController.safeText(
                response.getStatus() ,
                sObjectType.DocuSign_Log__c.Fields.Response_Status__c
            );
            // summarize description message...
            String message = '';
            if ( response.getStatusCode() == 201 ) {
                message = 'Workflow initiated successfully';
            } else {
                message = 'Unexpected response: ' + String.valueOf( response.getStatusCode() );
            }
            logEntry.Description__c = SchemaController.safeText(
                message ,
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
//