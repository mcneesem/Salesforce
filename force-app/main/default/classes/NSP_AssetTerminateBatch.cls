/**
Apex Class Name      :  NSP_AssetTerminateBatch
Version              :  1.0
Created Date         :  12/24/2021
Story                :  STY-03552
Modification Log     :
*--------------------------------------------------------------------------------------------------
*  Developer                   Date                   Description
* -------------------------------------------------------------------------------------------------
*  Virendra Kumar            11/24/2022           Update Asset Status and Termination Date
*  Ramya Ravi                02/08/2023           Add conditions to update the asset record  <STY-03867>
*/
global class NSP_AssetTerminateBatch implements Schedulable, Database.Batchable<sObject> {
    // test w/ NSP_AssetTerminateBatch_Test (84%)

    private static final Id WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(
        'Asset' ,
        NSP_ServiceConstants.WO_ASSET_RECORDTYPE
    );
    private static final Id RET_WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(
        'Asset' ,
        NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE
    );
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date last30Days = system.Today()-30;
        String finalDate = String.valueOf(last30Days).removeEnd(' 00:00:00');
        List<String> assetFields = new List<String>{
            'Id',
            'AccountId',
            'RecordTypeId',
            'NSP_Account_Status__c',
            'NSP_Termination_Date__c'
        };
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Asset', assetFields)
            .addFilter('AccountId', NULL, NSP_QueryBuilder.Operator.NOT_EQUALS,false)
            .addFilter('RecordTypeId', NSP_AssetTerminateBatch.WO_ASSET_RECORDTYPE , NSP_QueryBuilder.Operator.EQUALS,true)
            .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.TERMINATED , NSP_QueryBuilder.Operator.EQUALS, true)
            .addFilter('NSP_Termination_Date__c', finalDate , NSP_QueryBuilder.Operator.LESS_THAN_OR_EQUALS, false)
            .setSecurityEnforce(false);
        String query = queryBuilder.build();
        return Database.getQueryLocator(query);
    }

    global void execute( Database.BatchableContext bc , List<Asset> existAsset ) {
        List<Asset> assetToBeUpdated = new List<Asset>();
        Map<Id,Date> accountIDTermDateMap = new  Map<Id,Date>();
        List<Id> assetRecordIDList = getAssetRecordID();
        Set<Id> accountIds = new Set<Id>();
        for ( Asset record : existAsset ) {
            accountIds.add( record.AccountId );
        }
        List<Account> parents = [
            SELECT
                Id ,
                (
                    SELECT Id
                    FROM Assets
                    WHERE (
                        ( NSP_Account_Status__c != :NSP_ServiceConstants.TERMINATED )
                        AND ( RecordTypeId = :NSP_AssetTerminateBatch.WO_ASSET_RECORDTYPE )
                    )
                )
            FROM Account
            WHERE ( Id IN :accountIds )
        ];
        Map<Id,Account> parentsMap = new Map<Id,Account>( parents );
        //Loop through the asset list
        Set<Id> accIds = new Set<Id>();
        for ( Asset asst : existAsset ) {
            Account parent = null;
            if ( parentsMap.containsKey( asst.AccountId ) ) {
                parent = parentsMap.get( asst.AccountId );
            }
            Boolean hasNonTerminatedWoAsset = False;
            if ( ( parent != null )
                && ( parent.Assets != null )
                && ( parent.Assets.size() > 0 )
                )
            {
                // we have a non-terminated WO Asset for this AccountId
                hasNonTerminatedWoAsset = True;
            }
            if ( !hasNonTerminatedWoAsset ) {
                //get exist account ids
                accIds.add(asst.AccountId);
                //map of account Id and termination date
                accountIDTermDateMap.put(asst.AccountId, asst.NSP_Termination_Date__c);
            }
        }
        //update Status AND Termination Date for RT other then WO
        for ( Asset asst : [
                    SELECT
                        Id , AccountId , RecordTypeId , Status ,
                        NSP_Termination_Date__c , NSP_ProductBundle__c
                    FROM Asset
                    WHERE (
                        AccountId = :accIds
                        AND RecordTypeId IN :assetRecordIDList
                        AND Status != :NSP_ServiceConstants.TERMINATED
                    )
                ]
            )
        {
            if ( asst.RecordTypeId == NSP_AssetTerminateBatch.RET_WO_ASSET_RECORDTYPE
                || asst.NSP_ProductBundle__c == NSP_ServiceConstants.WoWSAsset
                )
            {
                asst.Status = 'Terminated';
                asst.NSP_Termination_Date__c = accountIDTermDateMap.get( asst.AccountId );
                assetToBeUpdated.add(asst);
            }
        }
        // update the asset list
        if ( !assetToBeUpdated.isEmpty() ) {
            updateAsset(assetToBeUpdated );
        }
    }

    public void execute( SchedulableContext sc ) {
        Database.executeBatch( new NSP_AssetTerminateBatch() , 200 );
    }

    //finish method of the batch class
    global void finish( Database.BatchableContext bc ) {
    }

    public static List<Id> getAssetRecordID() {
        List<Id> assetRecordIDList = new List<ID>();
        //AZD-523518 : Killswitch for RET_WO Asset Record Type
        Boolean isEnabledRecordTypeRetWo = AssetTerminateBatchSettings__c.getInstance(UserInfo.getUserId() ).IsEnabledRecordTypeRetWo__c;
        try {
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.TIME_ATTENDANCE_ASSET ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.ASSET_RECRUITING_SERVICES ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.XML_ASSET ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.LEARNING_DEVELOPMENT ));
            if(isEnabledRecordTypeRetWo){
            	assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE ));
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetTerminateBatch.class.getName() ,
                'getAssetRecordID' ,
                e
            );
        }
        return assetRecordIDList;
    }

    public static void updateAsset( List<Asset> assetToBeUpdated ) {
        try {
            Database.SaveResult[] result =  Database.update( assetToBeUpdated , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AssetTerminateBatch.class.getName() ,
                'updateAsset:update' ,
                result
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetTerminateBatch.class.getName() ,
                'updateAsset' ,
                e
            );
        }
    }

}