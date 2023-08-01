/* This class is responsible for initiating workflows by making REST Callouts to DocuSign CLM */
/* You can extend the searchForFolder method by invoking it from triggers / scheduled apex / batch jobs */
/* You can also create invocable actions by referencing the searchForFolder method and use it in Process Builders */
/* startInvoiceWorkflow method is used to start workflow in CLM */

public class NSP_DocuSignRESTUtility {
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
        String access_token = null;
        
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
        req.setHeader('Content-type', authRequestContentType);

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
                    access_token = parser.getText();
                    break;
                }
            }
        }

        return access_token;

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
        //Get the access token
        String accessToken = getAccessToken();

        //Call CLM API if a non-empty access token is returned
        if (!String.isEmpty(accessToken)) {
            
            for (String singleInvId : sfInvIds ) {
            //instantiate an Http instance  
            Http httpProtocol = new Http();

            //instantiate an HttpRequest instance  
            HttpRequest request = new HttpRequest();

            String endpoint = settingsMap.get('CLMv2ApiEndpoint').Value__c + settingsMap.get('DSAccountID').Value__c +'/workflows';
            request.setEndPoint(endpoint);

            //set the POST method
            request.setMethod('POST');

            //set Authentication Header
            request.setHeader('grant_type', 'Bearer');
            request.setHeader('Authorization', 'Bearer ' + accessToken);

            //set Accept Header
            request.setHeader('Accept', 'application/json');

            //set Content Type Header
            request.setHeader('Content-type', 'application/json');
			
            //set Empty Body - Check out https://developers.docusign.com/docs/clm-api/reference/Objects/Folders/Search/ for more details if required
            //{"name":"Test Inv","params": "<root><SFInvId>aBN8G000000KzANWA0</SFInvId></root>"}
            String workflowName = DocuSignRESTSettings__mdt.getInstance('NSP_Invoice_Workflow_Name').Value__c;
            String reqBody = '{"name":"'+workflowName+'","params": "<root><SFInvId>'+singleInvId+'</SFInvId></root>"}';
            request.setBody(reqBody);

            //Make the request and capture the response
            HttpResponse response = httpProtocol.send(request);
			
	    //Parse the response
        /*    String responseStatus = response.getStatus();
            if (responseStatus.equals('Created')) {
                NSP_DocuSignRESTUtility.workflowResponse responseObject = new NSP_DocuSignRESTUtility.workflowResponse();
                responseObject = (NSP_DocuSignRESTUtility.workflowResponse)System.JSON.deserialize(response.getBody(), NSP_DocuSignRESTUtility.workflowResponse.class);
                System.Debug(LoggingLevel.INFO, '***responseObject ' + responseObject);
            } */
        }
    }

    }
 
  /*   //wrapper class for Workflow API Response
    public class workflowResponse
    {
		public String Name;	//Test Inv
		public String StartDate;	//2023-02-15T17:44:25.623Z
		public String Status;	//Executing
		public String Info;	//
		public String Href;	//https://apiuatna11.springcm.com/v2/07bae8e0-f4aa-4b36-8886-efa661e3e9b0/workflows/69bb0461-58ad-ed11-b831-48df378a9c18
    }
	*/    
}