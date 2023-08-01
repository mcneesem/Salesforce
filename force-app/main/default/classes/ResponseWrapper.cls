public class ResponseWrapper{
    @AuraEnabled
    public Boolean status;
    @AuraEnabled
    public string data;
    @AuraEnabled
    public string errorMessage;
    public ResponseWrapper(Boolean status, String data, String errorMessage){
        this.status = status;
        this.data = data;
        this.errorMessage = errorMessage;
    }
}