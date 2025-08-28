public with sharing class WingspanRestUtility {
    // test w/ WingspanCreateUserActionTest (95%)

    private static List<Wingspan_Log__c> pendingLogs = new List<Wingspan_Log__c>();
    private static String currentHeaders = '';

    //construct GET Request to validate contact in wingspan Server
    public static Boolean getUserByEmail(Id contactId, Id recordId, Boolean isCheckOnly){
        Contact con = getContact(contactId);
        Boolean userFound = true;
        String method = 'GET';

        if( ( con != null ) 
           && ( !String.isBlank( con.Email ) )
           && ( !String.isBlank( recordId ) )
          ){
            //create endpoint URL
            String path = '/users/user/email/' + con.Email;
            //send API request
            HttpResponse resp = sendRequest(method,path,'', recordId);
            if( resp.getStatus() == 'Not Found' && resp.getStatusCode() == 404){
                //user not found -> can create new
                userFound = false;
            }
        }
        //insert only get api log
        if( isCheckOnly ){
            insertLogs();
        }
        return userFound;
    }
    
    //method to create contact as Admin in wingspan server
    public static String createClientAdmin(Id contactId, Id recordId){
        String createdUserId ='';
        String body = JSON.Serialize( getUserWrapper( contactId, recordId ) );
        String method = 'POST';
        
        //construct request
        if( !String.isBlank( recordId ) ){
            //create endpoint URL
            String path = '/users/organization/user';
            
            //call API
            HttpResponse resp = sendRequest(method,path,body, recordId);
            
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
        
        if( !String.isBlank( recordId ) ){
            String path = '/users/organization/user/'+ createdUserId + '/associate';
            
            //send API request        
            sendRequest(method,path,body, recordId);
        }
        //insert all api logs
        insertLogs();
    }
    
    //method to fetch Contact record
    private static Contact getContact(Id contactId){
        Contact cc = null;
        if( contactId != null){
            List<Contact> ccList = [SELECT id, Email, FirstName, LastName FROM Contact WHERE Id = :contactId];
            if( !ccList.isEmpty() ){
                cc = ccList[0];
            }
        }
        return cc;
    }
    
    //method to send http requests
    private static HttpResponse sendRequest(
        String method, 
        String path, 
        String body,        
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
            
            if ( !String.isBlank( path ) ) {
                url = WingspanRestUtility.baseUrl + path;
                req.setEndpoint( url );
            }
            
            if( !String.isBlank(method) ){
                req.setMethod(method);
            }
            
            Map<String,String> headers = new Map<String,String>{
                'Authorization' => 'Bearer ' + WingspanRestUtility.privateKey
            };
            if (  !String.isBlank(method) && method == 'POST' ) {
                headers.put( 'Accept' , 'application/json' );
                headers.put( 'Content-Type' , 'application/json' );
            }
            if( headers != null ){
                currentHeaders = JSON.serialize( headers );
                for(String key: headers.keyset()){
                    req.setHeader(key,headers.get(key));
                }
            }
            
            req.setTimeout( WingspanRestUtility.timeout );
            
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
        log.Class__c = SchemaController.safeText(
            WingspanRestUtility.class.getName() ,
            sObjectType.Wingspan_Log__c.Fields.Class__c
        );
        
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
            log.Method__c = SchemaController.safeText(
                logMethod ,
                sObjectType.Wingspan_Log__c.Fields.Method__c
            );
            
            log.Description__c = SchemaController.safeText(
                logDescription + '--' + description ,
                sObjectType.Wingspan_Log__c.Fields.Description__c
            );
            
            //request headers
            log.Request_Headers__c = SchemaController.safeText(
                currentHeaders ,
                sObjectType.Wingspan_Log__c.Fields.Request_Headers__c
            );
            
            //request and response body
            log.Request_Body__c = SchemaController.safeText(
                req.getBody() ,
                sObjectType.Wingspan_Log__c.Fields.Request_Body__c
            );
            
            log.Response_Body__c = SchemaController.safeText(
                response.getBody() ,
                sObjectType.Wingspan_Log__c.Fields.Response_Body__c
            );
            
            //populate endpoint url
            if( !String.isBlank( req.getEndpoint() ) ){
                log.Endpoint_URL__c = SchemaController.safeText(
                    req.getEndpoint() ,
                    sObjectType.Wingspan_Log__c.Fields.Endpoint_URL__c
                );
            }
            
            //object name and record id
            if( !String.isBlank(recordId) ){
                log.Object__c = SchemaController.safeText(
                    String.valueOf( recordId.getSObjectType() ) ,
                    sObjectType.Wingspan_Log__c.Fields.Object__c
                );
                
                log.Record_Id__c = SchemaController.safeText(
                    recordId ,
                    sObjectType.Wingspan_Log__c.Fields.Record_Id__c
                );
            }
            
            //response headers
            log.Response_Headers__c = SchemaController.safeText(
                WingspanRestUtility.getResponseHeaders( response ) ,
                sObjectType.Wingspan_Log__c.Fields.Response_Headers__c
            );
            
            //response status and code
            log.Response_Status__c = SchemaController.safeText(
                response.getStatus() ,
                sObjectType.Wingspan_Log__c.Fields.Response_Status__c
            );
            
            log.Response_Code__c = SchemaController.safeInteger(
                response.getStatusCode() ,
                sObjectType.Wingspan_Log__c.Fields.Response_Code__c
            );
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
    
    //DML called after all HTTP requests
    private static void insertLogs(){
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
        List<Asset> assets = null;
        if( ( !String.isBlank( recordId ) ) 
           && ( String.valueOf(recordId.getSObjectType()) == 'Asset' ) 
          ){
              //fetch record fields
              assets = [SELECT 
                       AccountId,
                       Asset_Number__c,
                       Opportunity__r.NSP_Number_of_Employees__c,
                       NSP_AccountName__c
                       FROM Asset
                       WHERE id = :recordId 
                       LIMIT 1];
          }
        //assign fields
        Asset record = null;
        if ( !assets.isEmpty() ) {
            record = assets[0];
        }
        if ( record  != null ) {
            if ( String.isNotBlank( record.AccountId ) ) {
                labelsWrap.insperityAccountId = record.AccountId;    
            }
            if ( String.isNotBlank( assets[0].Asset_Number__c ) ) {
                labelsWrap.saasId = record.Asset_Number__c;
            }
            if ( record.Opportunity__r.NSP_Number_of_Employees__c != null ) {
                labelsWrap.employeesEstimate = String.valueOf( record.Opportunity__r.NSP_Number_of_Employees__c );
            }
            if ( String.isNotBlank( record.NSP_AccountName__c ) ) {
                labelsWrap.accountName = record.NSP_AccountName__c;   
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
            if ( activeSetting == null ) {
                List<Wingspan_Settings__c> all = [
                    SELECT Id , Name , IsEnabled__c , BaseUrl__c , PrivateKey__c , UserId__c , Timeout__c
                    FROM Wingspan_Settings__c
                    WHERE ( IsEnabled__c = true )
                    LIMIT 1
                ];
                Wingspan_Settings__c local = null;
                if ( ( all != null ) && !all.isEmpty() ) {
                    local = all[0];
                }
                activeSetting = local;
            }
            return activeSetting;
        } 
        private set;
    }
    
    private static String baseUrl { 
        private get{
            if ( baseURL == null ) {
                String local = 'XXX_BASE_URL_XXX';
                if ( ( WingspanRestUtility.activeSetting != null )
                    && String.isNotBlank( WingspanRestUtility.activeSetting.BaseUrl__c )
                   )
                {
                    local = WingspanRestUtility.activeSetting.BaseUrl__c;
                }
                baseURL = local;
            }
            return baseURL;
        } private set; 
    }
    
    private static String privateKey { 
        private get{
            if ( privateKey == null ) {
                String local = 'XXX_PRIVATE_KEY_XXX';
                if ( ( WingspanRestUtility.activeSetting != null )
                    && String.isNotBlank( WingspanRestUtility.activeSetting.PrivateKey__c )
                   )
                {
                    local = WingspanRestUtility.activeSetting.PrivateKey__c;
                }
                privateKey = local;
            }
            return privateKey;
        } 
        private set; 
    }
    
    private static String userId { 
        private get{
            if ( ( userId == null )
                && ( WingspanRestUtility.activeSetting != null )
                && String.isNotBlank( WingspanRestUtility.activeSetting.UserId__c )
                )
            {
                userId = WingspanRestUtility.activeSetting.UserId__c;
            }
            return userId;
        }
        private set; 
    }
    
    private static Integer timeout {
        private get {
            if ( timeout == null ) {
                Integer local = 120000;
                if ( ( WingspanRestUtility.activeSetting != null )
                    && ( WingspanRestUtility.activeSetting.Timeout__c != null )
                   )
                {
                    local = WingspanRestUtility.activeSetting.Timeout__c.intValue();
                }
                // timeout must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // timeout must be less than or equal to 120000...
                if ( local > 120000 ) {
                    local = 120000;
                }
                timeout = local;
            }
            return timeout;
        }
        private set;
    }
}