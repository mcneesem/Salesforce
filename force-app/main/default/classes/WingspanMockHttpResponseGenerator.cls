@isTest
public class WingspanMockHttpResponseGenerator implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if( req != null ){
            if( req.getMethod() == 'GET'){
                res.setBody('{"error":"User not found with given email"}');
                res.setStatusCode(404);
                res.setStatus('Not Found');
            }

            if( req.getMethod() == 'POST'){
                res.setBody('{"userId":"xyz123"}');
                res.setStatusCode(200);
                res.setStatus('OK');    
            }
        } 
        return res;
    }
}