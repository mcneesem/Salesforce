public class NSP_AssetTerminateBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_AssetTerminateBatch_Test (84%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_AssetTerminateBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs everyday at 1am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AssetTerminateBatch ~ When the AIMS Status = Terminated and, the Termination Date = 30 days ago or longer on the WO asset, then set the Status field on the related assets to Terminated if they meet the criteria ~ everyday at 1 AM' + suffix ,
            '0 0 1 ? * * *' ,
            new NSP_AssetTerminateBatch()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        Id response = null;
        if ( NSP_AssetTerminateBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_AssetTerminateBatch() ,
                NSP_AssetTerminateBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    private static final Id WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(
        'Asset' ,
        NSP_ServiceConstants.WO_ASSET_RECORDTYPE
    );
    private static final Id RET_WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(
        'Asset' ,
        NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE
    );

    public Database.QueryLocator start(Database.BatchableContext bc) {
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

    public void execute( Database.BatchableContext bc , List<Asset> existAsset ) {
        if ( NSP_AssetTerminateBatch.isEnabled ) {
            List<Asset> assetToBeUpdated = new List<Asset>();
            Map<Id,Date> accountIDTermDateMap = new  Map<Id,Date>();
            List<Id> assetRecordIDList = NSP_AssetTerminateBatch.getAssetRecordIds();
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
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    //
    //

    private static List<Id> getAssetRecordIds() {
        List<Id> assetRecordIDList = new List<ID>();
        try {
            assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.TIME_ATTENDANCE_ASSET ) );
            assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET ) );
            assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.INTEGRA ) );
            assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.ASSET_RECRUITING_SERVICES ) );
            assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.XML_ASSET ) );
            assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.LEARNING_DEVELOPMENT ) );
            if ( NSP_AssetTerminateBatch.isEnabledRecordTypeRetWo ) {
                assetRecordIDList.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE ) );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetTerminateBatch.class.getName() ,
                'getAssetRecordIds' ,
                e
            );
        }
        return assetRecordIDList;
    }

    private static void updateAsset( List<Asset> assetToBeUpdated ) {
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

    //
    //
    //

    private static AssetTerminateBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = AssetTerminateBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_AssetTerminateBatch.settings != null ) {
                    local = NSP_AssetTerminateBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_AssetTerminateBatch.settings != null )
                    && ( NSP_AssetTerminateBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_AssetTerminateBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

    // AZD-523518 : Killswitch for RET_WO Asset Record Type
    private static Boolean isEnabledRecordTypeRetWo {
        private get {
            if ( isEnabledRecordTypeRetWo == null ) {
                Boolean local = False;
                if ( NSP_AssetTerminateBatch.settings != null ) {
                    local = NSP_AssetTerminateBatch.settings.IsEnabledRecordTypeRetWo__c;
                }
                isEnabledRecordTypeRetWo = local;
            }
            return isEnabledRecordTypeRetWo;
        }
        private set;
    }

}
//