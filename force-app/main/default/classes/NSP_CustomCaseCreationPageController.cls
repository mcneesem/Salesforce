public with sharing class NSP_CustomCaseCreationPageController {
    // test w/ NSP_CustomCaseCreationPageControllerTest (80%)

    private static final String SERVICE_OPERATIONS = 'Service Operations';

    @AuraEnabled(cacheable=true)
    public static List<NSP_Category_Sub_Category_Mapping__c> getCategoryList( String recordTypeId , Boolean isCatViewAll ) {
        try {
            List<NSP_Category_Sub_Category_Mapping__c> lstCatMapping = new List<NSP_Category_Sub_Category_Mapping__c>();
            String userTitle = NSP_CustomCaseCreationPageController.getUserTitle();
            String caseRecType = NSP_CustomCaseCreationPageController.getCaseRecordType( recordTypeId );
            if ( String.isNotBlank( caseRecType ) ) {
                if ( caseRecType.contains( NSP_ServiceConstants.PEO ) ) {
                    caseRecType = NSP_ServiceConstants.PEO;
                } else if ( caseRecType.contains( NSP_ServiceConstants.BPS ) ) {
                    caseRecType = NSP_ServiceConstants.BPS;
                }
            }
            if ( String.isNotBlank( userTitle )
                && !isCatViewAll
                && NSP_CustomCaseCreationPageController.hasPermissionAdmin
                )
            {
                lstCatMapping = [
                    SELECT
                        Id , Name , NSP_Category__c , NSP_CategoryDescription__c ,
                        NSP_Subcategory__c , NSP_Display_confidential_popup__c ,
                        NSP_SubcategoryDescription__c , NSP_Detail__c , NSP_Version__c ,
                        NSP_DetailDescription__c , NSP_UserTitle__c , NSP_RecordType__c
                    FROM NSP_Category_Sub_Category_Mapping__c
                    WHERE (
                        ( NSP_RecordType__c = :caseRecType )
                        AND ( NSP_UserTitle__c INCLUDES ( :userTitle ) )
                        AND ( NSP_isActive__c = true )
                        AND ( NSP_Subcategory__c != :NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                        AND ( Id NOT IN :NSP_CustomCaseCreationPageController.restrictedFlsaMappingIds )
                    )
                    ORDER BY NSP_Category__c , NSP_Subcategory__c
                ];
            } else if ( String.isNotBlank( userTitle )
                && !isCatViewAll
                && !NSP_CustomCaseCreationPageController.hasPermissionAdmin
                )
            {
                lstCatMapping = [
                    SELECT
                        Id , Name , NSP_Category__c , NSP_CategoryDescription__c ,
                        NSP_Subcategory__c , NSP_Display_confidential_popup__c ,
                        NSP_SubcategoryDescription__c , NSP_Detail__c , NSP_Version__c ,
                        NSP_DetailDescription__c , NSP_UserTitle__c , NSP_RecordType__c
                    FROM NSP_Category_Sub_Category_Mapping__c
                    WHERE (
                        ( NSP_RecordType__c = :caseRecType )
                        AND ( NSP_UserTitle__c INCLUDES ( :userTitle ) )
                        AND ( NSP_isActive__c = true )
                        AND ( NSP_Subcategory__c != :NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                        AND ( Id NOT IN :NSP_CustomCaseCreationPageController.restrictedFlsaMappingIds )
                    )
                    ORDER BY NSP_Category__c , NSP_Subcategory__c
                ];
            } else if ( !NSP_CustomCaseCreationPageController.hasPermissionAdmin ) {
                lstCatMapping = [
                    SELECT
                        Id , Name , NSP_Category__c , NSP_CategoryDescription__c ,
                        NSP_Subcategory__c , NSP_Display_confidential_popup__c ,
                        NSP_SubcategoryDescription__c , NSP_Detail__c , NSP_Version__c ,
                        NSP_DetailDescription__c , NSP_UserTitle__c , NSP_RecordType__c
                    FROM NSP_Category_Sub_Category_Mapping__c
                    WHERE (
                        ( NSP_RecordType__c = :caseRecType )
                        AND ( NSP_isActive__c = true )
                        AND ( NSP_Subcategory__c != :NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                        AND ( Id NOT IN :NSP_CustomCaseCreationPageController.restrictedFlsaMappingIds )
                    )
                    ORDER BY NSP_Category__c , NSP_Subcategory__c
                ];
            } else {
                lstCatMapping = [
                    SELECT
                        Id , Name , NSP_Category__c , NSP_CategoryDescription__c ,
                        NSP_Subcategory__c , NSP_Display_confidential_popup__c ,
                        NSP_SubcategoryDescription__c , NSP_Detail__c , NSP_Version__c ,
                        NSP_DetailDescription__c , NSP_UserTitle__c , NSP_RecordType__c
                    FROM NSP_Category_Sub_Category_Mapping__c
                    WHERE (
                        ( NSP_RecordType__c = :caseRecType )
                        AND ( NSP_isActive__c = true )
                        AND ( NSP_Subcategory__c != :NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                        AND ( Id NOT IN :NSP_CustomCaseCreationPageController.restrictedFlsaMappingIds )
                    )
                    ORDER BY NSP_Category__c , NSP_Subcategory__c
                ];
            }
            lstCatMapping = NSP_CustomCaseCreationPageController.getFilteredCategorySubCategoryRecords( lstCatMapping );
            return lstCatMapping;
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    private static List<NSP_Category_Sub_Category_Mapping__c> getFilteredCategorySubCategoryRecords( List<NSP_Category_Sub_Category_Mapping__c> lstCatMapping ) {
        String categroyHrEmployeeRelations = 'HR Employee Relations';
        String subCategorySeparationAgreementRequest = 'Separation Agreement Request';
        Map<String,NSP_Category_Sub_Category_Mapping__c> filteredMap = new Map<String,NSP_Category_Sub_Category_Mapping__c>();
        if ( ( lstCatMapping != null ) && !lstCatMapping.isEmpty() ) {
            for ( NSP_Category_Sub_Category_Mapping__c mapping : lstCatMapping ) {
                Boolean isServiceOps = NSP_CustomCaseCreationPageController.SERVICE_OPERATIONS.equalsIgnoreCase( mapping.NSP_Category__c );
                Boolean isHRSeparationAgreement = (
                    categroyHrEmployeeRelations.equalsIgnoreCase( mapping.NSP_Category__c )
                    && subCategorySeparationAgreementRequest.equalsIgnoreCase( mapping.NSP_Subcategory__c )
                );
                if ( isServiceOps && NSP_CustomCaseCreationPageController.hasPermissionUseCaseCategoryServiceOperations ) {
                    filteredMap.put( mapping.Id , mapping );
                } else if ( !isServiceOps && !isHRSeparationAgreement ) {
                    filteredMap.put( mapping.Id , mapping );
                }
            }
        }
        return filteredMap.values();
    }

    private static Boolean hasPermissionUseCaseCategoryServiceOperations {
        private get {
            if ( hasPermissionUseCaseCategoryServiceOperations == null ) {
                hasPermissionUseCaseCategoryServiceOperations = CustomPermissionController.checkUserPermission(
                    'Use_Case_Category_Service_Operations' ,
                    UserInfo.getUserId()
                );
            }
            return hasPermissionUseCaseCategoryServiceOperations;
        }
        private set;
    }

    private static Boolean hasPermissionFLSA {
        private get {
            if ( hasPermissionFLSA == null ) {
                hasPermissionFLSA = CustomPermissionController.checkUserPermission(
                    'NSP_FLSA' ,
                    UserInfo.getUserId()
                );
            }
            return hasPermissionFLSA;
        }
        private set;
    }

    private static Set<Id> restrictedFlsaMappingIds {
        private get {
            if ( restrictedFlsaMappingIds == null ) {
                Set<Id> local = new Set<Id>();
                if ( !NSP_CustomCaseCreationPageController.hasPermissionFLSA
                    && ( NSP_CustomCaseCreationPageController.restrictedFlsaMappings != null )
                    && !NSP_CustomCaseCreationPageController.restrictedFlsaMappings.isEmpty()
                    )
                {
                    local = NSP_CustomCaseCreationPageController.restrictedFlsaMappings.keySet();
                }
                restrictedFlsaMappingIds = local;
            }
            return restrictedFlsaMappingIds;
        }
        private set;
    }

    // prevent DmlExceptions...
    // ~ See Validation Rule: Case.NSP_FLSA_Permission
    // ~ excluded combinations of NSP_Category__c/NSP_SubCategory__c for Users without the NSP_FLSA Custom Permission...
    private static Map<Id,NSP_Category_Sub_Category_Mapping__c> restrictedFlsaMappings {
        private get {
            if ( restrictedFlsaMappings == null ) {
                List<String> restrictedFlsaSubcategories = new List<String>();
                if ( String.isNotBlank( System.Label.NSP_FLSA_Case_Sub_Categories ) ) {
                    restrictedFlsaSubcategories = System.Label.NSP_FLSA_Case_Sub_Categories.split( ',' );
                }
                restrictedFlsaMappings = new Map<Id,NSP_Category_Sub_Category_Mapping__c>(
                    [
                        SELECT Id
                        FROM NSP_Category_Sub_Category_Mapping__c
                        WHERE (
                            ( NSP_Category__c = 'HR Admin Compliance - FLSA' )
                            AND ( NSP_Subcategory__c IN :restrictedFlsaSubcategories )
                        )
                        ORDER BY NSP_Category__c , NSP_Subcategory__c
                    ]
                );
            }
            return restrictedFlsaMappings;
        }
        private set;
    }

    @AuraEnabled
    public static string getUserTitle(){
        String userId = UserInfo.getUserId();
        try {
          String userTitle= [SELECT ID,Title,NSP_Curated_Picklist_Role__c FROM USER WHERE ID =:userId ].NSP_Curated_Picklist_Role__c;
            return UserTitle;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled
    public static String getInternalAccountId(){

        try {
            if(System.Label.NSP_InternalAccountName!= null && String.isNotBlank(System.Label.NSP_InternalAccountName)){
                return [SELECT ID FROM Account  WHERE Name =:System.Label.NSP_InternalAccountName LIMIT 1 ].Id;
            }
              return null;
          } catch (Exception excep) {
              throw new AuraHandledException(excep.getMessage());
          }
    }

    @AuraEnabled
    public static list<Contact> getContactParent(String idParent){
        try {
            return [SELECT Id, AccountId ,Account.NSP_AIMS_Client__c FROM Contact WHERE Id = :idParent WITH SECURITY_ENFORCED ];
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }
    @AuraEnabled
    public static list<Asset> getAssetParent(String idParent){
        try {
            return [SELECT Id, AccountId, NSP_RET_Education__c FROM Asset WHERE Id = :idParent WITH SECURITY_ENFORCED ];
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled
    public static ResponseWrapper getCaseFromConfig(String type,String accountId){
        try{
            List<NSP_Case_Configuration__mdt> lCaseConfigurations = new List<NSP_Case_Configuration__mdt>([SELECT Id,Label,NSP_Subject__c,NSP_User_Notes__c FROM NSP_Case_Configuration__mdt WHERE Label =: type LIMIT 1]);

            NSP_Case_Configuration__mdt oCaseConfig = new NSP_Case_Configuration__mdt();
            if(lCaseConfigurations.size() > 0){
                oCaseConfig = lCaseConfigurations[0];
            }else{
                return new ResponseWrapper(false,'','No Case Type Configuration Found');
            }
            accountId = (accountId == '') ? null : accountId;
            Case oCase = new NSP_CaseService().fillCaseBasedOnType(new Case(Type = type,AccountId = accountId));

            return new ResponseWrapper(true,JSON.serialize(new CaseConfigWrapper(oCase,oCaseConfig)),'');
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    public class CaseConfigWrapper{
        @AuraEnabled
        public Case oCase;
        @AuraEnabled
        public NSP_Case_Configuration__mdt oCaseConfig;
        public CaseConfigWrapper(Case oCase, NSP_Case_Configuration__mdt oCaseConfig){
            this.oCase = oCase;
            this.oCaseConfig = oCaseConfig;
        }
    }

    //Attachment part by Sruthi - Start
    /** @method saveFiles()
       * @desc Creates a content version from a given file's base64 and name and Converting attachments to Content Versions(Files) as part of DF-05467
       * @param {String} recordId - Id of the record you want to attach this file to
       * @param {list<Object>} filesToInsert - content type you want to attach this file to
       * @return {Id} - returns the created attachment  if the
       *   upload was successful, otherwise returns null
        *Modified Date : 8/21/2023 */

    @AuraEnabled
    public static void saveFiles( List<Object> filesToInsert , String recordId ) {
        try {
            List<ContentVersion> contVersionList = new List<ContentVersion>();
            List<ContentDocumentLink> contDocumentLinkList = new List<ContentDocumentLink>();
            ContentVersion cVersion;
            ContentDocumentLink cDocLink;
            //Getting files from nsp_customcasecreation lwc component
            for ( Object file : filesToInsert ) {
                FileInfo fileData = (FileInfo)JSON.deserialize( JSON.serialize( file ) , FileInfo.class );
                cVersion = createContVersion( fileData.Title , fileData.FileContent );
                contVersionList.add( cVersion );// Adding each ContentVersion to the ContentVersionList
            }
            if ( !contVersionList.isEmpty() ) {
                List<Database.SaveResult> conVersionResults = Database.insert( contVersionList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_CustomCaseCreationPageController.class.getName() ,
                    'saveFiles:ContentVersion' ,
                    conVersionResults
                );
                //Iterate over ContentVersion List to create ContentDocumentLink Object.
                for ( ContentVersion contVersion : [
                                SELECT ContentDocumentId
                                FROM ContentVersion
                                WHERE ( Id IN :contVersionList )
                            ]
                        )
                {
                    cDocLink = createContDocLink( contVersion.ContentDocumentId , recordId );
                    contDocumentLinkList.add( cDocLink );// Adding each ContentDocumentLink to the ContentDocumentLink List
                }
                if ( !contDocumentLinkList.isEmpty() ) {
                    List<Database.SaveResult> contDocResults = Database.insert( contDocumentLinkList , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_CustomCaseCreationPageController.class.getName() ,
                        'saveFiles:ContentDocumentLink' ,
                        contDocResults
                    );
                }
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    /*
     * Method Name : createContVersion
     * Description : This is a method creates a ContentVersion for the files
     * Return Type : ContentVersion
     * Params : String Title, Blob Content
     * Date : 8/22/2023
     * */
    public static ContentVersion createContVersion(String Title, Blob Content){
        ContentVersion contVers = new ContentVersion();
        contVers.ContentLocation = 'S';
        contVers.PathOnClient = Title;
        contVers.Origin = 'H';
        contVers.OwnerId = userinfo.getUserId();
        contVers.Title = Title;
        contVers.VersionData = Content;
        return contVers;
    }
    /*
     * Method Name : createContDocLink
     * Description : This is a method creates a ContentDocumentLink for the ContentVersions
     * Return Type : ContentDocumentLink
     * Params : Id ContDocId, Id recId
     * Date : 8/22/2023
     * */
    public static ContentDocumentLink createContDocLink(Id ContDocId, Id recId){
        ContentDocumentLink contDocLink = new ContentDocumentLink();
        contDocLink.ContentDocumentId = ContDocId;
        contDocLink.LinkedEntityId = recId;
        contDocLink.ShareType = 'V';
        contDocLink.Visibility = 'AllUsers';
        return contDocLink;
    }
    public class FileInfo {
        public String Title;
        public Blob FileContent;
        public String FileType;
    }

    @AuraEnabled(cacheable=true)
    public static List<NSP_Category_Sub_Category_Mapping__c> getAllCategoryList( String recordTypeId , String selectedCat ) {
        try {
            String caseRecType = NSP_CustomCaseCreationPageController.getCaseRecordType( recordTypeId );
            if ( String.isNotBlank( caseRecType ) ) {
                if ( caseRecType.contains( NSP_ServiceConstants.PEO ) ) {
                    caseRecType = NSP_ServiceConstants.PEO;
                } else if ( caseRecType.contains( NSP_ServiceConstants.BPS ) ) {
                    caseRecType = NSP_ServiceConstants.BPS;
                }
            }
            List<NSP_Category_Sub_Category_Mapping__c> lstCatMapping = new List<NSP_Category_Sub_Category_Mapping__c>();
            if ( String.isNotBlank( selectedCat ) ) {
                lstCatMapping = [
                    SELECT
                        Id , Name , NSP_Category__c , NSP_Version__c , NSP_CategoryDescription__c ,
                        NSP_Subcategory__c , NSP_Display_confidential_popup__c ,
                        NSP_SubcategoryDescription__c , NSP_Detail__c, NSP_DetailDescription__c ,
                        NSP_UserTitle__c , NSP_RecordType__c
                    FROM NSP_Category_Sub_Category_Mapping__c
                    WHERE (
                        ( NSP_RecordType__c = :caseRecType )
                        AND ( NSP_isActive__c = true )
                        AND ( NSP_Subcategory__c != :NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                        AND ( Id NOT IN :NSP_CustomCaseCreationPageController.restrictedFlsaMappingIds )
                        AND ( NSP_Category__c = :selectedCat )
                    )
                    ORDER BY NSP_Category__c , NSP_Subcategory__c
                ];
            } else {
                lstCatMapping = [
                    SELECT
                        Id , Name , NSP_Category__c , NSP_Version__c , NSP_CategoryDescription__c ,
                        NSP_Subcategory__c , NSP_Display_confidential_popup__c ,
                        NSP_SubcategoryDescription__c , NSP_Detail__c, NSP_DetailDescription__c ,
                        NSP_UserTitle__c , NSP_RecordType__c
                    FROM NSP_Category_Sub_Category_Mapping__c
                    WHERE (
                        ( NSP_RecordType__c = :caseRecType )
                        AND ( NSP_isActive__c = true )
                        AND ( NSP_Subcategory__c != :NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                        AND ( Id NOT IN :NSP_CustomCaseCreationPageController.restrictedFlsaMappingIds )
                    )
                    ORDER BY NSP_Category__c , NSP_Subcategory__c
                ];
            }
            lstCatMapping = NSP_CustomCaseCreationPageController.getFilteredCategorySubCategoryRecords( lstCatMapping );
            return lstCatMapping;
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    /**
    * Iterates throught all categories create a Dependencies map of Cat/SubCat/Detail/Version
    * @return Serialized From of CategoryDependenyWrapper
    */
    @AuraEnabled(Cacheable=true)
    public static string getAllDependenciesValues(String recordTypeId){
        try {
            List<NSP_Category_Sub_Category_Mapping__c> lCategoriesRecords = getAllCategoryList(recordTypeId, '');
            Set<String> sCategories = new Set<String>();
            Set<String> sSubcategories = new Set<String>();
            Set<String> sDetails = new Set<String>();
            Set<String> sVersions = new Set<String>();
            for(NSP_Category_Sub_Category_Mapping__c oCategoryMapping : lCategoriesRecords){
                if(String.isNotBlank(oCategoryMapping.NSP_Category__c)){
                    sCategories.add(oCategoryMapping.NSP_Category__c);
                }
                if(String.isNotBlank(oCategoryMapping.NSP_Subcategory__c)){
                    sSubcategories.add(oCategoryMapping.NSP_Subcategory__c);
                }
                if(String.isNotBlank(oCategoryMapping.NSP_Detail__c)){
                    sDetails.add(oCategoryMapping.NSP_Detail__c);
                }
                if(String.isNotBlank(oCategoryMapping.NSP_Version__c)){
                    sVersions.add(oCategoryMapping.NSP_Version__c);
                }
            }
            return JSON.serialize(new AllFieldsValueWrapper(sCategories,sSubcategories,sDetails,sVersions));
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    /**
    * Iterates throught all categories create a Dependencies map of Cat/SubCat/Detail/Version based on User Title
    * @return Serialized From of CategoryDependenyWrapper
    */
    @AuraEnabled(Cacheable=true)
    public static string getCategoryDependenciesMap(String recordTypeId, Boolean isCatViewAll){
        try {
            List<NSP_Category_Sub_Category_Mapping__c> lCategoriesRecords = getCategoryList(recordTypeId, isCatViewAll);
            return JSON.serialize(getDependencyWrapper(lCategoriesRecords));

        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    public static CategoryDependenyWrapper getDependencyWrapper(List<NSP_Category_Sub_Category_Mapping__c> lCategoiresRecords){
        Map<String,Set<String>> mCatToSubCatogoriesSet = new Map<String,Set<String>>();
        Map<String,Set<String>> mCatSubToDetailsSet = new Map<String,Set<String>>();
        Map<String,Set<String>> mCatSubDetailToVersionsSet = new Map<String,Set<String>>();
         List<string> detailListToSort = new List<string>();
        List<string> versionListToSort = new List<string>();
        for(NSP_Category_Sub_Category_Mapping__c oCatSubMapping : lCategoiresRecords){
            if(String.isNotBlank(oCatSubMapping.NSP_Category__c)){
                if(mCatToSubCatogoriesSet.get(oCatSubMapping.NSP_Category__c) != null){
                    mCatToSubCatogoriesSet.get(oCatSubMapping.NSP_Category__c).add(oCatSubMapping.NSP_Subcategory__c);
                }else{
                    mCatToSubCatogoriesSet.put(oCatSubMapping.NSP_Category__c,new Set<String>{oCatSubMapping.NSP_Subcategory__c});
                }
                if(String.isNotBlank(oCatSubMapping.NSP_Subcategory__c) && String.isNotBlank(oCatSubMapping.NSP_Detail__c)){
                    String catSubCat = oCatSubMapping.NSP_Category__c + '-' + oCatSubMapping.NSP_Subcategory__c;
                    if(mCatSubToDetailsSet.get(catSubCat) != null){
                        mCatSubToDetailsSet.get(catSubCat).add(oCatSubMapping.NSP_Detail__c);
                    }else{
                        mCatSubToDetailsSet.put(catSubCat,new Set<String>{oCatSubMapping.NSP_Detail__c});
                    }
                    if(String.isNotBlank(oCatSubMapping.NSP_Version__c)){
                        String catSubCatDet = oCatSubMapping.NSP_Category__c + '-' + oCatSubMapping.NSP_Subcategory__c + '-' + oCatSubMapping.NSP_Detail__c;
                        if(mCatSubDetailToVersionsSet.get(catSubCatDet) != null){
                            mCatSubDetailToVersionsSet.get(catSubCatDet).add(oCatSubMapping.NSP_Version__c);
                        }else{
                            mCatSubDetailToVersionsSet.put(catSubCatDet,new Set<String>{oCatSubMapping.NSP_Version__c});
                        }
                    }
                }
            }
        }
        Map<String,List<String>> mCatToSubCatogories = new Map<String,List<String>>();
        Map<String,List<String>> mCatSubToDetails = new Map<String,List<String>>();
        Map<String,List<String>> mCatSubDetailToVersions = new Map<String,List<String>>();

        for(String category : mCatToSubCatogoriesSet.keySet()){
            mCatToSubCatogories.put(category,new List<String>(mCatToSubCatogoriesSet.get(category)));
        }
        for(String catSubcategory : mCatSubToDetailsSet.keySet()){
            detailListToSort = new List<String>(mCatSubToDetailsSet.get(catSubcategory));
            detailListToSort.sort();
            mCatSubToDetails.put(catSubcategory, detailListToSort);
        }
        for(String catSubCatDet : mCatSubDetailToVersionsSet.keySet()){
            versionListToSort = new List<String>(mCatSubDetailToVersionsSet.get(catSubCatDet));
            versionListToSort.sort();
            mCatSubDetailToVersions.put(catSubCatDet, versionListToSort);
        }
        return new CategoryDependenyWrapper(mCatToSubCatogories, mCatSubToDetails, mCatSubDetailToVersions);
    }

    public class CategoryDependenyWrapper{
        @AuraEnabled
        public Map<String,List<String>> mCatToSubCatogories;
        @AuraEnabled
        public Map<String,List<String>> mCatSubToDetails;
        @AuraEnabled
        public Map<String,List<String>> mCatSubDetailToVersions;
        public CategoryDependenyWrapper(Map<String,List<String>> mCatToSubCatogories,Map<String,List<String>> mCatSubToDetails,Map<String,List<String>> mCatSubDetailToVersions){
            this.mCatToSubCatogories = mCatToSubCatogories;
            this.mCatSubToDetails= mCatSubToDetails;
            this.mCatSubDetailToVersions = mCatSubDetailToVersions;
        }
    }
    public class AllFieldsValueWrapper{
        @AuraEnabled
        public List<String> sCategories;
        @AuraEnabled
        public List<String> sSubCategories;
        @AuraEnabled
        public List<String> sDetails;
        @AuraEnabled
        public List<String> sVersions;
        public AllFieldsValueWrapper(Set<String> sCategories,Set<String> sSubCategories,Set<String> sDetails,Set<String> sVersions){
            this.sCategories = new List<String>(sCategories);
            this.sSubCategories = new List<String>(sSubCategories);
            this.sDetails = new List<String>(sDetails);
            this.sVersions = new List<String>(sVersions);
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<String> getRelatedCategory(String selectedRole, String recordTypeId) {
        try{
            List<String> filteredCategories = new List<String>();
            Set<String> filteredCategoriesSet = new Set<String>();
            for(NSP_Category_Sub_Category_Mapping__c relatedRecord : getAllCategoryList(recordTypeId, '')){
                if(relatedRecord.NSP_UserTitle__c != selectedRole){
                    filteredCategoriesSet.add(relatedRecord.NSP_Category__c);
                }
            }
            filteredCategories = new List<String>(filteredCategoriesSet);
            return filteredCategories;
        }catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
    }

        /**
 * @method getRelatedCategory()
 * @param {String} selectedCategory
 * @param {String} recordTypeId
 * @return List<String>
 * */
@AuraEnabled(cacheable = true)
public static List < String > getRelatedSubCategory(String selectedCategory, String recordTypeId, Boolean isviewAllSubCat) {
    try{
        List < String > filteredSubCategories = new List < String > ();
        Set < String > filteredSubCategoriesSet = new Set < String > ();
        for (NSP_Category_Sub_Category_Mapping__c relatedRecord: getAllCategoryList(recordTypeId, selectedCategory)) {
            if (relatedRecord.NSP_Category__c == selectedCategory && !isviewAllSubCat) {
                filteredSubCategoriesSet.add(relatedRecord.NSP_Subcategory__c);
            }else{
                filteredSubCategoriesSet.add(relatedRecord.NSP_Subcategory__c);
            }
        }
        filteredSubCategories = new List < String > (filteredSubCategoriesSet);
        filteredSubCategories.sort();
        return filteredSubCategories;
    }catch(Exception excep){
        throw new AuraHandledException(excep.getMessage());
    }
}

    @AuraEnabled(cacheable=true)
    public static List<String> getRelatedDetail(String selectedSubCategory, String selectedCategory, String recordTypeId) {
        try{
            List<String> filteredDetails = new List<String>();
            Set<String> filteredDetailsSet = new Set<String>();
            for(NSP_Category_Sub_Category_Mapping__c relatedRecord : getAllCategoryList(recordTypeId, '')){
                                if(relatedRecord.NSP_Category__c + '-' + relatedRecord.NSP_Subcategory__c == selectedCategory + '-' +selectedSubCategory){
                    filteredDetailsSet.add(relatedRecord.NSP_Detail__c);
                }
            }
            filteredDetails = new List<String>(filteredDetailsSet);
            filteredDetails.sort();
            return filteredDetails;
        }catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getRelatedVersion(String selectedDetail, String recordTypeId) {
        try{
            List<String> filteredVersions = new List<String>();
            Set<String> filteredVersionsSet = new Set<String>();
            for(NSP_Category_Sub_Category_Mapping__c relatedRecord : getAllCategoryList(recordTypeId, '')){
                if(relatedRecord.NSP_Detail__c == selectedDetail){
                    filteredVersionsSet.add(relatedRecord.NSP_Version__c);
                }
            }
            filteredVersions = new List<String>(filteredVersionsSet);
            filteredVersions.sort();
            return filteredVersions;
        }catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
    }

    // @description Populates Asset on Case based on category, subcategory, and account.
    // @param category Category selected on Case creation.
    // @param subCategory Subcategory selected on Case creation.
    // @param accountId Id of the Account on the Case.
    // @return Active Asset, or most recently terminated Asset, or null.
    @AuraEnabled
    public static List<Asset> autoPopulateAsset( String category , String subCategory , String accountId ) {
        List<Asset> response = null;
        if ( String.isNotBlank( category ) && String.isNotBlank( subCategory ) ) {
            List<NSP_Category_Sub_Category_Mapping__c> mappings = queryCategorySubCategoryMapping( category , subCategory );
            if ( String.isNotBlank( accountId ) && mappings != null && !mappings.isEmpty() ) {
                String assetRecordTypeName = mappings[0].NSP_Asset_Record_Types__c;
                response = queryActiveAssets( accountId , assetRecordTypeName );
                if ( response == null || response.isEmpty() ) {
                    response = queryMostRecentTerminatedAsset( accountId , assetRecordTypeName );
                }
            }
        }
        return response;
    }

    // @description Queries category/subcategory mapping records for asset record type resolution.
    // @param category Category value to filter.
    // @param subCategory Subcategory value to filter.
    // @return Matching NSP_Category_Sub_Category_Mapping__c records.
    private static List<NSP_Category_Sub_Category_Mapping__c> queryCategorySubCategoryMapping(
        String category ,
        String subCategory
        )
    {
        return [
            SELECT
                Id , Name , NSP_Category__c ,
                NSP_Subcategory__c , NSP_Asset_Record_Types__c ,
                NSP_UserTitle__c , NSP_RecordType__c
            FROM NSP_Category_Sub_Category_Mapping__c
            WHERE (
                ( NSP_Category__c = :category )
                AND ( NSP_Subcategory__c = :subCategory )
            )
        ];
    }

    // @description Queries active (non-terminated, non-backout) assets for an account and record type.
    // @param accountId Account Id to filter.
    // @param assetRecordTypeName Asset record type name to filter.
    // @return Matching active Asset records.
    private static List<Asset> queryActiveAssets( String accountId , String assetRecordTypeName ) {
        return [
            SELECT Id , AccountId , RecordTypeId , RecordType.Name , Status
            FROM Asset
            WHERE (
                ( AccountId = :accountId )
                AND ( RecordType.Name = :assetRecordTypeName )
                AND (
                    Status NOT IN (
                        :NSP_ServiceConstants.TERMINATED ,
                        :NSP_ServiceConstants.BACKOUT
                    )
                )
            )
        ];
    }

    // @description Queries the most recently terminated asset for an account and record type.
    // @param accountId Account Id to filter.
    // @param assetRecordTypeName Asset record type name to filter.
    // @return Single most recently terminated Asset, or empty list.
    private static List<Asset> queryMostRecentTerminatedAsset( String accountId , String assetRecordTypeName ) {
        return [
            SELECT Id , AccountId , RecordTypeId , RecordType.Name , Status , NSP_Termination_Date__c
            FROM Asset
            WHERE (
                ( AccountId = :accountId )
                AND ( RecordType.Name = :assetRecordTypeName )
                AND ( NSP_Account_Status__c = :NSP_ServiceConstants.TERMINATED )
            )
            ORDER BY NSP_Termination_Date__c DESC NULLS LAST , LastModifiedDate DESC
            LIMIT 1
        ];
    }

    // @method getCaseRecordType()
    // @desc Fetch case record type name based on record type id passed or logged in user profile
    // @param {String} recordId - Record type Id of the case created
    // @return {String} - returns case record type name
    @AuraEnabled
    public static string getCaseRecordType( String recordTypeId ) {
        try {
            String response = null;
            //fetch case recordtype name based on recordtypeid selected on creation of case
            if ( String.isNotBlank( recordTypeId ) ) {
                List<RecordType> records = [
                    SELECT Id , Name
                    FROM RecordType
                    WHERE ( Id = :recordTypeId )
                ];
                if ( ( records != null ) && !records.isEmpty() ) {
                    response = records[0].Name;
                }
            } else {
                //if recordtypeid is null fetch case record type name based on logged in user profile id
                if ( ( NSP_CustomCaseCreationPageController.userInfoProfileName == NSP_ServiceConstants.PEOSERVICE )
                    || ( NSP_CustomCaseCreationPageController.userInfoProfileName == NSP_ServiceConstants.CONTACTCENTER )
                    || ( NSP_CustomCaseCreationPageController.userInfoProfileName == NSP_ServiceConstants.RT )
                    )
                {
                    response = NSP_ServiceConstants.PEO;
                }
                if ( ( NSP_CustomCaseCreationPageController.userInfoProfileName == NSP_ServiceConstants.BPSSERVICE )
                    || ( NSP_CustomCaseCreationPageController.hasPermissionAdmin )
                    )
                {
                    response = NSP_ServiceConstants.BPS;
                }
            }
            return response;
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    // @method isContactHasMultipleACRs()
    // @desc method to check whether the selected Contact has Muliple ACRs
    // @param {String} contId - Selected ContactId
    // @return {Boolean} - returns true or false based on Mulple ACRs
    @AuraEnabled
    public static Boolean isContactHasMultipleACRs( String contId ) {
        try {
            List<AccountContactRelation> acrList = [
                SELECT Id , AccountId , ContactId
                FROM AccountContactRelation
                WHERE ( ContactId = :contId )
            ];
            return ( ( acrList != null ) && ( acrList.size() > 1 ) );
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    //
    // @MethodName: getProfileName
    // @Description: This method describes to fetch the profile Name of loggedin User
    // @param :
    // @createdDate : 11/24/2022
    // @Story : STY-03083
    // @return void
    //
    @AuraEnabled
    public static String getProfileName() {
        try {
            return NSP_CustomCaseCreationPageController.userInfoProfileName;
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    private static String userInfoProfileName {
        private get {
            if ( userInfoProfileName == null ) {
                String local = null;
                List<Profile> records = [
                    SELECT Id , Name
                    FROM Profile
                    WHERE ( Id = :Userinfo.getProfileid() )
                ];
                Profile record = null;
                if ( ( records != null ) && !records.isEmpty() ) {
                    record = records[0];
                }
                if ( record != null ) {
                    local = record.Name;
                }
                userInfoProfileName = local;
            }
            return userInfoProfileName;
        }
        private set;
    }

    private static Boolean hasPermissionAdmin {
        private get {
            if ( hasPermissionAdmin == null ) {
                hasPermissionAdmin = (
                    String.isNotBlank( NSP_CustomCaseCreationPageController.userInfoProfileName )
                    && NSP_CustomCaseCreationPageController.userInfoProfileName.startsWith( 'System Admin' )
                );
            }
            return hasPermissionAdmin;
        }
        private set;
    }

    /**
* @MethodName: isMemberOfPrivateSection125Visibility
* @Description: This method describes to show private checkbox if the category is "H&W Section 125" and the loggedinUser in
NSP_Private_Section_125_Visibility public group
* @param :
* @createdDate : 11/29/2022
* @Story : STY-02804
* @return void
*/
@AuraEnabled
public static Boolean isMemberOfPrivateSection125Visibility(){
    Set<Id> grpUserIdSet = new Set<Id>();
    Boolean isShowPrivateCheckbox = false;
    try{
        for(GroupMember gMem : [SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName =: NSP_ServiceConstants.SECTION_125_PRIVATE_CASE_VISIBILTY]){
            grpUserIdSet.add(gMem.UserOrGroupId);
        }
        if(!grpUserIdSet.isEmpty() && grpUserIdSet.contains(userInfo.getUserId())){
            isShowPrivateCheckbox = true;
        }
        return isShowPrivateCheckbox;
    }catch (Exception excep) {
        throw new AuraHandledException(excep.getMessage());
    }
}

    /**
* @MethodName: getMapOfObjectNameAndKeyPrefix
* @Description: This method is used to get the object name and it's key prefix to use while the record to it's respective parent
* @param :
* @createdDate : 04/14/2023
* @Story : DF-03341
* @return void
*/
    @AuraEnabled
    public static Map<String, String> getMapOfObjectNameAndKeyPrefix(){
        Map<string, string> objectNameKeyPrefixMap = new Map<string, string>();

        try{
            String accountKeyPrefix = Account.SObjectType.getDescribe().getKeyPrefix(); // Account
            objectNameKeyPrefixMap.put('accountID', accountKeyPrefix);

            String contactKeyPrefix = Contact.SObjectType.getDescribe().getKeyPrefix(); // Contact
            objectNameKeyPrefixMap.put('contactID', contactKeyPrefix);

            String assetKeyPrefix = Asset.SObjectType.getDescribe().getKeyPrefix(); // Asset
            objectNameKeyPrefixMap.put('assetId', assetKeyPrefix);

            String projectKeyPrefix = pse__Proj__c.SObjectType.getDescribe().getKeyPrefix(); // Project
            objectNameKeyPrefixMap.put('projectId', projectKeyPrefix);

            String parentCaseKeyPrefix = Case.SObjectType.getDescribe().getKeyPrefix(); // ParentCase
            objectNameKeyPrefixMap.put('caseParentId', parentCaseKeyPrefix);

            String caseIssueKeyPrefix = NSP_Case_Issue__c.SObjectType.getDescribe().getKeyPrefix(); // caseIssue
            objectNameKeyPrefixMap.put('caseIssueId', caseIssueKeyPrefix);

            String planKeyPrefix = NSP_Plan__c.SObjectType.getDescribe().getKeyPrefix(); // Plan
            objectNameKeyPrefixMap.put('planID', planKeyPrefix);

            String planSubPlanKeyPrefix = NSP_Plan_SubPlan__c.SObjectType.getDescribe().getKeyPrefix(); // Sub Plan
            objectNameKeyPrefixMap.put('subplanID', planSubPlanKeyPrefix);

            String amendmentCheckListKeyPrefix = NSP_Amendment_Checklist__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Amendment_Checklist__c
            objectNameKeyPrefixMap.put('NSP_RET_Amendment_Checklist__c', amendmentCheckListKeyPrefix);

            String salesToImplKeyPrefix = NSP_Sales_to_Implementation__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Sales_to_Implementation__c
            objectNameKeyPrefixMap.put('NSP_RET_Sales_to_Implementation__c', salesToImplKeyPrefix);

            String monthlyParticipationKeyPrefix = NSP_Participation_SaaS_Activity__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Participation_SaaS_Activity__c
            objectNameKeyPrefixMap.put('NSP_RET_Monthly_Participation__c', monthlyParticipationKeyPrefix);

            String eoyAmendmentKeyPrefix = NSP_EOY_Amendment__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_EOY_Amendment__c
            objectNameKeyPrefixMap.put('NSP_RET_EOY_Amendments__c', eoyAmendmentKeyPrefix);

            String complianceKeyPrefix = NSP_Compliance__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Compliance__c
            objectNameKeyPrefixMap.put('NSP_RET_Compliance__c', complianceKeyPrefix);

            String cgndqKeyPrefix = NSP_CGNDQ__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_CGNDQ__c
            objectNameKeyPrefixMap.put('NSP_RET_CGNDQ__c', cgndqKeyPrefix);

            String planTrackingPrefix = NSP_5500_Plan_Tracking__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_5500_Plan_Tracking__c
            objectNameKeyPrefixMap.put('NSP_RET_5500_Plan_Tracking__c', planTrackingPrefix);

            String eligibilityKeyPrefix = NSP_Eligibility__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Eligibility__c
            objectNameKeyPrefixMap.put('NSP_RET_Eligibility__c', eligibilityKeyPrefix);

            String deconversionKeyPrefix = NSP_Deconversion__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Deconversion__c
            objectNameKeyPrefixMap.put('NSP_RET_Deconversion__c', deconversionKeyPrefix);

            String contributionKeyPrefix = NSP_Contribution__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Contribution__c
            objectNameKeyPrefixMap.put('NSP_RET_Contribution__c', contributionKeyPrefix);

            String clinetSubPlanHistoryKeyPrefix = NSP_Client_Sub_Plan_History__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Client_Sub_Plan_History__c
            objectNameKeyPrefixMap.put('NSP_RET_Client_Sub_Plan_History__c', clinetSubPlanHistoryKeyPrefix);

            String clientChangeFieldsKeyPrefix = NSP_Client_Change_Fields__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Client_Change_Fields__c
            objectNameKeyPrefixMap.put('NSP_RET_Client_Change__c', clientChangeFieldsKeyPrefix);

            String subPlanChangeHisKeyPrefix = NSP_Sub_Plan_Change_History__c.SObjectType.getDescribe().getKeyPrefix(); // NSP_Sub_Plan_Change_History__c
            objectNameKeyPrefixMap.put('NSP_RET_Sub_Plan_Change_History__c', subPlanChangeHisKeyPrefix);

            return objectNameKeyPrefixMap;
        }catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean getCaseSettingFlag() {
        return CustomCaseCreationSettings__c.getInstance(UserInfo.getProfileId()).IsReloadEnabled__c;
    }
    @AuraEnabled(cacheable=true)
    public static Boolean isUserInQueue() {
        Boolean userInQueue = false;
        String queueName = 'Compensation_Services';
        if(String.isNotBlank(queueName)){
          List<GroupMember> groupMemberList = [Select Id from GroupMember where UserOrGroupId = :UserInfo.getUserId() AND GroupId IN (SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName=:queueName)];
            if(!groupMemberList.isEmpty()){
                userInQueue = true;
            }
        }
        return userInQueue;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(String accountId) {
        List<Contact> contacts = new List<Contact>();
        try {
            if (!String.isBlank(accountId)) {
                List<AccountContactRelation> acrs = [
                    SELECT ContactId
                    FROM AccountContactRelation
                    WHERE ( AccountId = :accountId )
                    WITH SECURITY_ENFORCED
                ];
                if (!acrs.isEmpty()) {
                    Set<Id> contactIds = new Set<Id>();
                    for (AccountContactRelation acr : acrs) {
                        contactIds.add(acr.ContactId);
                    }
                    contacts = [
                        SELECT Id , Name
                        FROM Contact
                        WHERE ( Id IN :contactIds )
                        ORDER BY Name ASC
                    ];
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return contacts;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountContactRelation> getRelatedAccounts(String contactId) {
        List<AccountContactRelation> acrs = new List<AccountContactRelation>();
        try {
            if (!String.isBlank(contactId)) {
                acrs = [
                    SELECT AccountId , Account.Name , NSP_Is_Primary__c
                    FROM AccountContactRelation
                    WHERE ( ContactId = :contactId )
                    ORDER BY NSP_Is_Primary__c DESC , Account.Name ASC
                ];
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return acrs;
    }

}
//