global with sharing class DSAPIUserAuthenticator implements SpringCMIAuthenticator {
    // test w/ SpringCMTests (93%)
    // test w/ CLMDocumentTransferTest (17%)

    global  DSAPIUserAuthenticator(
        String apiAccountID ,
        String iss ,
        String aud ,
        String sub ,
        String pkey ,
        String dataCenter ,
        String version
        )
    {
        this.version = version;
        this.apiAccountID = apiAccountID;
        this.iss = iss;
        this.aud = aud;
        this.sub = sub;
        this.pkey = pkey;
        this.dataCenter = dataCenter;
    }

    private String version;
    private String apiAccountID;
    private String iss;
    private String aud;
    private String sub;
    private String pkey;
    private String dataCenter;
    private Datetime lastTokenRequest;
    private CLMTokenRequest tokenRequest;
    private String objectAPIURL;
    private String uploadAPIURL;
    private String downloadAPIURL;

    global String getObjectAPIUrl() {
        objectAPIURL = 'https://api' + dataCenter + '.springcm.com/' + version + '/' + apiAccountID;
        return objectAPIURL;
    }

    global String getUploadAPIUrl() {
        uploadAPIURL = 'https://apiupload' + dataCenter + '.springcm.com/' + version + '/' + apiAccountID;
        return uploadAPIURL;
    }

    global String getDownloadAPIUrl() {
        downloadAPIURL = 'https://apidownload' + dataCenter + '.springcm.com/' + version + '/' + apiAccountID;
        return downloadAPIURL;
    }

    global String accessToken() {
        if ( CLMDocumentTransfer.isEnabledRestToken ) {
            return NSP_DocuSignRESTUtility.getAccessToken();
        } else {
            if ( ( tokenRequest == null ) || ( Datetime.now() > TokenExpiration() ) ) {
                GetNewToken();
            }
            return tokenRequest.Access_Token;
        }
    }

    // DEPRECATED by CLMDocumentTransfer.isEnabledRestToken
    global DateTime tokenExpiration() {
        return LastTokenRequest.addSeconds( Integer.valueOf( tokenRequest.Expires_In ) );
    }

    // DEPRECATED by CLMDocumentTransfer.isEnabledRestToken
    global void getNewToken() {

        String access_token = null;

        //Instantiate a request object
        HttpRequest req = new HttpRequest();
        //set the request METHOD
        req.setMethod('POST');

        //set the request endpoint
        String authendpoint =  'https://'+aud+'/oauth/token';
        System.Debug(LoggingLevel.INFO, '**RequestAuthEndpoint' + authendpoint);
        req.setEndPoint(authendpoint);

        //set the request headers
        //1. Content -type
        String authRequestContentType = 'application/x-www-form-urlencoded';
        System.Debug(LoggingLevel.INFO, '**authRequestContentType ' + authRequestContentType);
        req.setHeader('Content-type', authRequestContentType);

        //2. Host
        String authRequestDomain = aud;
        System.Debug(LoggingLevel.INFO, '**authRequestDomain ' + authRequestDomain);
        req.setHeader('Host', authRequestDomain);

        //Body of the request
        String alg = 'RS256';
        String scope = 'signature impersonation spring_read spring_write';
        DocusignJWT jwtObject = new DocusignJWT(alg, sub, iss, pkey, scope, authRequestDomain);

        //Set the request body
        String requestBody = 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion='+ jwtObject.issue();
        System.Debug(LoggingLevel.INFO, '**RequestAuthBody' + requestBody);
        req.setBody(requestBody);

        //call the service
        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.Debug(LoggingLevel.INFO, '**ResponseAuthBody' + res.getbody());
        System.Debug(LoggingLevel.INFO, '**ResponseAuth' + res);

        //Obtain the access token from the Response
        if (res.getStatusCode() == 200) {
            this.tokenRequest = (CLMTokenRequest)JSON.deserialize(res.getBody(), CLMTokenRequest.class);
            system.debug(this.tokenRequest.Access_Token);
            this.lastTokenRequest = Datetime.now();
        }
    }

}
//