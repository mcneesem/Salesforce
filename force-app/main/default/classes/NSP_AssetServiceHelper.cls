// Represents the Asset Service helper which handles the logic for BPS project creation through automation.
public class NSP_AssetServiceHelper {
    // test w/ NSP_AssetServiceHelperTest (88%)

    public static final Id PEO_PROJECT = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT,NSP_ServiceConstants.PEOProject );
    public static final Id INTEGRA_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.INTEGRA );
    public static final Id PERFORM_SMART_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.PERFORMANCE_ASSET );
    public static final Id TIME_ATTENDANCE_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.ASSET_TT_RECORDTYPE );
    public static final Id XML_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.XML_ASSET );
    public static final Id WO_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
    public static final Id BPSRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);

    // This method will create the BPS Project for integra, xml, time and attendance, performsmart asset
    public void createBPSProject( List<Asset> assetList ) {
        Set<Id>accountIdSet = new Set<Id>();
        Set<Id> integraAssetSet = new Set<Id>();
        Set<Id> performSmartAssetSet = new Set<Id>();
        Set<Id> xmlAssetSet = new Set<Id>();
        Set<Id> timeAttendanceAssetSet = new Set<Id>();
        Map<Id, Opportunity> mapOfOpportunity = new Map<Id, Opportunity>();
        Map<Id, Id> mapOfAssetOppty = new Map<Id, Id>();
        List<pse__Proj__c> updatedProjectList = new List<pse__Proj__c>();
        List<Project_Asset__c> projectAssetMapping = new List<Project_Asset__c>();
        Map<Id, Account> mapOfAccount = new Map<Id, Account>();
        Id BPSRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
        try {
            List<String> assetRecordTypeList = new List<String>{INTEGRA_ASSET, PERFORM_SMART_ASSET, TIME_ATTENDANCE_ASSET, XML_ASSET};
            if ( assetList != null ){
                for ( Asset asset : assetList ) {
                    if ( ( asset.RecordTypeId == PERFORM_SMART_ASSET || asset.RecordTypeId == TIME_ATTENDANCE_ASSET )
                        && ( asset.Opportunity__c != null )
                        )
                    {
                        mapOfAssetOppty.put(asset.id,asset.Opportunity__c);
                    }
                }
                if ( !mapOfAssetOppty.values().isEmpty() ){
                    List<Opportunity> opptyList = [
                        SELECT Id , NSP_Time_Entry_Recommendation__c , NSP_IPMRecommendation__c
                        FROM Opportunity
                        WHERE (
                            ( Id IN :mapOfAssetOppty.values() )
                            AND (
                                ( NSP_PrimaryProduct__c = :NSP_ServiceConstants.PERFORMANCE_MANAGEMENT )
                                OR ( NSP_PrimaryProduct__c = :NSP_ServiceConstants.TIME_ATTENDANCE )
                                OR ( NSP_PrimaryProduct__c = :NSP_SalesConstants.WO )
                                OR ( NSP_PrimaryProduct__c = :NSP_SalesConstants.WS )
                            )
                        )
                    ];
                    if ( !opptyList.isEmpty() ){
                        for ( Opportunity oppty : opptyList ) {
                            mapOfOpportunity.put(oppty.Id,oppty);
                        }
                    }
                }
                for ( Asset asset : assetList ) {
                    //STY-03289 implementation
                    if ( asset.RecordTypeId == INTEGRA_ASSET && asset.AccountId!=null ) {
                        accountIdSet.add(asset.AccountId);
                        integraAssetSet.add(asset.Id);
                    }
                    if ( asset.RecordTypeId == PERFORM_SMART_ASSET
                        && asset.AccountId != null
                        && !asset.Is_Perform_WO_WS_Asset__c
                        && (
                            ( asset.Opportunity__c == null )
                            || (
                                mapOfAssetOppty.containsKey(asset.Id)
                                && mapOfOpportunity.containsKey(mapOfAssetOppty.get(asset.Id))
                                && ( mapOfOpportunity.get(mapOfAssetOppty.get(asset.id)).NSP_IPMRecommendation__c == NSP_SalesConstants.Yes )
                            )
                        )
                    )
                    {
                        accountIdSet.add(asset.AccountId);
                        performSmartAssetSet.add(asset.Id);
                    }
                    if ( asset.RecordTypeId == TIME_ATTENDANCE_ASSET
                        && asset.AccountId != null
                        && (
                            ( asset.Opportunity__c == null )
                            || (
                                mapOfAssetOppty.containsKey(asset.Id)
                                && mapOfOpportunity.containsKey(mapOfAssetOppty.get(asset.Id))
                                && ( mapOfOpportunity.get(mapOfAssetOppty.get(asset.id)).NSP_Time_Entry_Recommendation__c == NSP_ServiceConstants.Premier_Time_Att )
                            )
                        )
                    )
                    {
                        accountIdSet.add(asset.AccountId);
                        timeAttendanceAssetSet.add(asset.Id);
                    }
                    if ( asset.RecordTypeId == XML_ASSET && asset.AccountId!=null){
                        accountIdSet.add(asset.AccountId);
                        xmlAssetSet.add(asset.Id);
                    }
                }
            }
            // check if asset has active account
            // using KillSwitch__c by bypass the Account Status Filter -- AZD-516451
            Boolean isEnabledCreateBpsProjectStatusFilter = AssetTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsEnabledCreateBpsProjectStatusFilter__c;
            List<Account> accounts = null;
            if ( isEnabledCreateBpsProjectStatusFilter ) {
                accounts = [
                    SELECT
                        Id ,
                        Name ,
                        NSP_Sales_Service_Account_Status__c ,
                        (
                            SELECT Id , RecordTypeId
                            FROM Assets
                            WHERE ( RecordTypeId IN :assetRecordTypeList )
                        )
                    FROM Account
                    WHERE (
                        ( Id IN :accountIdSet )
                        AND (
                            ( NSP_Sales_Service_Account_Status__c = :NSP_ServiceConstants.STATUS_ACTIVE )
                            OR ( NSP_Sales_Service_Account_Status__c = :NSP_ServiceConstants.ASSET_ONBOARDING_STATUS )
                        )
                    )
                    ];
            } else {
                accounts = [
                    SELECT
                        Id ,
                        Name ,
                        NSP_Sales_Service_Account_Status__c ,
                        (
                            SELECT Id , RecordTypeId
                            FROM Assets
                            WHERE ( RecordTypeId IN :assetRecordTypeList )
                        )
                    FROM Account
                    WHERE ( Id IN :accountIdSet )
                ];
            }
            if ( ( accounts != null ) && !accounts.isEmpty() ) {
                for ( Account acc : accounts ) {
                    mapOfAccount.put( acc.Id , acc );
                }
            }
            // getting template from metadata
            Map<String, Template_Key_and_Id_Mapping__mdt> templateMap = new Map<String, Template_Key_and_Id_Mapping__mdt>();
            Set<String> templateKeySet = new Set<String>{
                NSP_ServiceConstants.INTEGRA,NSP_ServiceConstants.PERFORMANCE,
                NSP_ServiceConstants.XML_ASSET,NSP_ServiceConstants.CATEGORY_TIME_ATTENDANCE
            };
            List<Template_Key_and_Id_Mapping__mdt> templateList =[
                SELECT Key__c, Template_ID__c, Template_Name__c
                FROM Template_Key_and_Id_Mapping__mdt
                WHERE Key__c IN: templateKeySet AND NSP_From_Object__c = : NSP_ServiceConstants.FROM_OBJECT_ASSET
            ];
            for(Template_Key_and_Id_Mapping__mdt template :templateList){
                templateMap.put(template.Key__c, template);
            }
            //create project based on active account asset record type
            NSP_AssetServiceTriggerHelper assetServiceHelper = new NSP_AssetServiceTriggerHelper();
            for(Asset asset:AssetList){
                String templateType;
                Id projectId;
                Template_Key_and_Id_Mapping__mdt projectTemplateType = new Template_Key_and_Id_Mapping__mdt();
                //create integra implementation project
                if(integraAssetSet.contains(asset.Id) && mapOfAccount.get(asset.AccountId)!=null
                    && !hasMoreThanOneAsset(mapOfAccount.get(asset.AccountId), INTEGRA_ASSET )
                    )
                {

                    templateType=NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
                    projectTemplateType = templateMap.get(NSP_ServiceConstants.INTEGRA);
                    projectId = assetServiceHelper.createProjectWithTemplateFromAsset(projectTemplateType, asset.Id );
                }
                //create perform smart implementation project
                if(performSmartAssetSet.contains(asset.Id) && mapOfAccount.get(asset.AccountId)!=null ){
                    templateType=NSP_ServiceConstants.PERFORMSMART_IMPLEMENTATION;
                    projectTemplateType = templateMap.get(NSP_ServiceConstants.PERFORMANCE);
                    projectId = assetServiceHelper.createProjectWithTemplateFromAsset(projectTemplateType, asset.Id );
                }
                //create xml implementation project
                if(xmlAssetSet.contains(asset.Id) && mapOfAccount.get(asset.AccountId)!=null
                    && !hasMoreThanOneAsset(mapOfAccount.get(asset.AccountId), XML_ASSET )
                    )
                {
                    templateType=NSP_ServiceConstants.XML_IMPLEMENTATION;
                    projectTemplateType = templateMap.get(NSP_ServiceConstants.XML_ASSET);
                    projectId = assetServiceHelper.createProjectWithTemplateFromAsset(projectTemplateType, asset.Id );
                }
                //create ITA implementation project
                if ( timeAttendanceAssetSet.contains(asset.Id)
                    && ( mapOfAccount.get(asset.AccountId) != null )
                    && !hasMoreThanOneAsset(mapOfAccount.get(asset.AccountId), TIME_ATTENDANCE_ASSET )
                    )
                {
                    templateType=NSP_ServiceConstants.ITA_IMPLEMENTATION;
                    projectTemplateType = templateMap.get(NSP_ServiceConstants.CATEGORY_TIME_ATTENDANCE);
                    projectId = assetServiceHelper.createProjectWithTemplateFromAsset(projectTemplateType, asset.Id );
                }
                if(String.isNotBlank(projectId)){
                    // Update integra implementation Project Data
                    updatedProjectList.add(createProjectObject(projectId, BPSRECORDTYPE, asset, mapOfAccount.get(asset.AccountId).Name,templateType));
                    //Update the project with its related entity.
                    projectAssetMapping.add(NSP_AssetServiceTriggerHelper.linkProjectWithAsset(projectId, asset.Id));
                }
            }
            if(!updatedProjectList.isEmpty()){
                update updatedProjectList;
            }
            if(!projectAssetMapping.isEmpty()){
                insert projectAssetMapping;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetServiceHelper.class.getName() ,
                'createBPSProject' ,
                e
            );
        }
    }

    // This method will update the asset termination information section
    public static void updateTerminationInformation( List<Asset> newList , Map<Id,Asset> oldMapAsset ) {
        try{
            for(Asset asset: newList){
                //when the verbal termination received is checked
                if( asset.recordTypeId == WO_ASSET &&
                    asset.NSP_Verbal_Term_recd__c ==true && (oldMapAsset==null || (oldMapAsset!=null && oldMapAsset.get(asset.Id).NSP_Verbal_Term_recd__c!=true))
                    )
                {
                    asset.NSP_Verbal_Term_Date__c= asset.NSP_Verbal_Term_Date__c == null ? System.Today() : asset.NSP_Verbal_Term_Date__c;
                    asset.NSP_Verbal_Term_Updatedby__c=UserInfo.getUserId();
                }
                //when Written Termination Notice Received is checked
                if( asset.recordTypeId == WO_ASSET &&
                    asset.NSP_Written_Term_recd__c ==true && (oldMapAsset==null ||
                    (oldMapAsset!=null && oldMapAsset.get(asset.Id).NSP_Written_Term_recd__c!=true))
                    )
                {
                    asset.NSP_Written_Term_Date__c= asset.NSP_Written_Term_Date__c == null ? System.Today(): asset.NSP_Written_Term_Date__c;
                    asset.NSP_Written_Termination_Updated_By__c = UserInfo.getUserId();
                    asset.NSP_Pending_Termination__c = true;
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetServiceHelper.class.getName() ,
                'updateTerminationInformation' ,
                e
            );
        }
    }

    // This method will clear the asset termination information section
    public void clearAssetTerminationSection( List<Asset> newList , Map<Id,Asset> oldMapAsset ) {
        Set<Id> accountIdSet = new Set<Id> ();
        Map<Id, NSP_Sub_Client__c> mapOfSubAccount = new Map<Id,NSP_Sub_Client__c> ();
        List<Asset> updatedAssetList = new List<Asset>();
        try{
            for(Asset asset: newList){
                if(asset.recordTypeId == WO_ASSET && !String.isBlank(asset.AccountId)
                   && asset.NSP_Anticipated_Date_Of_Termination__c!=NULL && asset.NSP_Anticipated_Date_Of_Termination__c != oldMapAsset.get(asset.Id).NSP_Anticipated_Date_Of_Termination__c
                   )
                {
                    accountIdSet.add(asset.AccountId);
                }
            }
            //GET Sub client of asset account where sub client number ending with 00
            if(!accountIdSet.isEmpty()){
                for(NSP_Sub_Client__c subClient: [SELECT NSP_Sub_Client__c,NSP_Account__c,NSP_Renewal_Date__c FROM NSP_Sub_Client__c WHERE NSP_Sub_Client__c!=NULL AND
                    NSP_Sub_Client__c LIKE '%00' AND NSP_Renewal_Date__c!=null
                    AND NSP_Account__c IN :accountIdSet]
                    )
                {
                    mapOfSubAccount.put(subClient.NSP_Account__c,subClient);
                }
            }
            //clear asset termination form section values
            if(!mapOfSubAccount.isEmpty()){
                for(Asset asset: [SELECT AccountId,NSP_Renewal_Date__c,NSP_Client__c, NSP_Verbal_Term_recd__c,NSP_Verbal_Term_Date__c,NSP_Verbal_Term_Updatedby__c,
                                  NSP_Written_Term_recd__c,NSP_Written_Term_Date__c,NSP_Written_Termination_Updated_By__c,
                                  NSP_Anticipated_Date_Of_Termination__c,NSP_Reason_for_Term__c,NSP_Pending_Termination__c FROM Asset WHERE AccountId IN:mapOfSubAccount.keyset()  ]
                    )
                {
                    if(mapOfSubAccount.get(asset.AccountId).NSP_Renewal_Date__c>= asset.NSP_Anticipated_Date_Of_Termination__c){
                        if(asset.NSP_Verbal_Term_recd__c==true){
                            asset.NSP_Verbal_Term_recd__c =false;
                            asset.NSP_Verbal_Term_Date__c=null;
                            asset.NSP_Verbal_Term_Updatedby__c=Label.NSP_Deployment_Manager;
                            asset.NSP_Anticipated_Date_Of_Termination__c=null;
                            asset.NSP_Reason_for_Term__c=null;
                            asset.NSP_Pending_Termination__c=false;
                        }
                        if(asset.NSP_Written_Term_recd__c==true){
                            asset.NSP_Written_Term_recd__c =false;
                            asset.NSP_Written_Term_Date__c=null;
                            asset.NSP_Written_Termination_Updated_By__c=Label.NSP_Deployment_Manager;
                            asset.NSP_Anticipated_Date_Of_Termination__c=null;
                            asset.NSP_Reason_for_Term__c=null;
                            asset.NSP_Pending_Termination__c=false;
                        }
                        updatedAssetList.add(asset);
                    }
                }
            }
            if(!updatedAssetList.isEmpty()){
                database.update(updatedAssetList);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetServiceHelper.class.getName() ,
                'clearAssetTerminationSection' ,
                e
            );
        }
    }

    // This method checks if more than one asset is present of same record Type
    private static boolean hasMoreThanOneAsset( Account acc , Id recordTypeId ) {
        integer count=0;
        if(acc!=null && acc.assets!=null){
            for(Asset asset :acc.assets){
                if(asset.RecordTypeId==recordTypeId){
                    count++;
                }
                if(count>1){
                    return true;
                }
            }
        }
        return false;
    }

    //This method will return project with standard prefilled fields values
    private static pse__Proj__c createProjectObject( Id projId , Id recordTypeId , Asset asset , String accountName , String segmentType ) {
        pse__Proj__c project = new pse__Proj__c();
        project.Id= projId;
        project.Name=accountName+' : '+segmentType ;
        project.pse__Project_Status__c = NSP_ServiceConstants.INTAKE;
        project.pse__Account__c = asset.accountId;
        project.RecordTypeId = recordTypeId;
        project.OwnerId=asset.ownerId;
        project.pse__Start_Date__c=System.Today();
        project.NSP_Asset_Implementation_Project__c= True;
        return project;
    }

}
//
