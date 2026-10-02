global with sharing class CMSalesforceUserAuthenticator implements SpringCMIAuthenticator {
    // test w/ SpringCMTests (??%)

    private static final String SOAP_API_PATH = '/services/Soap/u/65.0/';

    global CMSalesforceUserAuthenticator(String clientID, String clientSecret,String authUrl,String dataCenter, String version, String sessionId,String salesforcePartnerUrl) {
        this.clientId = clientID;
        this.clientSecret = clientSecret;
        this.authUrl = authUrl;
        this.dataCenter = dataCenter;
        this.version = version;
        this.sessionId = sessionId;
        this.salesforcePartnerUrl = salesforcePartnerUrl;
    }

    global CMSalesforceUserAuthenticator(String clientID, String clientSecret,String authUrl,String dataCenter, String version, String sessionId) {
        this.clientId = clientID;
        this.clientSecret = clientSecret;
        this.authUrl = authUrl;
        this.dataCenter = dataCenter;
        this.version = version;
        this.sessionId = sessionId;
        this.salesforcePartnerUrl = URL.getOrgDomainURL().toExternalForm() + CMSalesforceUserAuthenticator.SOAP_API_PATH + UserInfo.getOrganizationId();
    }

    global CMSalesforceUserAuthenticator(String clientID, String clientSecret,String authUrl,String dataCenter, String version) {
        this.clientId = clientID;
        this.clientSecret = clientSecret;
        this.authUrl = authUrl;
        this.dataCenter = dataCenter;
        this.version = version;
        this.sessionId = UserInfo.getSessionId();
        this.salesforcePartnerUrl = URL.getOrgDomainURL().toExternalForm() + CMSalesforceUserAuthenticator.SOAP_API_PATH + UserInfo.getOrganizationId();
    }

    global CMSalesforceUserAuthenticator(String clientID, String clientSecret,String authUrl,String dataCenter) {
        this.clientId = clientID;
        this.clientSecret = clientSecret;
        this.authUrl = authUrl;
        this.dataCenter = dataCenter;
        this.version = 'v201606';
        this.sessionId = UserInfo.getSessionId();
        this.salesforcePartnerUrl = URL.getOrgDomainURL().toExternalForm() + CMSalesforceUserAuthenticator.SOAP_API_PATH + UserInfo.getOrganizationId();
    }

    private String clientId;
    private String clientSecret;
    private String authUrl;
    private String dataCenter;
    private String version;
    private String sessionId;
    private String salesforcePartnerUrl;
    private Datetime lastTokenRequest;
    private CLMTokenRequest tokenRequest;
    private String objectAPIURL;
    private String uploadAPIURL;
    private String downloadAPIURL;

    global String getObjectAPIUrl() {
        objectAPIURL = 'https://api' + dataCenter +'.springcm.com/'+ version;
        return objectAPIURL;
    }

    global String getUploadAPIUrl() {
        uploadAPIURL = 'https://apiupload' + dataCenter +'.springcm.com/'+ version;
        return uploadAPIURL;
    }

    global String getDownloadAPIUrl() {
        downloadAPIURL = 'https://apidownload' + dataCenter +'.springcm.com/'+ version;
        return downloadAPIURL;
    }

    global String accessToken() {
        if (tokenRequest ==null || Datetime.now() > TokenExpiration()) {
            GetNewToken();
        }
        return tokenRequest.Access_Token;
    }

    global DateTime tokenExpiration() {
        return LastTokenRequest.addSeconds(Integer.valueOf(tokenRequest.Expires_In));
    }

    global void getNewToken() {
        SpringCMHTTPRequestor req = new SpringCMHTTPRequestor(null);
        String body = '{ "session_id":"'+ this.sessionId + '", "api_url":"'+ this.salesforcePartnerUrl + '", "client_id": "' +clientId +'","client_secret": "'+clientSecret+ '"}';
        String resp = req.Post(authUrl, body, new Map<String,String>());
        this.tokenRequest = (CLMTokenRequest)JSON.deserialize(resp, CLMTokenRequest.class);
        this.lastTokenRequest = Datetime.now();
    }

}
//