public with sharing class WingspanRestService {
    // test w/ WingspanCreateUserActionTest (93%)

    //method to perform compound api callouts for initial wingspan user/client/admin validation and creation...
    public static Boolean createClientAdmin( Id contactId , Id recordId , Boolean isCheckOnly ) {
        Boolean isUserFound = true;
        try {
            if ( ( contactId != null ) && ( recordId != null ) ) {
                //validate contact in Wingspan Server
                isUserFound = WingspanRestService.getUserByEmail( contactId , recordId );
                if ( !isCheckOnly && !isUserFound ) {
                    //create contact in Wingspan Server
                    String createdUserId = WingspanRestService.postClientAdmin( contactId , recordId );
                    if ( String.isNotBlank( createdUserId ) ) {
                        //Associate Admin in Wingspan Server
                        WingspanRestService.postLinkAdmin( createdUserId , recordId ); // ignores response from link-admin api callout...
                    }
                }
            }
        } catch ( Exception e ) {
            WingspanRestService.handleException( e , 'createClientAdmin' );
        }
        WingspanRestService.insertLogs();
        return isUserFound;
    }

    //construct GET Request to validate contact in wingspan Server
    private static Boolean getUserByEmail( Id contactId , Id recordId ) {
        Boolean isUserFound = true;
        Contact con = WingspanRestService.selectContact( contactId );
        if ( ( con != null ) && ( String.isNotBlank( con.Email ) ) ) {
            WingspanRestAgent agent = new WingspanRestAgent();
            HttpResponse resp = agent.sendRequest(
                'GET' ,
                '/users/user/email/' + con.Email ,
                null ,
                recordId
            );
            WingspanRestService.logs.add( agent.log );
            if ( ( resp.getStatus() == 'Not Found' )
                && ( resp.getStatusCode() == 404 )
                )
            {
                //user not found -> can create new
                isUserFound = false;
            }
        }
        return isUserFound;
    }

    //method to create contact as Admin in wingspan server
    private static String postClientAdmin( Id contactId , Id recordId ) {
        String createdUserId = null;
        //construct request
        if ( ( contactId != null ) && ( recordId != null ) ) {
            WingspanRestAgent agent = new WingspanRestAgent();
            HttpResponse resp = agent.sendRequest(
                'POST' ,
                '/users/organization/user' ,
                WingspanRestService.buildUserWrapperJSON( contactId , recordId ) ,
                recordId
            );
            WingspanRestService.logs.add( agent.log );
            if ( resp.getStatusCode() == 200 ) {
                try {
                    //construct success
                    Map<String,Object> structuredResponse = (Map<String,Object>)JSON.deserializeUntyped( resp.getBody() ); // can throw exceptions when response body is not JSON...
                    createdUserId = (String)structuredResponse.get( 'userId' );
                } catch ( Exception e ) {
                    WingspanRestService.handleException( e , 'postClientAdmin' );
                }
            }
        }
        return createdUserId;
    }

    //method to associate Admin record in wingspan server
    private static void postLinkAdmin( String createdUserId , Id recordId ) {
        if ( String.isNotBlank( createdUserId ) ) {
            WingspanRestAgent agent = new WingspanRestAgent();
            agent.sendRequest(
                'POST' ,
                '/users/organization/user/' + createdUserId + '/associate' ,
                WingspanRestService.buildLinkUserToHubWrapperJSON() ,
                recordId
            );
            WingspanRestService.logs.add( agent.log );
        }
    }

    // property for keeping logs
    private static List<Wingspan_Log__c> logs {
        private get {
            if ( logs == null ) {
                logs = new List<Wingspan_Log__c>();
            }
            return logs;
        }
        private set;
    }

    //method to insert Wingspan Logs
    private static void insertLogs() {
        if ( !WingspanRestService.logs.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.insert( WingspanRestService.logs , false );
                NSP_ErrorLogHandler.logResults(
                    WingspanRestService.class.getName() ,
                    'insertLogs:insert' ,
                    results
                );
            } catch ( Exception e ) {
                WingspanRestService.handleException( e , 'insertLogs' );
            }
        }
    }

    //method to fetch Contact record
    private static Contact selectContact( Id contactId ) {
        Contact cc = null;
        if ( contactId != null ) {
            List<Contact> ccList = [
                SELECT Id , Email , FirstName , LastName
                FROM Contact
                WHERE ( Id = :contactId )
            ];
            if ( !ccList.isEmpty() ) {
                cc = ccList[0];
            }
        }
        return cc;
    }

    private static Asset selectAsset( Id recordId ) {
        Asset record = null;
        if ( ( recordId != null )
            && ( recordId.getSObjectType() == Asset.getSObjectType() )
            )
        {
            //fetch record fields
            List<Asset> records = [
                SELECT
                    Id ,
                    AccountId ,
                    Asset_Number__c ,
                    Opportunity__r.NSP_Number_of_Employees__c ,
                    NSP_AccountName__c
                FROM Asset
                WHERE ( Id = :recordId )
                LIMIT 1
            ];
            if ( ( records != null ) && !records.isEmpty() ) {
                record = records[0];
            }
        }
        return record;
    }

    //
    // mathos to handle JSON body wrappers...
    //

    private static String buildLinkUserToHubWrapperJSON() {
        String wrapperJSON = null;
        try {
            wrapperJSON = JSON.serialize( WingspanRestService.buildLinkUserToHubWrapper() );
        } catch ( Exception e ) {
            WingspanRestService.handleException( e , 'buildLinkUserToHubWrapperJSON' );
        }
        return wrapperJSON;
    }

    private static LinkUserToHubWrapper buildLinkUserToHubWrapper() {
        LinkUserToHubWrapper linkWrap = new LinkUserToHubWrapper();
        if ( String.isNotBlank( WingspanRestAgent.parentUserId ) ) {
            linkWrap.parentUserId = WingspanRestAgent.parentUserId;
        }
        InheritanceStrategyWrapper inheritanceWrap = new InheritanceStrategyWrapper();
        inheritanceWrap.organizationAccountConfig = 'Parent';
        linkWrap.inheritanceStrategy = inheritanceWrap;
        return linkWrap;
    }

    private static String buildUserWrapperJSON( Id contactId , Id recordId ) {
        String wrapperJSON = null;
        try {
            wrapperJSON = JSON.serialize( WingspanRestService.buildUserWrapper( contactId , recordId ) );
        } catch ( Exception e ) {
            WingspanRestService.handleException( e , 'buildUserWrapperJSON' );
        }
        return wrapperJSON;
    }

    //Create User Wrapper
    private static CreateUserWrapper buildUserWrapper( Id contactId , Id recordId ) {
        //fetch contact details
        Contact con = WingspanRestService.selectContact( contactId );
        //initialize user wrapper
        CreateUserWrapper userWrap = new CreateUserWrapper();
        //create profile wrapper
        ProfileWrapper profileWrap = new ProfileWrapper();
        if ( con != null ) {
            //get email
            if ( String.isNotBlank( con.Email ) ){
                userWrap.email = con.Email;
            }
            if ( String.isNotBlank( con.FirstName ) ) {
                profileWrap.firstName = con.FirstName;
            }
            if ( String.isNotBlank( con.FirstName ) ) {
                profileWrap.lastName = con.LastName;
            }
        }
        //create labels wrapper
        LabelsWrapper createdLabels = WingspanRestService.buildLabelsWrapper( recordId );
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

    //method to create labels for JSON
    private static LabelsWrapper buildLabelsWrapper( Id recordId ) {
        LabelsWrapper labelsWrap = new LabelsWrapper();
        Asset record = WingspanRestService.selectAsset( recordId );
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

    //
    // wrapper classes for JSON body...
    //

    private class CreateUserWrapper {
        private String email = '';
        private ProfileWrapper profile;
        private SettingsWrapper settings;
        private LabelsWrapper labels;
    }

    private class ProfileWrapper {
        private String firstName = '';
        private String lastName = '';
        private String preferredName = '';
    }

    private class SettingsWrapper {
        private String userAccountType = '';
    }

    private class LabelsWrapper {
        private String insperityAccountId = '';
        private String saasId = '';
        private String employeesEstimate = '';
        private String accountName = '';
    }

    private class LinkUserToHubWrapper {
        private String parentUserId = '';
        private InheritanceStrategyWrapper inheritanceStrategy;
    }

    private class InheritanceStrategyWrapper {
        private String organizationAccountConfig = '';
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            WingspanRestService.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            WingspanRestService.class.getName() ,
            methodName ,
            e
        );
    }

}
//