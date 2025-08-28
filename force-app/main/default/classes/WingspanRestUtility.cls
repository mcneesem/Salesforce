public with sharing class WingspanRestUtility {
    // test w/ WingspanCreateUserActionTest (93%)

    private static List<Wingspan_Log__c> pendingLogs = new List<Wingspan_Log__c>();
    private static String currentHeaders = '';
    
    //method to send http requests
    public static HttpResponse sendRequest(
        String method, 
        String path, 
        String body,        
        Id recordId
    ){
        String logDescription = '';
        String url = '';
        currentHeaders = '';
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
                log.Endpoint__c = SchemaController.safeText(
                    req.getEndpoint() ,
                    sObjectType.Wingspan_Log__c.Fields.Endpoint__c
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
    
    public static String userId { 
        public get{
            if ( ( userId == null )
                && ( WingspanRestUtility.activeSetting != null )
                && String.isNotBlank( WingspanRestUtility.activeSetting.UserId__c )
                )
            {
                userId = WingspanRestUtility.activeSetting.UserId__c;
            }
            return userId;
        }
        public set; 
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