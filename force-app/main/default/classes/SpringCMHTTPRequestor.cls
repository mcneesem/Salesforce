public with sharing class SpringCMHTTPRequestor {
    // test w/ SpringCMTests (79%)

    private SpringCMIAuthenticator auth;
    private Integer automaticRetrys { get; set; }

    public SpringCMHTTPRequestor( SpringCMIAuthenticator authenticator ) {
        this.auth = authenticator;
        this.automaticRetrys = SpringCMHTTPRequestor.retries;
    }

    public String post( String url , String body , Map<String,String> headers ) {
        return this.makeCall( url , body , headers , 'POST' , null );
    }

    public String get( String url , Map<String,String> headers ) {
        return this.makeCall( url , null , headers , 'GET' , 0 );
    }

    public String deleteCall( String url , Map<String,String> headers ) {
        return this.makeCall( url , null , headers , 'DELETE' , 0 );
    }

    public String put( String url , String body , Map<String,String> headers ) {
        return this.makeCall( url , body , headers , 'PUT' , 0 );
    }

    public String patch( String url , String body , Map<String,String> headers ) {
        return this.makeCall( url , body , headers , 'PATCH' , 0 );
    }

    public String postBlob( String url , Blob body , Map<String,String> headers , Integer numberofTrys ) {
        if ( numberofTrys == null ) {
            numberofTrys = 0;
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint( url );
        req.setMethod( 'POST' );
        req.setBodyAsBlob( body );
        req = this.prepareHttpRequest( req , headers );
        HttpResponse response = null;
        try {
            response = h.send( req );
        } catch ( Exception ex ) {
            if ( numberofTrys < this.automaticRetrys ) {
                return this.postBlob( url , body , headers , ( numberofTrys + 1 ) );
            }
            response = this.handleHttpException( response , ex );
        }
        response = this.handleHttpResponse( response );
        String responseBody = null;
        if ( response != null ) {
            responseBody = response.getBody();
        }
        return responseBody;
    }

    public Blob getBlob( String url , Map<String,String> headers , Integer numberofTrys ) {
        if ( numberofTrys == null ) {
            numberofTrys = 0;
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint( url );
        req.setMethod( 'GET' );
        req.setHeader( 'Content-Type' , 'application/json' );
        req = this.prepareHttpRequest( req , headers );
        HttpResponse response = null;
        try {
            response = h.send( req );
        } catch ( Exception ex ) {
            if ( numberofTrys < this.automaticRetrys ) {
                return this.getBlob( url , headers , numberofTrys + 1 );
            }
            response = this.handleHttpException( response , ex );
        }
        response = this.handleHttpResponse( response );
        Blob responseBlob = null;
        if ( response != null ) {
            responseBlob = response.getBodyAsBlob();
        }
        return responseBlob;
    }

    private String makeCall( String url , String body , Map<String,String> headers , String method , Integer numberofTrys ) {
        if ( headers == null ) {
            headers = new Map<String,String>();
        }
        if ( numberofTrys == null ) {
            numberofTrys = 0;
        }
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint( url );
        req.setMethod( method );
        if ( body != null ) {
            req.setBody( body );
        }
        req.setHeader( 'Content-Type' , 'application/json' );
        req = this.prepareHttpRequest( req , headers );
        HttpResponse response = null;
        try {
            response = h.send( req );
        } catch ( Exception ex ) {
            if ( numberofTrys < this.automaticRetrys ) {
                return this.makeCall( url , body , headers , method , ( numberofTrys + 1) );
            }
            response = this.handleHttpException( response , ex );
        }
        response = this.handleHttpResponse( response );
        String responseBody = null;
        if ( response != null ) {
            responseBody = response.getBody();
        }
        return responseBody;
    }

    private HttpRequest prepareHttpRequest( HttpRequest request , Map<String,String> headers ) {
        if ( request == null ) {
            request = new HttpRequest();
        }
        if ( headers == null ) {
            headers = new Map<String,String>();
        }
        if ( this.auth != null ) {
            request.setHeader( 'Authorization' , 'bearer ' + this.auth.AccessToken() );
        }
        for ( String key : headers.keySet() ) {
            request.setHeader( key , headers.get( key ) );
        }
        request.setTimeout( SpringCMHTTPRequestor.timeout );
        return request;
    }

    private HttpResponse handleHttpException( HttpResponse response , Exception e ) {
        if ( e != null ) {
            if ( SpringCMHTTPRequestor.isEnabledExceptions ) {
                throw e;
            } else {
                response = null;
            }
        }
        return response;
    }

    private HttpResponse handleHttpResponse( HttpResponse response ) {
        if ( ( response != null ) && ( response.getStatusCode() > 300 ) ) {
            CalloutException e = new CalloutException();
            e.setMessage( 'there was an error making a call to the api' );
            if ( SpringCMHTTPRequestor.isEnabledExceptions ) {
                throw e;
            } else {
                response = null;
            }
        }
        return response;
    }

    //
    // Custom Settings...
    //

    private static SpringCMHttpRequestorSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = SpringCMHttpRequestorSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( SpringCMHTTPRequestor.settings != null ) {
                    local = SpringCMHTTPRequestor.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Boolean isEnabledExceptions {
        private get {
            if ( isEnabledExceptions == null ) {
                Boolean local = false;
                if ( SpringCMHTTPRequestor.settings != null ) {
                    local = SpringCMHTTPRequestor.settings.IsEnabledExceptions__c;
                }
                isEnabledExceptions = local;
            }
            return isEnabledExceptions;
        }
        private set;
    }

    private static Integer retries {
        private get {
            if ( retries == null ) {
                Integer local = 10;
                if ( ( SpringCMHTTPRequestor.settings != null )
                    && ( SpringCMHTTPRequestor.settings.Retries__c != null )
                   )
                {
                    local = SpringCMHTTPRequestor.settings.Retries__c.intValue();
                }
                // retries must be greater than or equal to zero...
                if ( local < 0 ) {
                    local = 0;
                }
                // retries must be less than or equal to 10...
                if ( local > 10 ) {
                    local = 10;
                }
                retries = local;
            }
            return retries;
        }
        private set;
    }

    private static Integer timeout {
        private get {
            if ( timeout == null ) {
                Integer local = 120000;
                if ( ( SpringCMHTTPRequestor.settings != null )
                    && ( SpringCMHTTPRequestor.settings.Timeout__c != null )
                   )
                {
                    local = SpringCMHTTPRequestor.settings.Timeout__c.intValue();
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