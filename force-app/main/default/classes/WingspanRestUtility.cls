public with sharing class WingspanRestUtility {
    // test w/ WingspanRestUtilityHelperTest (95%)

    private static final String className = WingspanRestUtility.class.getName();
    private static List<Wingspan_Log__c> pendingLogs = new List<Wingspan_Log__c>();
    private static final String appJson = 'application/json';
    private static final String bearer = 'Bearer ';
    
    //construct GET Request to validate contact in wingspan Server
    public static Boolean getUserByEmail(Id contactId, Id recordId){
        Contact con = getContact(contactId);
        Boolean userFound = true;
        String method = 'GET';

        if( ( activeSetting != null ) 
           && ( !String.isBlank( WingspanRestUtility.baseUrl ) ) 
           && ( !String.isBlank( WingspanRestUtility.privateKey ) ) 
           && ( con != null ) 
           && ( !String.isBlank( con.Email ) )
           && ( !String.isBlank( recordId ) )
          ){
            //create endpoint URL
            String endpoint = WingspanRestUtility.baseUrl + '/users/user/email/' + con.Email;
            //create header
            Map<String,String> headers = new Map<String,String>{
                'Authorization' => bearer + WingspanRestUtility.privateKey
            };
			
            //send API request        
            HttpResponse resp = sendRequest(method,endpoint,'',headers, recordId);
            
            if( resp.getStatus() == 'Not Found' && resp.getStatusCode() == 404){
                //user not found -> can create new
                userFound = false;
            }
        }
        return userFound;
    }
    
    //method to create contact as Admin in wingspan server
    public static String createClientAdmin(Id contactId, Id recordId){
        String createdUserId ='';
        String body = JSON.Serialize( getUserWrapper( contactId, recordId ) );
        String method = 'POST';
        
        //construct request
        if( ( activeSetting != null ) 
           && ( !String.isBlank( WingspanRestUtility.baseUrl ) ) 
           && ( !String.isBlank( WingspanRestUtility.privateKey ) ) 
           && ( !String.isBlank( recordId ) )
          ){
              //create endpoint URL
              String endpoint = WingspanRestUtility.baseUrl + '/users/organization/user';
              
              //create header for Admin Creation POST request
              Map<String,String> headers = new Map<String,String>{
                  'Authorization' => bearer + WingspanRestUtility.privateKey, 
                  'Accept' => appJson,
                  'Content-Type' => appJson
              };
              
              //call API
              HttpResponse resp = sendRequest(method,endpoint,body,headers, recordId);
              
              if( resp.getStatusCode() == 200 ){
                  //construct success
                  Map<String,Object> structuredResponse = ( Map<String,Object> )JSON.deserializeUntyped( resp.getBody() );
                  createdUserId = ( String )structuredResponse.get( 'userId' );
              }
		}
        return createdUserId;
    }
    
    private static CreateUserWrapper getUserWrapper(Id contactId, Id recordId){
        //fetch contact details
        Contact con = getContact( contactId );
        
        //initialize user wrapper
        CreateUserWrapper userWrap = new CreateUserWrapper();
        
        if( con != null ){
            //get email
            if( !String.isBlank(con.Email) ){
                userWrap.email = con.Email;    
            }
            
            //create profile wrapper
            ProfileWrapper profileWrap = new ProfileWrapper();
            if( !String.isBlank(con.FirstName) ){
                profileWrap.firstName = con.FirstName;    
            }
            
            if( !String.isBlank(con.FirstName) ){
                profileWrap.lastName = con.LastName;
            }
            userWrap.profile = profileWrap;
        }
        
        //create labels wrapper
        userWrap.labels = createLabels( recordId );
        
        //create settings wrapper
        Settings settWrap = new Settings();
        settWrap.userAccountType = 'enterprise';
        userWrap.settings = settWrap;
        
        return userWrap;
    }
    
    public static void linkAdminToCHUB(String createdUserId, Id recordId){
        LinkUserToHubWrapper linkWrap = new LinkUserToHubWrapper();
        if ( !String.isBlank( WingspanRestUtility.userId )){
            linkWrap.parentUserId = WingspanRestUtility.userId;
        }
        InheritanceStrategyWrapper inheritanceWrap = new InheritanceStrategyWrapper();
        inheritanceWrap.organizationAccountConfig = 'Parent';
        linkWrap.inheritanceStrategy = inheritanceWrap;
        
        String body = JSON.Serialize( linkWrap );
        String method = 'POST';
        
        if( ( activeSetting != null ) 
           && ( !String.isBlank( WingspanRestUtility.baseUrl ) ) 
           && ( !String.isBlank( WingspanRestUtility.privateKey ) ) 
           && ( !String.isBlank( recordId ) )
          ){
              String endpoint = baseUrl + '/users/organization/user/'+ createdUserId + '/associate';
              Map<String,String> headers = new Map<String,String>{
                  'Authorization' => bearer + WingspanRestUtility.privateKey, 
                  'Accept' => appJson,
                  'Content-Type' => appJson
              };
              
              //send API request        
        	  sendRequest(method,endpoint,body,headers, recordId);
          }
    }
    
    //method to fetch Contact record
    private static Contact getContact(Id contactId){
        Contact cc = null;
        if( contactId != null){
            cc = [SELECT id, Email, FirstName, LastName FROM Contact WHERE Id = :contactId];
        }
        return cc;
    }
    
    //method to send http requests
    private static HttpResponse sendRequest(
        String method, 
        String endpoint, 
        String body, 
        Map<String,String> headers,
        Id recordId
    ){
        String logDescription = '';
        String url = '';
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        try{
            if( !String.isEmpty(body)){
                req.setBody(body);
            }
            
            if(!String.isBlank(endpoint)){
                req.setEndpoint(endpoint);
                url = endpoint;
            }
            
            if( !String.isBlank(method) ){
                req.setMethod(method);
            }
            
            if( headers != null ){
                for(String key: headers.keyset()){
                    req.setHeader(key,headers.get(key));
                }
            }
            
            req.setTimeout(120000);
            
            res = http.send(req);
            logDescription = 'No Error during callout.';
            
        }catch(exception e){
            //extract error message
            logDescription = e.getMessage();
        }finally{
            //log results
            insertLogToList(logDescription,req,res,recordId);
        }
        return res;
    }
    
    //log insertion methods...
    
    //method for creating Log Record
    private static void insertLogToList(
        String description,
        HttpRequest req,
        HttpResponse response,
        Id recordId) 
    {
        String logDescription = '';
        String logMethod = 'sendRequest';
        
        Wingspan_Log__c log = new Wingspan_Log__c();
        log.Class__c = className;
        
        if ( req != null && response != null ){
            String requestBody = req.getBody();
            String requestMethod = req.getMethod();   
            
            //populate description and method
            if( requestMethod == 'GET' ){
                logDescription = 'GET request for validating contact in wingspan server';
                logMethod += '-getUserByEmail';
            }else if( requestBody.contains('email') && requestMethod == 'POST' ){
                logDescription = 'POST request for creating Admin in wingspan server';
                logMethod += '-createClientAdmin';
            }else if( requestBody.contains('parentUserId') && requestMethod == 'POST' ){
                logDescription = 'POST request for associating Admin in wingspan server';
                logMethod += '-linkAdminToCHUB';
            }
            log.Method__c = logMethod;
            log.Description__c = logDescription + '--' + description;
            
            //request and response body
            log.Request_Body__c = requestBody;
            log.Response_Body__c = response.getBody();
            
            //populate endpoint url
            if( !String.isBlank( req.getEndpoint() ) ){
                log.Endpoint_URL__c = req.getEndpoint();    
            }
            
            //object name and record id
            if( !String.isBlank(recordId) ){
                log.Object__c = String.valueOf(recordId.getSObjectType());
                log.Record_Id__c = recordId;
            }
            
            //response headers
            log.Response_Headers__c = getResponseHeaders( response );
            
            //response status and code
            log.Response_Status__c = getResponseStatus( response );
            log.Response_Code__c = response.getStatusCode();
        }
        
        pendingLogs.add(log);
    }
    
    //method to get headers from response
    private static String getResponseHeaders( HttpResponse response ){
        Map<String,String> responseHeaders = new Map<String,String>();
        if( !response.getHeaderKeys().isEmpty() ){
            for( String key: response.getHeaderKeys() ){
                if( response.getHeader( key ) != null ){
                    responseHeaders.put( key, response.getHeader( key ) );
                }
            }
        }
         return JSON.serialize( responseHeaders );
    }
    
    //method to get response Status
    private static String getResponseStatus( HttpResponse response ){
        String status = '';
        if( response != null ){
            String responseStatus = response.getStatus();
            if( responseStatus.length() > 255 ){
                status = responseStatus.subString( 0, 255 );
            }else{
                status = responseStatus;
            }
        }
        return status;
    }
    
    //DML called after all HTTP requests
    public static void insertLogs(){
        if( !pendingLogs.isEmpty() ){
            try{
            	insert pendingLogs;    
            }catch (exception e){
                NSP_ErrorLogHandler.logException(
                    WingspanRestUtility.class.getName() ,
                    'insertLogs' ,
                    e
                );
            }finally{
                pendingLogs.clear();
            }
        }
    }
    
    //wrapper classes for JSON body...
    
    //wrapper class
    private class CreateUserWrapper{
        private String email = '';
        private ProfileWrapper profile;
        private Settings settings;
        private Labels labels;
    }
    
    private class ProfileWrapper{
        private String firstName = '';
        private String lastName = '';
    }
    
    private class Settings{
        private String userAccountType = '';
    }
    
    private class Labels{
        private String insperityAccountId = '';
        private String saasId = '';
        private String employeesEstimate = '';
        private String accountName = '';
    }
    
    //method to create labels for JSON
    private static Labels createLabels( Id recordId ){
        Labels labelsWrap = new Labels();
        Asset asset = null;
        if( ( !String.isBlank( recordId ) ) 
           && ( String.valueOf(recordId.getSObjectType()) == 'Asset' ) 
          ){
              //fetch record fields
              asset = [SELECT 
                       AccountId,
                       Asset_Number__c,
                       Opportunity__r.NSP_Number_of_Employees__c,
                       NSP_AccountName__c
                       FROM Asset
                       WHERE id = :recordId 
                       LIMIT 1];
          }
        //assign fields
        if( asset != null ){
            if( !String.isBlank( asset.AccountId ) ){
                labelsWrap.insperityAccountId = asset.AccountId;    
            }
            if( !String.isBlank( asset.Asset_Number__c ) ){
                labelsWrap.saasId = asset.Asset_Number__c;
            }
            if( asset.Opportunity__r.NSP_Number_of_Employees__c != null ){
                labelsWrap.employeesEstimate = String.valueOf( asset.Opportunity__r.NSP_Number_of_Employees__c );
            }
            if( !String.isBlank( asset.NSP_AccountName__c )){
                labelsWrap.accountName = asset.NSP_AccountName__c;   
            }
        }
        return labelsWrap;
    }
    
    private class LinkUserToHubWrapper{
        private String parentUserId = '';
        private InheritanceStrategyWrapper inheritanceStrategy;
    }
    
    private class InheritanceStrategyWrapper{
        private String organizationAccountConfig = '';
    }
    
    // attributes controlled by Custom Settings...
	
    private static Wingspan_Settings__c activeSetting { 
        private get{
            if( activeSetting == null ){
                activeSetting = [SELECT
                                 BaseUrl__c,
                                 PrivateKey__c,
                                 UserId__c
                                 FROM Wingspan_Settings__c 
                                 WHERE IsEnabled__c = true 
                                 LIMIT 1];
            }
            return activeSetting;
        } 
        private set;
    }
    
    private static String baseURL { 
        private get{
            if( ( baseURL == null ) && ( WingspanRestUtility.activeSetting != null ) ){
                baseURL = WingspanRestUtility.activeSetting.BaseUrl__c;
            }
            return baseURL;
        } private set; 
    }
    
    private static String privateKey { 
        private get{
            if( ( privateKey == null ) && ( WingspanRestUtility.activeSetting != null ) ){
                privateKey = WingspanRestUtility.activeSetting.PrivateKey__c;
            }
            return privateKey;
        } 
        private set; 
    }
    
    private static String userId { 
        private get{
            if( ( userId == null ) && ( WingspanRestUtility.activeSetting != null ) ){
                userId = WingspanRestUtility.activeSetting.UserId__c;
            }
            return userId;
        }
        private set; 
    }
}