public with sharing class NSP_ReportRequestWizardController {
    // test w/ NSP_ReportRequestWizardControllerTest (89%)

    public static final Id WO_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
    private static final String NOT_FOUND = 'Not Found';
    @AuraEnabled
    public static List<NSP_ReportRequest__c> getReportRequestList(String recordTypeIds ) {
        try {
            String userId = UserInfo.getUserId();
            return [SELECT Id,Name,NSP_Employee_Status__c, NSP_ClientName__c, NSP_ClientName__r.Name,NSP_ReportPlace__c,NSP_columsToBeTotaled__c,NSP_ListAdditionalClients_subAccounts__c,NSP_ReportName__c,
                    RecordTypeId,NSP_HowIsReportUsed__c,NSP_InternalClientReport__c,NSP_Existing_NewReport__c,NSP_NeedcolumnHeading__c,NSP_HowToSort__c,
                    NSP_ReportType__c,RecordType.DeveloperName,CreatedDate,NSP_LastSavedPageNumber__c  FROM NSP_ReportRequest__c WHERE RecordTypeId = : recordTypeIds AND NSP_IsDraft__c = true  AND OwnerId =:userId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 100 ];
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled
    public static list<contentversion> releatedFiles(String idParent){
        list<id> lstConDocs = new list<id>();
        try {
            for(ContentDocumentLink cntLink : [Select Id, ContentDocumentId From ContentDocumentLink WHERE LinkedEntityId =:idParent]) {
                lstConDocs.add(cntLink.ContentDocumentId);
            }
            if(!lstConDocs.isEmpty()) {
                return [SELECT Id, Title, ContentDocumentId ,PathOnClient,CreatedDate,FileExtension FROM ContentVersion WHERE ContentDocumentId IN :lstConDocs WITH SECURITY_ENFORCED LIMIT 100 ];
            }
            else {
                return new List<contentversion>();
            }
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getInternalAccountId(){

        try {
            if( String.isNotBlank(System.Label.NSP_Insperity_Account)){
                Id insperityAccountId = test.isRunningTest() ? null : System.Label.NSP_Insperity_Account;
                return insperityAccountId;
            }
            return null;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getQueueByName(String queueLabel){
        try {
            String developmentQueue= [ SELECT ID,DeveloperName, Name FROM Group WHERE Name = : queueLabel  LIMIT 1 ].ID;
            return developmentQueue;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    //
    // @MethodName: getHRspecialistAndFinanceLevel
    // @Description: This method fetch HR specialist from Account team and Finance level, segment, service region from WO asset
    // @param : String accountID
    // @modifiedDate : 12/09/2022
    // @return Map<String,String>
    //
    @AuraEnabled
    public static Map<String,String> getHRspecialistAndFinanceLevel( String accountID ) {
        try {
            Map<String,String> jSONmap =new Map<String,String>();
            String financeLevel,segment,region = NOT_FOUND;
            List <String> assetFields = new List <String> {
                'Id' ,
                    'AccountId' ,
                    'NSP_Service_Region__c' ,
                    'NSP_Account_Status__c' ,
                    'toLabel(NSP_Financial_Guidelines__c)' ,
                    'NSP_Client_Segment_type__c'
                    };
                        jSONmap = getAccountTeamUsers( accountID );
            // fetch credit level, service region and client segment type from wo asset associated with client name selected
            String assetQuery = new NSP_QueryBuilder( 'Asset' , assetFields )
                .addFilter( 'RecordTypeId' , WO_ASSET )
                .addFilter( 'AccountId' , accountID )
                .setSecurityEnforce( false )
                .build();
            assetQuery += ' AND (NSP_Financial_Guidelines__c!=NULL OR NSP_Client_Segment_type__c!=null OR NSP_Service_Region__c!=null) ';
            assetQuery += 'ORDER BY LastModifiedDate ASC LIMIT 1';
            Asset[] asset = Database.query( assetQuery );
            if ( !asset.isEmpty() ) {
                financeLevel= asset[0].NSP_Financial_Guidelines__c;
                if ( NSP_ServiceConstants.ASSET_ACTIVE_STATUS.equalsIgnoreCase( asset[0]?.NSP_Account_Status__c )
                    || NSP_ServiceConstants.TERMINATED.equalsIgnoreCase( asset[0]?.NSP_Account_Status__c )
                   )
                {
                    segment=asset[0].NSP_Client_Segment_type__c;
                }
                region = asset[0].NSP_Service_Region__c;
            }
            //map finance level, region and segment of wizard output to credit level and segment type of wo asset respecitvely
            jSONmap.put( 'FinanceLevel' , financeLevel );
            jSONmap.put( 'segment' , segment );
            jSONmap.put( 'region' , region );
            return jSONmap;
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    //== Method to get the User Id from Account Teams using the account Id
    private static Map<String,String> getAccountTeamUsers( String accountID ) {
        Map<String,String> jSONmap = new Map<String,String>();
        String userId, psUserId = NOT_FOUND;
        Set<String> roles = new Set<String>{
            'HR Specialist' ,
                'Bus. Team-HRSp/CL' ,
                'Performance Specialist'
                };
                    //fetch Primary HR specialist from Account team associated with the accountid
                    List<NSP_Account_Team__c> accountTeam = [
                        SELECT
                        Id , NSP_Primary__c ,
                        NSP_User__r.Name , NSP_User__c ,
                        NSP_Role__c , NSP_Account__c
                        FROM NSP_Account_Team__c
                        WHERE (
                            NSP_Account__c = :accountID
                            AND NSP_Role__c = :roles
                            AND NSP_User__c != null
                        )
                    ];
        //Map HR specialist of wizard output to Account team HR Specialist
        if ( !accountTeam?.isEmpty() ) {
            for ( NSP_Account_Team__c accTeam : accountTeam ) {
                psUserId = setAndGetPerformanceSpecialistUserId(
                    accTeam.NSP_Role__c ,
                    psUserId ,
                    accTeam.NSP_User__c ,
                    accTeam.NSP_Primary__c
                );
                userId = setAndGetHRSpecialistUserId(
                    accTeam.NSP_Role__c ,
                    userId ,
                    accTeam.NSP_User__c ,
                    accTeam.NSP_Primary__c
                );
            }
        }
        jSONmap.put( 'UserId' , userId );
        jSONmap.put( 'psUserId' , psUserId );
        return jSONmap;
    }

    //== Method to set and get the Performance Specialist User Id
    private static String setAndGetPerformanceSpecialistUserId( String role , String userID , String accountTeamUser , Boolean isPrimary ) {
        String returnValue = userId;
        if ( NSP_ServiceConstants.PERFOMANCE_SPECIALIST.equalsIgnoreCase(role)
            && ( isPrimary || NOT_FOUND.equalsIgnoreCase(userID) )
           )
        {
            returnValue = accountTeamUser;
        }
        return returnValue;
    }

    //== Method to set and get HR Specialist User Id
    private static String setAndGetHRSpecialistUserId( String role , String userID , String accountTeamUser , Boolean isPrimary ) {
        String returnValue = userId;
        if ( ( NSP_ServiceConstants.HRSpecialist.equalsIgnoreCase(role) || NSP_ServiceConstants.BUS_TEAM_HRSP_CL.equalsIgnoreCase(role) )
            && ( isPrimary || NOT_FOUND.equalsIgnoreCase( userID ) )
           )
        {
            returnValue = accountTeamUser;
        }
        return returnValue;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountContactRelation> retrieveContactRecords (String accountId ) {
        try {
            //Contact[] contacts  =  [SELECT Name, Email from Contact WHERE AccountId =:accountId];
            //fetch related contacts instead of direct contacts
            AccountContactRelation [] acrs = [SELECT ContactId, Contact.name, Contact.NSP_Work_email__c, NSP_Work_Email__c  from AccountContactRelation WHERE AccountId =:accountId];
            if(!acrs.isEmpty()){
                return acrs;
            }else {
                return new List<AccountContactRelation> () ;
            }
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    //
    // @MethodName: getWSEEDetails
    // @Description: This method fetch DOB, WORK STATE, EMP STATE FROM WSEE SELECTED
    // @param : String contactID, String accountID
    // @modifiedDate : 12/09/2022
    // @return List<wizardOutputWrapper>

    @AuraEnabled
    public static List<WizardOutputWrapper> getWSEEDetails(String contactID, String accountId) {
        try {

            List<WizardOutputWrapper> wizardOutputWrapperList = new List<WizardOutputWrapper>();

            WizardOutputWrapper wizOtWrapper = new WizardOutputWrapper();

            // Set default values
            wizOtWrapper.empStatus = null;
            wizOtWrapper.terminationDate = null;
            wizOtWrapper.subClientNum = null;

            if (String.isNotBlank(contactID)) {

                // Fetch contact details
                List<Contact> conList = [
                    SELECT Id,
                    NSP_Date_of_Birth__c,
                    Name
                    FROM Contact
                    WHERE Id = :contactID
                    LIMIT 1
                ];

                if (!conList.isEmpty()) {

                    Contact contact = conList[0];

                    // Map DOB from contact
                    wizOtWrapper = setAndGetContactFields(contact, wizOtWrapper);
                }

                if (String.isNotBlank(accountId)) {

                    // Fetch related sub client contacts
                    List<NSP_Sub_Client_Contact__c> accSubClientContList = [
                        SELECT Id,
                        NSP_Is_Primary__c,
                        NSP_Employee_Status__c,
                        NSP_Status_Date__c,
                        NSP_AIMS_Sub_Client__c,
                        NSP_Sub_Client__c,
                        NSP_Sub_Client__r.NSP_Account__c,
                        NSP_Sub_Client__r.Name
                        FROM NSP_Sub_Client_Contact__c
                        WHERE NSP_Contact__c = :contactID
                        AND NSP_Sub_Client__r.NSP_Account__c = :accountId
                        AND NSP_Sub_Client__c != null
                    ];

                    if (!accSubClientContList.isEmpty()) {
                    wizOtWrapper =NSP_ReportRequestWizardController.setAndGetSubClinetContactFields(wizOtWrapper,accSubClientContList);
                    }
                }

                wizardOutputWrapperList.add(wizOtWrapper);
            }

            return wizardOutputWrapperList;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static NSP_Sub_Client_Contact_Address__c getWorkState(
        String subClientContactId,
        String contactID
    ) {

        NSP_Sub_Client_Contact_Address__c sccAddress;

        if (String.isNotBlank(subClientContactId) && String.isNotBlank(contactID)) {

                List<NSP_Sub_Client_Contact_Address__c> sccAddressList = [
                    SELECT NSP_State__c,
                    NSP_Sub_Client_Contact__c
                    FROM NSP_Sub_Client_Contact_Address__c
                    WHERE NSP_Sub_Client_Contact__r.NSP_Contact__c = :contactID
                    AND NSP_Sub_Client_Contact__c = :subClientContactId
                    LIMIT 1
                ];

                if (!sccAddressList.isEmpty()) {
                    sccAddress = sccAddressList[0];
                }
            }

        return sccAddress;
    }

    //== Set and get Sub Clinet Contact Fields
    private static WizardOutputWrapper setAndGetSubClinetContactFields( WizardOutputWrapper wizOtWrapper,List<NSP_Sub_Client_Contact__c> subclientContacts ) {

        if (subclientContacts != null && !subclientContacts.isEmpty()) {
            wizOtWrapper.subclientContacts = subclientContacts;
        }
        return wizOtWrapper;
    }

    //== Set and Get Contact field mapping
    private static WizardOutputWrapper setAndGetContactFields(Contact contact, WizardOutputWrapper wizOtWrapper)
    {
        // Default values
        wizOtWrapper.contactName = null;
        wizOtWrapper.dateOfBirth = null;

        if(contact.NSP_Date_of_Birth__c !=null)
        {
            wizOtWrapper.contactName =  contact.Name;
            wizOtWrapper.dateOfBirth =  contact.NSP_Date_of_Birth__c;
        }
        return wizOtWrapper;
    }

    /**
* @MethodName: getActiveEmployeeCount
* @Description: This method fetch unique active employee count from WO asset
* @param :  String accountID
* @createdDate : 12/14/2022
* @return Boolean true if the employee count is greater than 45
*/
    @AuraEnabled
    public static Boolean getActiveEmployeeCount ( String accountId){
        try{
            List<String> assetFields = new List<String> {'Id', 'AccountId',
                'NSP_Unique_Active_Employee__c'};
                    //return true if asset associated to account has unique active employees greater than or equal to 45
                    String assetQuery = new NSP_QueryBuilder(
                        'Asset',
                        assetFields)
                    .addFilter('AccountId', String.escapeSingleQuotes(accountID))
                    .addFilter('RecordTypeId', WO_ASSET)
                    .setSecurityEnforce(false)
                    .build();
            assetQuery += ' AND NSP_Unique_Active_Employee__c!=NULL AND NSP_Unique_Active_Employee__c >=  10 ORDER BY LastModifiedDate ASC LIMIT 1' ;
            List<Asset> assetList = Database.query(assetQuery);

            if(assetList.size()>0){
                return true;
            }
            return false;
        }catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    public class WizardOutputWrapper{
        @AuraEnabled
        public String mailingState{get;set;}
        @AuraEnabled
        public Date dateOfBirth{get;set;}
        @AuraEnabled
        public String empStatus{get;set;}
        @AuraEnabled
        public Date terminationDate{get;set;}
        @AuraEnabled
        public Set<String> subClientNum{get;set;}
        @AuraEnabled
        public String contactName{get;set;}
        @AuraEnabled
        public List<NSP_Sub_Client_Contact__c> subclientContacts{set;get;}
    }

    @AuraEnabled
    public static String getHRspecialist(String accountID){
        try {
            String userId;
            NSP_Account_Team__c[] accountTeam =[SELECT Id, NSP_User__r.Name, NSP_User__c, NSP_Role__c,NSP_Account__c FROM NSP_Account_Team__c
                                                WHERE NSP_Role__c ='HR Specialist' AND NSP_Account__c =:accountID AND NSP_User__c !=null  ORDER BY LastModifiedDate ASC LIMIT 1];
            if(accountTeam.size()>0){
                userId= accountTeam[0].NSP_User__c;
            }
            return userId;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled
    public static String getAIMSfromPEOasset(String accountID){
        try {
            String aimsNumb;
            Asset[] assetList =[SELECT NSP_Client__c, RecordType.DeveloperName, CreatedDate FROM Asset
                                WHERE NSP_Client__c != null AND RecordType.DeveloperName ='WO' AND AccountId =: accountID ORDER BY CreatedDate DESC  LIMIT 1];

            if(assetList.size()>0){
                aimsNumb= assetList[0].NSP_Client__c;
            }
            return aimsNumb;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }

    }

    /**
* @MethodName: getAccountWoAsset
* @Description: This method fetch wo-asset associated to account
* @param :  String accountID
* @createdDate : 03/23/2023
* @return string assetId of wo-asset recordType assosiated with given accountId
*/

    @AuraEnabled
    public static String getAccountWoAsset(String accountId){
        try {
            String woAsset = '';
            List<String> assetFields = new List<String> {'Id', 'AccountId', 'RecordTypeId'};
                //return true if recordtype of asset is wo-asset associated to account
                String assetQuery = new NSP_QueryBuilder(
                    'Asset',
                    assetFields)
                .addFilter('AccountId', String.escapeSingleQuotes(accountId))
                .addFilter('RecordTypeId', WO_ASSET)
                .addLimit(1)
                .setSecurityEnforce(false)
                .build();
            List<Asset> assetList = Database.query(assetQuery);
            if(assetList.size()>0){
                woAsset= assetList[0].Id;
            }
            return woAsset;
        } catch (Exception exc) {
            throw new AuraHandledException(exc.getMessage());
        }

    }

    //
    // @MethodName: createCaseDocuments
    // @Description: This method will create documents for case based on wizard output
    // @param: String caseID, string NSP_ReprotRequest__c.ID
    // @return: N/A
    //
    @AuraEnabled
    public static void createCaseDocuments( Id reportRequestID , Id caseID ) {
        try {
            Set<Id> recordTypeIdSet = new Set<Id>();
            recordTypeIdSet.add( NSP_GenericRecordType.getRecordTypeId( 'NSP_ReportRequest__c' , 'NSP_SeparationRequest' ) );
            recordTypeIdSet.add( NSP_GenericRecordType.getRecordTypeId( 'NSP_ReportRequest__c' , 'NSP_SurveyRequest' ) );
            List<NSP_ReportRequest__c> requests = [
                SELECT Id
                FROM NSP_ReportRequest__c
                WHERE (
                    Id = :reportRequestID
                    AND RecordTypeId = :recordTypeIdSet
                )
                LIMIT 1
            ];
            // Query results to check for the Report Reqeust with Seperarion Agreement Record Type
            if ( !requests?.isEmpty() ) {
                NSP_ReportRequest__c request = requests[0];
                List<ContentDocumentLink> lstConDocs = new List<ContentDocumentLink>();
                // Getting the content document links related to Report Request record for content document ID
                for ( ContentDocumentLink cntLink : [
                    SELECT Id , ContentDocumentId , ShareType , Visibility
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :request.ID
                ]
                    )
                {
                    lstConDocs.add(
                        new ContentDocumentLink(
                            LinkedEntityId=caseID ,
                            ContentDocumentId=cntLink.ContentDocumentId ,
                            ShareType='I' ,
                            Visibility='InternalUsers'
                        )
                    );
                }
                if ( lstConDocs?.size() > 0 ) {
                    Database.insert( lstConDocs , false );
                }
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

}
//