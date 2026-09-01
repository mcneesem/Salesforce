public with sharing class WingspanRestService {
    // test w/ WingspanCreateUserActionTest (90%)
    
    private static Map<Id,List<OpportunityLineItem>> oppItemMap = new Map<Id,List<OpportunityLineItem>>();
    public static final String NON_SSO = 'Non SSO';
    public static final String HR360 = 'HR360';
    public static final String HRSCALE = 'HRScale';
    private static final String OBJ_ASSET = 'Asset';
    private static final String ENTERPRISE = 'enterprise';

    //method to perform compound api callouts for initial wingspan user/client/admin validation and creation...
    public static Boolean createClientAdmin( Id contactId , Id recordId , Boolean isCheckOnly ) {
        Boolean isUserFound = true;
        String email = '';
        String platform = '';
        Asset record = new Asset();
        try {
            if( String.isNotBlank( recordId ) ){
                String sObjectName = WingspanRestService.getObjectName( recordId );
                //get email from Asset
                if( sObjectName == WingspanRestService.OBJ_ASSET ){
                    record = WingspanRestService.selectAsset( recordId );
                    email = WingspanRestService.extractAssetEmail( 
                        record ,
                        contactId
                    );
                    if ( String.isNotBlank( record.Platform__c ) ) {
                        platform = record.Platform__c;
                    }
                }else if( ( sObjectName == 'SBQQ__Quote__c' ) && ( String.isNotBlank( contactId ) ) ){
                    //get email from Quote
                    email = WingspanRestService.getEmailFromContact( WingspanRestService.selectContact( contactId ) );
                }
                //check for validation request
                isUserFound = WingspanRestService.makeValidationRequest( 
                    isCheckOnly , 
                    email , 
                    recordId , 
                    platform 
                );
                //check for account creation request
                WingspanRestService.makeAccountRequest( 
                    isUserFound , 
                    isCheckOnly , 
                    contactId , 
                    record 
                );
            }
        } catch ( Exception e ) {
            WingspanRestService.handleException( e , 'createClientAdmin' );
        }
        WingspanRestService.insertLogs();
        return isUserFound;
    }
    
    //method to make get request for validating payer account
    private static Boolean makeValidationRequest( 
        Boolean isCheckOnly , 
        String email , 
        Id recordId , 
        String platform 
    ) {
        Boolean isUserFound = true;
        if(  !( 
            ( WingspanRestService.isEnabledSso( platform ) ) 
            && ( !isCheckOnly ) ) //isCheckOnly = true for validate customer stakeholder
          ) 
        {
            //does not send validation request while creating SSO wingspan account
            isUserFound = WingspanRestService.getUserByEmail( email , recordId , platform );
        }
        return isUserFound;
    }
    
    //method to create request for inserting payer account in wingspan
    private static void makeAccountRequest(Boolean isUserFound, Boolean isCheckOnly, Id contactId, Asset record){
        //driven only by asset
        if ( ( !isCheckOnly ) 
            && ( record != null ) 
            && ( ( !isUserFound ) 
                || ( WingspanRestService.isEnabledSso( record.Platform__c ) )
               ) 
           ) 
        {
            //create contact in Wingspan Server for SSO and non-SSO
            String createdUserId = WingspanRestService.postClientAdmin( contactId , record );
            if ( String.isNotBlank( createdUserId ) ) {
                if( record.Platform__c == WingspanRestService.NON_SSO ){
                    //Associate Admin in Wingspan Server (2nd call only for non-sso)
                    WingspanRestService.postLinkAdmin( createdUserId , record ); // ignores response from link-admin api callout...
                }
                //store user Id back into Asset record in future
                WingspanRestService.updateAsset( 
                    createdUserId , 
                    record.id , 
                    WingspanRestService.processAddons( record.Opportunity__c, record.ProductCode ) 
                );
            }
        }
    }

    //construct GET Request to validate contact in wingspan Server
    private static Boolean getUserByEmail( String email , Id recordId , String platform ) {
        Boolean isUserFound = true;
        if ( ( String.isNotBlank( email ) ) && ( String.isNotBlank( recordId ) ) ) {
            WingspanRestAgent agent = new WingspanRestAgent();
            HttpResponse resp = agent.sendRequest(
                'GET' ,
                '/users/user/email/' + email ,
                null ,
                recordId ,
                platform
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
    private static String postClientAdmin( Id contactId , Asset record ) {
        String createdUserId = null;
        String path  ='/users/organization/user';//non-sso url
        if ( ( record != null ) && ( WingspanRestService.isEnabledSso( record.Platform__c ) ) )
        {
            //sso url
            path = '/v2/organizations/{userId}/platform-accounts';
        }
        //construct request
        if ( record != null ) {
            WingspanRestAgent agent = new WingspanRestAgent();
            HttpResponse resp = agent.sendRequest(
                'POST' ,
                path,
                WingspanRestService.buildUserWrapperJSON( contactId , record ) ,
                record.Id ,
                record.Platform__c
            );
            WingspanRestService.logs.add( agent.log );
            if ( resp.getStatusCode() == 200 || resp.getStatusCode() == 201 ) {
                try {
                    //construct success
                    Map<String,Object> structuredResponse = (Map<String,Object>)JSON.deserializeUntyped( 
                        resp.getBody() 
                    ); // can throw exceptions when response body is not JSON...
                    String fetchIdString = '';
                    if ( ( record.Platform__c == WingspanRestService.NON_SSO ) 
                        || ( String.isBlank( record.Platform__c ) ) 
                       ) 
                    {
                        fetchIdString = 'userId';
                    } else if ( WingspanRestService.isEnabledSso( record.Platform__c ) ) 
                    {
                        fetchIdString = 'payerUserId';
                    }
                    createdUserId = (String)structuredResponse.get( fetchIdString );
                } catch ( Exception e ) {
                    WingspanRestService.handleException( e , 'postClientAdmin' );
                }
            }
        }
        return createdUserId;
    }

    //method to associate Admin record in wingspan server
    private static void postLinkAdmin( String createdUserId , Asset record ) {
        if ( String.isNotBlank( createdUserId ) ) {
            WingspanRestAgent agent = new WingspanRestAgent();
            agent.sendRequest(
                'POST' ,
                '/users/organization/user/' + createdUserId + '/associate' ,
                WingspanRestService.buildLinkUserToHubWrapperJSON() ,
                record.Id ,
                record.Platform__c
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
                SELECT 
                    Id , 
                    Email , 
                    FirstName , 
                    LastName
                FROM Contact
                WHERE ( Id = :contactId )
            ];
            if ( !ccList.isEmpty() ) {
                cc = ccList[0];
            }
        }
        return cc;
    }
    
    //helper method to get email from contact record
    private static String getEmailFromContact( Contact con ) {
        String email = '';
        if( ( con != null ) && ( String.isNotBlank( con.Email ) ) ){
            email = con.Email;
        }
        return email;
    }

    //helper method to fetch Asset record
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
                    NSP_AccountName__c ,
                    Platform__c ,
                    Payer_Account_Email__c ,
                    Customer_Stakeholder__c ,
                    NSP_WO_AIMS_Client_Number__c ,
                    Opportunity__c ,
                    NSP_OrderProduct__r.SBQQ__BundleRoot__r.Product2.Name ,
                    ProductCode 
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
    
    //method to fetch Object name
    private static String getObjectName(Id recordId){
        String objectName = '';
        if ( String.isNotBlank( recordId ) ){
            Schema.SObjectType sObjectType = recordId.getSObjectType();
            if ( sObjectType != null ) {
                objectName = sObjectType.getDescribe().getName();
            }
        }
        return objectName;
    }
    
    //method to extract email from Asset record
    private static String extractAssetEmail(Asset record, Id contactId){
        String email = '';
        if( record != null )
        {
            if( ( record.Platform__c == WingspanRestService.NON_SSO ) 
               || ( String.isBlank( record.Platform__c ) ) 
              )
            {
                if( String.isNotBlank( contactId ) ){
                    //non SSO asset takes email from customer stakeholder
                    //Validate_Customer_Stakeholder flow passes contact Id for Non SSO
                    email = WingspanRestService.getEmailFromContact( WingspanRestService.selectContact( contactId ) );
                }else if( ( record.Customer_Stakeholder__c != null ) 
                         && ( String.isNotBlank( record.Customer_Stakeholder__r.Email ) ) 
                        )
                {
                    email = record.Customer_Stakeholder__r.Email;
                }
            }else if( ( WingspanRestService.isEnabledSso( record.Platform__c ) )
                     && ( String.isNotBlank( record.Payer_Account_Email__c ) ) 
                    )
            {
                //SSO email comes from formula field
                email = record.Payer_Account_Email__c;
            }
        }
        return email;
    }
    
    @future
    private static void updateAsset(String createdUserId, Id recordId , String addons){
        try{ 
            if( ( String.isNotblank( createdUserId ) ) 
               && ( recordId != null ) 
              )
            {
                List<Asset> assets = [
                    SELECT 
                        id , 
                        Payer_Account_Id__c , 
                        Product_Addons__c 
                    FROM Asset 
                    WHERE Id =:recordId 
                    LIMIT 1
                ];
                if( assets != null && !assets.isEmpty() ){
                    assets[0].Payer_Account_Id__c = createdUserId;
                    if( String.isNotBlank( addons ) ) {
                        assets[0].Product_Addons__c = addons;
                    } else {
                        assets[0].Product_Addons__c = '';
                    }
                    List<Database.SaveResult> res = Database.update( assets , false );
                    NSP_ErrorLogHandler.logResults(
                        WingspanRestService.class.getName() ,
                        'updateAsset' ,
                        res
                    );
                }
            }
        }catch (exception e){
            WingspanRestService.handleException( e , 'updateAsset' );
        }
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

    //method to build body wrapper
    private static String buildUserWrapperJSON( Id contactId , Asset record ) {
        String wrapperJSON = null;
        try {
            if( record != null ){
                if( WingspanRestService.isEnabledSso( record.Platform__c ) )
                {
                    //construct SSO wrapper
                    wrapperJSON = JSON.serialize( WingspanRestService.buildCreateSsoUserWrapper( record ) );
                }else {
                    //construt non-SSO wrapper
                    wrapperJSON = JSON.serialize( WingspanRestService.buildUserWrapper( contactId , record ) );
                }
            }
        } catch ( Exception e ) {
            WingspanRestService.handleException( e , 'buildUserWrapperJSON' );
        }
        return wrapperJSON;
    }

    //Create User Wrapper
    private static CreateUserWrapper buildUserWrapper( Id contactId , Asset record ) {
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
        LabelsWrapper createdLabels = WingspanRestService.buildLabelsWrapper( record );
        userWrap.labels = createdLabels;
        //complete profile wrap
        profileWrap.preferredName = createdLabels.accountName;
        userWrap.profile = profileWrap;
        //create settings wrapper
        SettingsWrapper settWrap = new SettingsWrapper();
        settWrap.userAccountType = WingspanRestService.ENTERPRISE;
        userWrap.settings = settWrap;
        return userWrap;
    }

    //method to create labels for JSON
    private static LabelsWrapper buildLabelsWrapper( Asset record ) {
        LabelsWrapper labelsWrap = new LabelsWrapper();
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
            labelsWrap.packageTier = WingspanRestService.processPackageTier( record.ProductCode );
            labelsWrap.addons = WingspanRestService.processAddons( record.Opportunity__c, record.ProductCode );
            labelsWrap.platform = WingspanRestService.processPlatform( record.Platform__c );
        }
        return labelsWrap;
    }
    
    //method to create the wrapper for SSO request
    private static CreateSsoUserWrapper buildCreateSsoUserWrapper(Asset record){
        CreateSsoUserWrapper wrap = new CreateSsoUserWrapper();
        if( record != null ){
            if( String.isNotBlank( record.NSP_WO_AIMS_Client_Number__c  ) ) {
                wrap.externalIdResolution = 'insperityClientId';
            }
            if( String.isNotBlank( record.NSP_WO_AIMS_Client_Number__c ) ) {
                wrap.externalId = record.NSP_WO_AIMS_Client_Number__c;
            }
            if ( record.Platform__c == WingspanRestService.HR360 ){
                wrap.domain = 'HR360.insperity.com';
            } else if ( record.Platform__c == WingspanRestService.HRSCALE ) {
                wrap.domain = '';//for later
            }
            if ( String.isNotBlank( record.Payer_Account_Email__c ) ) {
                wrap.payerEmail = record.Payer_Account_Email__c;
            }
            if ( String.isNotBlank( record.NSP_AccountName__c ) ) {
                wrap.companyName = sanitizeText( record.NSP_AccountName__c , true , 120 );
            }
            SsoLabelsWrapper labelWrap = buildSsoLabelsWrapper ( record );
            if( labelWrap != null ) {
                wrap.labels = labelWrap;
            }
        }
        return wrap;
    }
    
    private static SsoLabelsWrapper buildSsoLabelsWrapper ( Asset record ) {
        SsoLabelsWrapper labelsWrap = new SsoLabelsWrapper();
        if ( record != null ) {
            if( String.isNotBlank( record.NSP_WO_AIMS_Client_Number__c  ) ) {
                labelsWrap.insperityClientId = record.NSP_WO_AIMS_Client_Number__c;
            }
            if ( String.isNotBlank( record.Asset_Number__c ) ) {//this is repeated
                labelsWrap.saas_id = record.Asset_Number__c;
            }
            if ( String.isNotBlank( record.AccountId ) ) {
                labelsWrap.insperityAccountId = record.AccountId;
            }
            labelsWrap.platform = WingspanrestService.processPlatform( record.Platform__c );
            if ( String.isNotBlank( record.NSP_AccountName__c ) ) {//this is repeated
                labelsWrap.account_name = record.NSP_AccountName__c;
            }
            if ( record.Opportunity__r.NSP_Number_of_Employees__c != null ) {
                labelsWrap.employees_estimate = String.valueOf( record.Opportunity__r.NSP_Number_of_Employees__c );
            }
            labelsWrap.packageTier = WingspanRestService.processPackageTier( record.ProductCode );
            labelsWrap.addons = WingspanRestService.processAddons( record.Opportunity__c, record.ProductCode );
        }
        return labelsWrap;
    }
    
    //method to remove unwanted characters
    private static String sanitizeText ( String text , Boolean trim, Integer trimLength ) {
        String outputText = '';
        if ( String.isNotBlank( text ) ) {
            outputText = text;
            if ( !WingspanRestAgent.restrictedCharacters.isEmpty() ) {
                for ( String str : WingspanRestAgent.restrictedCharacters ) {
                    if ( outputText.contains( str ) ) {
                        //replace restricted charcters with asterisk
                        outputText = outputText.replace( str , '*' );
                    }
                }
            }
            if ( trim
                && ( trimLength != null )
                && ( trimlength < outputText.length() )
                )
            {
                //trim the length
                outputText = outputText.subString( 0 , trimLength );
            }
        }
        return outputText;
    }
        
    //method to generate platform for label
    private static String processPlatform( String platform){
        String labelPlatform = '';
        if ( platform == WingspanRestService.HR360 ){
            labelPlatform = 'Premier';
        } else if ( platform == WingspanRestService.HRSCALE ) {
            labelPlatform = 'Workday';
        }
          else if ( platform == WingspanRestService.NON_SSO ) {
            labelPlatform = 'Non SSO';
        }
        return labelPlatform;
    }
    
    //method to check for SSO
    private static Boolean isEnabledSso( String platform ) {
        return (
            ( platform == WingspanRestService.HR360 )
            || ( platform == WingspanRestService.HRSCALE )
        );
    }
    
    //method to generate package tier label
    private static String processPackageTier ( String productCode ) {
        String packageTier = '';
        if ( productCode == 'CMEP' ) {
            packageTier = 'Essential';
        } else if ( productCode == 'CMCP' ) {
            packageTier = 'Complete';
        }
        else if ( productCode == 'CMPlat' ) {
            packageTier = 'Complete';
        }
        return packageTier;
    }
    //create addons param using custom settings
    private static List<String> COMPLETE_ADDONS {
    private get {
        if ( COMPLETE_ADDONS == null ) {
            COMPLETE_ADDONS = WingspanRestAgent.completeAddons;
        }
        return COMPLETE_ADDONS;
    }
    private set;
    }

    //determine where to fetch the addons from
    private static String processAddons ( Id oppId , String productCode ) {
    List<String> addons = ( productCode == 'CMPlat' )
        ? WingspanRestService.COMPLETE_ADDONS
        : WingspanRestService.buildAddonsList( oppId );
    return String.join( addons , ',' );
    }

    //create addons param using opp line items
    private static List<String> buildAddonsList ( Id oppId ) {
        if ( WingspanRestService.oppItemMap == null ) {
            WingspanRestService.oppItemMap = new Map<Id,List<OpportunityLineItem>>();
        }
        List<OpportunityLineItem> oppItems = new List<OpportunityLineItem>();
        if ( String.isNotBlank( oppId ) ) {
            if ( WingspanRestService.oppItemMap.containsKey( oppId ) ) {
                // reuse cache for previous query results...
                oppItems = WingspanRestService.oppItemMap.get( oppId );
            } else {
                // generate oppItems...  and add to static cache...
                oppItems = [
                    SELECT
                        Id ,
                        NSP_Product_Name__c
                    FROM OpportunityLineItem
                    WHERE (
                        ( OpportunityId = :oppId )
                        AND ( ProductCode NOT IN :WingspanRestAgent.restrictedProducts )
                    )
                ];
                WingspanRestService.oppItemMap.put( oppId , oppItems );
            }
        }
        List<String> addons = new List<String>();
        if ( ( oppItems != null ) && !oppItems.isEmpty() ) {
            for ( OpportunityLineItem item : oppItems ) {
                if( String.isNotBlank( item.NSP_Product_Name__c ) ) {
                    addons.add( item.NSP_Product_Name__c );
                }
            }
        }
        return  addons;
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
    
    private class CreateSsoUserWrapper {
        private String externalIdResolution = 'ClientId';
        private String externalId = '';
        private String domain = '';
        private String payerEmail = '';
        private String companyName = '';
        private SsoLabelsWrapper labels;
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
        private String packageTier = '';
        private String platform ='';
        private String addOns = '';
    }
    
    private class SsoLabelsWrapper {
        private String insperityClientId = '';
        private String saas_id = '';
        private String insperityAccountId = '';
        private String platform ='';
        private String account_name = '';
        private String employees_estimate = '';
        private String packageTier = '';
        private String addOns = '';
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