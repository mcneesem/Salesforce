public with sharing class WingspanRestService {
    // test w/ WingspanCreateUserActionTest (93%)
    
    public static Boolean createClientAdmin( Id contactId, Id recordId , Boolean isCheckOnly ){
        Boolean result = true;
        String createdUserId = '';
        if( ( contactId !=null ) 
           && ( recordId != null )
          ){
              //validate contact in Wingspan Server
              result = WingspanRestService.getUserByEmail( contactId, recordId, isCheckOnly );
              if( ( !isCheckOnly ) && ( !result ) ){
                  //create contact in Wingspan Server
                  createdUserId = WingspanRestService.createClientAdmin( contactId, recordId );
                  if( !String.isBlank( createdUserId ) ){
                      //Associate Admin in Wingspan Server
                      WingspanRestService.linkAdminToCHUB( createdUserId, recordId );
                  }
              }
          }
        return result;
    }
    
    //construct GET Request to validate contact in wingspan Server
    private static Boolean getUserByEmail(Id contactId, Id recordId, Boolean isCheckOnly){
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
              WingspanRestUtility agent = new WingspanRestUtility();
              HttpResponse resp = agent.sendRequest( method , path , '' , recordId );
              WingspanRestService.logs.add( agent.log );
              if( resp.getStatus() == 'Not Found' && resp.getStatusCode() == 404){
                  //user not found -> can create new
                  userFound = false;
              }
          }
        //insert only get api log
        if( isCheckOnly ){
            WingspanRestService.insertLogs();
        }
        return userFound;
    }
    
    //method to create contact as Admin in wingspan server
    private static String createClientAdmin(Id contactId, Id recordId){
        String createdUserId ='';
        String body = JSON.Serialize( getUserWrapper( contactId, recordId ) );
        String method = 'POST';
        
        //construct request
        if( !String.isBlank( recordId ) ){
            //create endpoint URL
            String path = '/users/organization/user';
            
            //call API
            WingspanRestUtility agent = new WingspanRestUtility();
            HttpResponse resp = agent.sendRequest( method , path , body , recordId );
            WingspanRestService.logs.add( agent.log );
            
            if( resp.getStatusCode() == 200 ){
                //construct success
                Map<String,Object> structuredResponse = ( Map<String,Object> )JSON.deserializeUntyped( resp.getBody() );
                createdUserId = ( String )structuredResponse.get( 'userId' );
            }
        }
        return createdUserId;
    }
    
    private static void linkAdminToCHUB(String createdUserId, Id recordId){
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
            WingspanRestUtility agent = new WingspanRestUtility();
            agent.sendRequest( method , path , body , recordId );
            WingspanRestService.logs.add( agent.log );
        }
        //insert all api logs
        WingspanRestService.insertLogs();
    }
    
    private static void insertLogs() {
        if ( !WingspanRestService.logs.isEmpty() ) {
            try {
                insert WingspanRestService.logs;
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    WingspanRestUtility.class.getName() ,
                    'insertLogs' ,
                    e
                );
            }
        }
    }
    
    private static CreateUserWrapper getUserWrapper(Id contactId, Id recordId){
        //fetch contact details
        Contact con = getContact( contactId );
        
        //initialize user wrapper
        CreateUserWrapper userWrap = new CreateUserWrapper();
        
        //create profile wrapper
        ProfileWrapper profileWrap = new ProfileWrapper();
        
        if( con != null ){
            //get email
            if( !String.isBlank(con.Email) ){
                userWrap.email = con.Email;    
            }
            if( !String.isBlank(con.FirstName) ){
                profileWrap.firstName = con.FirstName;    
            }
            if( !String.isBlank(con.FirstName) ){
                profileWrap.lastName = con.LastName;
            }
        }
        
        //create labels wrapper
        LabelsWrapper createdLabels = createLabels( recordId );
        userWrap.labels = createdLabels;
        
        //complete profile wrap
        profileWrap.preferredName = createdLabels.accountName;
        userWrap.profile = profileWrap;
        
        //create settings wrapper
        SettingsWrapper settWrap = new SettingsWrapper();
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
    private static LabelsWrapper createLabels( Id recordId ){
        LabelsWrapper labelsWrap = new LabelsWrapper();
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
            if ( String.isNotBlank( record.Asset_Number__c ) ) {
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
        private SettingsWrapper settings;
        private LabelsWrapper labels;
    }
    
    private class ProfileWrapper{
        private String firstName = '';
        private String lastName = '';
        private String preferredName = '';
    }
    
    private class SettingsWrapper{
        private String userAccountType = '';
    }
    
    private class LabelsWrapper{
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
    
    //property for keeping logs
    private static List<Wingspan_Log__c> logs {
        private get {
            if ( logs == null ) {
                logs = new List<Wingspan_Log__c>();
            }
            return logs;
        }
        private set;
    }
    
}