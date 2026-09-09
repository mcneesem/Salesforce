public with sharing class WingspanRestAgent {
    // test w/ WingspanCreateUserActionTest (89%)

    //method to send http requests
    public HttpResponse sendRequest(
        String method ,
        String path ,
        String body ,
        Id recordId ,
        String platform
        )
    {
        String logDescription = '';
        String url = '';
        String currentHeaders = '';
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        try {
            if ( !String.isEmpty( body ) ) {
                req.setBody( body );
            }
            if ( String.isNotBlank( path ) ) {
                url = this.buildUrl( path , platform , method );
                req.setEndpoint( url );
            }
            if ( String.isNotBlank( method ) ) {
                req.setMethod( method );
            }
            Map<String,String> headers = new Map<String,String>{
                'Authorization' => 'Bearer ' + this.buildAuthKey( platform , method )
            };
            if ( method == 'POST' ) {
                headers.put( 'Accept' , 'application/json' );
                headers.put( 'Content-Type' , 'application/json' );
                headers.put( 'X-WINGSPAN-USER' , this.buildWingspanUserId( platform ) );
            }
            if ( headers != null ) {
                currentHeaders = JSON.serialize( headers );
                for ( String key : headers.keyset() ) {
                    req.setHeader( key , headers.get( key ) );
                }
            }
            req.setTimeout( WingspanRestAgent.timeout );
            res = http.send( req );
            logDescription = 'No Error during callout.';
        } catch( Exception e ) {
            //extract error message
            logDescription = e.getMessage();
        } finally {
            //log results
            this.buildLog( logDescription , currentHeaders , req , res , recordId );
        }
        return res;
    }

    //method for creating Log Record
    private void buildLog(
        String description ,
        String requestHeaders ,
        HttpRequest request ,
        HttpResponse response ,
        Id recordId
        )
    {
        log.Class__c = SchemaController.safeText(
            WingspanRestAgent.class.getName() ,
            sObjectType.Wingspan_Log__c.Fields.Class__c
        );
        //record id and sobjectype
        if ( String.isNotBlank( recordId ) ) {
            log.Record_Id__c = SchemaController.safeText(
                recordId ,
                sObjectType.Wingspan_Log__c.Fields.Record_Id__c
            );
            log.Object__c = SchemaController.safeText(
                String.valueOf( recordId.getSObjectType() ) ,
                sObjectType.Wingspan_Log__c.Fields.Object__c
            );
        }
        //request headers
        if ( String.isNotBlank( requestHeaders) ) {
            log.Request_Headers__c = SchemaController.safeText(
                requestHeaders.replace( 
                    WingspanRestAgent.privateKey , 
                    'XXX_PRIVATE_KEY_REMOVED_XXX' 
                ).replace( 
                    WingspanRestAgent.ssoPrivateKey , 
                    'XXX_SSO_PRIVATE_KEY_REMOVED_XXX' 
                ) ,
                sObjectType.Wingspan_Log__c.Fields.Request_Headers__c
            );
        }
        if ( request != null && response != null ) {
            //populate description and method
            String requestBody = request.getBody();
            String requestMethod = request.getMethod();
            String logDescription = '';
            String logMethod = 'sendRequest';
            if ( requestMethod == 'GET' ) {
                logDescription = 'GET request for validating contact in wingspan server';
                logMethod += '-getUserByEmail';
            } else if ( requestMethod == 'POST' ) {
                if ( requestBody.contains( 'email' ) ) {
                    logDescription = 'POST request for creating non-SSO Admin in wingspan server';
                    logMethod += '-postClientAdmin';
                } else if ( requestBody.contains( 'payerEmail' ) ) {
                    logDescription = 'POST request for creating SSO Admin in wingspan server';
                    logMethod += '-postClientAdmin(SSO)';
                } else if ( requestBody.contains( 'parentUserId' ) ) {
                    logDescription = 'POST request for associating Admin in wingspan server';
                    logMethod += '-postLinkAdmin';
                }
            }
            log.Description__c = SchemaController.safeText(
                logDescription + '--' + description ,
                sObjectType.Wingspan_Log__c.Fields.Description__c
            );
            log.Method__c = SchemaController.safeText(
                logMethod ,
                sObjectType.Wingspan_Log__c.Fields.Method__c
            );
            //endpoint
            if ( String.isNotBlank( request.getEndpoint() ) ) {
                log.Endpoint__c = SchemaController.safeText(
                    request.getEndpoint() ,
                    sObjectType.Wingspan_Log__c.Fields.Endpoint__c
                );
            }
            //request body
            log.Request_Body__c = SchemaController.safeText(
                request.getBody() ,
                sObjectType.Wingspan_Log__c.Fields.Request_Body__c
            );
            //response headers
            log.Response_Headers__c = SchemaController.safeText(
                this.getResponseHeaders( response ) ,
                sObjectType.Wingspan_Log__c.Fields.Response_Headers__c
            );
            //response body
            log.Response_Body__c = SchemaController.safeText(
                response.getBody() ,
                sObjectType.Wingspan_Log__c.Fields.Response_Body__c
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
    }

    public Wingspan_Log__c log {
        public get {
            if ( log == null ) {
                log = new Wingspan_Log__c();
            }
            return log;
        }
        private set;
    }

    private String buildWingspanUserId( String platform ) {
        String wingspanUserId = WingspanRestAgent.xWingspanUserId;
        if ( platform == WingspanRestService.HR360 && String.isNotBlank( WingspanRestAgent.hr360ParentUserId ) ) {
            wingspanUserId = WingspanRestAgent.hr360ParentUserId;
        } else if ( platform == WingspanRestService.HRSCALE && String.isNotBlank( WingspanRestAgent.hrScaleParentUserId ) ) {
            wingspanUserId = WingspanRestAgent.hrScaleParentUserId;
        }
        return wingspanUserId;
    }

    //method to get headers from response
    private String getResponseHeaders( HttpResponse response ) {
        Map<String,String> responseHeaders = new Map<String,String>();
        if ( ( response != null ) && !response.getHeaderKeys().isEmpty() ) {
            for ( String key : response.getHeaderKeys() ) {
                if ( response.getHeader( key ) != null ) {
                    responseHeaders.put( key , response.getHeader( key ) );
                }
            }
        }
        return JSON.serialize( responseHeaders );
    }

    //method to construct URL endpoint
    private String buildUrl( String path , String platform , String method ){
        String url = WingspanRestAgent.baseUrl;
        if( method == 'GET' || platform == WingspanRestService.NON_SSO || String.isBlank( platform ) ) {
            url = url + path;
        }
        if( String.isNotBlank( path ) && String.isNotBlank( platform ) && Method != 'GET') {
            if ( platform == WingspanRestService.HR360 && String.isNotBlank( WingspanRestAgent.hr360ParentUserId ) ) {
                url = url + path.replace( '{userId}' , WingspanRestAgent.hr360ParentUserId );
            } else if ( platform == WingspanRestService.HRSCALE && String.isNotBlank( WingspanRestAgent.hrScaleParentUserId ) ) {
                url = url + path.replace( '{userId}' , WingspanRestAgent.hrScaleParentUserId );
            }
        }
        return url;
    }

    //method to build authentication key
    private String buildAuthKey(String platform, String method){
        String authKey = WingspanRestAgent.privateKey;
        if( ( String.isNotBlank( platform ) )
           && method != 'GET'
           && ( ( platform == WingspanRestService.HR360 )
               || ( platform == WingspanRestService.HRSCALE )
              )
           && ( String.isNotBlank( WingspanRestAgent.ssoPrivateKey ) )
          )
        {
            authKey = WingspanRestAgent.ssoPrivateKey;
        }

        return authKey;
    }

    //
    // attributes controlled by Custom Settings...
    //

    private static Wingspan_Settings__c settings {
        private get{
            if ( settings == null ) {
                List<Wingspan_Settings__c> all = [
                    SELECT
                        Id ,
                        Name ,
                        IsEnabled__c ,
                        BaseUrl__c ,
                        ParentUserId__c ,
                        PrivateKey__c ,
                        Timeout__c ,
                        XWingspanUserId__c ,
                        SsoPrivateKey__c ,
                        HR360ParentUserId__c ,
                        HRScaleParentUserId__c ,
                        RestrictedCharacters__c ,
                        RestrictedProducts__c,
                        Complete_Addons__c
                    FROM Wingspan_Settings__c
                    WHERE ( IsEnabled__c = true )
                    LIMIT 1
                ];
                Wingspan_Settings__c local = null;
                if ( ( all != null ) && !all.isEmpty() ) {
                    local = all[0];
                }
                settings = local;
            }
            return settings;
        }
        private set;
    }

    private static String baseUrl {
        private get{
            if ( baseURL == null ) {
                String local = 'XXX_BASE_URL_XXX';
                if ( ( WingspanRestAgent.settings != null )
                    && String.isNotBlank( WingspanRestAgent.settings.BaseUrl__c )
                   )
                {
                    local = WingspanRestAgent.settings.BaseUrl__c;
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
                if ( ( WingspanRestAgent.settings != null )
                    && String.isNotBlank( WingspanRestAgent.settings.PrivateKey__c )
                   )
                {
                    local = WingspanRestAgent.settings.PrivateKey__c;
                }
                privateKey = local;
            }
            return privateKey;
        }
        private set;
    }

    private static String ssoPrivateKey {
        private get {
            if ( ( ssoPrivateKey == null )
                && ( WingspanRestAgent.settings != null )
                && String.isNotBlank( WingspanRestAgent.settings.SsoPrivateKey__c )
               )
            {
                ssoPrivateKey = WingspanRestAgent.settings.SsoPrivateKey__c;
            }
            return ssoPrivateKey;
        }
        private set;
    }

    private static String xWingspanUserId {
        private get {
            if ( ( xWingspanUserId == null )
                && ( WingspanRestAgent.settings != null )
                && String.isNotBlank( WingspanRestAgent.settings.XWingspanUserId__c )
               )
            {
                xWingspanUserId = WingspanRestAgent.settings.XWingspanUserId__c;
            }
            return xWingspanUserId;
        }
        private set;
    }

    public static String parentUserId {
        public get {
            if ( ( parentUserId == null )
                && ( WingspanRestAgent.settings != null )
                && String.isNotBlank( WingspanRestAgent.settings.ParentUserId__c )
               )
            {
                parentUserId = WingspanRestAgent.settings.ParentUserId__c;
            }
            return parentUserId;
        }
        private set;
    }

    public static String hr360ParentUserId {
        public get {
            if ( ( hr360ParentUserId == null )
                && ( WingspanRestAgent.settings != null )
                && String.isNotBlank( WingspanRestAgent.settings.HR360ParentUserId__c )
               )
            {
                hr360ParentUserId = WingspanRestAgent.settings.HR360ParentUserId__c;
            }
            return hr360ParentUserId;
        }
        private set;
    }

    public static String hrScaleParentUserId {
        public get {
            if ( ( hrScaleParentUserId == null )
                && ( WingspanRestAgent.settings != null )
                && String.isNotBlank( WingspanRestAgent.settings.HRScaleParentUserId__c )
               )
            {
                hrScaleParentUserId = WingspanRestAgent.settings.HRScaleParentUserId__c;
            }
            return hrScaleParentUserId;
        }
        private set;
    }

    public static List<String> restrictedCharacters {
        public get {
            if ( restrictedCharacters == null ) {
                List<String> local = new List<String>();
                if ( WingspanRestAgent.settings != null ) {
                    String rawRestrictedCharacters = WingspanRestAgent.settings.RestrictedCharacters__c;
                    if ( String.isNotBlank( rawRestrictedCharacters ) ) {
                        List<String> splitRestrictedCharacters = rawRestrictedCharacters.split( ',' );
                        if ( ( splitRestrictedCharacters != null ) && ( splitRestrictedCharacters.size() > 0 ) ) {
                            local = splitRestrictedCharacters;
                        }
                    }
                }
                restrictedCharacters = local;
            }
            return restrictedCharacters;
        }
        private set;
    }

    public static List<String> completeAddons {
    public get {
        if ( completeAddons == null ) {
            List<String> local = new List<String>();
            if ( WingspanRestAgent.settings != null ) {
                String rawCompleteAddons = WingspanRestAgent.settings.Complete_Addons__c;
                if ( String.isNotBlank( rawCompleteAddons ) ) {
                    List<String> splitCompleteAddons = rawCompleteAddons.split( '\\s*,\\s*' );
                    if ( ( splitCompleteAddons != null ) && ( splitCompleteAddons.size() > 0 ) ) {
                        local = splitCompleteAddons;
                    }
                }
            }
            completeAddons = local;
        }
        return completeAddons;
    }
        private set;
   }

    public static List<String> restrictedProducts {
        public get {
            if ( restrictedProducts == null ) {
                List<String> local = new List<String>();
                if ( WingspanRestAgent.settings != null ) {
                    String rawRestrictedProducts = WingspanRestAgent.settings.RestrictedProducts__c;
                    if ( String.isNotBlank( rawRestrictedProducts ) ) {
                        List<String> splitRestrictedProducts = rawRestrictedProducts.split( ',' );
                        if ( ( splitRestrictedProducts != null ) && ( splitRestrictedProducts.size() > 0 ) ) {
                            local = splitRestrictedProducts;
                        }
                    }
                }
                restrictedProducts = local;
            }
            return restrictedProducts;
        }
        private set;
    }

    private static Integer timeout {
        private get {
            if ( timeout == null ) {
                Integer local = 120000;
                if ( ( WingspanRestAgent.settings != null )
                    && ( WingspanRestAgent.settings.Timeout__c != null )
                   )
                {
                    local = WingspanRestAgent.settings.Timeout__c.intValue();
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
//