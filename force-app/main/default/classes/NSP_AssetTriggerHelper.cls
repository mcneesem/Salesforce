public with sharing class NSP_AssetTriggerHelper {
    // test w/ NSP_AssetTriggerHelperTest (82%)

    private static final Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    private static final Id wxAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );
    private static final Id cpqAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_CPQ_Asset' );
    private static final Id performanceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Performance_Management' );
    private static final Id employmentScreeningAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Employment_Screening' );
    private static final Id recruitingServicesAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Recruiting_Services' );
    private static final Id applicantTrackingAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Applicant_Tracking' );
    private static final Id retWoAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'RET_WO' );
    private static final Id retChoiceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'RET_Choice' );
    private static final Id stpChecklistRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'NSP_Checklist__c' , 'NSP_Sold_to_Paid_Checklist' );

    //
    // Iterates throught the list of new Account and passes the required attributes to other methods.
    // @param newList List of New Accounts.
    // @return void
    //
    public void beforeInsertDirector( List<Asset> newList ) {
        try {
            // ADO-314743
            // ~ handle Default Asset Record Type change for "Integration User" Profile
            // ~ Salesforce Automation (Id=0054x0000057XwoAAE) depends on "CPQ Asset" default...
            // ~ Insperity Integration (AIMS) (Id=0054x0000057MPSAA2) previously depended on "WO" default...
            if ( NSP_AssetTriggerHelper.isEnabledRecordTypeDefault
                && ( newList != null )
                && !newList.isEmpty()
                )
            {
                for ( Asset record : newList ) {
                    if ( String.isBlank( record.RecordTypeId ) // null/blank/undefined Asset Record Type
                        || ( record.RecordTypeId == NSP_AssetTriggerHelper.cpqAssetRecordTypeId ) // Asset Record Type: CPQ Asset (Id=0124x000000yRuyAAE)
                        )
                    {
                        record.RecordTypeId = NSP_AssetTriggerHelper.woAssetRecordTypeId; // Asset Record Type: WO (Id=0124x000000yRuzAAE)
                    }
                }
            }
            this.updatePayDateOnAsset( newList , null ); // added for STY-03387
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'beforeInsertDirector' );
        }
    }

    //
    // Iterates throught the list of new Account and passes the required attributes to other methods.
    // @param newList List of New Account.
    // @param newMap List of New Account.
    // @return void
    //
    public void afterInsertDirector( List<Asset> newList , Map<Id,Asset> newMap ) {
        try {
            this.updateInvoiceDate( newList , newMap );
            if ( NSP_AssetTriggerHelper.isEnabledAccountAssetSummary ) {
                AccountAssetSummary.accountWOWXFieldUpdate( newList , newMap );
            } else {
                this.peoTESClientStatus( newList , newMap );
            }
            this.updateRETAsset( newList , newMap );
            List<Asset> ast = new List<Asset>();
            List<Asset> docusignAsset = new List<Asset>();
            for( Asset assetObj: newList ) {
                if ( ( assetObj.Status != null )
                    && ( ( assetObj.Status == 'Active' ) || ( assetObj.Status == 'Onboarding' ) )
                    )
                {
                    ast.add(assetObj);
                }
                if ( ( assetObj.Status != null )
                    && ( assetObj.RecordTypeId != NSP_AssetTriggerHelper.woAssetRecordTypeId )
                    && ( assetObj.RecordTypeId != NSP_AssetTriggerHelper.cpqAssetRecordTypeId )
                    )
                {
                    docusignAsset.add(assetObj);
                }
            }
            if ( !docusignAsset.isEmpty() ) {
                NSP_AssetTriggerHelper.updateAssetInDocusign( docusignAsset );
            }
            if ( !ast.isEmpty() ) {
                NSP_AssetTriggerHelper.updateActiveAssets( ast );
            }
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'afterInsertDirector' );
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newMap, oldMap List of Assets.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,Asset> newMap , Map<Id,Asset> oldMap ) {
        try {
            this.updatePayDateOnAsset( newMap.values() , oldMap ); // added for STY-03387
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'beforeUpdateDirector' );
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newMap, oldMap List of Assets.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,Asset> newMap , Map<Id,Asset> oldMap ) {
        if ( ( newMap != null ) && !newMap.isEmpty() ) {
            NSP_SObjectHistoryTrackingHelper.enqueueJob(
                (Map<Id,sObject>)newMap ,
                (Map<Id,sObject>)oldMap
            );
        }
        this.updateInvoiceDate( newMap.values() , oldMap );
        if ( NSP_AssetTriggerHelper.isEnabledAccountAssetSummary ) {
            AccountAssetSummary.accountWOWXFieldUpdate( newMap.values() , oldMap );
        } else {
            this.peoTESClientStatus( newMap.values() , oldMap );
        }
        this.updateRETAsset( newMap.values() , oldMap );
        Set<Id> asstIdSet = new Set<Id>();
        List<Asset> ast = new List<Asset>();
        List<Asset> docusignAsset = new List<Asset>();
        for ( Asset asst : newMap.values() ) {
            Asset oldRecord = oldMap.get( asst.Id );
            if ( oldRecord != null ) {
                if ( ( asst.NSP_Government_Contractor__c != oldRecord.NSP_Government_Contractor__c )
                    && ( asst.recordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                    )
                {
                    asstIdSet.add( asst.Id );
                }
                if ( asst.Status != oldRecord.Status ) {
                    ast.add( asst );
                }
                if ( ( asst.Status != oldRecord.Status )
                    && ( asst.RecordTypeId != NSP_AssetTriggerHelper.woAssetRecordTypeId )
                    && ( asst.RecordTypeId != NSP_AssetTriggerHelper.cpqAssetRecordTypeId )
                    )
                {
                    docusignAsset.add( asst );
                }
            }
        }
        if ( !docusignAsset.isEmpty() ) {
            NSP_AssetTriggerHelper.updateAssetInDocusign( docusignAsset );
        }
        if ( !ast.isEmpty() ) {
            NSP_AssetTriggerHelper.updateActiveAssets( ast );
        }
        if ( !asstIdSet.isEmpty() ) {
            this.mapGovernmentContratcorOnPDS( asstIdSet );
        }
    }

    //
    // @MethodName: updateAssetInDocusign
    // @Description: Active asset for docusign use
    // @param :List<Asset> ast
    // @return void
    //
    private static void updateAssetInDocusign( List<Asset> ast ) {
        try {
            Map<Id,Set<String>> accountToAssetRecordtypeMap = new Map<Id,Set<String>>();
            Map<Id,RecordTypeInfo> rtinfos = Asset.sObjectType.getDescribe().getRecordTypeInfosById();
            List<Id> accountList = new List<Id>();
            for ( Asset eachAsset : ast ) {
                if ( eachAsset.AccountId != null ) {
                    accountList.add( eachAsset.AccountId );
                }
            }
            List<String> excludeStatusValues = new List<String>();
            List<String> excluderecordTypeWithStatusValues = new List<String>();
            List<String> excluderecordTypeValues = new List<String>();
            if ( NSP_AssetTriggerHelper.settings != null ) {
                if ( String.isNotBlank( NSP_AssetTriggerHelper.settings.Exclude_Status__c ) ) {
                    excludeStatusValues = NSP_AssetTriggerHelper.settings.Exclude_Status__c.split( '\\R' );
                }
                if ( String.isNotBlank( NSP_AssetTriggerHelper.settings.Exclude_Record_Types_WRT_Status__c ) ) {
                    excluderecordTypeWithStatusValues = NSP_AssetTriggerHelper.settings.Exclude_Record_Types_WRT_Status__c.split( '\\R' );
                }
                if ( String.isNotBlank( NSP_AssetTriggerHelper.settings.Exclude_Record_Types__c ) ) {
                    excluderecordTypeValues = NSP_AssetTriggerHelper.settings.Exclude_Record_Types__c.split( '\\R' );
                }
            }
            List <Asset> assetList = [
                SELECT Id , RecordTypeId , RecordType.Name , AccountId , Status
                FROM Asset
                WHERE (
                    ( AccountId IN :accountList )
                    AND (
                        NOT (
                            (
                                ( RecordType.Name = :excluderecordTypeWithStatusValues )
                                AND ( Status = :excludeStatusValues )
                            )
                            OR ( RecordType.Name = :excluderecordTypeValues )
                        )
                    )
                )
            ];
            for ( Asset eachAsset : assetList ) {
                if ( eachAsset.AccountId != null ) {
                    if ( !accountToAssetRecordtypeMap.containsKey( eachAsset.AccountId ) ) {
                        accountToAssetRecordtypeMap.put( eachAsset.AccountId , new Set<String>() );
                    }
                    String rtName;
                    if ( rtinfos.containsKey( eachAsset.RecordTypeId ) ) {
                        rtName = rtinfos.get( eachAsset.RecordTypeId ).getName();
                    }
                    // Adding all recordtype here from all related assets
                    accountToAssetRecordtypeMap.get( eachAsset.AccountId ).addAll( rtName.split( ',' ) );
                }
            }
            List<Account> acctLst = new List<Account>();
            for ( Account eachAccount : [
                        SELECT Id , Docusign_Assets__c
                        FROM Account
                        WHERE ( Id IN :accountList )
                    ]
                )
            {
                //Clearing old value for Docusign_Assets__c
                eachAccount.Docusign_Assets__c = null;
                if ( accountToAssetRecordtypeMap.containsKey( eachAccount.Id ) ) {
                    //Adding value into Set for dedupe
                    Set<String> existingassetsrecordtype = accountToAssetRecordtypeMap.get( eachAccount.Id );
                    //Adding value from set to List
                    List<String> activeAssetList = new List<String>();
                    activeAssetList.addAll( existingassetsrecordtype );
                    if ( !activeAssetList.isEmpty() ) {
                        eachAccount.Docusign_Assets__c = String.join( activeAssetList , ', ' );
                    }
                }
                acctLst.add( eachAccount );
            }
            update acctLst;
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'updateAssetInDocusign' );
        }
    }

    //
    // @MethodName: updateActiveAssets
    // @Description: This method is used to Update Active Asset on Account
    // @param :List<Asset> ast
    // @Defect : STY-04435
    // @return void
    //
    private static void updateActiveAssets( List<Asset> ast ) {
        Map<Id, Set<String>> mp = new Map<Id, Set<String>>();
        Map<Id, RecordTypeInfo> rtinfos = Asset.sObjectType.getDescribe().getRecordTypeInfosById();
        List<Id> accountList = new List<Id>();
        for ( Asset eachAsset : ast ) {
            if ( eachAsset.AccountId != null ) {
                accountList.add( eachAsset.AccountId );
            }
        }
        List<Account> accList =[
            SELECT Id , NSP_Active_Assets__c
            FROM Account
            WHERE ( Id IN :accountList )
        ];
        for ( Account acc: accList ) {
            acc.NSP_Active_Assets__c = '';
        }
        update accList;
        List<Asset> assetList = new List<Asset>();
        assetList = [
            SELECT Id , RecordTypeId , RecordType.Name , AccountId , Status
            FROM Asset
            WHERE (
                ( AccountId IN :accountList )
                AND (
                    ( Status = 'Active' )
                    OR ( Status = 'Onboarding' )
                )
            )
        ];
        for ( Asset eachAsset : assetList ) {
            if ( eachAsset.AccountId != null ) {
                if ( !mp.containsKey( eachAsset.AccountId ) ) {
                    mp.put( eachAsset.AccountId , new Set<String>() );
                }
                String rtName;
                if ( rtinfos.containsKey( eachAsset.RecordTypeId ) ) {
                    rtName = rtinfos.get( eachAsset.RecordTypeId ).getName();
                }
                // Adding all recordtype here from all related assets
                mp.get( eachAsset.AccountId ).addAll( rtName.split( ';' ) );
            }
        }
        List<Account> acctLst = [
            SELECT Id , NSP_Active_Assets__c
            FROM Account
            WHERE ( Id IN :mp.keySet() )
        ];
        for ( Account a : acctLst ) {
            if ( mp.ContainsKey( a.Id ) ) {
                Set<String> existingassetsrecordtype = mp.get( a.Id );
                List<String> activeAssetList = new List<String>();
                activeAssetList.addAll( existingassetsrecordtype );
                a.NSP_Active_Assets__c = String.join( activeAssetList , ';' );
            }
        }
        update acctLst;
    }

    //
    // @MethodName: mapGovernmentContratcorOnPDS
    // @Description: This method is used to map Government Contractor checkbox on PDS after Asset Update
    // @param :Set<Id> assetIdSet
    // @createdDate : 10/11/2022
    // @Defect : STY-03277
    // @return void
    //
    private void mapGovernmentContratcorOnPDS( Set<Id> assetIdSet ) {
        try {
            Map<Id,Boolean> isSubClientGovConMap = new Map<Id,Boolean>();
            List<NSP_Payroll__c> payRollList = new List<NSP_Payroll__c>();
            for ( NSP_Sub_Client__c subClient : [
                        SELECT
                            Id ,
                            NSP_Asset__c ,
                            NSP_Asset__r.NSP_Government_Contractor__c ,
                            NSP_Asset__r.RecordTypeId
                        FROM NSP_Sub_Client__c
                        WHERE ( NSP_Asset__c IN: assetIdSet )
                    ]
                )
            {
                isSubClientGovConMap.put(
                    subClient.Id ,
                    subClient.NSP_Asset__r.NSP_Government_Contractor__c
                );
            }
            if ( !isSubClientGovConMap.isEmpty() ) {
                for ( NSP_Payroll__c pRoll : [
                            SELECT
                                Id ,
                                NSP_Sub_Client_Name__c ,
                                NSP_Government_Contractor__c
                            FROM NSP_Payroll__c
                            WHERE ( NSP_Sub_Client_Name__c IN :isSubClientGovConMap.keySet() )
                        ]
                    )
                {
                    pRoll.NSP_Government_Contractor__c = isSubClientGovConMap.get( pRoll.NSP_Sub_Client_Name__c );
                    payRollList.add( pRoll );
                }
                if ( !payRollList.isEmpty() ) {
                    Database.update( payRollList );
                }
            }
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'mapGovernmentContratcorOnPDS' );
        }
    }

    //
    // @MethodName: createPlatformEventForAsset
    // @Description: This method is used to fire platform event for Asset field change based on metadata.
    // @param :List<Asset> newAssets, map<Id, Asset> oldAssets
    // @createdDate : 11/03/2022
    // @Defect : STY-03624
    // @return void
    //
    public static void createPlatformEventForAsset( List<Asset> newAssets , Map<Id,Asset> oldAssets ) {
        //Boolean to check if any field is changed
        List<Asset_Event__e> assetEventToBeInserted = New List<Asset_Event__e>();
        List<string> assetFieldDetails = new List<string>();

        //Get Record details for Metadata
        NSP_Platform_Event_Fields_Management__mdt assetFieldFromMdt = NSP_Platform_Event_Fields_Management__mdt.getInstance( 'Asset_Fields' );
        if ( assetFieldFromMdt.NSP_Active__c ) {
            assetFieldDetails.addall( assetFieldFromMdt.NSP_Fields__c.split( ';' ) );
        }
        for ( Asset record : newAssets ) {
            Boolean isModified = false;
            for ( String assetField : assetFieldDetails ) {
                Boolean isValidRecordType = (
                    ( record.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                    || ( record.RecordTypeId == NSP_AssetTriggerHelper.performanceAssetRecordTypeId )
                    || ( record.RecordTypeId == NSP_AssetTriggerHelper.employmentScreeningAssetRecordTypeId )
                    || ( record.RecordTypeId == NSP_AssetTriggerHelper.recruitingServicesAssetRecordTypeId )
                    || ( record.RecordTypeId == NSP_AssetTriggerHelper.applicantTrackingAssetRecordTypeId )
                );
                if ( isValidRecordType ) {
                    Asset oldAsset = null;
                    if ( ( oldAssets != null ) && oldAssets.containsKey( record.Id ) ) {
                        oldAsset = oldAssets.get( record.Id );
                    }
                    if ( ( oldAsset == null ) || ( record.get( assetField ) != oldAsset.get( assetField ) ) ) {
                        isModified = true;
                    }
                }
            }
            if ( isModified ) {
                String aimsClient = record.NSP_Client__c;
                if ( String.isBlank( aimsClient ) ) {
                    aimsClient = record.NSP_WO_AIMS_Client_Number__c;
                }
                Asset_Event__e assetEventToBeCreated = new Asset_Event__e();
                assetEventToBeCreated.AssetId__c = record.Id;
                assetEventToBeCreated.AssetStatus__c = record.Status;
                assetEventToBeCreated.AssetRecordTypeId__c = record.RecordTypeId;
                assetEventToBeCreated.RecordTypeName__c = record.RecordTypeName__c;
                assetEventToBeCreated.NSP_Substance_Abuse_Policy__c = record.NSP_Substance_Abuse_Policy__c;
                assetEventToBeCreated.NSP_ES_e_Verify_Client__c = record.NSP_IES_e_Verify_Client__c;
                assetEventToBeCreated.NSP_AIMS_Client__c = aimsClient;
                assetEventToBeCreated.NSP_Minor_Job_Position__c = record.NSP_Minor_Job_Position__c;
                assetEventToBeCreated.I_9_Availability__c = record.I_9_Availability__c;
                assetEventToBeCreated.E_Verify_Services__c = record.E_Verify_Services__c;
                assetEventToBeCreated.I_9_Assist__c = record.I_9_Assist__c;
                assetEventToBeInserted.add( assetEventToBeCreated );
            }
        }
        if ( !assetEventToBeInserted.isEmpty() ) {
            List<Database.SaveResult> results = EventBus.publish( assetEventToBeInserted );
            NSP_ErrorLogHandler.logResults(
                NSP_AssetTriggerHelper.class.getName() ,
                'createPlatformEventForAsset' ,
                results
            );
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newList, oldMap List of Assets.
    // @return void
    // Created By: Rahul Singh
    // Date :8/29/2022
    //
    private void updateInvoiceDate( List<Asset> newList , Map<Id,Asset> oldMap ) {
        try {
            Set<Id> idSet = new Set<Id>();
            if ( ( newList != null ) && !newList.isEmpty() ) {
                for ( Asset newAsset : newList ) {
                    if ( ( newAsset.Opportunity__c != null )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                        && ( newAsset.NSP_AIMS_First_Pay_Date__c != null )
                        )
                    {
                        Asset oldAsset = ( ( oldMap != null ) ? oldMap.get( newAsset.Id ) : null );
                        if ( Trigger.isInsert
                            || ( ( oldAsset != null )
                                && ( ( newAsset.NSP_AIMS_First_Pay_Date__c != oldAsset.NSP_AIMS_First_Pay_Date__c )
                                    || ( newAsset.Opportunity__c != oldAsset.Opportunity__c )
                                    )
                                )
                            )
                        {
                            idSet.add( newAsset.Opportunity__c );
                        }
                    }
                }
            }
            List<Asset> assetResult = null;
            if ( !idSet.isEmpty() ) {
                // PreventDmlExceptions: FIELD_CUSTOM_VALIDATION_EXCEPTION, You do not have access to edit this Opportunity. Once it is Closed Won it cannot be modified. Please contact Sales Operations team
                // ~ ignore Assets with a "Closed Won" Opportunity...
                assetResult = [
                    SELECT Id , NSP_AIMS_First_Pay_Date__c , Opportunity__c
                    FROM Asset
                    WHERE (
                        ( Opportunity__c IN :idSet )
                        AND ( Opportunity__r.StageName != 'Closed Won' )
                        AND ( NSP_AIMS_First_Pay_Date__c != null )
                    )
                    ORDER BY NSP_AIMS_First_Pay_Date__c DESC
                    LIMIT 1
                ];
            }
            List<Opportunity> oppList = new List<Opportunity>();
            if ( ( assetResult != null ) && !assetResult.isEmpty() ) {
                for ( Asset assetWo : assetResult ) {
                    oppList.add(
                        new Opportunity(
                            Id=assetWo.Opportunity__c ,
                            Nsp_1st_Pay_Invoice_Date_Reporting__c = assetWo.NSP_AIMS_First_Pay_Date__c
                        )
                    );
                }
            }
            if ( !oppList.isEmpty() ) {
                update oppList;
            }
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'updateInvoiceDate' );
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newList, oldMap List of Assets.
    // @return void
    // description: logic to copy to Asset Projected First Pay Date with opportunity with primary product  WS/WO
    // from check list Requested First Pay Date from check list.
    // Date :9/27/2022 for STY-03387
    //
    private void updatePayDateOnAsset( List<Asset> newList , Map<Id,Asset> oldMap ) {
        Set<Id> opportunityIdSet = new Set<Id>();
        Map<Id,NSP_Checklist__c> opportunityIdToChecklistMap = new Map<Id,NSP_Checklist__c>();
        for( Asset newAsset : newList ) {
            Asset oldAsset = ( ( oldMap != null ) ? oldMap.get( newAsset.Id ) : null );
            if ( ( newAsset.Opportunity__c != null )
                && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                && ( Trigger.isInsert || ( newAsset.Opportunity__c != oldAsset.Opportunity__c ) )
                )
            {
                opportunityIdSet.add( newAsset.Opportunity__c ); // get opportunity id
            }
        }
        if ( !opportunityIdSet.isEmpty() ) {
            // create opportunity to checklist map
            for ( NSP_Checklist__c eachChecklist : [
                        SELECT
                            Id ,
                            NSP_Requested_First_Pay_Date__c ,
                            NSP_Opportunity__c
                        FROM NSP_Checklist__c
                        WHERE (
                            ( NSP_Opportunity__c IN :opportunityIdSet )
                            AND ( NSP_Opportunity__r.NSP_PrimaryProduct__c IN ( 'WS' , 'WO' ) )
                            AND ( RecordTypeId = :NSP_AssetTriggerHelper.stpChecklistRecordTypeId )
                            AND ( NSP_Requested_First_Pay_Date__c != null )
                        )
                    ]
                )
            {
                opportunityIdToChecklistMap.put( eachChecklist.NSP_Opportunity__c , eachChecklist );
            }
            for ( Asset newAsset : newList ) {
                Asset oldAsset = ( ( oldMap != null ) ? oldMap.get( newAsset.Id ) : null );
                if ( ( newAsset.Opportunity__c != null )
                    && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                    && ( Trigger.isInsert || ( newAsset.Opportunity__c != oldAsset.Opportunity__c ) )
                    && opportunityIdToChecklistMap.containsKey( newAsset.Opportunity__c )
                    )
                {
                    NSP_Checklist__c objChecklist = opportunityIdToChecklistMap.get( newAsset.Opportunity__c );
                    newAsset.NSP_Projected_First_Pay_Date__c = objChecklist.NSP_Requested_First_Pay_Date__c; // assign value
                }
            }
        }
    }

    //
    // MethodName: updateAssetServiceRegion
    // Description : This method is used to update Service Region Field on before Insert.
    // Params: List<Asset> Boolean isInsert
    //
    public static void updateAssetServiceRegion( List<Asset> newList ) {
        Map<Id,NSP_Account_Team__c> accountTeamById = new Map<Id,NSP_Account_Team__c>();
        Set<Id> setofAccountIds = new Set<Id>();
        for ( Asset asset : newList ) {
            //accountId should not be null and record type should be 'WO'
            if ( ( asset.AccountId != null )
                && ( asset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                )
            {
                setofAccountIds.add( asset.AccountId );
            }
        }
        if ( !setofAccountIds.isEmpty() ) {
            //Build Account Map for Service Region
            for ( NSP_Account_Team__c accountTeam : [
                        SELECT
                            Id ,
                            Name ,
                            NSP_Account__c ,
                            NSP_User__r.NSP_Service_Region__c ,
                            NSP_Role__c
                        FROM NSP_Account_Team__c
                        WHERE (
                            ( NSP_Account__c = :setofAccountIds )
                            AND ( NSP_Role__c = 'Manager, HR Services' )
                            AND ( NSP_User__c != null )
                        )
                    ]
                )
            {
                accountTeamById.put( accountTeam.NSP_Account__c , accountTeam );
            }
            for ( Asset asset : newList ) {
                if ( accountTeamById.containsKey( asset.AccountId ) ) {
                     asset.NSP_Service_Region__c = accountTeamById.get( asset.AccountId ).NSP_User__r.NSP_Service_Region__c;
                }
            }
        }
    }

    //
    // MethodName: processLeadParentFromAsset
    // Description : Method to process lead parent on plan subplan and child asset. story STY-03796
    // Params: List<Id>
    //
    @InvocableMethod(label='processLeadParentFromAsset' description='Method to process lead parent on plan subplan and child asset' category='Asset')
    public static void processLeadParentFromAsset( List<Id> assetIds ) {
        NSP_ProcessAssetforLeadParent.processLeadParent( new Set<Id>( assetIds ) );
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newList, oldMap List of Assets.
    // @return void
    // description: logic to populate peoTESClientStatus
    // Date :6/2/2023 for STY-04442
    //
    private void peoTESClientStatus( List<Asset> newList , Map<Id,Asset> oldMap ) {
        try {
            List<Account> accListLookup = new List<Account> ();
            Set<Id> accIdSet = new Set<Id>();
            Map<Id,Asset> assetWoOnboard = new Map<Id,Asset>();
            Map<Id,Asset> assetWxOnboard = new Map<Id,Asset>();
            Map<Id,Asset> assetWoWxTerm = new Map<Id,Asset>();
            Map<Id,Asset> assetWoTerm = new Map<Id,Asset>();
            Map<Id,Asset> assetWxTerm = new Map<Id,Asset>();
            Map<Id,Asset> assetWxLatestTerm = new Map<Id,Asset>();
            Map<Id,Asset> assetWoLatestTerm = new Map<Id,Asset>();
            Map<Id,Asset> assetWoWxLatestTerm = new Map<Id,Asset>();
            List<Id> onboardList = new List<Id>();
            List<Id> onactiveList = new List<Id>();
            List<Id> woWxActiveList = new List<Id>();
            List<String> status = new List<String>{
                'Onboarding' ,
                'Active' ,
                'Terminated'
            };
            for ( Asset newAsset : newList ) {
                Asset oldAsset = ( ( oldMap != null ) ? oldMap.get( newAsset.Id ) : null );
                if ( ( ( ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                            || ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                            )
                        && status.contains( newAsset.Status )
                        )
                    && ( ( Trigger.isInsert && ( newAsset.AccountId != null ) )
                        || ( Trigger.isUpdate && ( newAsset.Status != oldAsset.Status ) && ( newAsset.AccountId != null ) )
                        )
                    )
                {
                    accIdSet.add( newAsset.AccountId ); // get asset id
                    if ( ( ( newAsset.Status == 'Onboarding' ) || ( newAsset.Status == 'Active' ) )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                        )
                    {
                        assetWoOnboard.put( newAsset.AccountId , newAsset );
                    } else if ( ( ( newAsset.Status == 'Onboarding' ) || ( newAsset.Status == 'Active' ) )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                        )
                    {
                        assetWxOnboard.put( newAsset.AccountId , newAsset );
                    } else if ( ( newAsset.Status == 'Terminated' )
                        && ( ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                            || ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                            )
                        )
                    {
                        assetWoWxTerm.put( newAsset.AccountId , newAsset );
                    }
                    if ( ( newAsset.Status == 'Terminated' )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.woAssetRecordTypeId )
                        )
                    {
                        assetWoTerm.put( newAsset.AccountId , newAsset );
                    }
                    if ( ( newAsset.Status == 'Terminated' )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                        )
                    {
                        assetWxTerm.put( newAsset.AccountId , newAsset );
                    }
                }
            }
            if ( !assetWoWxTerm.isEmpty() ) {
                for ( Asset assetLi : [
                            SELECT Id , AccountId
                            FROM Asset
                            WHERE (
                                (
                                    ( RecordTypeId = :NSP_AssetTriggerHelper.woAssetRecordTypeId )
                                    OR ( RecordTypeId = :NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                                )
                                AND (
                                    ( Status = 'Active' )
                                    OR ( Status = 'Onboarding' )
                                )
                                AND ( accountid IN :assetWoWxTerm.keySet() )
                            )
                        ]
                    )
                {
                    woWxActiveList.add( assetLi.AccountId );
                }
                for ( Account acc : [
                            SELECT
                                Id ,
                                (
                                    SELECT id,accountid,NSP_Termination_Date__c,Status,NSP_Product_Line__c
                                    FROM Assets
                                    WHERE (
                                        ( NSP_Termination_Date__c != null )
                                        AND ( Status = 'Terminated' )
                                        AND (
                                            ( RecordTypeId = :NSP_AssetTriggerHelper.woAssetRecordTypeId )
                                            OR ( RecordTypeId = :NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                                        )
                                    )
                                    ORDER BY NSP_Termination_Date__c DESC
                                    LIMIT 1
                                )
                            FROM Account
                            WHERE ( Id IN :assetWoWxTerm.keySet() )
                        ]
                    )
                {
                    for ( asset asobj : acc.Assets ) {

                        assetWoWxLatestTerm.put( asobj.AccountId , asobj );
                    }
                }
            }
            if ( !assetWoTerm.isEmpty() ) {
                for ( Asset assetLi : [
                            SELECT Id , AccountId
                            FROM Asset
                            WHERE (
                                ( RecordTypeId = :NSP_AssetTriggerHelper.woAssetRecordTypeId )
                                AND (
                                    ( Status = 'Active' )
                                    OR ( Status = 'Onboarding' )
                                )
                                AND ( AccountId IN :assetWoTerm.keySet() )
                            )
                        ]
                    )
                {
                    onboardList.add( assetLi.AccountId );
                }
                for ( Account acc : [
                            SELECT
                                Id ,
                                (
                                    SELECT Id , AccountId , NSP_Termination_Date__c
                                    FROM Assets
                                    WHERE (
                                        ( NSP_Termination_Date__c != null )
                                        AND ( Status = 'Terminated' )
                                        AND ( RecordTypeId = :NSP_AssetTriggerHelper.woAssetRecordTypeId )
                                    )
                                    ORDER BY NSP_Termination_Date__c DESC
                                    LIMIT 1
                                )
                            FROM Account
                            WHERE ( Id IN :assetWoTerm.keySet() )
                        ]
                    )
                {
                    for ( asset asobj : acc.Assets ) {
                        assetWoLatestTerm.put( asobj.AccountId , asobj );
                    }
                }
            }
            if ( !assetWxTerm.isEmpty() ) {
                for ( Asset assetLi : [
                            SELECT Id , AccountId
                            FROM Asset
                            WHERE (
                                ( RecordTypeId = :NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                                AND (
                                    ( Status = 'Active' )
                                    OR ( Status = 'Onboarding' )
                                )
                                AND ( AccountId IN :assetWxTerm.keySet() )
                            )
                        ]
                    )
                {
                    onactiveList.add( assetLi.accountid );
                }
                for ( Account acc : [
                            SELECT
                                Id ,
                                (
                                    SELECT Id , AccountId , NSP_Termination_Date__c
                                    FROM Assets
                                    WHERE (
                                        ( NSP_Termination_Date__c != null )
                                        AND ( Status = 'Terminated' )
                                        AND ( RecordTypeId = :NSP_AssetTriggerHelper.wxAssetRecordTypeId )
                                    )
                                    ORDER BY NSP_Termination_Date__c DESC
                                    LIMIT 1
                                )
                            FROM Account
                            WHERE ( Id IN :assetWxTerm.keySet() )
                        ]
                    )
                {
                    for( asset asobj : acc.Assets ) {
                        assetWxLatestTerm.put( asobj.AccountId , asobj );
                    }
                }
            }
            if ( !accIdSet.isEmpty() ) {
                for ( Id accId : accIdSet ) {
                    Account accObject = new Account();
                    accObject.Id = accId;
                    if ( assetWoOnboard.containsKey( accId ) ) {
                        if ( assetWoOnboard.get( accId ).NSP_Product_Line__c != null ) {
                            String nspProduct = assetWoOnboard.get( accId ).NSP_Product_Line__c;
                            String nspStatus = assetWoOnboard.get( accId ).Status;
                            String nspClientStatus = nspProduct + ' - ' + nspStatus;
                            accObject.PEO_TES_Client_Status__c = nspClientStatus;
                        } else {
                            String nspStatus = assetWoOnboard.get( accId ).Status;
                            accObject.PEO_TES_Client_Status__c = nspStatus;
                        }
                    } else if ( assetWxOnboard.containsKey( accId ) ) {
                        if ( assetWxOnboard.get( accId ).NSP_Product_Line__c != null ) {
                            String nspProduct = assetWxOnboard.get( accId ).NSP_Product_Line__c;
                            String nspStatus = assetWxOnboard.get( accId ).Status;
                            String nspClientStatus = nspProduct + ' - ' + nspStatus;
                            accObject.PEO_TES_Client_Status__c = nspClientStatus;
                        } else {
                            String nspStatus = assetWxOnboard.get( accId ).Status;
                            accObject.PEO_TES_Client_Status__c = nspStatus;
                        }
                    } else if ( assetWoWxTerm.containsKey( accId )
                        && !woWxActiveList.contains( accId )
                        && !assetWoWxLatestTerm.isEmpty()
                        )
                    {
                        if ( assetWoWxLatestTerm.get(accId).NSP_Product_Line__c != null ) {
                            String nspProduct = assetWoWxLatestTerm.get( accId ).NSP_Product_Line__c;
                            String nspStatus = assetWoWxLatestTerm.get( accId ).Status;
                            String nspClientStatus = nspProduct + ' - ' + nspStatus;
                            accObject.PEO_TES_Client_Status__c = nspClientStatus;
                        } else {
                            String nspStatus = assetWoWxLatestTerm.get( accId ).Status;
                            accObject.PEO_TES_Client_Status__c = nspStatus;
                        }
                    } else if ( assetWoWxTerm.containsKey( accId )
                        && !woWxActiveList.contains( accId )
                        && assetWoWxLatestTerm.isEmpty()
                        )
                    {
                        if ( assetWoWxTerm.get( accId ).NSP_Product_Line__c != null ) {
                            String nspProduct = assetWoWxTerm.get( accId ).NSP_Product_Line__c;
                            String nspStatus = assetWoWxTerm.get( accId ).Status;
                            String nspClientStatus = nspProduct + ' - ' + nspStatus;
                            accObject.PEO_TES_Client_Status__c = nspClientStatus;
                        } else {
                            String nspStatus = assetWoWxTerm.get( accId ).Status;
                            accObject.PEO_TES_Client_Status__c = nspStatus;
                        }
                    }
                    if ( assetWoOnboard.containsKey( accId ) ) {
                        accObject.WO_Asset__c = assetWoOnboard.get( accId ).Id;
                    } else if ( assetWoTerm.containsKey( accId )
                        && !onboardList.contains( accId )
                        && !assetWoLatestTerm.isEmpty()
                        )
                    {
                        accObject.WO_Asset__c = assetWoLatestTerm.get( accId ).Id;
                    } else if ( assetWoTerm.containsKey( accId )
                        && !onboardList.contains( accId )
                        && assetWoLatestTerm.isEmpty()
                        )
                    {
                        accObject.WO_Asset__c = assetWoTerm.get( accId ).Id;
                    }
                    if ( assetWxOnboard.containsKey( accId ) ) {
                        accObject.WX_Asset__c = assetWxOnboard.get( accId ).Id;
                    } else if ( assetWxTerm.containsKey( accId )
                        && !onactiveList.contains( accId )
                        && !assetWxLatestTerm.isEmpty()
                        )
                    {
                        accObject.WX_Asset__c = assetWxLatestTerm.get( accId ).Id;
                    } else if ( assetWxTerm.containsKey( accId )
                        && !onactiveList.contains( accId )
                        && assetWxLatestTerm.isEmpty()
                        )
                    {
                        accObject.WX_Asset__c = assetWxTerm.get( accId ).Id;
                    }
                    accListLookup.add( accObject );
                }
            }
            if ( !accListLookup.isEmpty() ) {
                update accListLookup;
            }
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'peoTESClientStatus' );
        }
    }

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newList, oldMap List of Assets.
    // @return void
    // description: logic to populate updateRETAsset
    // Date :6/2/2023 for STY-04442
    //
    private void updateRETAsset( List<Asset> newList , Map<Id,Asset> oldMap ) {
        try {
            List<Id> onRetList = new List<Id>();
            List<Account> retList = new List<Account>();
            Set<Id> accIdSet = new Set<Id>();
            Map<Id,Asset> assetRetOnboard = new Map<Id,Asset>();
            Map<Id,Asset> assetChoiceOnboard = new Map<Id,Asset>();
            Map<Id,Asset> assetRet_ChoiceTerm = new Map<Id,Asset>();
            Map<Id,Asset> assetRet_ChoiceLatestTerm = new Map<Id,Asset>();
            for ( Asset newAsset : newList ) {
                Asset oldAsset = ( ( oldMap != null ) ? oldMap.get( newAsset.Id ) : null );
                if ( ( Trigger.isInsert && ( newAsset.AccountId != null ) )
                    || ( Trigger.isUpdate && ( newAsset.Status != oldAsset.Status ) && ( newAsset.AccountId != null ) )
                    )
                {
                    accIdSet.add( newAsset.AccountId ); // get asset id
                    if ( ( ( newAsset.Status == 'Onboarding' ) || ( newAsset.Status == 'Active' ) )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.retWoAssetRecordTypeId )
                        )
                    {
                        assetRetOnboard.put( newAsset.AccountId , newAsset );
                    } else if ( ( ( newAsset.Status == 'Onboarding' ) || ( newAsset.Status == 'Active' ) )
                        && ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.retChoiceAssetRecordTypeId )
                        )
                    {
                        assetChoiceOnboard.put( newAsset.AccountId , newAsset );
                    } else if ( ( newAsset.Status == 'Terminated' )
                        && ( ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.retWoAssetRecordTypeId )
                            || ( newAsset.RecordTypeId == NSP_AssetTriggerHelper.retChoiceAssetRecordTypeId )
                            )
                        )
                    {
                        assetRet_ChoiceTerm.put( newAsset.AccountId , newAsset );
                    }
                }
            }
            if ( !assetRet_ChoiceTerm.isEmpty() ) {
                for ( Asset assetLi : [
                            SELECT Id , AccountId
                            FROM Asset
                            WHERE (
                                (
                                    ( RecordTypeId = :NSP_AssetTriggerHelper.retWoAssetRecordTypeId )
                                    OR ( RecordTypeId = :NSP_AssetTriggerHelper.retChoiceAssetRecordTypeId )
                                )
                                AND (
                                    ( Status = 'Active' )
                                    OR ( Status = 'Onboarding' )
                                )
                                AND ( accountid IN :assetRet_ChoiceTerm.KeySet() )
                            )
                        ]
                    )
                {
                    onRetList.add( assetLi.AccountId );
                }
                for ( Account acc : [
                            SELECT
                                Id ,
                                (
                                    SELECT Id , AccountId , NSP_Termination_Date__c
                                    FROM Assets
                                    WHERE (
                                        ( NSP_Termination_Date__c != null )
                                        AND (
                                            ( RecordTypeId = :NSP_AssetTriggerHelper.retWoAssetRecordTypeId )
                                            OR ( RecordTypeId = :NSP_AssetTriggerHelper.retChoiceAssetRecordTypeId )
                                        )
                                    )
                                    ORDER BY NSP_Termination_Date__c DESC
                                    LIMIT 1
                                )
                            FROM Account
                            WHERE ( Id IN :assetRet_ChoiceTerm.keySet() )
                        ]
                    )
                {
                    for ( asset asobj : acc.Assets ) {
                        assetRet_ChoiceLatestTerm.put( asobj.AccountId , asobj );
                    }
                }
            }
            if ( !accIdSet.isEmpty() ) {
                for ( Id accId : accIdSet ) {
                    if ( assetRetOnboard.containsKey( accId ) ) {
                        retList.add(
                            new Account(
                                Id=accId ,
                                RET_Asset__c=assetRetOnboard.get( accId ).Id
                            )
                        );
                    } else if ( assetChoiceOnboard.containsKey( accId ) ) {
                        retList.add(
                            new Account(
                                Id=accId ,
                                RET_Asset__c=assetChoiceOnboard.get( accId ).Id
                            )
                        );
                    } else if ( assetRet_ChoiceTerm.containsKey( accId )
                        && !onRetList.contains( accId )
                        && !assetRet_ChoiceLatestTerm.isEmpty()
                        )
                    {
                        retList.add(
                            new Account(
                                Id=accId ,
                                RET_Asset__c=assetRet_ChoiceLatestTerm.get( accId ).Id
                            )
                        );
                    } else if ( assetRet_ChoiceTerm.containsKey( accId )
                        && !onRetList.contains( accId )
                        && assetRet_ChoiceLatestTerm.isEmpty()
                        )
                    {
                        retList.add(
                            new Account(
                                Id=accId ,
                                RET_Asset__c=assetRet_ChoiceTerm.get( accId ).Id
                            )
                        );
                    }
                }
            }
            if ( !retList.isEmpty() ) {
                update retList;
            }
        } catch ( Exception e ) {
            NSP_AssetTriggerHelper.handleException( e , 'updateRETAsset' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_AssetTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_AssetTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

    //
    //
    //

    private static AssetTriggerSettings__c settings {
        get {
            if ( settings == null ) {
                settings = AssetTriggerSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledRecordTypeDefault {
        get {
            if ( isEnabledRecordTypeDefault == null ) {
                Boolean local = False;
                if ( NSP_AssetTriggerHelper.settings != null ) {
                    local = NSP_AssetTriggerHelper.settings.IsEnabledRecordTypeDefault__c;
                }
                isEnabledRecordTypeDefault = local;
            }
            return isEnabledRecordTypeDefault;
        }
        private set;
    }

    private static Boolean isEnabledAccountAssetSummary {
        get {
            if ( isEnabledAccountAssetSummary == null ) {
                Boolean local = False;
                if ( NSP_AssetTriggerHelper.settings != null ) {
                    local = NSP_AssetTriggerHelper.settings.IsEnabledAccountAssetSummary__c;
                }
                isEnabledAccountAssetSummary = local;
            }
            return isEnabledAccountAssetSummary;
        }
        private set;
    }

}
//