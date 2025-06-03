public with sharing class AccountAssetSummary {
    // test w/ AccountAssetSummaryTest (94%)

    private static final Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    private static final Id wxAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );

    public static void accountWOWXFieldUpdate( List<Asset> newList, Map<Id, Asset> oldMap ) {
        String productWOSS = 'WOSS';
        Set<String> statusSet = new Set<String>{
            'Active' ,
            'Backout' ,
            'Onboarding' ,
            'Terminated'
        };
        Set<Id> relevantRecordTypes = new Set<Id>{
            AccountAssetSummary.woAssetRecordTypeId ,
            AccountAssetSummary.wxAssetRecordTypeId
        };
        Map<Id,Asset> assetWOWXMap = new Map<Id,Asset>();
        List<Account> accListLookup = new List<Account>();
        Asset oldAsset = null;
        if ( ( newList != null ) && !newList.isEmpty() ) {
            for ( Asset newAsset : newList ) {
                if ( ( newAsset != null )
                    && ( newAsset.Id != null )
                    && ( oldMap != null )
                    && ( newAsset.Status != null )
                    )
                {
                    oldAsset = oldMap.get( newAsset.Id );
                    if ( oldAsset != null ) {
                        Boolean isRelevantStatus = statusSet.contains( newAsset.Status );
                        Boolean isRelevantRecordType = relevantRecordTypes.contains( newAsset.RecordTypeId );
                        Boolean isStatusChanged = ( newAsset.Status != oldAsset.Status );
                        if ( isRelevantStatus
                            && isRelevantRecordType
                            && ( newAsset.AccountId != null )
                            && ( Trigger.isInsert || ( Trigger.isUpdate && isStatusChanged ) )
                            )
                        {
                            assetWOWXMap.put( newAsset.AccountId , newAsset );
                        }
                    }
                }
            }
        }
        // Query accounts with relevant assets
        if ( !assetWOWXMap.isEmpty() ) {
            List<Account> accounts = [
                SELECT
                    Id ,
                    (
                        SELECT
                            Id ,
                            AccountId ,
                            Status ,
                            RecordTypeId ,
                            NSP_Termination_Date__c ,
                            NSP_Product_Line__c ,
                            NSP_ProductBundle__c
                        FROM Assets
                        WHERE ( RecordTypeId IN :relevantRecordTypes )
                        ORDER BY NSP_Termination_Date__c DESC
                    )
                FROM Account
                WHERE ( Id IN :assetWOWXMap.keySet() )
            ];
            for ( Account accRecord : accounts ) {
                Account acc = new Account(
                    Id=accRecord.Id
                );
                Asset latestWOAsset = null;
                Asset latestWXAsset = null;
                for ( Asset asset : accRecord.Assets ) {
                    Boolean isActiveOrOnboarding = (
                        ( asset.Status == NSP_ServiceConstants.ASSET_ACTIVE_STATUS )
                        || ( asset.Status == NSP_ServiceConstants.ASSET_ONBOARDING_STATUS )
                    );
                    Boolean isTerminatedOrBackout = (
                        ( asset.Status == NSP_ServiceConstants.TERMINATED )
                        || ( asset.Status == NSP_ServiceConstants.BACKOUT )
                    );
                    if ( asset.RecordTypeId == AccountAssetSummary.woAssetRecordTypeId ) {
                        // Process WO assets
                        if ( isActiveOrOnboarding ) {
                            acc.WO_Asset__c = asset.Id;
                            break;
                        }
                        if ( isTerminatedOrBackout
                            && ( ( latestWOAsset == null ) || ( asset.NSP_Termination_Date__c > latestWOAsset.NSP_Termination_Date__c ) )
                            )
                        {
                            latestWOAsset = asset;
                        }
                    } else if ( asset.RecordTypeId == AccountAssetSummary.wxAssetRecordTypeId ) {
                        // Process WX assets
                        if ( isActiveOrOnboarding
                            && ( asset.NSP_ProductBundle__c != productWOSS )
                            )
                        {
                            acc.WX_Asset__c = asset.Id;
                            break;
                        }
                        if ( isTerminatedOrBackout
                            && ( ( latestWXAsset == null ) || ( asset.NSP_Termination_Date__c > latestWXAsset.NSP_Termination_Date__c ) )
                            )
                        {
                            latestWXAsset = asset;
                        }
                    }
                }
                if ( ( acc.WO_Asset__c == null ) && ( latestWOAsset != null ) ) {
                    acc.WO_Asset__c = latestWOAsset.Id;
                }
                if ( ( acc.WX_Asset__c == null ) && ( latestWXAsset != null ) ) {
                    acc.WX_Asset__c = latestWXAsset.Id;
                }
                for ( Asset asset : accRecord.Assets ) {
                    Boolean isActiveOrOnboarding = (
                        ( asset.Status == NSP_ServiceConstants.ASSET_ACTIVE_STATUS )
                        || ( asset.Status == NSP_ServiceConstants.ASSET_ONBOARDING_STATUS )
                    );
                    Boolean isActiveWO = (
                        ( asset.RecordTypeId == AccountAssetSummary.woAssetRecordTypeId )
                        && isActiveOrOnboarding
                    );
                    Boolean isActiveWX = (
                        ( asset.RecordTypeId == AccountAssetSummary.wxAssetRecordTypeId )
                        && isActiveOrOnboarding
                        && ( asset.NSP_ProductBundle__c != productWOSS )
                    );
                    Boolean isTerminatedOrBackout = (
                        ( accRecord.Assets.size() == 1 )
                        && (
                            ( asset.Status == NSP_ServiceConstants.TERMINATED )
                            || ( asset.Status == NSP_ServiceConstants.BACKOUT )
                        )
                    );
                    if ( isActiveWO || isActiveWX || isTerminatedOrBackout ) {
                        acc.PEO_TES_Client_Status__c = AccountAssetSummary.getClientStatus( asset );
                        break;
                    } else if ( accRecord.Assets.size() > 1 ) {
                        Asset assetWithTermDate = null;
                        Boolean allTerminatedOrBackout = true;
                        for ( Asset assetCheck : accRecord.Assets ) {
                            if ( ( assetCheck.Status != NSP_ServiceConstants.TERMINATED ) && ( assetCheck.Status != NSP_ServiceConstants.BACKOUT ) ) {
                                allTerminatedOrBackout = false;
                                break;
                            }
                            if ( ( assetCheck.NSP_Termination_Date__c != null ) && ( assetWithTermDate == null ) ) {
                                assetWithTermDate = assetCheck;
                            }
                        }
                        // If all assets are terminated/backout and an asset with a termination date is found
                        if ( allTerminatedOrBackout && ( assetWithTermDate != null ) ) {
                            acc.PEO_TES_Client_Status__c = AccountAssetSummary.getClientStatus( assetWithTermDate );
                        }
                    }
                }
                accListLookup.add( acc );
            }
        }
        // Update accounts
        try {
            if ( !accListLookup.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( accListLookup , false );
                NSP_ErrorLogHandler.logResults(
                    AccountAssetSummary.class.getName() ,
                    'accountWOWXFieldUpdate:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                AccountAssetSummary.class.getName() ,
                'accountWOWXFieldUpdate' ,
                e
            );
        }
    }

    private static String getClientStatus( Asset record ) {
        String response = null;
        if ( record != null ) {
            response = record.Status;
            if ( String.isNotBlank( record.NSP_Product_Line__c ) ) {
                response = record.NSP_Product_Line__c + ' - ' + record.Status;
            }
        }
        return response;
    }

}
//