// intentionally `without sharing` to ensure nsp_visualIndicator LWC displays accurate indicators for all records...
public without sharing class NSP_VisualIndicatorHelper {
    // test w/ NSP_VisualIndicatorHelper_Test (97%)

    //
    // returns the account details for
    // @param accId Id related to account.
    // @return void
    //
    @AuraEnabled(cacheable=true)
    public static List<VisualIndicatorWrapper> gethisAccount( String accId ) {
        try {
            List<VisualIndicatorWrapper> resultList = new List<VisualIndicatorWrapper>();
            if ( ( accId != null ) && String.isNotBlank( accId ) ) {
                List<Account> accList = getAccounts( accId );
                if (accList != null && !accList.isEmpty()) {
                    List<NSP_Service_Exception__c> expList = extractServiceExceptions(accList);
                    List<Asset> assetList = extractAssets(accList);
                    List<NSP_Survey__c> surveyList = extractSurveys(accList);
                    VisualIndicatorWrapper accWrapper = createVisualIndicatorWrapper(expList, assetList, surveyList);
                    resultList = wrapAccounts(accList, accWrapper);
                }
            }
            return resultList;
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    private static List<Account> getAccounts( String accId ) {
        Id vocSurveyRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Survey__c' , 'VOC' );
        List<Account> accounts = new List<Account>();
        if ( ( accId != null ) && String.isNotBlank( accId ) ) {
            accounts = [
                SELECT
                    Id ,
                    Name ,
                    Industry ,
                    NSP_Account_Health__c ,
                    NSP_Paperless__c ,
                    NSP_Renewal_Probability__c ,
                    (
                        SELECT
                            Id ,
                            NSP_End_Date__c
                        FROM Service_Exceptions__r
                    ) ,
                    (
                        SELECT
                            Id ,
                            NSP_Paperless__c ,
                            NSP_Workforce_Sync__c ,
                            NSP_Client_Retained_Workers_Comp__c ,
                            NSP_Pending_Termination__c ,
                            NSP_Product_Line__c ,
                            Is_HRScale__c ,
                            RecordTypeId ,
                            NSP_National_Account__c ,
                            HRCore_Strategic_Partner__c
                        FROM Assets
                    ) ,
                    (
                        SELECT Id, Survey_End_Date__c
                        FROM Surveys__r
                        WHERE (
                            RecordTypeId = :vocSurveyRecordTypeId
                            AND Survey_End_Date__c != null
                        )
                        ORDER BY Survey_End_Date__c DESC
                        LIMIT 1
                    )
                FROM Account
                WHERE ( Id = :accId )
            ];
        }
        return accounts;
    }

    private static List<NSP_Service_Exception__c> extractServiceExceptions( List<Account> accList ) {
        List<NSP_Service_Exception__c> expList = new List<NSP_Service_Exception__c>();
        if (accList != null) {
            for (Account acc : accList) {
                if (acc.Service_Exceptions__r != null && !acc.Service_Exceptions__r.isEmpty()) {
                    expList.addAll(acc.Service_Exceptions__r);
                }
            }
        }
        return expList;
    }

    private static List<Asset> extractAssets( List<Account> accList ) {
        List<Asset> assetList = new List<Asset>();
        if (accList != null) {
            for (Account acc : accList) {
                if (acc.Assets != null && !acc.Assets.isEmpty()) {
                    assetList.addAll(acc.Assets);
                }
            }
        }
        return assetList;
    }

    private static List<NSP_Survey__c> extractSurveys( List<Account> accList ) {
        List<NSP_Survey__c> surveyList = new List<NSP_Survey__c>();
        if (accList != null) {
            for (Account acc : accList) {
                if (acc.Surveys__r != null && !acc.Surveys__r.isEmpty()) {
                    surveyList.addAll(acc.Surveys__r);
                }
            }
        }
        return surveyList;
    }

    private static VisualIndicatorWrapper createVisualIndicatorWrapper(
        List<NSP_Service_Exception__c> expList ,
        List<Asset> assetList ,
        List<NSP_Survey__c> surveyList
        )
    {
        VisualIndicatorWrapper accWrapper = new VisualIndicatorWrapper();
        if (expList != null) {
            checkServiceExceptions(expList, accWrapper);
        }
        if (assetList != null) {
            checkAssets(assetList, accWrapper);
        }
        if (surveyList != null) {
            checkSurveys(surveyList, accWrapper);
        }
        return accWrapper;
    }

    private static void checkServiceExceptions(
        List<NSP_Service_Exception__c> expList ,
        VisualIndicatorWrapper accWrapper
        )
    {
        if ( ( expList != null )
            && !expList.isEmpty()
            && ( accWrapper != null )
            )
        {
            for ( NSP_Service_Exception__c eachException : expList ) {
                if ( ( eachException.NSP_End_Date__c == null )
                    || ( eachException.NSP_End_Date__c >= Date.today() )
                    )
                {
                    accWrapper.serviceExceptionPresent = true;
                }
            }
        }
    }

    private static void checkAssets( List<Asset> assetList , VisualIndicatorWrapper accWrapper ) {
        if (assetList != null && !assetList.isEmpty() && accWrapper != null){
            for (Asset asset : assetList) {
                getAssets(asset,accWrapper);
            }
        }
    }

    private static void getAssets( Asset asset , VisualIndicatorWrapper accWrapper ) {
        Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
        String wsProductLine = 'Workforce Synchronization';
        if ( asset.RecordTypeId == woAssetRecordTypeId ) {
            accWrapper.assetPaperlessPresent = asset.NSP_Paperless__c;
            accWrapper.assetNationalAccount = asset.NSP_National_Account__c;
            if ( ( asset.NSP_Product_Line__c != null )
                && ( asset.NSP_Product_Line__c == wsProductLine )
                )
            {
                accWrapper.workSyncClientTrue = true;
            }
            // HRScale Indicator
            accWrapper.hrScale = asset.Is_HRScale__c;
        }
        if ( ( asset.NSP_Client_Retained_Workers_Comp__c != null )
            && ( asset.NSP_Client_Retained_Workers_Comp__c == '100% Client' )
            )
        {
            accWrapper.client100True = true;
        }
        if ( ( asset.NSP_Client_Retained_Workers_Comp__c != null )
            && ( asset.NSP_Client_Retained_Workers_Comp__c == 'Client & Insperity' )
            )
        {
            accWrapper.clientAndInsperity = true;
        }
        if ( asset.NSP_Pending_Termination__c ) {
            accWrapper.pendingTermination = true;
        }
        if ( asset.HRCore_Strategic_Partner__c ) {
            accWrapper.hrCoreStrategicPartner = true;
        }
    }

    private static void checkSurveys( List<NSP_Survey__c> surveyList , VisualIndicatorWrapper accWrapper ) {
        accWrapper.vocSurveyIndicator = false;
        if ( ( surveyList != null )
            && !surveyList.isEmpty()
            && ( surveyList[0].Survey_End_Date__c != null )
            )
        {
            Date surveyLimitDate = surveyList[0].Survey_End_Date__c.addDays( 180 );
            if ( Date.today().daysBetween( surveyLimitDate ) >= 0 ) {
                accWrapper.vocSurveyIndicator = true;
            }
        }
    }

    private static List<VisualIndicatorWrapper> wrapAccounts(
        List<Account> accList ,
        VisualIndicatorWrapper accWrapper
        )
    {
        List<VisualIndicatorWrapper> accWrapperList = new List<VisualIndicatorWrapper>();
        if (accList != null && accWrapper != null){
            for (Account acc : accList) {
                accWrapper.accRecord = acc;
                accWrapperList.add(accWrapper);
            }
        }
        return accWrapperList;
    }

    //
    // returns the account Id for the object that component is placed on(Case,Asset,Account)
    // @param accId Id related to object Id.
    // @return String
    //
    @AuraEnabled(cacheable=true)
    public static String getAccountId(String accId) {
        Id objectId = accId;
        Id accountId;
        SObjectType objectName = objectId.getSObjectType();
        if(String.valueOf(objectName) == 'Account'){
            accountId = accId;
        }else if(String.valueOf(objectName) == 'Asset'){
            Asset a = [SELECT Id,AccountId FROM Asset WHERE Id=:accId limit 1];
            accountId = a.AccountId;
        }else if(String.valueOf(objectName) == 'Case'){
            Case c = [SELECT Id,AccountId FROM Case WHERE Id=:accId limit 1];
            accountId = c.AccountId;
        } else if(String.valueOf(objectName) == 'Opportunity') {
            List<Opportunity> oppRecords = [SELECT ID, AccountId FROM Opportunity WHERE ID =:accId LIMIT 1];
            if(oppRecords != null && !oppRecords?.isEmpty() && oppRecords[0].AccountId != null) {
                accountId = oppRecords[0].AccountId;
            }
        }
        return accountId;
    }

    //
    // returns the caseRecordIdConfirmed(to confirm the recordId is a case and is created from Email-to-case) for the object that component is placed
    // @param caseId related to object Id.
    // @return Boolean
    //
    @AuraEnabled(cacheable=true)
    public static Boolean isCaseFromEmail( String caseId ) {
        Boolean emailToCaseConfirmed = false;
        // Check if the caseId is a Case record Id
        if ( String.isNotBlank( caseId )
            && ( caseId InstanceOf Id )
            && ( Id.valueOf( caseId ).getSObjectType() == Case.getSObjectType() )
            )
        {
            // Get Parent Case (if any) to allow OR condition on parent's email messages
            Id targetCaseId = Id.valueOf( caseId );
            List<Case> caseList = [
                SELECT Id , ParentId
                FROM Case
                WHERE ( Id = :targetCaseId )
                LIMIT 1
            ];
            // collect parent id values...
            Set<Id> parentIds = new Set<Id>();
            parentIds.add( targetCaseId );
            if ( !caseList.isEmpty()
                && ( caseList[0].ParentId != null )
                )
            {
                parentIds.add( caseList[0].ParentId );
            }
            // Check EmailMessage for both current Case and Parent Case
            List<EmailMessage> emailMessages = [
                SELECT Id
                FROM EmailMessage
                WHERE (
                    ( ParentId IN :parentIds )
                    AND ( Incoming = true )
                    AND ( EmailRoutingAddressId != null )
                )
                LIMIT 1
            ];
            // Return true if there are any incoming email messages related to the case/parent case
            if ( !emailMessages.isEmpty() ) {
                emailToCaseConfirmed = true;
            }
        }
        return emailToCaseConfirmed;
    }

    //
    // returns the account details wrapper for
    // @param
    // @return void
    //
    public class VisualIndicatorWrapper{
        @AuraEnabled
        public Account accRecord { get; set; }
        @AuraEnabled
        public Boolean serviceExceptionPresent { get; set; }
        @AuraEnabled
        public Boolean assetPaperlessPresent { get; set; }
        @AuraEnabled
        public Boolean assetNationalAccount { get; set; }
        @AuraEnabled
        public Boolean workSyncClientTrue { get; set; }
        @AuraEnabled
        public Boolean client100True { get; set; }
        @AuraEnabled
        public Boolean clientAndInsperity { get; set; }
        @AuraEnabled
        public Boolean pendingTermination { get; set; }
        @AuraEnabled
        public Boolean vocSurveyIndicator { get; set; }
        @AuraEnabled
        public Boolean hrScale { get; set; }
        @AuraEnabled
        public Boolean hrCoreStrategicPartner  { get; set; }
    }

}
//
