/**
Apex Class Name      :  NSP_AssetServiceTriggerHelper
Test Class Name      :  NSP_AssetServiceTriggerHelperTest
Version              :  1.0
Created Date         :  6/1/2022
Author               :  Jatin
Function             :  Represents the Asset trigger helper which handles all the logic.
Story                :
Modification Log     :  11/09/2023-Suhas : Added RET Client Id for Sync WO Asset.
*--------------------------------------------------------------------------------------------------
* Developer                   Date                   Description
* -------------------------------------------------------------------------------------------------
* Virendra Kumar               9/30/2022           First Iteration
* Ramya Ravi                   10/28/2022          V2.0- RET - Automation - Subplan Lead Parent Sync to Associated Assets  <STY-02671>
* Ramya Ravi                   11/02/2022          V3.0 - TES Asset & RET Asset - AIMS Information - <STY-02841>
* Ramya Ravi                   11/04/2022          V4.0 - RET Asset - Sync WO Asset data to RET Asset  <STY-03527>
* Abhishek Kumar               12/26/2022          v5.0 - Account - Product First Pay Date <STY-03597>
* Ramya Ravi                   01/16/2022          v6.0 - Create project from asset <STY-02234>
*/
public class NSP_AssetServiceTriggerHelper {
    // test w/ NSP_AssetServiceTriggerHelperTest (78%)

    public final String PEORECORDTYPE = 'PEO';
    public final String HRSPECIALISTROLE = 'HR Specialist';
    public final String BTHRSPECIALISTROLE = 'Bus. Team-HRSp/CL';
    public final String MHRSPECIALISTROLE = 'Manager, HR Services';
    public final List<String> lAccountTeamRoles = new List<String>{HRSPECIALISTROLE,BTHRSPECIALISTROLE,MHRSPECIALISTROLE};
    public final String REVIEWBIOMETRICSUBJECT = 'Review Biometric Timekeeping and Policies with Client';
    public final String VALIDATEBIOMETRICSUBJECT = 'Validate Biometric Consent form removed from OEE; Discuss removal of handbook policy w/ client';
    public final String HRSERVICECATEGORY = 'HR Services';
    public final String HRINFRASTRUCTURESUBCATEGORY = 'HR Infrastructure';
    public final String CLIENTGUIDANCE = 'Client Guidance';
    public final String WO_RECORD_TYPE = 'WO';
    public final String ASSET_STATUS_ONBOARDING = 'Onboarding';
    public final String ASSET_STATUS_PURCHASED = 'Purchased';
    public final String ASSET_STATUS_ACTIVE = 'Active';
    public final String ASSET_AIMS_STATUS_TERMINATED = 'Terminated';
    public final String ASSET_STATUS_BACKOUT = 'Backout';
    private static final String ASSET = 'Asset';
    public static final Id PEORECORDTYPE = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
    public static List<String> OnboardingStatusRecordTypes = System.Label.NSP_Asset_Record_Type_with_Initial_Status_Onboarding.split(',');
    public static List<String> NonServiceAsset = System.Label.NSP_Non_Service_Asset.split(',');
    public static List<String> AssetStartDateCurrentMonth = System.Label.NSP_Asset_Status_Start_Date_Current_Month.split(',');
    static final List<String> AssetRecTypeSet = System.Label.ASSET_BPS_RET_RECORDTYPES.split( ',' ); //<STY-02841>
    private static final Map<String, Schema.RecordTypeInfo> ASSET_RECORD_TYPES = NSP_GenericRecordType.getRecordTypeMap( 'Asset' );
    static final Id HardwareLoanerAsset = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.HARDWARE_LOANER_RECORD_TYPE).getRecordTypeId();
    static final Id HardwareAsset = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.HARDWARE_RECORD_TYPE).getRecordTypeId();
    static final Id InsuranceServiceRT = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.INSURANCE_SERVICES_RECORDTYPE).getRecordTypeId();
    static final Id ApplicantTrackingRT = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.APPLICANT_TRACKING_RECORD_TYPE).getRecordTypeId();
    static final Id EmploymentScreeningRT = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.EMPLOYMENT_SCREENING_RECORD_TYPE).getRecordTypeId();
    static final Id CertifyRT = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.CERTIFY).getRecordTypeId();
    static final Id XmlAssetRecordId = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.XML_ASSET).getRecordTypeId();
    static final Id TimeAttendanceRecordId = ASSET_RECORD_TYPES.get(NSP_ServiceConstants.TIME_ATTENDANCE_ASSET).getRecordTypeId();
    static final Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.WO_ASSET_RECORDTYPE);//<STY-02841>
    static final Id RETChoiceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE); //<STY-03527>
    static final Id RETWOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE); //<STY-03527>
    private static final Id wxWaAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(ASSET, 'NSP_Asset_Product');
    private static final Id CPQ_ASSET_RECORDTYPE_ID = NSP_GenericRecordType.getRecordTypeId(ASSET, 'NSP_CPQ_Asset');
    private static final Id PERFORM_SMART_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.PERFORMANCE_ASSET );
    private static final Id INTEGRA_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.INTEGRA );
    private static final String ASSET_TERMINATION_PAYROLL_TEMPLATE = 'NSP_Retention_Strategy_Payroll_Email';
    private static final String ASSET_TERMINATION_OTHER_ROLE_TEMPLATE = 'NSP_Asset_Retention_Strategy_Email';
    private static final String RSAP = 'Relationship Strategy Action Plan';
    private static final Id hardWareRecordTypeId = NSP_GenericRecordType.getRecordTypeId(ASSET, 'Hardware_Asset');
    private static final String errorMessage = System.Label.NSP_Error_Message_Without_CreateAsset_PermSet_On_Asset;

    //
    // Creating Constructor to call FF API's
    // Creating Mock records of FF Api's Using interfaces
    //
    public NSP_FF_APIs implInstance = new NSP_FF_APIImpl();
    public NSP_AssetServiceTriggerHelper(){
        if(Test.isRunningTest()){
            this.implInstance = new Nsp_FFApiMock();
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // Method Name: beforeInsertDirector
    // @param newList List of New Assets.
    // @return void
    //
    public void beforeInsertDirector( List<Asset> assets ) {
        List<Asset> notEditableRETFieldsAssetList = new List<Asset>();
        Boolean hasRETCustomPermission = NSP_AssetServiceTriggerHelper.hasNspRetAssetCreateEdit;
        //<STY-02841>   start
        Set<ID> accountID = new Set<ID>();
        List<Asset> assetLstToUpdate = new List<Asset>();
        Boolean isValid = false;
        List<Id> finalRecordTypeIds = new List<Id>();
        List<Asset> nonWOassetList = new List<Asset>();
        Map<Id, List<Asset>> RETBPSassets = new Map<Id, List<Asset>>();
        Map<String, String> recTypeLabelMap = new Map<String, String>();
        Map<String, Schema.RecordTypeInfo> assetAllRecordTypes = NSP_AssetServiceTriggerHelper.ASSET_RECORD_TYPES;
        Map<Id, Account> assetAccIdNameMap;
        Set<Id> accIdSet = new Set<Id>();

        //Get all asset record Type IDs
        for(String recTypeName : AssetRecTypeSet){
            finalRecordTypeIds.add(assetAllRecordTypes.get(recTypeName).getRecordTypeId());
        }

        for (String recTypeName : assetAllRecordTypes.keySet()) {
            Schema.RecordTypeInfo info = assetAllRecordTypes.get(recTypeName);
            recTypeLabelMap.put(info.getRecordTypeId(), info.getName());
        }

        //<STY-02841> end
        //Iterating over assets
        for(Asset asset : assets){
            // Check whether Exception checkbox is checked or Exception reason is given
            if(asset.NSP_Segment_Exception__c || String.isNotBlank(asset.NSP_Segment_Exception_Reason__c)){
                //Updating asset records to updateSegmentExceptionDetails
                updateSegmentExceptionDetails(asset);
            }
            //<STY-02841> start - Check if any RET/BPS/Asset is inserted
            if(finalRecordTypeIds.contains(asset.RecordTypeId) && asset.AccountId!=null){
                isValid = true;
                accountID.add(asset.AccountId);
                assetLstToUpdate.add(asset);
            }//<STY-02841> end

            String recordTypeLabel = recTypeLabelMap.get(asset.RecordTypeId);
            if( OnboardingStatusRecordTypes.contains(recordTypeLabel)
                && asset.NSP_Account_Status__c != NSP_ServiceConstants.TERMINATED
                && !asset.Is_Perform_WO_WS_Asset__c
                )
            {
                asset.Status = ASSET_STATUS_ONBOARDING;
            }else if(NonServiceAsset.contains(recordTypeLabel)){
                asset.Status = ASSET_STATUS_PURCHASED;
            }
            // Added as part of defect - DF-03761
            if(asset.AccountId != null){
                if(asset.NSP_Biometric_End_Date__c >= System.today()){
                    asset.NSP_Biometric_Indicator_Assigned__c = true;
                }
            }
            if(asset.recordTypeId == hardWareRecordTypeId && asset.Status ==NSP_ServiceConstants.TERMINATED &&
                asset.NSP_Early_Termination_Notice__c == True){
                asset.NSP_Early_Termination_Notice__c = false;
            }
            //Added as part of DF-04204
            if(asset.AccountId != null &&
              asset.NSP_Product_Line__c != NSP_SalesConstants.PROD_WX &&
              asset.NSP_Product_Line__c != NSP_SalesConstants.PROD_WA &&
              asset.RecordTypeId != WOAssetRecordTypeId &&
              asset.RecordTypeId != CPQ_ASSET_RECORDTYPE_ID &&
              asset.NSP_TransitionType__c == null){
                   nonWOassetList.add(asset);
                   accIdSet.add(asset.AccountId);
            }

            //As a part of DF-04328
            if(hasRETCustomPermission == false){
                notEditableRETFieldsAssetList.add(asset);
            }
        }

        //Added as part of DF-04204
        if(!accIdSet.isEmpty()){
            assetAccIdNameMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN: accIdSet]);
        }

        //To Update Asset Name
        //Added as part of DF-04204
        if(!nonWOassetList.isEmpty() && assetAccIdNameMap != null && recTypeLabelMap != null){
            NSP_AssetServiceTriggerHelper.updateAssetNameAsPerConvention(nonWOassetList, assetAccIdNameMap, recTypeLabelMap);
        }

        //As a part of DF-04328
        if(!notEditableRETFieldsAssetList.isEmpty()){
            throwErrorMessageForNonEditFields(notEditableRETFieldsAssetList, null, false, true);
        }
        //<STY-02841> start

        if(!isValid){
            return;
        }

        // Get the existing WO asset linked to the account set and create map<Account ID , WOAsset>
        for ( Asset asset : [
                    SELECT
                        Id ,
                        NSP_WO_AIMS_Client_Number__c ,
                        AccountId ,
                        NSP_Company_Name__c ,
                        NSP_Client__c ,
                        Disable_Sync_RET_Client_ID__c ,
                        NSP_Account_Status__c ,
                        NSP_Account_Status_Date__c ,
                        NSP_Client_Segment_type__c ,
                        NSP_Client_SegmentDate__c ,
                        NSP_Service_Package__c ,
                        NSP_AIMS_First_Pay_Date__c ,
                        NSP_Legal_Name__c ,
                        NSP_DBA__c ,
                        NSP_Business_Type__c ,
                        NSP_FEIN__c ,
                        NSP_Business_Inception_Date__c ,
                        NSP_SIC_Code__c ,
                        NSP_Legal_Entity_Description__c ,
                        NSP_NAICS_Code__c ,
                        NSP_AIMS_Original_First_Pay_Date__c ,
                        NSP_Sales_Office__c ,
                        NSP_RET_Region__c ,
                        NSP_RET_AIMS_Original_Empl_Date__c ,
                        NSP_RET_NAICS_Description__c ,
                        NSP_Phone__c ,
                        NSP_RET_Phone_Ext__c ,
                        NSP_Email__c ,
                        NSP_Renewal_Date__c
                    FROM Asset
                    WHERE (
                        ( AccountId IN :accountID )
                        AND ( RecordTypeId = :WOAssetRecordTypeId )
                        AND ( NSP_Account_Status__c = :NSP_ServiceConstants.ASSET_ACTIVE_STATUS )
                        AND ( NSP_Client__c != null )
                    )
                ]
            )
        {
            // Populate Map <Account ID , WOAsset>
            List<Asset> assetLst = RETBPSassets.containsKey(asset.AccountId) ? RETBPSassets.get(asset.AccountId) : new List<Asset>();
            assetLst.add(asset);
            RETBPSassets.put(asset.AccountId, assetLst);
        }

        //Loop through the asset to update values and populate values from WO asset to existing asset
        for(Asset getAsst : assetLstToUpdate){
            List<Asset> asssetsLst = RETBPSassets?.get(getAsst.AccountId);
            if(asssetsLst != null && !asssetsLst.isEmpty()){
                getAsst = updateAssets(getAsst, asssetsLst[0]);
            }
        }
        //<STY-02841> end

    }

    /* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newMap List of Assets.
* @return void
* //Added as a part of <STY-02841>
*/
    public void afterInsertAsset(List<Asset> newList, Map<Id,Asset> newMap){
        //As a part ofSTY-02819
        Set<Id> updateServiceSegmentAssetIdSet = new Set<Id>();
        List<Asset> assetToUpdate = new List<Asset>();
        List<Id> accountID = new List<Id>();
        List<Asset> RETBPSassets = new List<Asset>();
        Boolean isValid = false;
        Map<Id, Asset> WOAssetMap = new Map<Id, Asset>();
        Set<Id>accountIdSet = new Set<Id>();
        Set<Id> fsoAssetSet = new Set<Id>();
        Set<Id> MMAssetSet = new Set<Id>();
        Set<Id> woAssetIdSet = new Set<Id>();
        Set<Id> assetPayrollSet = new Set<Id>();
        Set<String> listWXParentIds = new Set<String>();
        Map<String,String> mapwXParentIdAccountId = new Map<String,String>();
        Id woAssetRecordType = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Id wXRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WX_WA);
        List<Asset> listOfAsset = new List<Asset>();

        //Get list of Account IDs
        for(Asset asset : newList){
            // added as a part of DF-03798
            if(asset.AccountId!=null &&
                (asset.RecordTypeId == WOAssetRecordTypeId || asset.RecordTypeId==wxWaAssetRecordTypeId) &&
                (asset.NSP_Unique_Active_Employee__c!=null  || asset.NSP_Current_SaaS_Seats__c !=null ) &&
                (asset.Status == NSP_ServiceConstants.ASSET_ONBOARDING_STATUS || asset.Status == NSP_ServiceConstants.ASSET_ACTIVE_STATUS)){
                assetPayrollSet.add(asset.AccountId);
            }
            if(asset.AccountId!=null){
                accountID.add(asset.AccountId);
            }
            if(asset.NSP_Account_Status__c == NSP_ServiceConstants.ASSET_ACTIVE_STATUS &&
               asset.RecordTypeId == WOAssetRecordTypeId &&
               asset.NSP_Client__c != null){
                   // check if atleast one WO asset is inserted
                   isValid = true;
                   // Store account Id and WO asset in Map
                   WOAssetMap.put(asset.AccountId,asset);
               }

            //As a part ofSTY-02819
            if(asset.AccountId != NULL && (asset.Status == NSP_ServiceConstants.ASSET_ONBOARDING_STATUS ||
                                           asset.Status == NSP_ServiceConstants.ASSET_ACTIVE_STATUS) &&
               (asset.RecordTypeId == WOAssetRecordTypeId || asset.RecordTypeId == wxWaAssetRecordTypeId)){
                updateServiceSegmentAssetIdSet.add(asset.AccountId);

               }
            // Added as a part of STY-02129
            if(asset.RecordTypeId == woAssetRecordType && (asset.Status != NSP_ServiceConstants.TERMINATED
                && asset.Status != NSP_ServiceConstants.BACKOUT )){
                String segmentType = asset.NSP_Client_Segment_type__c;
                // checking for MM , BT Core ,EG asset
                if(isFsoAsset(segmentType) || isMidMarketAsset(segmentType)){
                    if(isMidMarketAsset(segmentType)){
                        MMAssetSet.add(asset.Id);
                    }
                    else if(isFsoAsset(segmentType)){
                        fsoAssetSet.add(asset.Id);
                    }
                    woAssetIdSet.add(asset.Id);
                }
                if(asset.AccountId!=null){
                    accountIdSet.add(asset.AccountId);
                     woAssetIdSet.add(asset.Id);
                }
            }
            if (asset.RecordTypeId == wXRecordTypeId && asset.AccountId != NULL && asset.NSP_WX_WA_CHILD_ID__c != NULL && asset.NSP_WX_WA_Parent_ID__c != null && (asset.Status != NSP_ServiceConstants.ASSETBLACKOUT || asset.Status != NSP_ServiceConstants.TERMINATED)) {
                listWXParentIds.add(asset.NSP_WX_WA_Parent_ID__c);
                mapwXParentIdAccountId.put(asset.NSP_WX_WA_Parent_ID__c, asset.AccountId);
            }
        }

        List<Account> listofaccts = NSP_AssetServiceTriggerHelper.getAccounts( accountID );
        if ( !listofaccts.isEmpty() ) {
            for ( Account acc : listofaccts ) {
                listOfAsset.addAll( acc.Assets );
            }
        }
        //Call to updateAccountStatus method - DF-03777
        this.updateAccountStatus( listofAsset , listOfaccts );

        if(isValid){
            //Get all BPS assets related to the Same account
            RETBPSassets = returnRETBPSassets(accountID);
            // Loop through the BPS asset, copy data from WO asset and update records
            for(Asset getAsstList : RETBPSassets){
                if(WOAssetMap.containsKey(getAsstList.AccountId)){
                    Asset WOAsset = WOAssetMap.get(getAsstList.AccountId);
                    assetToUpdate.add(updateAssets(getAsstList,WOAsset)) ;
                }
            }
            //Update the assets
            if(!assetToUpdate.isEmpty()){
                UpdateLstAssets(assetToUpdate);
            }
        }
        //As a part ofSTY-02819
        if(!updateServiceSegmentAssetIdSet.isEmpty()){
            updateServiceSegmentOnAccount(updateServiceSegmentAssetIdSet);
        }
        // added as a part of DF-03798
        if(!assetPayrollSet.isEmpty()){
            updateaccountPayrollEmployee(assetPayrollSet);
        }
        // added as a part of STY-02726 Relate separate accounts into an account group and Identifiy the types of relationships between those accounts so that I can ensure all users have a clear view of how accounts relate, ownership
        if(!listWXParentIds.isEmpty() && !mapwXParentIdAccountId.isEmpty()){
            createWXAssetGroups(mapwXParentIdAccountId,wXRecordTypeId);
          }
        // added as a part of STY-02129
        if(!woAssetIdSet.isEmpty()){
           System.enqueueJob( new NSP_AssetProjectCreation( woAssetIdSet,accountIdSet,fsoAssetSet,MMAssetSet) );
        }

    }
    /* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newMap, oldMap List of Assets.
* @return void
* //Added as a part of <STY-02841>
*/
    public void afterUpdateAsset( List<Asset> newList,Map<Id, Asset> oldMap){
        List<Asset> assetToUpdate = new List<Asset>();
        List<Asset> assetToUpdateNull = new List<Asset>();
        List<Id> accountID = new List<Id>();
        List<Asset> RETBPSassets = new List<Asset>();
        Boolean isValid = false;
        Boolean isNull = false;
        Map<Id, Asset> WOAssetMap = new Map<Id, Asset>();
        List<Id> AccountIDNull = new List<Id>();
        Set<Id> assetPayrollSet = new Set<Id>();
        // check if atleast one field in WO asset is updated as per condition
        for(Asset asset : newList) {
            Asset oldMapvalue =  oldMap.get(asset.id);
            // added as a part of DF-03798
        if(asset.AccountId!=null &&
            (asset.RecordTypeId == WOAssetRecordTypeId || asset.RecordTypeId==wxWaAssetRecordTypeId) &&
            ((asset.NSP_Unique_Active_Employee__c!=null && oldMapvalue.NSP_Unique_Active_Employee__c !=asset.NSP_Unique_Active_Employee__c) ||
            (asset.NSP_Current_SaaS_Seats__c !=null && oldMapvalue.NSP_Current_SaaS_Seats__c !=asset.NSP_Current_SaaS_Seats__c) ||
            (oldMapvalue.Status != asset.Status))){
                assetPayrollSet.add(asset.AccountId);
            }
         if(asset.AccountId!=null){
             accountID.add(asset.AccountId);}
         if(  asset.RecordTypeId == WOAssetRecordTypeId &&
            asset.NSP_Account_Status__c == NSP_ServiceConstants.ASSET_ACTIVE_STATUS  &&
            asset.NSP_Client__c != null &&
            (   asset.NSP_Account_Status_Date__c != oldMapvalue.NSP_Account_Status_Date__c ||
             asset.NSP_Account_Status__c != oldMapvalue.NSP_Account_Status__c ||
             asset.NSP_Client_Segment_type__c != oldMapvalue.NSP_Client_Segment_type__c ||
             asset.NSP_Client_SegmentDate__c != oldMapvalue.NSP_Client_SegmentDate__c ||
             asset.NSP_Service_Package__c != oldMapvalue.NSP_Service_Package__c ||
             asset.NSP_AIMS_First_Pay_Date__c != oldMapvalue.NSP_AIMS_First_Pay_Date__c ||
             asset.NSP_Legal_Name__c != oldMapvalue.NSP_Legal_Name__c ||
             asset.NSP_DBA__c != oldMapvalue.NSP_DBA__c ||
             asset.NSP_Business_Type__c != oldMapvalue.NSP_Business_Type__c ||
             asset.NSP_FEIN__c != oldMapvalue.NSP_FEIN__c ||
             asset.NSP_Business_Inception_Date__c != oldMapvalue.NSP_Business_Inception_Date__c ||
             asset.NSP_SIC_Code__c != oldMapvalue.NSP_SIC_Code__c ||
             asset.NSP_Legal_Entity_Description__c != oldMapvalue.NSP_Legal_Entity_Description__c ||
             asset.NSP_NAICS_Code__c != oldMapvalue.NSP_NAICS_Code__c ||
             asset.NSP_AIMS_Original_First_Pay_Date__c != oldMapvalue.NSP_AIMS_Original_First_Pay_Date__c   ||
             asset.NSP_Sales_Office__c != oldMapvalue.NSP_Sales_Office__c ||
             asset.NSP_Phone__c  != oldMapvalue.NSP_Phone__c    ||
             asset.NSP_RET_Phone_Ext__c  != oldMapvalue.NSP_RET_Phone_Ext__c   ||
             asset.NSP_Email__c  != oldMapvalue.NSP_Email__c ||
             asset.NSP_Renewal_Date__c  != oldMapvalue.NSP_Renewal_Date__c  ||
             asset.NSP_Client__c    !=  oldMapvalue.NSP_RET_Client_ID__c    //11092023 - STY-241721
            )){
                // check if atleast one field in WO asset is updated as per condition
                isValid = true;
                WOAssetMap.put(asset.AccountId,asset );
            }
            // check if  WO asset is made INACTIVE
            NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
            if ( asset.RecordTypeId == WOAssetRecordTypeId
                && asset.NSP_Account_Status__c != oldMapvalue.NSP_Account_Status__c
                && asset.NSP_Account_Status__c != NSP_ServiceConstants.ASSET_ACTIVE_STATUS
                && asset.NSP_Client__c != null
                && triggerSwitch != null
                && triggerSwitch.Null_BPS_assets__c
                )
            {
                // check if  WO asset is made INACTIVE
                isNull = true;
                AccountIDNull.add( asset.AccountId );
            }
        }

        if(isValid){
            RETBPSassets = returnRETBPSassets(accountID);
            // Loop through the BPS asset,  copy data from WO asset and update records
            for(Asset getAsst : RETBPSassets){
                if(WOAssetMap.containsKey(getAsst.AccountId)){
                    Asset WOAsset = WOAssetMap.get(getAsst.AccountId);
                    assetToUpdate.add(updateAssets(getAsst,WOAsset)) ;
                }
            }
            UpdateLstAssets(assetToUpdate);
        }
        if(isNull){
            RETBPSassets = returnRETBPSassets(accountID);
            List<String> fieldsToUpdate = new List<String>{'NSP_WO_AIMS_Client_Number__c', 'NSP_Company_Name__c','NSP_Account_Status__c','NSP_Account_Status_Date__c',
                'NSP_Client_Segment_type__c','NSP_Client_SegmentDate__c','NSP_Service_Package__c','NSP_AIMS_First_Pay_Date__c','NSP_Legal_Name__c','NSP_DBA__c',
                'NSP_Business_Type__c','NSP_FEIN__c','NSP_Business_Inception_Date__c','NSP_SIC_Code__c','NSP_Legal_Entity_Description__c','NSP_NAICS_Code__c',
                'NSP_AIMS_Original_First_Pay_Date__c','NSP_Sales_Office__c','NSP_Phone__c','NSP_RET_Phone_Ext__c','NSP_Email__c','NSP_Renewal_Date__c'};

                    // Loop through the BPS asset,  copy data from WO asset and update records
                    for(Asset getAsst : RETBPSassets){
                        if(AccountIDNull.contains(getAsst.AccountId)){
                            for(String fieldName :fieldsToUpdate){
                                getAsst.put(fieldName, null);
                            }
                            assetToUpdateNull.add(getAsst) ;
                        }
                    }
            UpdateLstAssets(assetToUpdateNull);
        }
        // added as a part of DF-03798
        if(!assetPayrollSet.isEmpty()){
            updateaccountPayrollEmployee(assetPayrollSet);
        }
    }

    // Helper methods to reuse in afterInsert and afterUpdate methods
    // updateAssets()
    // ReturnRETBPSassets()
    // ReturnAssetRecordtypes()
    // UpdateLstAssets()
    private Asset updateAssets( Asset getAsst , Asset assLst ) {
        Asset returnAsset = getAsst;
        getAsst.NSP_WO_AIMS_Client_Number__c = assLst.NSP_Client__c;
        //10212025-STY-462099-START
        if ( ( getAsst.RecordTypeId == RETWOAssetRecordTypeId )
            && !assLst.Disable_Sync_RET_Client_ID__c
            )
        {
            getAsst.NSP_RET_Client_ID__c = assLst.NSP_Client__c;//11092023-STY-241721
        }
        //10212025-STY-462099-END
        getAsst.NSP_Client__c = null;
        getAsst.NSP_Company_Name__c = null;
        getAsst.NSP_Account_Status__c = assLst.NSP_Account_Status__c;
        getAsst.NSP_Account_Status_Date__c = assLst.NSP_Account_Status_Date__c;
        getAsst.NSP_Client_Segment_type__c = assLst.NSP_Client_Segment_type__c;
        getAsst.NSP_Client_SegmentDate__c = assLst.NSP_Client_SegmentDate__c;
        getAsst.NSP_Service_Package__c = assLst.NSP_Service_Package__c;
        getAsst.NSP_AIMS_First_Pay_Date__c = assLst.NSP_AIMS_First_Pay_Date__c;
        getAsst.NSP_Legal_Name__c = assLst.NSP_Legal_Name__c;
        getAsst.NSP_DBA__c = assLst.NSP_DBA__c;
        getAsst.NSP_Business_Type__c = assLst.NSP_Business_Type__c;
        getAsst.NSP_FEIN__c = assLst.NSP_FEIN__c;
        getAsst.NSP_Business_Inception_Date__c = assLst.NSP_Business_Inception_Date__c;
        getAsst.NSP_SIC_Code__c = assLst.NSP_SIC_Code__c;
        getAsst.NSP_Legal_Entity_Description__c = assLst.NSP_Legal_Entity_Description__c;
        getAsst.NSP_NAICS_Code__c = assLst.NSP_NAICS_Code__c;
        getAsst.NSP_AIMS_Original_First_Pay_Date__c = assLst.NSP_AIMS_Original_First_Pay_Date__c;
        getAsst.NSP_Sales_Office__c = assLst.NSP_Sales_Office__c;
        getAsst.NSP_RET_Region__c = null;
        getAsst.NSP_RET_AIMS_Original_Empl_Date__c = null;
        getAsst.NSP_Phone__c = assLst.NSP_Phone__c;
        getAsst.NSP_RET_Phone_Ext__c = assLst.NSP_RET_Phone_Ext__c;
        getAsst.NSP_Email__c = assLst.NSP_Email__c;
        getAsst.NSP_Renewal_Date__c = assLst.NSP_Renewal_Date__c;
        return returnAsset;
    }

    private  List<Asset> returnRETBPSassets(List<ID> accountID){
        List<Asset> records = new List<Asset>();
        for ( Asset assLst : [
                    SELECT
                        Id ,
                        NSP_WO_AIMS_Client_Number__c ,
                        Disable_Sync_RET_Client_ID__c ,
                        AccountId ,
                        NSP_Company_Name__c ,
                        NSP_Client__c ,
                        NSP_Account_Status__c ,
                        NSP_Account_Status_Date__c ,
                        NSP_Client_Segment_type__c ,
                        NSP_Client_SegmentDate__c ,
                        NSP_Service_Package__c ,
                        NSP_AIMS_First_Pay_Date__c ,
                        NSP_Legal_Name__c ,
                        NSP_DBA__c ,
                        NSP_Business_Type__c ,
                        NSP_FEIN__c ,
                        NSP_Business_Inception_Date__c ,
                        NSP_SIC_Code__c ,
                        NSP_Legal_Entity_Description__c ,
                        NSP_NAICS_Code__c ,
                        NSP_AIMS_Original_First_Pay_Date__c ,
                        NSP_Sales_Office__c ,
                        NSP_RET_Region__c ,
                        NSP_RET_AIMS_Original_Empl_Date__c ,
                        NSP_RET_NAICS_Description__c ,
                        NSP_Phone__c ,
                        NSP_RET_Phone_Ext__c ,
                        NSP_Email__c ,
                        NSP_Renewal_Date__c ,
                        RecordTypeId
                    FROM Asset
                    WHERE (
                        ( AccountId IN :accountID )
                        AND ( RecordType.DeveloperName IN :AssetRecTypeSet )
                    )
                ]
            )
        {
            records.add( assLst );
        }
        return records;
    }

    /**
* Iterates throught the list of new Asset and passes the required attributes to other methods.
* Method Name: afterInsertFilter
* @param newList List of New Asset.
* @param newList Map of New Asset.
* @return void
*
*/
    public void afterInsertFilter(List<Asset> lAssets , Map<Id,Asset> mAssets){
        Set<Id> sAccountIds = new Set<Id>();
        Set<Id> setOfProductId =  new Set<Id> ();
        Set<Id> setOfAssetId = new Set<Id> ();
        List<Asset> lFutureAssets = new List<Asset>();
        List<Asset> lPastAssets = new List<Asset>();
        Map<Id, Id> mapOfAccountIdAssetId = new Map<Id, Id>();
        Set<Id> firstPayDateUpdatedAccountId = new Set<Id>();
        //Iterating over list of Assets
        for(Asset oAsset  : lAssets){
            //Checking if ID Is equal to null or not
            if(oAsset.AccountId != null){
                sAccountIds.add(oAsset.AccountId);
                setOfAssetId.add(oAsset.id);
                // DATE NULL CHECK REMOVED
                if(oAsset.NSP_Biometric_Start_Date__c != null){
                    lFutureAssets.add(oAsset);
                }
            }

            if(oAsset.Product2Id != null && oAsset.Name != NSP_ServiceConstants.TIME_ATTENDANCE_ASSET &&
               oAsset.Name != NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET &&
               oAsset.Name != NSP_ServiceConstants.INTEGRA_ASSET &&
               oAsset.Name != NSP_ServiceConstants.XML_ASSET){
                   setOfProductId.add(oAsset.Product2Id);
               }

            // Added as part of STY-00667
            if(oAsset.AccountId != null && oAsset.recordTypeId == WOAssetRecordTypeId){
                mapOfAccountIdAssetId.put(oAsset.AccountId, oAsset.Id);
            }
            //added as part of STY-03597 changes
            if(oAsset.NSP_First_Pay_Date__c !=null && oAsset.accountId != null){
                firstPayDateUpdatedAccountId.add(oAsset.accountId);
            }
        }
        //added as part of STY-03597 changes
        if(!firstPayDateUpdatedAccountId.isEmpty()){
            updateEarliestProductFirstPayDateOnAccount(firstPayDateUpdatedAccountId);
        }
        // This will create Project Asset Junction record
        if(!setOfProductId.isEmpty() && !System.isFuture() && !System.isBatch()){
            createProjectAssetJunction(sAccountIds, setOfAssetId, setOfProductId, null, False);
        }
        //Checking if list of future assets size is greater than or equal to zero or not
        if(lFutureAssets.size() > 0){
            //This will create case from asset
            createCaseFromAsset(lFutureAssets,sAccountIds);
        }
        //Checking if map of Account ID Asset ID is empty or not
        if(!mapOfAccountIdAssetId.isEmpty()){
            //This will link Asset with Implimentation Profile
            linkAssetWithImpProfile(mapOfAccountIdAssetId);
        }
        if(mAssets!=null){
            subPlanLeadParentSync(mAssets,null,true);//<STY-02671>
        }
    }

    /**
* Future method to create Project Asset Junction record
*Method Name: createProjectAssetJunction
* @param setOfAccountId Set of Account Id related to Asset.
* @param setOfAssetId Set of Asset.
* @param setOfProductId Set of ProductId related to Asset (will be passed when project already exist).
* @param setOfAssetName Set of Asset Name (will be passed when Project and Project Asset both getting craeted).
* @param createProjectAndProjectAssetJunction Boolean var, True when Project already exist and False, when Project just got created.
* @return void
*
*/
    @future
    public static void createProjectAssetJunction(Set<Id> setOfAccountId, Set<Id> setOfAssetId, Set<Id> setOfProductId, Set<String> setOfAssetName, Boolean createProjectAndProjectAssetJunction){
        Map<String, Id> mapOfAccountIdAndProjectName = new Map<String, Id> ();
        Map<Id, String> mapOfProductAndProductCode = new Map<Id, String> ();
        Map<Id, Set<String>> mapOfAccountIdAndTemplateUsed = new Map<Id, Set<String>> ();
        List<Project_Asset__c> listOfProjectAsset = new List<Project_Asset__c> ();
        Map<String,Template_Key_and_Id_Mapping__mdt> mKeyToTemplate = new Map<String,Template_Key_and_Id_Mapping__mdt>();
        // Getting Account and all project name on Account
        for(pse__Proj__c project : [SELECT Name,pse__Account__c,Templates_Used__c FROM pse__Proj__c WHERE pse__Account__c IN : setOfAccountId]){
            //Checking if Project Name is equal to null or not
            if(project.Name != null){
                mapOfAccountIdAndProjectName.put(project.Name + '-' + project.pse__Account__c, project.id);
                if(mapOfAccountIdAndTemplateUsed.containsKey(project.pse__Account__c)){
                    mapOfAccountIdAndTemplateUsed.get(project.pse__Account__c).add(project.Name);
                } else{
                    mapOfAccountIdAndTemplateUsed.put(project.pse__Account__c, new Set<String> {project.Name});
                }
            }
        }
        //Checking if it is creating Project And ProjectAssetJunction or not
        if(!createProjectAndProjectAssetJunction){
            //Iterating product
            for(Product2 prod : [SELECT ProductCode FROM Product2 WHERE ID IN : setOfProductId]){
                //Checking if map of product records and product code records contains product IDs or not
                if(!mapOfProductAndProductCode.containsKey(prod.id)){
                    mapOfProductAndProductCode.put(prod.id, prod.ProductCode);
                }
            }
            // Getting Mapping from Custom Metadata for getting Project template
            for(Template_Key_and_Id_Mapping__mdt oTemp : [SELECT Key__c, Template_ID__c, Template_Name__c
                                                          FROM Template_Key_and_Id_Mapping__mdt
                                                          WHERE Key__c IN : mapOfProductAndProductCode.values() and
                                                          NSP_From_Object__c = : NSP_ServiceConstants.FROM_OBJECT_ASSET]){
                                                              mKeyToTemplate.put(oTemp.Key__c,oTemp);
                                                          }
        } else {
            for(Template_Key_and_Id_Mapping__mdt oTemp : [SELECT Key__c, Template_ID__c, Template_Name__c
                                                          FROM Template_Key_and_Id_Mapping__mdt
                                                          WHERE Key__c IN : setOfAssetName and
                                                          NSP_From_Object__c = : NSP_ServiceConstants.FROM_OBJECT_ASSET]){
                                                              mKeyToTemplate.put(oTemp.Key__c,oTemp);
                                                          }
        }
        // Creating Project Asset Junction record
        for(Asset ast : [SELECT Name,AccountId, Product2Id FROM Asset WHERE ID IN : setOfAssetId]){
            if(mapOfAccountIdAndTemplateUsed.get(ast.AccountId) != null){
                Project_Asset__c projAsset = new Project_Asset__c ();
                projAsset.Asset__c = ast.id;
                if(!createProjectAndProjectAssetJunction && mapOfProductAndProductCode.containskey(ast.Product2Id)){
                    if(mKeyToTemplate.containsKey(mapOfProductAndProductCode.get(ast.Product2Id))){
                        if(mapOfAccountIdAndTemplateUsed.get(ast.AccountId).contains(mKeyToTemplate.get(mapOfProductAndProductCode.get(ast.Product2Id)).Template_Name__c)){
                            projAsset.Project__c = mapOfAccountIdAndProjectName.get(mKeyToTemplate.get(mapOfProductAndProductCode.get(ast.Product2Id)).Template_Name__c + '-' +ast.AccountId);
                        }
                    }
                } else {
                    if(mapOfAccountIdAndTemplateUsed.get(ast.AccountId).contains(mKeyToTemplate.get(ast.Name).Template_Name__c)){
                        projAsset.Project__c = mapOfAccountIdAndProjectName.get(mKeyToTemplate.get(ast.Name).Template_Name__c + '-' + ast.AccountId);
                    }
                }
                //Adding Project Asset records to list of Project Assets
                listOfProjectAsset.add(projAsset);
            }
        }
        //CHecking if List of Project Asset is empty or not
        if(!listOfProjectAsset.isEmpty()){
            //Inserting List of Project Asset
            Database.insert(listOfProjectAsset, false);
        }
    }

    /**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
*Method Name : afterUpdateFilter
* @param newMap, oldMap List of Assets.
* @return void
*
*/
    public void afterUpdateFilter(Map<Id,Asset> mNewAssets, Map<Id,Asset> mOldAssets){
        Set<Id> updateServiceSegmentAssetIdSet = new Set<Id>();
        List<Asset> lFutureAssets = new List<Asset>();
        List<Asset> lupdateAssets = new List<Asset>();
        Set<Id> firstPayDateUpdatedAccountId = new Set<Id>();
        Set<Id> sAccountIds = new Set<Id>();
        Set<Id> asstIdSet = new Set<Id>();
        Set<Id> asstIdSetWithTermNotice = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        List<Asset> listOfAsset = new List<Asset>();
        Map<ID,String> acctIDStatusMap = new Map<ID,String>();
        //Iterating over New Assets
        for(Asset oAsset  : mNewAssets.values()){
            if(oAsset.AccountId != null){
                sAccountIds.add(oAsset.AccountId);
                if(oAsset.NSP_Biometric_Indicator_Assigned__c == false && oAsset.NSP_Biometric_Start_Date__c >= System.today() && mOldAssets.get(oAsset.Id).NSP_Biometric_Start_Date__c == null ){
                    lupdateAssets.add( new Asset ( Id = oAsset.Id , NSP_Biometric_Indicator_Assigned__c = true));
                    lFutureAssets.add(oAsset);
                }
            }
            //Checking whether Government Contractor is changed or not
            if(oAsset.NSP_Government_Contractor__c != mOldAssets.get(oAsset.Id).NSP_Government_Contractor__c && oAsset.recordTypeId == WOAssetRecordTypeId
              ){
                  asstIdSet.add(oAsset.Id);
              }
            //added as part of STY-00586 changes
            if(oAsset.NSP_Written_Term_recd__c != mOldAssets.get(oAsset.Id).NSP_Written_Term_recd__c
               && oAsset.AccountId != null
               && oAsset.NSP_Written_Term_recd__c == TRUE){
                   asstIdSetWithTermNotice.add(oAsset.Id);
                   accountIdSet.add(oAsset.AccountId);
               }

            //added as part of STY-03597 changes
            if(oAsset.NSP_First_Pay_Date__c !=null && oAsset.NSP_First_Pay_Date__c != mOldAssets.get(oAsset.Id).NSP_First_Pay_Date__c && oAsset.accountId != null){
                firstPayDateUpdatedAccountId.add(oAsset.accountId);
            }

            //As a part ofSTY-02819
            if((oAsset.RecordTypeId == WOAssetRecordTypeId || oAsset.RecordTypeId == wxWaAssetRecordTypeId) &&
               (oAsset.NSP_Client_Segment_type__c != mOldAssets.get(oAsset.Id).NSP_Client_Segment_type__c ||
                oAsset.NSP_Product_Segment__c != mOldAssets.get(oAsset.Id).NSP_Product_Segment__c) || oAsset.Status != mOldAssets.get(oAsset.Id).Status
               && oAsset.AccountId != NULL){
                   updateServiceSegmentAssetIdSet.add(oAsset.AccountId);
               }
        }
        //added as part of STY-03597 changes
        if(!firstPayDateUpdatedAccountId.isEmpty()){
            updateEarliestProductFirstPayDateOnAccount(firstPayDateUpdatedAccountId);
        }
        //added as part of STY-00586 changes
        if(!asstIdSetWithTermNotice.isEmpty() && !accountIdSet.isEmpty()){
            sendRetentionStrategyTerminationEmail(asstIdSetWithTermNotice, accountIdSet);
        }
        //Checking if list of Future assets Size is greater than zero or not
        if(lFutureAssets.size() > 0){
            createCaseFromAsset(lFutureAssets,sAccountIds);
            NSP_AssetTriggerHandler.TriggerDisabled = true;
            update lupdateAssets;
            NSP_AssetTriggerHandler.TriggerDisabled = true;
        }
       //Iterating over New Assets
        for(Asset asset  : mNewAssets.values()){
          if(asset.Status !=mOldAssets.get(asset.Id).Status){
            sAccountIds.add(asset.AccountId);
           }
        }

        List<Account> listofaccts = NSP_AssetServiceTriggerHelper.getAccounts( new List<Id>( sAccountIds ) );
        if ( !listofaccts.isEmpty() ){
            for ( Account acc : listofaccts ) {
                listOfAsset.addAll( acc.Assets );
            }
        }
        //Call to updateAccountStatus method - DF-03777
        this.updateAccountStatus( listofAsset , listOfaccts );

        if(!asstIdSet.isEmpty()){
            mapGovernmentContratcorOnPDS(asstIdSet);
        }
        if(mNewAssets!=null){
            subPlanLeadParentSync(mNewAssets,mOldAssets,false);//<STY-02671>
        }

        //As a part ofSTY-02819
        if(!updateServiceSegmentAssetIdSet.isEmpty()){
            updateServiceSegmentOnAccount(updateServiceSegmentAssetIdSet);
        }
    }

    private static Boolean hasNspBpsCreateAssetAccess {
        private get {
            if ( hasNspBpsCreateAssetAccess == null ) {
                hasNspBpsCreateAssetAccess = CustomPermissionController.checkUserPermission( 'NSP_BPS_Create_Assets_Access' , UserInfo.getUserId() );
            }
            return hasNspBpsCreateAssetAccess;
        }
        private set;
    }

    private static Boolean hasNspRetAssetCreateEdit {
        private get {
            if ( hasNspRetAssetCreateEdit == null ) {
                hasNspRetAssetCreateEdit = CustomPermissionController.checkUserPermission( 'NSP_RET_Asset_Create_Edit' , UserInfo.getUserId() );
            }
            return hasNspRetAssetCreateEdit;
        }
        private set;
    }

    private static void updateRETClientId( Asset record , Asset recordOld ) {
        if ( ( record != null )
            && ( record.RecordTypeId == NSP_AssetServiceTriggerHelper.RETWOAssetRecordTypeId )
            && String.isNotEmpty( record.NSP_WO_AIMS_Client_Number__c )
            && !record.Disable_Sync_RET_Client_ID__c
            && ( recordOld != null )
            && ( ( record.NSP_WO_AIMS_Client_Number__c != recordOld.NSP_WO_AIMS_Client_Number__c )
                || ( record.Disable_Sync_RET_Client_ID__c != recordOld.Disable_Sync_RET_Client_ID__c )
                )
            )
        {
            record.NSP_RET_Client_ID__c = record.NSP_WO_AIMS_Client_Number__c;
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // Method Name:beforeUpdateDirector
    // @param newList List of New Assets.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,Asset> newMap , Map<Id,Asset> oldMap ) {
        List<Asset> notEditableBPSFieldsAssetList = new List<Asset>();
        List<Asset> notEditableRETFieldsAssetList = new List<Asset>();
        Boolean hasBPSCustomPermission = NSP_AssetServiceTriggerHelper.hasNspBpsCreateAssetAccess;
        Boolean hasRETCustomPermission = NSP_AssetServiceTriggerHelper.hasNspRetAssetCreateEdit;
        for(Asset asset : newMap.values()){
            // Check whether Exception checkbox is being checked or Exception reason is being populated.
            Asset oldAsset = oldMap.get(asset.Id);
            NSP_AssetServiceTriggerHelper.updateRETClientId( asset , oldAsset );//10212025-STY-462099
            if((asset.NSP_Segment_Exception__c && !oldAsset.NSP_Segment_Exception__c)
               || (String.isNotBlank(asset.NSP_Segment_Exception_Reason__c) && String.isBlank(oldAsset.NSP_Segment_Exception_Reason__c))){
                   updateSegmentExceptionDetails(asset);
               }
            //<STY-02671> start
            if((asset.RecordTypeId == RETChoiceAssetRecordTypeId ||
                asset.RecordTypeId == RETWOAssetRecordTypeId)
               &&
               asset.NSP_RET_Plan_and_Sub_Plan__c != null &&
               asset.NSP_Client_is_Lead_Parent__c == true &&
               oldMap.get(asset.Id).NSP_Client_is_Lead_Parent__c == false &&
               asset.NSP_RET_lead_parent__c != null
              ){
                  asset.addError(label.NSP_RET_Lead_Parent_Assigned) ;
              }
            //<STY-02671> end
            // added as a part of STY-03212
            if(asset.RecordTypeId == WOAssetRecordTypeId){
                updateTerminationDate(asset,oldMap);
            }

            if(hasBPSCustomPermission == false){
                notEditableBPSFieldsAssetList.add(asset);
            }

            if(hasRETCustomPermission == false){
                notEditableRETFieldsAssetList.add(asset);
            }
        }
        // added as a part of STY-03551
        restrictProductSegupdate(newMap.values() , oldMap);
        //added as a part of STY-03479
        updateAssetTerminationDate(newMap.values() , oldMap);

        //As a part of DF-04328
        if(!notEditableBPSFieldsAssetList.isEmpty()){
            throwErrorMessageForNonEditFields(newMap.values(), oldMap, true, false);
        }
        //As a part of DF-04328
        if(!notEditableRETFieldsAssetList.isEmpty()){
            throwErrorMessageForNonEditFields(newMap.values(), oldMap, false, false);
        }
    }

    //
    // Iterates throught the list of Future Assets and passes the required attributes to other methods.
    // Method Name:createCaseFromAsset
    // @param newList List of Future Assets.
    // @param set<Id>sAccountIds set of Account Ids
    // @return void
    //
    public void createCaseFromAsset( List<Asset> lFutureAssets , Set<Id> sAccountIds ) {
        Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );

        List<NSP_Account_Team__c> lAccountTeams = new List<NSP_Account_Team__c>([SELECT Id,NSP_Account__c,NSP_Role__c,NSP_User__c,NSP_Primary__c FROM NSP_Account_Team__c WHERE NSP_Account__c IN : sAccountIds AND NSP_Role__c IN : lAccountTeamRoles]);

        Map<Id,Map<String,Id>> mAccountToUsers = new Map<ID,Map<String,Id>>();
        Map<Id,Map<String,Boolean>> mAccountToValues = new Map<ID,Map<String,Boolean>>();
        for(NSP_Account_Team__c oAccountTeam: lAccountTeams){
            //Checking if Account Team user Is null or not
            if(oAccountTeam.NSP_User__c == null){
                continue;
            }
                if( mAccountToUsers.get(oAccountTeam.NSP_Account__c) != null ){
                         mAccountToUsers.get(oAccountTeam.NSP_Account__c).put(oAccountTeam.NSP_Role__c,oAccountTeam.NSP_User__c);
                         mAccountToValues.get(oAccountTeam.NSP_Account__c).put(oAccountTeam.NSP_Role__c,oAccountTeam.NSP_Primary__c);
                }else {
                    mAccountToUsers.put(oAccountTeam.NSP_Account__c,new Map<String,Id>{oAccountTeam.NSP_Role__c => oAccountTeam.NSP_User__c});
                    mAccountToValues.put(oAccountTeam.NSP_Account__c,new Map<String,Boolean>{oAccountTeam.NSP_Role__c => oAccountTeam.NSP_Primary__c});
                }
        }
        //Creating list which stores list of cases
        List<Case> lCases = new List<Case>();
        for(Asset oAsset : lFutureAssets){
            Map<String,Id> mAccountTeamUsers = mAccountToUsers.get(oAsset.AccountId);
            Map<String,Boolean> mAccountTeamValues = mAccountToValues.get(oAsset.AccountId);
            Id caseOwnerId = getCaseOwnerId(mAccountTeamUsers, mAccountTeamValues);
            lCases.add(new Case(Subject=REVIEWBIOMETRICSUBJECT,OwnerId = caseOwnerId,NSP_Category__c = HRSERVICECATEGORY,NSP_SubCategory__c = HRINFRASTRUCTURESUBCATEGORY,NSP_Detail__c = CLIENTGUIDANCE,RecordTypeId = peoRecordTypeId,AssetId = oAsset.Id,AccountId = oAsset.AccountId));
        }
        //Checking if list of cases size is zero or not
        if(lCases.size() > 0){
            //Inserting list of cases
            insert lCases;
        }
    }
    /**
*Method Name:getCaseOwnerId
* @param Map<String,Id>mAccountTeamUsers Mapping Account Team And Users
* @return void
*
*/
    public Id getCaseOwnerId(Map<String,Id> mAccountTeamUsers, Map<String,Boolean> mAccountTeamValues){
        Id caseOwnerId = UserInfo.getUserId();
        //Checking if map of Account Team Users is equal to null or not
        if(mAccountTeamUsers != null){
            if(mAccountTeamUsers.get(HRSPECIALISTROLE) != null && mAccountTeamUsers.get(BTHRSPECIALISTROLE) != null){
                caseOwnerId = true == mAccountTeamValues.get(HRSPECIALISTROLE)?
                    mAccountTeamUsers.get(HRSPECIALISTROLE)
                    : mAccountTeamUsers.get(BTHRSPECIALISTROLE);
            }else if(mAccountTeamUsers.get(HRSPECIALISTROLE) != null){
                caseOwnerId = mAccountTeamUsers.get(HRSPECIALISTROLE);
            }else if(mAccountTeamUsers.get(BTHRSPECIALISTROLE) != null){
                caseOwnerId = mAccountTeamUsers.get(BTHRSPECIALISTROLE);
            }else if(mAccountTeamUsers.get(MHRSPECIALISTROLE) != null){
                caseOwnerId = mAccountTeamUsers.get(MHRSPECIALISTROLE);
            }
        }
        return caseOwnerId;
    }

    /**
     * Iterates throught the list of new Assets and passes the required attributes to other methods.
     * Method Name : createAccountGroupsForAssets
     * @param newList List of New Assets.
     * @param Map of new mAssets
     * @return void
     * STY-01099 to create Groups for Account when an asset is added
     */
    public void createAccountGroupsForAssets(List<Asset> newList , Map<Id,Asset> mAssets){
        try{
            Map<Id,Set<Id>> mapAccountIdRecordTypeId = new Map<Id,Set<Id>>();
            //Iterating over new list asset
            for(Asset asset : newList){
                if(mapAccountIdRecordTypeId.containskey(asset.AccountId)){
                    mapAccountIdRecordTypeId.get(asset.AccountId).add(asset.RecordTypeId);
                }else{
                    mapAccountIdRecordTypeId.put(asset.AccountId,new Set<Id>{asset.RecordTypeId});
                }
            }
            //Create Account Groups and Group Members when asset is added to Account
            if(!mapAccountIdRecordTypeId.isEmpty()){
                createAccGroupsMembersGroups(mapAccountIdRecordTypeId,newList);
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'createAccountGroupsForAssets'
            );
        }
    }

    //
    // Iterates throught the list of new Assets to create new groups and group Members
    // @param set of AccountIds.
    // Method Name: createAccGroupsMembersGroups
    // @param list of New Assets
    // @return void
    //
    public void createAccGroupsMembersGroups( Map<Id,Set<Id>> mapAccountIdRecordTypeId , List<Asset> newList ) {
        Id autoCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Account_Group__c' , 'Automatically_Created' );
        Map<Id,Set<String>> mapAccountIdSetGroupType = new Map<Id,Set<String>>();
        Set<NSP_Account_Group__c> lstAccGroups = new Set<NSP_Account_Group__c>();
        List<NSP_Account_Group_Member__c> lstAccGroupMembrs = new List<NSP_Account_Group_Member__c>();
        Id wORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
        //check if AccountGroup Already exists with the associated Account Group member to Account
        for(NSP_Account_Group_Member__c accGroupMember: [SELECT Id, NSP_Member_Account__c , NSP_Member_Account__r.Name, NSP_Group__c, NSP_Group__r.NSP_Type__c, NSP_Group__r.Name FROM  NSP_Account_Group_Member__c  WHERE NSP_Member_Account__c IN: mapAccountIdRecordTypeId.keyset()]){
            if(mapAccountIdSetGroupType.containsKey(accGroupMember.NSP_Member_Account__c)){
                mapAccountIdSetGroupType.get(accGroupMember.NSP_Member_Account__c).add(accGroupMember.NSP_Group__r.NSP_Type__c);
            }else{
                mapAccountIdSetGroupType.put(accGroupMember.NSP_Member_Account__c,new set<string>{accGroupMember.NSP_Group__r.NSP_Type__c});
            }
        }

        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, Name FROM Account WHERE Id IN: mapAccountIdRecordTypeId.keyset()]);

        for(Id accId: mapAccountIdRecordTypeId.keyset()){
            for(Id rectypeId : mapAccountIdRecordTypeId.get(accId)){
                if(rectypeId == wORecordTypeId && !mapAccountIdSetGroupType.isEmpty() && mapAccountIdSetGroupType.containsKey(accId) && !mapAccountIdSetGroupType?.get(accId)?.contains(NSP_ServiceConstants.GROWTH_FORECAST)){
                    lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.GROWTH_FORECAST, NSP_Account__c = mapAccounts.get(accId).Name, NSP_Type__c = NSP_ServiceConstants.GROWTH_FORECAST));
                }
                //Checking Existing Group, not found then Create Groups for all RT except WX_WA
                if(!mapAccountIdSetGroupType.isEmpty() && mapAccountIdSetGroupType.containsKey(accId) && !mapAccountIdSetGroupType?.get(accId)?.contains(NSP_ServiceConstants.RENEWAL_PROBABILITY)){
                    lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.RENEWAL_PROBABILITY, NSP_Account__c = mapAccounts.get(accId).Name, NSP_Type__c = NSP_ServiceConstants.RENEWAL_PROBABILITY));
                }
                if(!mapAccountIdSetGroupType.isEmpty() && mapAccountIdSetGroupType.containsKey(accId) && !mapAccountIdSetGroupType?.get(accId)?.contains(NSP_ServiceConstants.ACCOUNT_HEALTH)){
                    lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.ACCOUNT_HEALTH, NSP_Account__c = mapAccounts.get(accId).Name, NSP_Type__c = NSP_ServiceConstants.ACCOUNT_HEALTH));
                }

                //if No Existing Group Exists Creating New Groups
                if(mapAccountIdSetGroupType.isEmpty()){
                    //Only for WO Growth Forecast will be Created.
                    if(rectypeId == wORecordTypeId ){
                        lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.GROWTH_FORECAST, NSP_Account__c = mapAccounts.get(accId).Name, NSP_Type__c = NSP_ServiceConstants.GROWTH_FORECAST));
                    }
                    //For all recordtypes Renewal and Account Health Groups are Created
                    lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.RENEWAL_PROBABILITY, NSP_Account__c = mapAccounts.get(accId).Name, NSP_Type__c = NSP_ServiceConstants.RENEWAL_PROBABILITY));
                    lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.ACCOUNT_HEALTH, NSP_Account__c =  mapAccounts.get(accId).Name, NSP_Type__c = NSP_ServiceConstants.ACCOUNT_HEALTH));
                }
            }
        }

        //Establish New Realtion for Created/Existing Groups with Account Group Member
        if(!lstAccGroups.isEmpty()){
            List<NSP_Account_Group__c> lstAccGrps = new List<NSP_Account_Group__c>();
            lstAccGrps.addAll(lstAccGroups);
            Database.insert(lstAccGrps,false);

            for(Id key : mapAccountIdRecordTypeId.keyset()){
                for(NSP_Account_Group__c accGroup : lstAccGroups){
                    lstAccGroupMembrs.add(new NSP_Account_Group_Member__c(NSP_Member_Account__c = key,
                        NSP_Group__c = accGroup.Id,
                        NSP_Primary__c = true));
                }
            }
        }
        //Checking if list of accouny group members is empty or not
        if(!lstAccGroupMembrs.isEmpty()){
            Database.Insert(lstAccGroupMembrs,false);
        }
    }

    /**
     * Query all the existing Groups that are associated to Account
     * Method Name: getExistingGroups
     * @param set<Id> setAccountIds
     * @return Map<Id,set<String>> Accounts and AccountRelatedGroups
     */
    public static WxAssetGroup getExistingGroups(List < String > setAccountIds, Set < String > setWXParentIds) {
        Map < String, set < String >> mapGroupIdSetAccountIds = new Map < String, set < String >> ();
        Map < String, String > mapParentIdGroupId = new Map < String, String > ();
        Map<String,Map < String, NSP_Account_Group_Member__c>> accountIdWithGroupMember = new Map<String,Map < String, NSP_Account_Group_Member__c>>();
        WxAssetGroup resultWrapper = new WxAssetGroup();
        //get Account and Existing Groups
        for (NSP_Account_Group_Member__c accGroupMember: [SELECT Id, NSP_Member_Account__c, NSP_Group__r.NSP_Wx_ParentId__c, NSP_Group__c
                FROM NSP_Account_Group_Member__c
                WHERE (NSP_Member_Account__c IN: setAccountIds OR NSP_Group__r.NSP_Wx_ParentId__c IN: setWXParentIds)
                AND NSP_Group__r.NSP_Wx_ParentId__c != null AND NSP_Group__r.NSP_Type__c =: NSP_ServiceConstants.ISOLVED
            ]) {
            if (mapGroupIdSetAccountIds.containsKey(accGroupMember.NSP_Group__r.NSP_Wx_ParentId__c)) {
                mapGroupIdSetAccountIds.get(accGroupMember.NSP_Group__r.NSP_Wx_ParentId__c).add(accGroupMember.NSP_Member_Account__c);
                accountIdWithGroupMember.get(accGroupMember.NSP_Group__r.NSP_Wx_ParentId__c).put(accGroupMember.NSP_Member_Account__c, accGroupMember);
            } else {
                mapGroupIdSetAccountIds.put(accGroupMember.NSP_Group__r.NSP_Wx_ParentId__c, new set < string > {
                    accGroupMember.NSP_Member_Account__c
                });
                accountIdWithGroupMember.put(accGroupMember.NSP_Group__r.NSP_Wx_ParentId__c, new Map<String,NSP_Account_Group_Member__c>{ accGroupMember.NSP_Member_Account__c => accGroupMember });

            }
            mapParentIdGroupId.put(accGroupMember.NSP_Group__r.NSP_Wx_ParentId__c, accGroupMember.NSP_Group__c);
        }
        resultWrapper.mapParentIdGroupId = mapParentIdGroupId;
        resultWrapper.mapGroupIdSetAccountIds = mapGroupIdSetAccountIds;
        resultWrapper.accountIdWithGroupMember = accountIdWithGroupMember;
        return resultWrapper;
    }

    /**
     * check for the WX WA parent and child of Account from Asset and return the count
     * Method Name: getParentCountOfAsset
     * @param set<Id> setAccountIds
     * @param Id wXRecordTypeId
     * @return Map<String,Set<Id>>
     */

    public static WxAssetGroup getParentCountOfAsset(Set < String > setWxParentIds, Id wXRecordTypeId) {
        Map < String, Set < String >> mapWxParentIdAccountId = new Map < String, Set < String >> ();
        Map < String, String > mapParentIdPrimaryAccountId = new Map < String, String > ();
        WxAssetGroup resultWrapper = new WxAssetGroup();

        for (Asset asset: [SELECT AccountId, NSP_WX_WA_Parent_ID__c, NSP_WX_WA_CHILD_ID__c FROM Asset
                WHERE NSP_WX_WA_Parent_ID__c IN: setWxParentIds
                AND recordtypeId =: wXRecordTypeId AND NSP_WX_WA_Parent_ID__c != NULL AND NSP_WX_WA_CHILD_ID__c != NULL
                AND (status !=: NSP_ServiceConstants.ASSETBLACKOUT OR status !=: NSP_ServiceConstants.TERMINATED)
                ORDER BY NSP_WX_WA_Parent_ID__c, NSP_WX_WA_CHILD_ID__c ASC NULLS LAST
            ]) {
            if (!mapWxParentIdAccountId.containsKey(asset.NSP_WX_WA_Parent_ID__c) ) {
                 //Identify parent asset on the using WxParentId field
                mapWxParentIdAccountId.put(asset.NSP_WX_WA_Parent_ID__c, new Set<String> {
                    asset.AccountId
                });
                //Indentify the primaryAccount for the Account Group if child is the least value with the same parent Id
                mapParentIdPrimaryAccountId.put(asset.NSP_WX_WA_Parent_ID__c, asset.AccountId);
            } else {
               //Identify child asset on the using WxchildId field
                mapWxParentIdAccountId.get(asset.NSP_WX_WA_Parent_ID__c).add(asset.AccountId);
            }
        }

        resultWrapper.mapWxParentIdAccountIds = mapWxParentIdAccountId;
        resultWrapper.mapParentIdPrimaryAccountId = mapParentIdPrimaryAccountId;
        return resultWrapper;
    }

    /**
     * Create WX AccountGroup When Asset is Created
     *Method Name: createWXAssetGroups
     * @param List<Asset> newList
     * @return void
     */
    public static void createWXAssetGroups( Map<String,String> mapwXParentIdAccountId , Id wXRecordTypeId ) {
        try{
            if ( !mapwXParentIdAccountId.isEmpty() ) {
                createWXAccountGroup(
                    mapwXParentIdAccountId.keyset() ,
                    mapwXParentIdAccountId ,
                    wXRecordTypeId
                );
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'createWXAssetGroups'
            );
        }
    }

    //
    // Create WX AccountGroup When Asset is Updated
    // Method Name:createWXAssetGroupsonUpdate
    // @param List<Asset> newList
    // @param Map<Id,Asset> oldMap
    // @return void
    //
    public static void createWXAssetGroupsonUpdate( List<Asset> newList , Map<Id,Asset> oldMap ) {
        Map<String,String> mapwXParentIdAccountId = new Map<String,String>();
        Map<String,String> mapOldParentIdAccountId = new Map<String,String>();
        try {
            Id wxRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );
            for (Asset asst: newList) {
                if (isWxAsset(asst, wxRecordTypeId, oldMap)) {
                    mapwXParentIdAccountId.put(asst.NSP_WX_WA_Parent_ID__c, asst.AccountId);
                }
                if (isWxAssetChildUpdated(asst, wxRecordTypeId, oldMap)) {
                    mapOldParentIdAccountId.put(oldMap.get(asst.Id).NSP_WX_WA_Parent_ID__c, oldMap.get(asst.Id).AccountId);
                }
            }

            //Delete Account Group if no Group Member is associated
            if (!mapOldParentIdAccountId.isEmpty()) {
                deleteAccountGroups(mapOldParentIdAccountId);
            }

            //if the WxAssets then Create AccountGroups and Group members
            createWXAccountGroup(mapwXParentIdAccountId.keyset(), mapwXParentIdAccountId, wXRecordTypeId);


        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'createWXAssetGroupsonUpdate'
            );
        }
    }

    /**
     * Check is WXAsset to Create WX AccountGroup
     * @param Asset asst
     * @param Id wxRecordTypeId
     * @param Map<Id,Asset> oldMap
     * @return Boolean
     */
    private static Boolean isWxAsset(Asset asst, Id wxRecordTypeId, Map<Id, Asset> oldMap) {
        return asst.RecordTypeId == wxRecordTypeId && asst.AccountId != NULL && asst.NSP_WX_WA_Parent_ID__c != NULL && asst.NSP_WX_WA_CHILD_ID__c != NULL &&
            (oldMap.get(asst.Id).NSP_WX_WA_Parent_ID__c != asst.NSP_WX_WA_Parent_ID__c || oldMap.get(asst.Id).NSP_WX_WA_CHILD_ID__c != asst.NSP_WX_WA_CHILD_ID__c || oldMap.get(asst.Id).Status != asst.Status) &&
            (asst.Status != NSP_ServiceConstants.ASSETBLACKOUT || asst.Status != NSP_ServiceConstants.TERMINATED);
    }

    /**
     * Check is WXAsset to Create WX AccountGroup
     * @param Asset asst
     * @param Id wxRecordTypeId
     * @param Map<Id,Asset> oldMap
     * @return Boolean
     */
    private static Boolean isWxAssetChildUpdated(Asset asst, Id wxRecordTypeId, Map<Id, Asset> oldMap) {
        return asst.RecordTypeId == wxRecordTypeId && asst.AccountId != NULL && (asst.Status != NSP_ServiceConstants.ASSETBLACKOUT || asst.Status != NSP_ServiceConstants.TERMINATED) &&
            ((oldMap.get(asst.Id).NSP_WX_WA_CHILD_ID__c != asst.NSP_WX_WA_CHILD_ID__c && asst.NSP_WX_WA_CHILD_ID__c == NULL ) || oldMap.get(asst.Id).NSP_WX_WA_Parent_ID__c != asst.NSP_WX_WA_Parent_ID__c || oldMap.get(asst.Id).Status != asst.Status);
    }


    //
    // When Asset is WxAsset, New Account Group and Account GroupMember is Created
    // @param List<Asset> newList
    // @param List<String> listWXParentIds
    // @param Map<String,String> mapwXParentIdAccountId
    // @param Id wXRecordTypeId
    // @return void
    //
    private static void createWXAccountGroup( Set<String> setWXParentIds , Map<String,String> mapwXParentIdAccountId , Id wXRecordTypeId ) {
        Id autoCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Account_Group__c' , 'Automatically_Created' );

        List < sObject > lstRecordsToUpsert = new List < sObject > ();

        WxAssetGroup assetAccountsWrapper = getParentCountOfAsset(setWXParentIds, wXRecordTypeId);
        //Get WxParentId and Set of AccountIds to Create Account Groups
        Map < String, Set < String >> mapWXParentIdSetAccountIds = assetAccountsWrapper.mapWxParentIdAccountIds;
        Map < String, String > mapParentIdPrimaryAccountId = assetAccountsWrapper.mapParentIdPrimaryAccountId;
        //check if AccountGroup Already exists with the associated Account Group member to Account
        WxAssetGroup existingGroupsWrapper = getExistingGroups(mapwXParentIdAccountId.values(), setWXParentIds);
        Map < String, Set < String >> existingGroupIdSetAccountIds = existingGroupsWrapper.mapGroupIdSetAccountIds;
        Map <String, Map < String, NSP_Account_Group_Member__c>> accountIdWithGroupMember = existingGroupsWrapper.accountIdWithGroupMember;
        //check if AccountGroup Already exists with the associated Account Group member to Account
        Map < String, String > existingGroupAccountIds = existingGroupsWrapper.mapParentIdGroupId;
        //Get Accounts to map the primary Account of ther group
        Map < Id, Account > mapAccounts = new Map < Id, Account > ([SELECT Id, Name FROM Account WHERE Id IN: mapParentIdPrimaryAccountId.values()]);

        if (!mapWXParentIdSetAccountIds.isEmpty()) {
            //iterate WX ParenId and create Group and Group Members
            for (String parentId: mapWXParentIdSetAccountIds.keyset()) {
                Map<String, NSP_Account_Group_Member__c>  existingAccountGrpMbrs = accountIdWithGroupMember.get(parentId);
                Integer wxParentIdAccountsCount = mapWXParentIdSetAccountIds.containskey(parentId) ? mapWXParentIdSetAccountIds?.get(parentId)?.size() : 0;
                //Creating Account group if doesnot exists for Account
                if (!existingGroupIdSetAccountIds.containsKey(parentId) && wxParentIdAccountsCount >= 2) {
                    lstRecordsToUpsert.add(
                        new NSP_Account_Group__c(
                            RecordTypeId = autoCreatedRecordTypeId,
                            Name = NSP_ServiceConstants.ISOLVED,
                            NSP_Wx_ParentId__c = parentId,
                            NSP_Account__c = mapAccounts.get(mapParentIdPrimaryAccountId?.get(parentId))?.Name,
                            NSP_Type__c = NSP_ServiceConstants.ISOLVED
                        )
                    );
                }

                for (String accId: mapWXParentIdSetAccountIds.get(parentId)) {
                    //Creating Account group Memeber if doesnot exists for Account
                    if (existingAccountGrpMbrs == NULL && wxParentIdAccountsCount >= 2) {

                        NSP_Account_Group_Member__c accGrpMem = new NSP_Account_Group_Member__c(NSP_Member_Account__c = accId, NSP_Primary__c = false);
                        if (mapParentIdPrimaryAccountId?.containskey(parentId) && mapParentIdPrimaryAccountId?.get(parentId) == accId) {
                            accGrpMem.NSP_Primary__c = true;
                        }
                        NSP_Account_Group__c accountGrpReference = new NSP_Account_Group__c(NSP_Wx_ParentId__c = parentId);
                        accGrpMem.NSP_Group__r = accountGrpReference;
                        lstRecordsToUpsert.add(accGrpMem);

                    } else if (existingAccountGrpMbrs != NULL && !existingAccountGrpMbrs?.containsKey(accId) && wxParentIdAccountsCount >= 2) {
                        //Creating Account group Memeber if doesnot exists for Account
                        NSP_Account_Group_Member__c accGrpMem = new NSP_Account_Group_Member__c(NSP_Member_Account__c = accId, NSP_Group__c = existingGroupAccountIds.get(parentId));
                        if (mapParentIdPrimaryAccountId.containskey(parentId) && mapParentIdPrimaryAccountId?.get(parentId) == accGrpMem.NSP_Member_Account__c) {
                            accGrpMem.NSP_Primary__c = true;
                        }
                        lstRecordsToUpsert.add(accGrpMem);

                    } else if (existingAccountGrpMbrs != NULL && existingAccountGrpMbrs?.containsKey(accId) && wxParentIdAccountsCount >= 2 && mapParentIdPrimaryAccountId?.get(parentId) == existingAccountGrpMbrs?.get(accId)?.NSP_Member_Account__c) {

                        //Creating Account group Memeber if doesnot exists for Account
                        NSP_Account_Group_Member__c accGrpMem = existingAccountGrpMbrs?.get(accId);
                        accGrpMem.NSP_Primary__c = true;
                        lstRecordsToUpsert.add(accGrpMem);

                    }
                }
            }
            if (!lstRecordsToUpsert.isEmpty()) {
                lstRecordsToUpsert.sort();
                List<Database.UpsertResult> results = Database.upsert(lstRecordsToUpsert, false);
                NSP_ErrorLogHandler.logResults(
                    NSP_AssetServiceTriggerHelper.class.getName() ,
                    'createWXAccountGroup' ,
                    results
                );
            }
        }
    }

    /**
     * Delete Account Group if no Group Member is associated
     * @param set<Id>setAccountIds
     * @return Void
     */
    @TestVisible
    private static void deleteAccountGroups(Map < String, String > mapOldParentIdAccountId) {
        List < sObject > lstAccGroupsToDelete = new List < sObject > ();

        for (NSP_Account_Group_Member__c grpMembr: [SELECT Id, NSP_Group__c, NSP_Member_Account__c,
                NSP_Group__r.NSP_Group_Member_Count__c
                FROM NSP_Account_Group_Member__c
                WHERE NSP_Group__r.NSP_Wx_ParentId__c IN: mapOldParentIdAccountId.keyset()
                AND NSP_Member_Account__c IN: mapOldParentIdAccountId.values()
                AND NSP_Group__r.NSP_Type__c =: NSP_ServiceConstants.ISOLVED
            ]) {
            //if group has more than 3 members delete only group Member
            if (grpMembr.NSP_Group__r.NSP_Group_Member_Count__c > 2) {
                lstAccGroupsToDelete.add(new NSP_Account_Group_Member__c(Id = grpMembr.Id));
            } else {
                //if group has less than 3 members delete group
                lstAccGroupsToDelete.add(new NSP_Account_Group__c(Id = grpMembr.NSP_Group__c));
            }
        }

        if (!lstAccGroupsToDelete.isEmpty()) {
            Database.DeleteResult[] lstGroupResults = Database.delete(lstAccGroupsToDelete, false);
            NSP_ErrorLogHandler.logResults(
                NSP_AssetServiceTriggerHelper.class.getName() ,
                'deleteAccountGroups' ,
                lstGroupResults
            );
        }
    }

    public class WxAssetGroup {
        public Map < String, Set < String >> mapWxParentIdAccountIds;
        public Map < String, String > mapParentIdPrimaryAccountId;
        public Map < String, String > mapParentIdGroupId;
        public Map < String, Set < String >> mapGroupIdSetAccountIds;
        public Map<String,Map < String, NSP_Account_Group_Member__c>> accountIdWithGroupMember;
    }

    // Updates Segment Exception Set By & Segment Exception Date field.
    private void updateSegmentExceptionDetails(Asset asset){
        asset.NSP_Segment_Exception_Set_By__c = UserInfo.getName();
        asset.NSP_Segment_Exception_Date__c = Date.today();
    }

    /**
    * Name        : linkProjectWithAsset
    * Purpose     : Method to link the entity to the project
    * @param      : Id projectId, Id assetId
    * @return     : Project_Asset__c
    */
    public static Project_Asset__c linkProjectWithAsset(Id projectId, Id assetId){
        Project_Asset__c newProject = new Project_Asset__c();
        newProject.Project__c = projectId;
        newProject.Asset__c = assetId;

        return newProject;
    }

    public Id createProjectWithTemplateFromAsset(Template_Key_and_Id_Mapping__mdt oTempKey, Id assetId){
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest =
            new pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest(oTempKey.Template_ID__c, System.Today());

        projRequest.ProjectName = oTempKey.Template_Name__c;
        projRequest.IsActive = true;
        projRequest.Mappers = new List<pse.SObjectCloneMapper>{
            NSP_CreateProjFromFlow.getDefaultMappers()
        };
        List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = this.implInstance.createProjectwithTemplate(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{ projRequest });
        ID newProjectId = this.implInstance.getProjectId(projResponse);
        //Delete Budget
        List<pse__Budget__c> lBudgets = [SELECT id FROM pse__Budget__c WHERE pse__Project__c = : newProjectId];
        delete lBudgets;
        return this.implInstance.getProjectId(projResponse);
    }

    private static Boolean isMidMarketAsset(String segmentType){
        return segmentType == NSP_ServiceConstants.MMAssetSegment || segmentType == NSP_ServiceConstants.MMEAssetSegment;
    }

    private static Boolean isFsoAsset(String segmentType){
        return segmentType == NSP_ServiceConstants.EG100AssetSegment || segmentType == NSP_ServiceConstants.EG50AssetSegment
            || segmentType == NSP_ServiceConstants.CoreAssetSegment || segmentType == NSP_ServiceConstants.BTAssetSegment;
    }

    public static void updatePaperlessBatchDateBeforeInsertOrUpdate(List<Asset> NewList , Map<Id, Asset> OldMap){
        Id WORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('WO').getRecordTypeId();

        For(Asset assetObj : NewList){
            If(assetObj.RecordTypeId == WORecordTypeId &&
               ((assetObj.NSP_Account_Status__c != null && OldMap == null) ||
                (OldMap != null && OldMap.containskey(assetObj.Id) &&
                 assetObj.NSP_Account_Status__c != OldMap.get(assetObj.Id).NSP_Account_Status__c))){
                     assetObj.NSP_Paperless_Batch_Date__c = System.Today();
                 }
        }
    }

    /**
* Name        : linkAssetWithImpProfileAndImpProject
* Purpose     : This method describes that when asset is created after the Implementation profile, then map the created asset to the
Implementation profile related to the account of the created asset
* @param      : Map<String, Asset> mapOfAccountIdAsset
* @return     : void
* @story      : STY-00667
*/
    public static void linkAssetWithImpProfile(Map < Id, Id > mapOfAccountIdAssetId){
        List < Implementation_Profile__c > impProfileList = new List < Implementation_Profile__c > ();
        for (Implementation_Profile__c impPro : [SELECT Id,
                                                 Account__c,
                                                 NSP_Asset__c
                                                 FROM Implementation_Profile__c
                                                 WHERE Account__c IN: mapOfAccountIdAssetId.keySet()
                                                 AND NSP_Asset__c = null]) {
                                                     impPro.NSP_Asset__c = mapOfAccountIdAssetId.get(impPro.Account__c);
                                                     impProfileList.add(impPro);
                                                 }
        if (!impProfileList.isEmpty()) {
            try {
                database.update(impProfileList);
            } catch ( Exception e ) {
                NSP_AssetServiceTriggerHelper.handleException(
                    e ,
                    'linkAssetWithImpProfile'
                );
            }
        }
    }
    /**
* @MethodName: mapGovernmentContratcorOnPDS
* @Description: This method is used to map Government Contractor checkbox on PDS after Asset Update
* @param :Set<Id> assetIdSet
* @createdDate : 10/11/2022
* @Defect : STY-03277
* @return void
*/
    public void mapGovernmentContratcorOnPDS(Set<Id> assetIdSet){
        Map<Id, Boolean> isSubClientGovConMap = new Map<Id, Boolean>(); // Map of SubCLient and Its related Asset Government Contrator
        List<NSP_Payroll__c> payRollList = new List<NSP_Payroll__c>(); // To store payroll List to Update
        for(NSP_Sub_Client__c  subClient :[SELECT Id,
                                           NSP_Asset__c,
                                           NSP_Asset__r.NSP_Government_Contractor__c,
                                           NSP_Asset__r.recordTypeId
                                           FROM NSP_Sub_Client__c
                                           WHERE NSP_Asset__c IN: assetIdSet] ){
                                            isSubClientGovConMap.put(subClient.Id, subClient.NSP_Asset__r.NSP_Government_Contractor__c);
                                           }
        if(!isSubClientGovConMap.isEmpty()){
            for(NSP_Payroll__c pRoll : [SELECT Id, NSP_Sub_Client_Name__c,
                                        NSP_Government_Contractor__c
                                        FROM NSP_Payroll__c
                                        WHERE NSP_Sub_Client_Name__c IN:isSubClientGovConMap.keySet() ]){
                                            pRoll.NSP_Government_Contractor__c = isSubClientGovConMap.get(pRoll.NSP_Sub_Client_Name__c);
                                            payRollList.add(pRoll);
                                        }
            try{
                if(!payRollList.isEmpty()){
                    Database.update(payRollList);
                }
            } catch ( Exception e ) {
                NSP_AssetServiceTriggerHelper.handleException(
                    e ,
                    'mapGovernmentContratcorOnPDS'
                );
            }
        }
    }

    //<STY-02671> start
    public void UpdateLstPSP( List<NSP_Plan_SubPlan__c> PSPToUpdate ) {
        try {
            Database.update( PSPToUpdate );
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'UpdateLstPSP'
            );
        }
    }

    public void UpdateLstAssets( List<Asset> assetToUpdate ) {
        try {
            if ( !assetToUpdate.isEmpty() ) {
                Database.update( assetToUpdate );
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'UpdateLstAssets'
            );
        }
    }
    //<STY-02671> end

    /**
* @MethodName: subPlanLeadParentSync
* @Description: This method is used to update asset, plan subplan after insert/update
* @param : Set<Id> PSPIds
* @createdDate : 17/10/2022
* @Defect : <STY-02671>
* @return void
*/
    public void  subPlanLeadParentSync (Map<Id, Asset> newMap,Map<Id, Asset> oldMap,boolean IsInsert){
        Set<Id> PSPIds = new Set<Id>();
        Map<Id, Id> asstPSPMap = new Map<Id, Id>();
        List<Asset> assetToUpdate = new List<Asset>() ;
        List<NSP_Plan_SubPlan__c> PSPToUpdate = new List<NSP_Plan_SubPlan__c>() ;
        Set<Id> PSPIdsRemove = new Set<Id>();

        for(Asset asst:newMap.values() ){
            // Insert/ Update -> check for NSP_Client_is_Lead_Parent__c = true condition, store plansubplan IDs
            if( (asst.RecordTypeId == RETChoiceAssetRecordTypeId ||
                 asst.RecordTypeId == RETWOAssetRecordTypeId) &&
               asst.NSP_RET_Plan_and_Sub_Plan__c != null &&
               asst.NSP_Client_is_Lead_Parent__c == true &&
               asst.NSP_RET_lead_parent__c == null &&
               ((IsInsert == false &&
                 oldMap.get(asst.Id).NSP_Client_is_Lead_Parent__c == false) ||
                IsInsert == true )){
                    PSPIds.add(asst.NSP_RET_Plan_and_Sub_Plan__c);
                    asstPSPMap.put(asst.NSP_RET_Plan_and_Sub_Plan__c, asst.Id);
                }
            // If NSP_Client_is_Lead_Parent__c is unchecked, then nullify NSP_RET_lead_parent__c,NSP_Subplan_Lead_Parent__c values in Plan subplan and related asset records
            if(IsInsert == false &&
               (asst.RecordTypeId == RETChoiceAssetRecordTypeId ||
                asst.RecordTypeId == RETWOAssetRecordTypeId) &&
               asst.NSP_RET_Plan_and_Sub_Plan__c != null &&
               asst.NSP_Client_is_Lead_Parent__c == false &&
               oldMap.get(asst.Id).NSP_Client_is_Lead_Parent__c == true){
                   PSPIdsRemove.add(asst.NSP_RET_Plan_and_Sub_Plan__c);
                   PSPIds.add(asst.NSP_RET_Plan_and_Sub_Plan__c);
               }
        }
        // Query Asset records which has same plan subplan IDs
        for(Asset asst: [Select id,NSP_RET_lead_parent__c , NSP_RET_Plan_and_Sub_Plan__c, NSP_Client_is_Lead_Parent__c FROM Asset WHERE NSP_RET_Plan_and_Sub_Plan__c in : PSPIds ]){
            Asset asstRec = new Asset();
            asstRec.Id = asst.Id;
            // Get the related asset records which has same plan subplan and update it's NSP_RET_lead_parent__c field to current Asset
            if(asstPSPMap.containskey(asst.NSP_RET_Plan_and_Sub_Plan__c) &&
               asstPSPMap.get(asst.NSP_RET_Plan_and_Sub_Plan__c) !=  asst.Id){
                   asstRec.NSP_RET_lead_parent__c = asstPSPMap.get(asst.NSP_RET_Plan_and_Sub_Plan__c);
                   assetToUpdate.add(asstRec);
               }
            // check for asset with plan subplan ID to remove NSP_RET_lead_parent__c field value as NSP_Client_is_Lead_Parent__c is unchecked
            if(PSPIdsRemove.contains(asst.NSP_RET_Plan_and_Sub_Plan__c)){
                asstRec.NSP_RET_lead_parent__c = null;
                assetToUpdate.add(asstRec);
            }
        }
        for(Id PSPIdsLst : asstPSPMap.keySet()){
            //Get all the plan subplan records and update NSP_Subplan_Lead_Parent__c field
            NSP_Plan_SubPlan__c PSPRec =  new NSP_Plan_SubPlan__c();
            PSPRec.Id = PSPIdsLst;
            PSPRec.NSP_Subplan_Lead_Parent__c = asstPSPMap.get(PSPIdsLst);
            PSPToUpdate.add(PSPRec);
        }
        for(Id PSPIdsLst : PSPIdsRemove){
            //Get all the plan subplan records and nullify NSP_Subplan_Lead_Parent__c field as NSP_Client_is_Lead_Parent__c is unchecked
            NSP_Plan_SubPlan__c PSPRec =  new NSP_Plan_SubPlan__c();
            PSPRec.Id = PSPIdsLst;
            PSPRec.NSP_Subplan_Lead_Parent__c = null;
            PSPToUpdate.add(PSPRec);
        }
        // Update related assets
        if(!assetToUpdate.isEmpty()){
            UpdateLstAssets(assetToUpdate);
        }
        //Update plan subplan records
        if(!PSPToUpdate.isEmpty()){
            UpdateLstPSP(PSPToUpdate);
        }
    }

    /***********************************************************************************************
* MethodName: updateTerminationDate
* Description :  This method updates the Termination Dates on Asset
* Added as part of STY-03212
* Author: Nischay Jindal
* ********************************************************************************************/
    public static void updateTerminationDate(Asset ast, Map<Id, Asset> oldAssetMap){
        Id woassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        // checking if the status is terminated
        if(ast.RecordTypeId != woassetRecordTypeId){
        if(ast.NSP_Account_Status__c != null && ast.NSP_Account_Status__c == NSP_ServiceConstants.TERMINATED  &&
           (oldAssetMap.get(ast.Id).NSP_Account_Status__c != NSP_ServiceConstants.TERMINATED ||
            (ast.NSP_Account_Status_Date__c != oldAssetMap.get(ast.Id).NSP_Account_Status_Date__c) ) ){
                // update termination date
                ast.NSP_Termination_Date__c = ast.NSP_Account_Status_Date__c;
            }
        else if(ast.NSP_Account_Status__c != null && ast.NSP_Account_Status__c == NSP_ServiceConstants.ASSET_ACTIVE_STATUS  &&
                oldAssetMap.get(ast.Id).NSP_Account_Status__c == NSP_ServiceConstants.TERMINATED ){
                    ast.NSP_Termination_Date__c = null;
                }
        }
    }

    /***********************************************************************************************
    * MethodName: restrictProductSegupdate
    * Description :  This method restricts the Product Segment Update on Asset
    * Added as part of STY-03551
    * Author: Nischay Jindal
    * ********************************************************************************************/
    public static void restrictProductSegupdate(List<Asset> assetList , Map<Id,Asset> oldAssetMap){
        Map<String,String> projectAssetRecordTypeMap = new Map<String,String>();
        Set<Id> assetIdSet = new Set<Id>();
        Set<Id>assetRecordTypeIdSet = new Set<Id>();
        Map<Id,List<PermissionSetAssignment>> mapUserIdSetPSA = new Map<Id,List<PermissionSetAssignment>>();
        Set<Id> eligibleAssets = new Set<Id>();
        try{
            // creating a map of Asset recordtype and Project Tempaltes
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.WX_WA,NSP_ServiceConstants.HCM_PROJECT_NAME);
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.ASSET_TT_RECORDTYPE,NSP_ServiceConstants.ITA_IMPLEMENTATION);
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.APPLICANT_TRACKING_RECORD_TYPE,NSP_ServiceConstants.RSTalentConnectIMP);
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.ASSET_OP_RECORDTYPE,NSP_ServiceConstants.OPRTImpl);
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.PERFORMANCE_ASSET,NSP_ServiceConstants.PERFORMSMART_IMPLEMENTATION);
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.INTEGRA_ASSET,NSP_ServiceConstants.INTEGRA_IMPLEMENTATION);
            projectAssetRecordTypeMap.put(NSP_ServiceConstants.XML_ASSET,NSP_ServiceConstants.XMLProject);

            // retreiving BPS Permission Set
            PermissionSet bpsPermissionSet = [SELECT Id FROM PermissionSet WHERE Name =: NSP_ServiceConstants.bpsAssetPermSet];

            // checking if the current user has BPS perm Set Assigned
            List<PermissionSetAssignment> bpsAssignments = [Select Id,AssigneeId FROM PermissionSetAssignment WHERE
                                                            PermissionSetId =:bpsPermissionSet.Id AND AssigneeId =:userInfo.getUserId() ];
            // creating a map of user and PSA
            for(PermissionSetAssignment psa :bpsAssignments){
                if(!mapUserIdSetPSA.containsKey(psa.AssigneeId)){
                    mapUserIdSetPSA.put(psa.AssigneeId , new List<PermissionSetAssignment>());
                }
                mapUserIdSetPSA.get(psa.AssigneeId).add(psa);
            }
            // retreiving the asset recordtype ID
            for(String AstRecordType : projectAssetRecordTypeMap.keySet()){
                assetRecordTypeIdSet.add(NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,AstRecordType));
            }
            // creating AssetId set to retrieve the Project Assets
            for(Asset asset:assetList){
                if(mapUserIdSetPSA.containsKey(userInfo.getUserId()) && assetRecordTypeIdSet.contains(asset.RecordTypeId)){
                    assetIdSet.add(asset.Id);
                }
            }
            // fetching Project Asset List
            List<String> FIELDS = new List<String>{'Id','Asset__c', 'Asset__r.RecordType.DeveloperName', 'Project__r.pse__Project_Status__c', 'Asset__r.NSP_Product_Segment__c',
                'Project__c', 'Project__r.TemplateName__c', 'Project__r.NSP_Client_Size__c'};

                    NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Project_Asset__c', FIELDS);
            queryBuilder.setSecurityEnforce(false);
            String queryPrjAsset = queryBuilder.build();
            queryPrjAsset += ' WHERE Asset__c IN:assetIdSet  AND  (Project__r.pse__Project_Status__c != ' + '\''+ NSP_ServiceConstants.ASSET_ONBOARDING_STATUS +'\''+ ' OR Project__r.pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.INTAKE+'\''+ ')';

            List<Project_Asset__c> prjAssetList = Database.Query(queryPrjAsset);

            // creating set of eligible Assets
            for(Project_Asset__c prjAsset :prjAssetList){
                if(projectAssetRecordTypeMap.containsKey(prjAsset.Asset__r.RecordType.DeveloperName)
                   && projectAssetRecordTypeMap.get(prjAsset.Asset__r.RecordType.DeveloperName) == prjAsset.Project__r.TemplateName__c ){
                       eligibleAssets.add(prjAsset.Asset__c );
                   }
            }
            // validating the Assets  records
            for(Asset asset:assetList){
                if(asset.NSP_Product_Segment__c!=oldAssetMap.get(asset.Id).NSP_Product_Segment__c
                   && mapUserIdSetPSA.containsKey(userInfo.getUserId()) && assetRecordTypeIdSet.contains(asset.RecordTypeId)
                   && !eligibleAssets.contains(asset.Id)){
                       asset.addError(label.NSP_BPSPermisisonAssetValidation);
                   }
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'restrictProductSegupdate'
            );
        }
    }

    /**************************************************************************
* MethodName    : sendRetentionStrategyTerminationEmail
* Description   : This method is used to send email to particular
*                 Account Team roles after asset update
* Params        : Map<Id, sObject> newMap, Map<Id, sObject> oldMap
* **************************************************************************/
    public void sendRetentionStrategyTerminationEmail(Set<Id> assetIdSet, Set<Id> accountIdSet){
        //Variable Declaration
        List<String> payrollRolesUsers = new List<String>();
        List<String> otherRolesUsers = new List<String>();

        // check accountIDset not empty
        if(!accountIdSet.isEmpty()){
            for(NSP_Account_Team__c team : [SELECT Id,NSP_Account__c, NSP_Role__c, NSP_User__c
                                            FROM NSP_Account_Team__c
                                            WHERE NSP_Account__c IN: accountIdSet
                                            AND (NSP_Role__c =: NSP_ServiceConstants.BUS_TEAM_HRSP_CL
                                                 OR NSP_Role__c =: NSP_ServiceConstants.PAYROLL_SPECIALIST
                                                 OR NSP_Role__c =: NSP_ServiceConstants.PAYROLL_SUPERVISOR
                                                 OR NSP_Role__c =: NSP_ServiceConstants.CLIENT_LIAISION
                                                 OR NSP_Role__c =: NSP_ServiceConstants.MANAGER_HRSERVICES
                                                 OR NSP_Role__c =: NSP_ServiceConstants.EXECUTIVE)]){
                                                     //Adding Payroll related role users to list
                                                     if(team.NSP_Role__c == NSP_ServiceConstants.PAYROLL_SPECIALIST
                                                        || team.NSP_Role__c == NSP_ServiceConstants.PAYROLL_SUPERVISOR){
                                                            payrollRolesUsers.add(team.NSP_User__c);
                                                        }
                                                     //Adding Other role users to list
                                                     if(team.NSP_Role__c == NSP_ServiceConstants.CLIENT_LIAISION
                                                        || team.NSP_Role__c == NSP_ServiceConstants.MANAGER_HRSERVICES
                                                        || team.NSP_Role__c == NSP_ServiceConstants.EXECUTIVE
                                                        || team.NSP_Role__c == NSP_ServiceConstants.BUS_TEAM_HRSP_CL) {
                                                            otherRolesUsers.add(team.NSP_User__c);
                                                        }
                                                 }
        }

        //Sending email to payroll role users
        if(!payrollRolesUsers.isEmpty()){
            sendMail(assetIdSet, accountIdSet, ASSET_TERMINATION_PAYROLL_TEMPLATE, payrollRolesUsers);
        }
        //Sending email to other role users
        if(!otherRolesUsers.isEmpty()){
            sendMail(assetIdSet, accountIdSet, ASSET_TERMINATION_OTHER_ROLE_TEMPLATE, otherRolesUsers);
        }
    }

    //
    // MethodName : sendMail
    // Description : This method is used to send email
    // Params : Map<Id, Asset> newMap, String templateName, List<String> sendToAddress
    //
    public void sendMail( Set<Id> assetIdSet , Set<Id> accountIdSet , String templateName , List<String> sendToAddress ) {
        if ( EmailDeliverabilityController.isEnabledOutbound ) {
            String mailBody;
            List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

            List<String> fields = new List<String>{'Id'};
            Id emailTemplateId = NSP_sObjectSelector.selectByDeveloperName(fields, templateName).Id;

            List<String> rsvpFields = new List<String>{'Id'};
            String query = new NSP_QueryBuilder('NSP_Relationship_Strategy_Action_Plan__c', rsvpFields)
                .addFilter('NSP_Account__c', new List<Id>(accountIdSet), NSP_QueryBuilder.Operator.INCLUDES)
                .orderBy('createdDate', 'DESC', false).addLimit(1).build()
                ;
            List<NSP_Relationship_Strategy_Action_Plan__c> rsvp = (List<NSP_Relationship_Strategy_Action_Plan__c>)Database.query(query);

            if(!rsvp.isEmpty()){
                String rsvpURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' +rsvp[0].Id;

                if(emailTemplateId != null){
                    for(Id assetId : assetIdSet){
                        Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateId, UserInfo.getUserId(), assetId);
                        if(email.htmlbody.contains(RSAP)){
                            mailBody = email.getHtmlBody()+NSP_ServiceConstants.BLANK_SPACE+'<a href="'+rsvpURL+'"'+'>'+rsvpURL+'</a>';
                            email.setHtmlBody(mailBody);
                        }
                        email.setTemplateId(emailTemplateId);
                        email.setToAddresses(sendToAddress);
                        email.setSaveAsActivity(false);
                        emailList.add(email);
                    }

                    if ( emailList.size() > 0 ) {
                        try {
                            Messaging.sendEmail( emailList );
                        } catch ( Exception e ) {
                            NSP_AssetServiceTriggerHelper.handleException(
                                e ,
                                'sendMail'
                            );
                        }
                    }
                }
            }
        }
    }

    private static void handleException( Exception e , String methodName ) {
        if ( e != null ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetServiceTriggerHelper.class.getName() ,
                methodName ,
                e
            );
        }
    }

    /***********************************************************************************************
* MethodName: updateEarliestProductFirstPayDateOnAccount
* Description : update related account with earliest first pay date
* Story : STY-03597
* Author :Abhishek Kumar
* Params: List<Asset> assetList
* ********************************************************************************************/
    public void updateEarliestProductFirstPayDateOnAccount(Set<Id> accountsId ){
        Map<Id,Account> mapOfAccountIdWithAccount = new Map<Id,Account>();
        Boolean isCheckFirstIteration = true;
        try{

            //iterating over account to map rec with Id
            for(Account eachAccount : [ SELECT Id,NSP_Product_First_Pay_Date__c FROM Account WHERE Id IN: accountsId]){
                mapOfAccountIdWithAccount.put(eachAccount.Id,eachAccount );
            }
            //iterating over all related asset to account to get earliest pay date
            for(Asset eachRelatedAsset : [ SELECT Id,accountId,NSP_First_Pay_Date__c FROM Asset WHERE accountId IN: accountsId]){
                //comparing if NSP_First_Pay_Date__c on asset is earlier than NSP_Product_First_Pay_Date__c on account
                 if(eachRelatedAsset.NSP_First_Pay_Date__c != null &&
                (isCheckFirstIteration ||
                    (mapOfAccountIdWithAccount.get(eachRelatedAsset.accountId).NSP_Product_First_Pay_Date__c != null && mapOfAccountIdWithAccount.get(eachRelatedAsset.accountId).NSP_Product_First_Pay_Date__c > eachRelatedAsset.NSP_First_Pay_Date__c)||
                    (mapOfAccountIdWithAccount.get(eachRelatedAsset.accountId).NSP_Product_First_Pay_Date__c == null && eachRelatedAsset.NSP_First_Pay_Date__c != null)
                    )){
                       mapOfAccountIdWithAccount.get(eachRelatedAsset.accountId).NSP_Product_First_Pay_Date__c = eachRelatedAsset.NSP_First_Pay_Date__c;
                }
                isCheckFirstIteration = false;
            }
            //update account with earliest first pay date
            if ( !mapOfAccountIdWithAccount.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( mapOfAccountIdWithAccount.values() );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssetServiceTriggerHelper.class.getName() ,
                    'updateEarliestProductFirstPayDateOnAccount' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'updateEarliestProductFirstPayDateOnAccount'
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updateAssetTerminationDate
* Description : update termination date on Asset
* Story : STY-03479
* Author :Nischay Jindal
* Params: List<Asset> assetList , Map<Id,Asset> oldAssetMap
* ********************************************************************************************/
    public static void updateAssetTerminationDate(List<Asset> assetList , Map<Id,Asset> oldAssetMap ){
        Set<Id> assetIdSet = new Set<Id>();
        Map<Id,Project_Asset__c> assetProjectAssetMap = new Map<Id,Project_Asset__c>();
        Id woAssetRecordTypeId =NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Id hardwareAssetRecordTypeId =NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_CPQConstants.HARWARE_ASSET_RECORDTYPE);
        try{
            for(Asset ast :assetList){
                if( (ast.Status== NSP_ServiceConstants.TERMINATED || ast.Status == NSP_ServiceConstants.BACKOUT)
                   && ast.Status != oldAssetMap.get(ast.Id).Status){
                       assetIdSet.add(ast.Id);
                   }
            }
            if(!assetIdSet.isEmpty()){
                for(Project_Asset__c prjAsset: [Select Id ,Project__c, Asset__r.NSP_OrderProduct__r.Order.Status, Project__r.Go_Live_Date__c, Project__r.pse__Project_Status__c, Asset__c
                                                FROM Project_Asset__c WHERE Asset__c IN:assetIdSet AND Asset__r.RecordTypeId !=:woAssetRecordTypeId
                                               ]){
                                                   assetProjectAssetMap.put(prjAsset.Asset__c, prjAsset);
                                               }
                for(Asset ast:assetList ){
                    if(ast.RecordTypeId !=woAssetRecordTypeId && ast.RecordTypeId !=hardwareAssetRecordTypeId){
                        if(assetProjectAssetMap.containsKey(ast.Id) && (ast.Status == NSP_ServiceConstants.BACKOUT || ast.Status==NSP_ServiceConstants.TERMINATED)){
                            if( assetProjectAssetMap.get(ast.Id).Asset__r.NSP_OrderProduct__r.Order.Status !=null &&
                               assetProjectAssetMap.get(ast.Id).Asset__r.NSP_OrderProduct__r.Order.Status !=NSP_ServiceConstants.ACTIVATED &&
                               assetProjectAssetMap.get(ast.Id).Project__r.Go_Live_Date__c !=Null ){
                                   ast.NSP_Termination_Date__c = assetProjectAssetMap.get(ast.Id).Project__r.Go_Live_Date__c;
                               }
                            else if( assetProjectAssetMap.get(ast.Id).Project__r.Go_Live_Date__c !=Null &&
                                    (assetProjectAssetMap.get(ast.Id).Project__r.pse__Project_Status__c ==NSP_ServiceConstants.PROJECTSTATUSCLOSED ||
                                     assetProjectAssetMap.get(ast.Id).Project__r.pse__Project_Status__c ==NSP_ServiceConstants.PROJECTSTATUSCANCELLED)
                                   ){
                                       ast.NSP_Termination_Date__c = assetProjectAssetMap.get(ast.Id).Project__r.Go_Live_Date__c;
                                   }
                        }

                        else if(!assetProjectAssetMap.containsKey(ast.Id) && ast.Status== NSP_ServiceConstants.TERMINATED){
                            ast.NSP_Termination_Date__c = system.Now().Date();
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'updateAssetTerminationDate'
            );
        }
    }

    // ********************************************************************************************
    // MethodName: updateServiceSegmentOnAccount
    // Description : update Service Segment on Account
    // Story : STY-03292
    // Params: List<Asset> assetList
    // ********************************************************************************************
    public static void updateServiceSegmentOnAccount( Set<Id> accountIdSet ) {
        List<Account> accountToUpdateList = new List<Account>();
        Map<Id,Asset> accIdAssetMap = new Map<Id,Asset>();
        List<String> assetStatusList = new List<String>{
            NSP_ServiceConstants.ASSETBLACKOUT ,
            NSP_ServiceConstants.TERMINATED
        };
        Set<Id> assetRecordTypeIdSet = new Set<Id>{WOAssetRecordTypeId, wxWaAssetRecordTypeId};

        try {
            if(!accountIdSet.isEmpty()){
                    for(Asset assetRec:  [SELECT Id, AccountId,
                                          RecordTypeId,
                                          Status,
                                          NSP_Product_Segment__c,
                                          NSP_Client_Segment_type__c
                                          FROM Asset
                                          WHERE AccountId IN: accountIdSet AND
                                          RecordTypeId IN: assetRecordTypeIdSet]){
                                              if(assetRec.RecordTypeId == woAssetRecordTypeId && !assetStatusList.contains(assetRec.Status)){
                                                  accIdAssetMap.put(assetRec.AccountId, assetRec);
                                              }
                                              else if(assetRec.RecordTypeId == wxWaAssetRecordTypeId && !assetStatusList.contains(assetRec.Status)
                                                      && (accIdAssetMap.isEmpty() || (!accIdAssetMap.isEmpty() && !accIdAssetMap.keySet().contains(assetRec.AccountId)))){
                                                          accIdAssetMap.put(assetRec.AccountId, assetRec);
                                                      }

                                          }

                    Boolean switchEnabled = AssetTriggerSettings__c.getInstance( UserInfo.getUserId() ).IsAccountServiceSegmentCheckEnabled__c;
                    if(!accIdAssetMap.isEmpty()){
                        for(Account acc : [SELECT Id, NSP_Service_Segment__c FROM Account WHERE Id IN: accIdAssetMap.keySet()]){
                            acc.NSP_Service_Segment__c = accIdAssetMap.get(acc.Id).recordTypeId == woAssetRecordTypeId ? accIdAssetMap.get(acc.Id).NSP_Client_Segment_type__c :
                            accIdAssetMap.get(acc.Id).NSP_Product_Segment__c;
                            accountToUpdateList.add(acc);
                        }
                    } else if( switchEnabled ) {
                        for(Account acc : [SELECT Id, NSP_Service_Segment__c FROM Account WHERE Id IN: accountIdSet]){
                            acc.NSP_Service_Segment__c = NSP_ServiceConstants.EMPTY_STRING;
                            accountToUpdateList.add(acc);
                        }
                    }
            }
            if ( !accountToUpdateList.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( accountToUpdateList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssetServiceTriggerHelper.class.getName() ,
                    'updateServiceSegmentOnAccount' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'updateServiceSegmentOnAccount'
            );
        }
    }

    //
    // MethodName: updateAccountStatus
    // Description : updates parent account status if new asset is added/ existing asset updated
    // Story : DF-03777
    // Params: List<Asset> assetList, List<Account> accountList
    //
    public void updateAccountStatus( List<Asset> assetList , List<Account> accountList ) {
        List<Account> accountsToUpdate = new List<Account>();
        for ( Account acc : accountList ) {
            String derived = NSP_AssetServiceTriggerHelper.deriveServiceAccountStatus( acc );
            if ( String.isNotBlank( derived ) ) {
                acc.NSP_Sales_Service_Account_Status__c = derived;
            }
            accountsToUpdate.add( acc );
        }
        if ( !accountsToUpdate?.isEmpty() ) {
            try {
                List<Database.SaveResult> results = Database.update( accountsToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_AssetServiceTriggerHelper.class.getName() ,
                    'updateAccountStatus' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_AssetServiceTriggerHelper.handleException(
                    e ,
                    'updateAccountStatus'
                );
            }
        }
    }

    // Helper to derive the Account status based on related assets with precedence:
    // Active > Onboarding > On Demand > Prospecting (if any open Opportunities)
    private static String deriveServiceAccountStatus( Account acc ) {
        String returnValue = '';
        Boolean anyActive = false;
        Boolean anyOnBoarding = false;
        Boolean anyOnDemand = false;
        Boolean anyProspecting = (
            ( acc != null )
            && ( acc.Opportunities != null )
            && !acc.Opportunities.isEmpty()
        );
        List<Asset> filteredAssets = NSP_AssetServiceTriggerHelper.filterOnAssetRecordTypes( ( acc != null ) ? acc.Assets : null );
        for ( Asset assetRecord : filteredAssets ) {
            if ( ( assetRecord != null ) && String.isNotBlank( assetRecord.Status ) ) {
                if (assetRecord.Status == NSP_SalesConstants.ACTIVE) {
                    anyActive = true;
                } else if (assetRecord.Status == NSP_SalesConstants.ONBOARDING) {
                    anyOnBoarding = true;
                } else if (assetRecord.Status == NSP_ServiceConstants.AssetStatusOnDemand) {
                    anyOnDemand = true;
                }
            }
        }
        if ( anyActive ) {
            returnValue = NSP_SalesConstants.ACTIVE;
        } else if ( anyOnBoarding ) {
            returnValue = NSP_SalesConstants.ONBOARDING;
        } else if ( anyOnDemand ) {
            returnValue = NSP_ServiceConstants.AssetStatusOnDemand;
        } else if ( anyProspecting ) {
            returnValue = NSP_SalesConstants.PROSPECTING;
        }
        return returnValue;
    }

    /***********************************************************************************************
    * MethodName: updateaccountPayrollEmployee
    * Description : updates payroll Employee on Account
    * Story : DF-03798
    * Params: Set<Id>assetIdSet
    * ********************************************************************************************/
    public static void updateaccountPayrollEmployee(Set<Id>accountIdSet){
        List<Account> accountList = new List<Account>();
        List<Account> newAccountList = new List<Account>();
        for(Asset ast:[SELECT Id ,AccountId, recordTypeId ,NSP_Unique_Active_Employee__c,NSP_Current_SaaS_Seats__c, Status FROM Asset WHERE AccountId IN:accountIdSet
                       ORDER BY recordType.Name]){
            if ((ast.recordTypeId == WOAssetRecordTypeId && ast.NSP_Unique_Active_Employee__c != null) &&
               (ast.Status == NSP_ServiceConstants.ASSET_ONBOARDING_STATUS || ast.Status == NSP_ServiceConstants.ASSET_ACTIVE_STATUS)) {
                    Account acc = new Account();
                    acc.Id = ast.AccountId;
                    acc.NSP_Payroll_employee__c = ast.NSP_Unique_Active_Employee__c;
                    accountList.add(acc);
                    break;
                }else if ((ast.recordTypeId == wxWaAssetRecordTypeId && ast.NSP_Current_SaaS_Seats__c != null) &&
                         (ast.Status == NSP_ServiceConstants.ASSET_ONBOARDING_STATUS || ast.Status == NSP_ServiceConstants.ASSET_ACTIVE_STATUS)) {
                              Account acc = new Account();
                              acc.Id = ast.AccountId;
                              acc.NSP_Payroll_employee__c = Decimal.valueOf(ast.NSP_Current_SaaS_Seats__c);
                              accountList.add(acc);
                              break;
                         }
        }
        for(Account account:[Select Id, NSP_Payroll_employee__c from Account WHERE Id IN:accountIdSet]){
            if(!accountList.contains(account)){
                Account acc = new Account();
                acc.Id = account.Id;
                acc.NSP_Payroll_employee__c = null;
                newAccountList.add(acc);
            }
        }
        if(!newAccountList.isEmpty()){
            List<Database.SaveResult> results = Database.update(newAccountList,false);
            NSP_ErrorLogHandler.logResults(
                NSP_AssetServiceTriggerHelper.class.getName() ,
                'updateaccountPayrollEmployee:newAccountList' ,
                results
            );
        }
        if(!accountList.isEmpty()){
            List<Database.SaveResult> results = Database.update(accountList,false);
            NSP_ErrorLogHandler.logResults(
                NSP_AssetServiceTriggerHelper.class.getName() ,
                'updateaccountPayrollEmployee:accountList' ,
                results
            );
        }
    }

    /***********************************************************************************************
    * MethodName: updateAssetNameAsPerConvention
    * Description : To update Asset Name as per decided naming convention
    * Story : DF-04204
    * Params: List<Asset> assetList, Map<Id, Account> assetAccIdNameMap,
    * Map<String, String> recTypeLabelMap
    *********************************************************************************************/
    public static void updateAssetNameAsPerConvention(List<Asset> assetList, Map<Id, Account> assetAccIdNameMap, Map<String, String> recTypeLabelMap){
        for(Asset assetRec : assetList){
            if(assetRec.AccountId != null && recTypeLabelMap != null && assetRec.RecordTypeId != null){
                assetRec.Name = assetAccIdNameMap.get(assetRec.AccountId).Name+ ' - ' +recTypeLabelMap.get(assetRec.RecordTypeId);
            }
        }
    }

    //
    // MethodName: throwErrorMessageForNonEditFields
    // Description : Throw error message if user tries to edit fields for which perm set is not assigned
    // Story : DF-04328
    //
    public void throwErrorMessageForNonEditFields( List<Asset> assetList , Map<Id,Asset> oldMap , Boolean isBPSAssetFields , Boolean onCreate ) {
        List<Profile> profiles = [ SELECT Id , Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1 ];
        String profileName = null;
        if ( ( profiles != null ) && !profiles.isEmpty() ) {
            profileName = profiles[0].Name;
        }
        Boolean isBPSUserFields = false ;
        //List of all fields which RET users cannot edit if BPS Create Asset perm set is not assigned
        List<String> nonEditableBPSAssetFields = System.Label.NSP_BPS_Non_Editable_Fields.split( ',' );
        //List of all fields which RET users cannot edit if RET Create Asset perm set is not assigned
        List<String> nonEditableRETFields = System.Label.NSP_RET_Non_Editable_Fields.split( ',' );
        List<String> nonEditableAssetFields = ( isBPSAssetFields && profileName == NSP_ServiceConstants.BPSSERVICE ) ? nonEditableBPSAssetFields :
                                            ( !isBPSAssetFields && profileName == NSP_ServiceConstants.RT ) ? nonEditableRETFields : null;
        if ( nonEditableAssetFields == nonEditableBPSAssetFields ) {
            isBPSUserFields = true;
        }
        try {
            if ( nonEditableAssetFields != null ) { // prevent NullPointerExceptions
                for ( Asset assetRec : assetList ) {
                    Asset oldAsset = oldMap != null ? oldMap.get( assetRec.Id ) : null;
                    for ( String nonEditableField : nonEditableAssetFields ) {
                        //if the value is entered/edited in the nonEditableAssetFields throw a validation error message
                        if ( ( oldAsset != null && assetRec.get( nonEditableField ) != oldAsset.get( nonEditableField ) )
                            || ( assetRec.get( nonEditableField ) != null && onCreate == true )
                            )
                        {
                            if ( isBPSUserFields ) {
                                throwErrorOnSpecificRecordTypesAndField( assetRec , oldAsset , nonEditableField );
                            }else{
                                assetRec.addError( nonEditableField , NSP_AssetServiceTriggerHelper.errorMessage );
                            }
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_AssetServiceTriggerHelper.handleException(
                e ,
                'throwErrorMessageForNonEditFields'
            );
        }
    }

    // TO throw error message while editing Asset Recordtype as a BPS User
    private void throwErrorOnSpecificRecordTypesAndField( Asset assetRec , Asset oldAsset , String nonEditableField ) {
        List<String> nonEditableRETFields = System.Label.NSP_RET_Non_Editable_Fields.split(',');
        //List of all fields which BPS users cannot edit if Create Asset perm set is not assigned
        List<String> nonEditableBPSAssetFields = System.Label.NSP_BPS_Non_Editable_Fields.split(',');
        List<String> nonEditableHardwareLoanerBPSAssetFields = System.Label.NSP_BPS_Non_Hardware_Loaner_Fields.split(',');
        List<String> nonEditableHardwareBPSAssetFields = System.Label.NSP_BPS_Non_Hardware_Fields.split(',');
        List<String> nonEditableXMLBPSAssetFields = System.Label.NSP_BPS_Non_XML_Fields.split(',');
        List<String> nonEditableInsuranceServicesBPSAssetFields = System.Label.NSP_BPS_Non_Insurance_Services_Fields.split(',');
        List<String> nonEditableEmploymentScreeningBPSAssetFields = System.Label.NSP_BPS_Non_Employment_Screening_Fields.split(',');
        List<String> nonEditableCertifyBPSAssetFields = System.Label.NSP_BPS_Non_Certify_Fields.split(',');
        List<String> nonEditableApplicantTrackingBPSAssetFields = System.Label.NSP_BPS_Non_Applicant_Tracking_Fields.split(',');
        List<String> nonEditableTimeAttendanceBPSAssetFields = System.Label.NSP_BPS_Non_Time_Attendance_Fields.split(',');
        List<String> nonEditablePerformanceBPSAssetFields = System.Label.BPS_Non_Performance_Management_Fields.split(',');
        List<String> nonEditableIntegraBPSAssetFields = System.Label.BPS_Integra_Asset_Feilds.split(',');
        Id assetRecordTypeId = assetRec.RecordTypeId;
        if ( assetRecordTypeId != null ) {
            Boolean isValid = False;
            if ( ( assetRecordTypeId == HardwareLoanerAsset && nonEditableHardwareLoanerBPSAssetFields.size()>0 && nonEditableHardwareLoanerBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == HardwareAsset && nonEditableHardwareBPSAssetFields.size()>0 && nonEditableHardwareBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == XmlAssetRecordId && nonEditableXMLBPSAssetFields.size()>0 && nonEditableXMLBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == InsuranceServiceRT && nonEditableInsuranceServicesBPSAssetFields.size()>0 && nonEditableInsuranceServicesBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == ApplicantTrackingRT && nonEditableApplicantTrackingBPSAssetFields.size()>0 && nonEditableApplicantTrackingBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == EmploymentScreeningRT && nonEditableEmploymentScreeningBPSAssetFields.size()>0 && nonEditableEmploymentScreeningBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == CertifyRT && nonEditableCertifyBPSAssetFields.size()>0 &&nonEditableCertifyBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == TimeAttendanceRecordId && nonEditableTimeAttendanceBPSAssetFields.size()>0 && nonEditableTimeAttendanceBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == PERFORM_SMART_ASSET && nonEditablePerformanceBPSAssetFields.size()>0 && nonEditablePerformanceBPSAssetFields.Contains(nonEditableField) )
                || ( assetRecordTypeId == INTEGRA_ASSET && nonEditableIntegraBPSAssetFields.size()>0 && nonEditableIntegraBPSAssetFields.Contains(nonEditableField))
                )
            {
                isValid = True;
            }
            if ( !isValid ) {
                assetRec.addError( nonEditableField , NSP_AssetServiceTriggerHelper.errorMessage );
            }
        }
    }

    //== Method to check for the exclude list of record type names from the Asset
    //@input params: List of Assets
    //@output params: List of Assets
    public static List<Asset> filterOnAssetRecordTypes( List<Asset> records ) {
        List<Asset> result = new List<Asset>();
        // Option A: return a new filtered list (no in-place mutation)
        if ( ( records != null ) && !records.isEmpty() ) {
            // List of Asset Record type names to exclude
            Set<String> excludedNames = new Set<String>{
                'RET WO',
                'RET Choice',
                'CPQ Asset',
                'Hardware Asset',
                'Hardware Loaner Asset',
                'Certify',
                'XML',
                'Integra',
                'Time & Attendance',
                'Performance Management'
            };
            for ( Asset record : records ) {
                String rtName = ( ( ( record != null ) && ( record.RecordType != null ) ) ? record.RecordType.Name : null );
                if ( String.isNotBlank( rtName ) && !excludedNames.contains( rtName ) ) {
                    result.add( record );
                }
            }
        }
        return result;
    }

    // == Method to return the List of accounts
    //@input params: List of Assets
    //@output params:
    private static List<Account> getAccounts( List<Id> accountIds ) {
        List<Account> returnList = new List<Account>();
        if ( ( accountIds != null ) && !accountIds.isEmpty() ) {
            returnList = [
                SELECT
                    Id ,
                    NSP_Sales_Service_Account_Status__c ,
                    (
                        SELECT
                            Id ,
                            Status ,
                            NSP_Account_Status__c ,
                            AccountId ,
                            RecordType.Name
                        FROM Assets
                    ) ,
                    (
                        SELECT
                            Id ,
                            StageName
                        FROM Opportunities
                        WHERE ( StageName NOT IN ( 'Closed Won' , 'Closed Lost' ) )
                    )
                FROM Account
                WHERE ( Id IN :accountIds )
            ];
        }
        return returnList;
    }

}
//
