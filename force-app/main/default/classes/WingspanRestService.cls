public with sharing class WingspanRestService {
    // test w/ WingspanCreateUserActionTest (96%)

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
              HttpResponse resp = WingspanRestUtility.sendRequest(method,path,'', recordId);
              if( resp.getStatus() == 'Not Found' && resp.getStatusCode() == 404){
                  //user not found -> can create new
                  userFound = false;
              }
          }
        //insert only get api log
        if( isCheckOnly ){
            WingspanRestUtility.insertLogs();
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
            HttpResponse resp = WingspanRestUtility.sendRequest(method,path,body, recordId);
            
            if( resp.getStatusCode() == 200 ){
                //construct success
                Map<String,Object> structuredResponse = ( Map<String,Object> )JSON.deserializeUntyped( resp.getBody() );
                createdUserId = ( String )structuredResponse.get( 'userId' );
            }
        }
        return createdUserId;
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
            WingspanRestUtility.sendRequest(method,path,body, recordId);
        }
        //insert all api logs
        WingspanRestUtility.insertLogs();
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
    
    private class LinkUserToHubWrapper{
        private String parentUserId = '';
        private InheritanceStrategyWrapper inheritanceStrategy;
    }
    
    private class InheritanceStrategyWrapper{
        private String organizationAccountConfig = '';
    }
    
}