// This class is responsible for initiating workflows by making REST Callouts to DocuSign CLM
// You can extend the searchForFolder method by invoking it from triggers / scheduled apex / batch jobs
// startInvoiceWorkflow method is used to start workflow in CLM
public class NSP_DocuSignRESTUtility {
    // test w/ NSP_DocuSignInvoiceDocumentBatchTest (84%)

    private static final String CONTENT_TYPE = 'Content-Type';
    private static final String APPLICATION_JSON = 'application/json';

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

    private static String authEndpoint {
        private get {
            if ( authEndpoint == null ) {
                String local = null;
                if ( NSP_DocuSignRESTUtility.settingsMap != null ) {
                    DocuSignRESTSettings__mdt setting = NSP_DocuSignRESTUtility.settingsMap.get( 'RequestAuthEndpoint' );
                    if ( ( setting != null )
                        && String.isNotBlank( setting.Value__c )
                        )
                    {
                        local = setting.Value__c;
                    }
                }
                authEndpoint = local;
            }
            return authEndpoint;
        }
        private set;
    }

    private static String privateKey {
        private get {
            if ( privateKey == null ) {
                String local = '';
                if ( NSP_DocuSignRESTUtility.settingsMap != null ) {
                    DocuSignRESTSettings__mdt setting = NSP_DocuSignRESTUtility.settingsMap.get( 'RequestPrivateKey' );
                    if ( ( setting != null )
                        && String.isNotBlank( setting.Value__c )
                        )
                    {
                        local = setting.Value__c;
                    }
                }
                privateKey = local;
            }
            return privateKey;
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
        // initialize new POST request...
        HttpRequest request = new HttpRequest();
        request.setMethod( 'POST' );
        // set the request endpoint
        request.setEndPoint( NSP_DocuSignRESTUtility.authEndpoint );
        // set request headers... and prepare request headers for logging...
        Map<String,String> requestHeaders = new Map<String,String>();
        // Content-Type
        String authRequestContentType = NSP_DocuSignRESTUtility.settingsMap.get( 'RequestAuthContentType' ).Value__c;
        request.setHeader( NSP_DocuSignRESTUtility.CONTENT_TYPE , authRequestContentType );
        requestHeaders.put( NSP_DocuSignRESTUtility.CONTENT_TYPE , authRequestContentType );
        // Host
        String authRequestDomain = NSP_DocuSignRESTUtility.settingsMap.get( 'RequestAuthDomain' ).Value__c;
        request.setHeader( 'Host' , authRequestDomain );
        requestHeaders.put( 'Host' , authRequestDomain );
        // construct a jwt blob...
        DocuSignJWT jwtObject = new DocuSignJWT(
            'RS256' , // alg
            NSP_DocuSignRESTUtility.settingsMap.get( 'DSUserName' ).Value__c ,
            NSP_DocuSignRESTUtility.settingsMap.get( 'RequestIntegratorKey' ).Value__c , // iss
            NSP_DocuSignRESTUtility.privateKey , // pkey
            NSP_DocuSignRESTUtility.settingsMap.get( 'RequestScope' ).Value__c , // scope
            authRequestDomain
        );
        // set the request body
        String requestBody = '';
        try {
            requestBody = NSP_DocuSignRESTUtility.settingsMap.get( 'RequestAuthBody' ).Value__c + jwtObject.issue();
        } catch ( Exception e ) {
            requestHeaders.put(
                'Jwt-Issue-Apex-Exception' ,
                e.getTypeName() + ': ' + e.getMessage()
            );
        }
        request.setBody( requestBody );
        CLMTokenRequest token = null;
        try {
            // send the request...
            Http http = new Http();
            HTTPResponse response = http.send( request );
            // build log...
            DocuSign_Log__c logEntry = NSP_DocuSignRESTUtility.buildLogEntry(
                JSON.serialize( requestHeaders ) ,
                request ,
                response ,
                null
            );
            // parse response for the access token...
            if ( response.getStatusCode() == 200 ) {
                token = (CLMTokenRequest)JSON.deserialize( response.getBody() , CLMTokenRequest.class );
            }
            // log authentication attempts...
            NSP_DocuSignRESTUtility.logAuthenticationAttempts( logEntry );
        } catch ( Exception e ) {
            String message = ''
                + NSP_DocuSignRESTUtility.class.getName()
                + '.'
                + 'getTokenRequest'
                + ': '
                + e.getTypeName()
                + ': '
                + e.getMessage()
                ;
            NSP_DocuSignRESTUtility.logAuthenticationAttempts(
                new DocuSign_Log__c(
                    Description__c=SchemaController.safeText(
                        message ,
                        sObjectType.DocuSign_Log__c.Fields.Description__c
                    )
                )
            );
        }
        return token;
    }

    private static void logAuthenticationAttempts( DocuSign_Log__c logEntry ) {
        if ( CLMDocumentTransfer.isEnabledRestTokenLogging
            && ( logEntry != null )
            && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) // prevent LimitExceptions...
            )
        {
            NSP_DocuSignRESTUtility.logAuthenticationAttempts( JSON.serialize( logEntry ) );
        }
    }

    @future
    public static void logAuthenticationAttempts( String logBlob ) {
        try {
            DocuSign_Log__c logEntry = null;
            if ( String.isNotBlank( logBlob ) ) {
                logEntry = (DocuSign_Log__c)JSON.deserialize(
                    logBlob ,
                    DocuSign_Log__c.class
                );
            }
            if ( logEntry != null ) {
                List<Database.SaveResult> results = Database.insert( new List<DocuSign_Log__c>{ logEntry } , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_LeadTriggerHelper.class.getName() ,
                    'logAuthenticationAttempts:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_DocuSignRESTUtility.class.getName() ,
                'logAuthenticationAttempts' ,
                e
            );
        }
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
                        + NSP_DocuSignRESTUtility.settingsMap.get( 'CLMv2ApiEndpoint' ).Value__c
                        + NSP_DocuSignRESTUtility.settingsMap.get( 'DSAccountID' ).Value__c
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
        // capture request header details...
        logEntry.Request_Headers__c = SchemaController.safeText(
            NSP_DocuSignRESTUtility.removeRequestAccessToken( requestHeaders , request ) ,
            sObjectType.DocuSign_Log__c.Fields.Request_Headers__c
        );
        logEntry.Record_Id__c = SchemaController.safeText(
            recordId ,
            sObjectType.DocuSign_Log__c.Fields.Record_Id__c
        );
        // capture request details...
        if ( request != null ) {
            logEntry.Endpoint__c = SchemaController.safeText(
                request.getEndpoint() ,
                sObjectType.DocuSign_Log__c.Fields.Endpoint__c
            );
            logEntry.Request_Body__c = SchemaController.safeText(
                NSP_DocuSignRESTUtility.removeRequestAssertion( request.getBody() ) ,
                sObjectType.DocuSign_Log__c.Fields.Request_Body__c
            );
        }
        // capture response details...
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
            String responseBody = response.getBody();
            if ( String.isNotBlank( responseBody ) ) {
                Map<String,Object> responseBodyDeserialize = (Map<String,Object>)JSON.deserializeUntyped( responseBody );
                if ( responseBodyDeserialize.containsKey( 'access_token' ) ) {
                    responseBody = responseBody.replace(
                        (String)responseBodyDeserialize.get( 'access_token' ) ,
                        'XXX_ACCESS_TOKEN_REMOVED_XXX'
                    );
                }
            }
            logEntry.Response_Body__c = SchemaController.safeText(
                NSP_DocuSignRESTUtility.removeResponseAccessToken( response.getBody() ) ,
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
        }
        return logEntry;
    }

    private static String removeRequestAccessToken( String requestHeaders , HttpRequest request ) {
        if ( String.isNotBlank( requestHeaders )
            && ( request != null )
            && ( request.getEndpoint() != NSP_DocuSignRESTUtility.authEndpoint )
            && String.isNotBlank( NSP_DocuSignRESTUtility.accessToken )
            )
        {
            requestHeaders = requestHeaders.replace(
                NSP_DocuSignRESTUtility.accessToken ,
                'XXX_ACCESS_TOKEN_REMOVED_XXX'
            );
        }
        return requestHeaders;
    }

    private static String removeRequestAssertion( String requestBody ) {
        if ( String.isNotBlank( requestBody ) ) {
            PageReference reference = new PageReference( '/?' + requestBody );
            if ( reference != null ) {
                Map<String,String> parameters = reference.getParameters();
                if ( parameters.containsKey( 'assertion' ) ) {
                    requestBody = requestBody.replace(
                        parameters.get( 'assertion' ) ,
                        'XXX_ASSERTION_REMOVED_XXX'
                    );
                }
            }
        }
        return requestBody;
    }

    private static String removeResponseAccessToken( String responseBody ) {
        if ( String.isNotBlank( responseBody ) ) {
            Map<String,Object> responseBodyDeserialize = (Map<String,Object>)JSON.deserializeUntyped( responseBody );
            if ( responseBodyDeserialize.containsKey( 'access_token' ) ) {
                responseBody = responseBody.replace(
                    (String)responseBodyDeserialize.get( 'access_token' ) ,
                    'XXX_ACCESS_TOKEN_REMOVED_XXX'
                );
            }
        }
        return responseBody;
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