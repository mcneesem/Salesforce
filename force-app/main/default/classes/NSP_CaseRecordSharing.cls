/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  October 18, 2022                                                             
Function             :  Represents the NSP_CaseRecordSharing which handles all the logic that is related case sharing based on category/SubCategory Mapping public group field.
Test class           :  NSP_CaseRecordSharingTest
Story                : STY-03293                                                                      
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
***************************************************************************************************/
public class NSP_CaseRecordSharing {
    // test w/ NSP_CaseRecordSharingTest (85%)

    private static Map<String,Id> grpNameGrpIdMap = new Map<String,Id>();
    private static Map<String,List<String>> catSubCatGroupNamesMap = new Map<String,List<String>>();
    private static Map<String,List<String>> catSubCatDetailGroupNamesMap = new Map<String,List<String>>();
    private static List<String> fields = new List<String>{
        'Id' ,
        'Type' ,
        'DeveloperName'
    };

    //
    // @MethodName: shareCaseOnUpdate
    // @Description: This method describes about Sharing of case to public group based on category/SubCategory Mapping.
    // @param : List<Case> caseList
    // @createdDate : 10/18/2022
    // @Story : STY-03293
    // @return void
    //
    public static void shareCaseOnUpdate( List<Case> caseList , Boolean onAfterUpdate , Set<String> categorySet , Set<String> subCatSet ) {
        try {
            getMapOfCatSubCatPublicGrps( caseList , categorySet , subCatSet );
            getGrpNameAndGrpId( caseList );
            if ( onAfterUpdate ) {
                removeSharingOnCaseUpdate( caseList );
            }
            sharingOnCaseUpdate( caseList );
        } catch ( Exception e ) {
            NSP_CaseRecordSharing.handleException( e , 'shareCaseOnUpdate' );
        }
    }

    /**
* @MethodName: shareCaseOnUpdate
* @Description: This method describes about removing Sharing of case.
* @param : List<Case> caseList
* @createdDate : 10/18/2022
* @Story : STY-03293
* @return void                          
*/
    public static void removeSharingOnCaseUpdate(List<Case> caseList){
        try{
            List < CaseShare > oldCaseShare = [SELECT Id,UserOrGroupId FROM CaseShare 
                                               WHERE RowCause =: NSP_ServiceConstants.manualRowCause AND 
                                               CaseId IN: caseList];
            if (!oldCaseShare.isEmpty()) {
                delete oldCaseShare;
            }
        } catch ( Exception e ) {
            NSP_CaseRecordSharing.handleException( e , 'removeSharingOnCaseUpdate' );
        }
    }

    /**
* @MethodName: sharingOnCaseUpdate
* @Description:  This method describes about Sharing of case to public group based on Category..
* @param : List<Case> caseList
* @createdDate : 10/18/2022
* @Story : STY-03293
* @return void                          
*/
    public static void sharingOnCaseUpdate(List<Case> caseList){ 
        List < CaseShare > caseShareInsertionList = new List < caseShare > ();
        CaseShare cseShare ;
        try{
            if(!catSubCatGroupNamesMap.isEmpty() && !grpNameGrpIdMap.isEmpty()){
            for (Case cse: caseList) {
                List<string> getGrpList = cse.NSP_Detail__c != null ? catSubCatDetailGroupNamesMap.get(cse.NSP_Category__c+';'+cse.NSP_SubCategory__c+ ';' + cse.NSP_Detail__c)
                   													 : catSubCatGroupNamesMap.get(cse.NSP_Category__c+';'+cse.NSP_SubCategory__c);
                for(String grp : getGrpList){
                     cseShare = new CaseShare();
                    cseShare = createCaseShareRecord(grpNameGrpIdMap.get(grp), cse.Id);
                    caseShareInsertionList.add(cseShare);
                }
            }
        }
            if(!caseShareInsertionList.isEmpty()){
                database.insert(caseShareInsertionList);
            }
        } catch ( Exception e ) {
            NSP_CaseRecordSharing.handleException( e , 'sharingOnCaseUpdate' );
        }
    }

    /**
* @MethodName: sharePrivateCases
* @Description:  This method describes about Sharing of case to public group based on NSP_Private__c checkbox.
* @param : List<Case> caseList
* @createdDate : 11/29/2022
* @Story : STY-02804
* @return void                          
*/
    public static void sharePrivateCases(List<Case> caseList){ 
        List < CaseShare > caseShareInsertionList = new List < caseShare > ();
        CaseShare cseShare ;
        try{
            Id  privateSection125VisibilityGrpId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SECTION_125_PRIVATE_CASE_VISIBILTY, fields).Id;
            for (Case cse: caseList) {
                cseShare = new CaseShare();
                cseShare = createCaseShareRecord(privateSection125VisibilityGrpId, cse.Id);
                caseShareInsertionList.add(cseShare);
            }
            if(!caseShareInsertionList.isEmpty()){
                database.insert(caseShareInsertionList);
            }
        } catch ( Exception e ) {
            NSP_CaseRecordSharing.handleException( e , 'sharePrivateCases' );
        }
    }

    //
    // @MethodName: getGrpNameAndGrpId
    // @Description:  This method describes about getting groupName and GroupId based on Category.
    // @param : List<Case> caseList
    // @createdDate : 10/18/2022
    // @Story : STY-03293
    // @return void
    //
    public static void getGrpNameAndGrpId( List<Case> cseList ) {
        NSP_CaseRecordSharing.grpNameGrpIdMap = new Map<String,Id>();
        if ( ( cseList != null ) && !cseList.isEmpty() ) {
            List<String> getGrpList = new List<String>();
            for ( Case cse : [
                        SELECT Id , NSP_Category__c , NSP_SubCategory__c,NSP_Detail__c
                        FROM Case
                        WHERE ( Id IN :cseList )
                    ]
                )
            {
                List<String> temp = NSP_CaseRecordSharing.getGroupNamesHelper( cse );
                if ( ( temp != null ) && !temp.isEmpty() ) {
                    getGrpList.addAll( temp );
                }
            }
            for ( group grp : [
                        SELECT Id , Name
                        FROM Group
                        WHERE ( Name IN :getGrpList )
                    ]
                )
            {
                NSP_CaseRecordSharing.grpNameGrpIdMap.put( grp.Name , grp.Id );
            }
        }
    }

    private static List<string> getGroupNamesHelper( Case caseRec ) {
        List<string> groupNames = new List<string>();
        if ( caseRec != null ) {
            if ( String.isNotBlank( caseRec.NSP_Detail__c ) ) {
                String key = ''
                    + caseRec.NSP_Category__c
                    + ';'
                    + caseRec.NSP_SubCategory__c
                    + ';'
                    + caseRec.NSP_Detail__c
                    ;
                if ( ( NSP_CaseRecordSharing.catSubCatDetailGroupNamesMap != null )
                    && NSP_CaseRecordSharing.catSubCatDetailGroupNamesMap.containsKey( key )
                    && ( NSP_CaseRecordSharing.catSubCatDetailGroupNamesMap.get( key ) != null )
                    )
                {
                    groupNames = NSP_CaseRecordSharing.catSubCatDetailGroupNamesMap.get( key );
                }
            } else {
                String key = ''
                    + caseRec.NSP_Category__c
                    + ';'
                    + caseRec.NSP_SubCategory__c
                    ;
                if ( ( NSP_CaseRecordSharing.catSubCatGroupNamesMap!= null )
                    && NSP_CaseRecordSharing.catSubCatGroupNamesMap.containsKey( key )
                    && ( NSP_CaseRecordSharing.catSubCatGroupNamesMap.get( key ) != null )
                    )
                {
                    groupNames = NSP_CaseRecordSharing.catSubCatGroupNamesMap.get( key );
                }
            }
        }
        return groupNames;
    }

        /**
* @MethodName: getMapOfCatSubCatPublicGrps
* @Description:  This method describes about mapping of public groups based on combination of Category and SubCategory.
* @param : List<Case> cseList, Set<String> categorySet, Set<String> subCatSet 
* @createdDate : 10/18/2022
* @Story : STY-03293
* @return void                           
*/  
    public static void getMapOfCatSubCatPublicGrps( List<Case> cseList , Set<String> categorySet , Set<String> subCatSet ) {
        catSubCatGroupNamesMap = new Map<String,List<String>>();
        catSubCatDetailGroupNamesMap = new Map<String,List<String>>();
        for(NSP_Category_Sub_Category_Mapping__c catSubCatMapping : [SELECT Id, NSP_Category__c, NSP_Subcategory__c, 
                                                                     NSP_Public_Groups_To_Share__c,
                                                                     NSP_Detail__c
                                                                     FROM NSP_Category_Sub_Category_Mapping__c 
                                                                     WHERE NSP_Category__c IN: categorySet 
                                                                     AND NSP_Subcategory__c IN: subCatSet
                                                                     AND NSP_Public_Groups_To_Share__c != null]){
                                                                         catSubCatDetailGroupNamesMap.put(catSubCatMapping.NSP_Category__c+';'+catSubCatMapping.NSP_Subcategory__c+';'+catSubCatMapping.NSP_Detail__c, catSubCatMapping.NSP_Public_Groups_To_Share__c.split(';'));
                                                                          catSubCatGroupNamesMap.put(catSubCatMapping.NSP_Category__c+';'+catSubCatMapping.NSP_Subcategory__c, catSubCatMapping.NSP_Public_Groups_To_Share__c.split(';'));
                                                                     }
    }

    /**
	* @MethodName: shareMigratedCase
	* @Description:  This method describes about mapping of public groups based on combination of Category and SubCategory.
	* @param : List<Case> cseList, Set<String> categorySet, Set<String> subCatSet 
	* @createdDate : 11/25/2022
	* @Story : STY-02204
	* @return void                           
	*/
    
    public static void shareMigratedCase (List<Case> migratedCaseList, Set<String> categorySet, Set<String> subCatSet){
        
        List<String> categoryList = new List<String>();
        List < CaseShare > caseShareInsertionList = new List < caseShare > ();
        CaseShare cseShare ;

        try{
            if(!categorySet.isEmpty() ){
                for(NSP_Category_Sub_Category_Mapping__c catSubCatMapping : [SELECT Id, NSP_Category__c, NSP_Subcategory__c, 
                                                                            NSP_Public_Groups_To_Share__c,
                                                                            NSP_Detail__c
                                                                            FROM NSP_Category_Sub_Category_Mapping__c 
                                                                            WHERE NSP_Category__c in :categorySet 
                                                                            AND NSP_Subcategory__c in : subCatSet
                                                                            AND NSP_Public_Groups_To_Share__c = null]){
                                                                             categoryList.add(catSubCatMapping.NSP_Category__c+'_'+catSubCatMapping.NSP_Subcategory__c);
                                                                         }
                Id  groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.ALL_DATA_GROUP, fields).Id;
                
                for(Case migrateCase :migratedCaseList ){
                    cseShare = new CaseShare();
                    if(categoryList.contains(migrateCase.NSP_Category__c+'_'+migrateCase.NSP_SubCategory__c)){
                        cseShare = createCaseShareRecord(groupId, migrateCase.Id); 
                        caseShareInsertionList.add(cseShare);
                    }
                }
                if(!caseShareInsertionList.isEmpty()){
                	database.insert(caseShareInsertionList);
            	}
            }
        } catch ( Exception e ) {
            NSP_CaseRecordSharing.handleException( e , 'shareMigratedCase' );
        }
    }

    //
    // @MethodName: createCaseShareRecord
    // @Description:  This method describes about creating caseShareInstance.
    // @createdDate : 10/18/2022
    // @Story : STY-03293
    // @return void
    //
    public static caseShare createCaseShareRecord( String userOrGrpId , String recordId ) {
        CaseShare newCaseShare = new CaseShare();
        newCaseShare.RowCause = NSP_ServiceConstants.manualRowCause;
        newCaseShare.UserOrGroupId = userOrGrpId;
        newCaseShare.caseAccessLevel = NSP_ServiceConstants.editSharingAccess;
        newCaseShare.CaseId = recordId;
        return newCaseShare;
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_CaseRecordSharing.class.getName() ,
            methodName ,
            e
        );
    }

}
//