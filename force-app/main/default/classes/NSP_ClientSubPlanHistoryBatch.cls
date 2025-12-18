public class NSP_ClientSubPlanHistoryBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_ClientSubPlanHistoryBatchTest (84%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_ClientSubPlanHistoryBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs everyday at 2am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_ClientSubPlanHistoryBatch ~ update the status of the Retirement Services Assets considering associated Client Subplan History records ~ everyday at 2 AM' + suffix ,
            '0 0 2 * * ? *' ,
            new NSP_ClientSubPlanHistoryBatch()
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
        if ( NSP_ClientSubPlanHistoryBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_ClientSubPlanHistoryBatch() ,
                NSP_ClientSubPlanHistoryBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        //get RET_Choice Asset Record Type Id
        Id retChoiceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
        //get RET_WO Asset Record Type Id
        Id retWOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_WO');
        //query to get the client sub plan history records where start date is in future and end date is less than or equal to today
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Start_Date__c ,
                    NSP_End_Date__c ,
                    NSP_Asset__c ,
                    NSP_Asset__r.RecordTypeId ,
                    NSP_Current_Subplan__c ,
                    CreatedDate
                FROM NSP_Client_Sub_Plan_History__c
                WHERE (
                    ( NSP_Asset__c != null )
                    AND (
                        ( NSP_Asset__r.RecordTypeId = :retChoiceAssetRecordTypeId )
                        OR ( NSP_Asset__r.RecordTypeId = :retWOAssetRecordTypeId )
                    )
                )
                WITH SECURITY_ENFORCED
                ORDER BY NSP_Start_Date__c DESC
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<NSP_Client_Sub_Plan_History__c> scope ) {
        // ADO-328811
        Map<Id,NSP_Client_Sub_Plan_History__c> subPlanHistoryMap = this.buildSubPlanHistoryMap( scope );
        //Iterate through the list of client sub plan history and add asset Ids and remove those assets which will not be terminating
        Set<Id> assetIdSet = new Set<Id>();
        Set<Id> nonTermAssetIdSet = new Set<Id>();
        for ( NSP_Client_Sub_Plan_History__c clientSubPlanHistoryRec :  subPlanHistoryMap.values()) {
            assetIdSet.add( clientSubPlanHistoryRec.NSP_Asset__c );
            if ( ( clientSubPlanHistoryRec.NSP_Start_Date__c >= Date.today() )
                && ( clientSubPlanHistoryRec.NSP_End_Date__c == null && clientSubPlanHistoryRec.NSP_Current_Subplan__c == true)
                )
            {
                assetIdSet.remove( clientSubPlanHistoryRec.NSP_Asset__c );
                nonTermAssetIdSet.add( clientSubPlanHistoryRec.NSP_Asset__c );
            }
        }
        List<Asset> assetRecordToUpdate = [
            SELECT Id , NSP_Termination_Date__c , Status
            FROM Asset
            WHERE (
                ( Id IN :assetIdSet )
                AND ( OwnerId NOT IN :NSP_ClientSubPlanHistoryBatch.skewedAssetOwnerIds )
            )
        ];
        List<Asset> nonTermAssetToUpdate = [
            SELECT Id , NSP_Termination_Date__c , Status
            FROM Asset
            WHERE (
                ( Id IN :nonTermAssetIdSet )
                AND ( OwnerId NOT IN :NSP_ClientSubPlanHistoryBatch.skewedAssetOwnerIds )
            )
        ];
        List<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList = [
            SELECT Id , NSP_Start_Date__c , CreatedDate , NSP_End_Date__c , NSP_Asset__c
            FROM NSP_Client_Sub_Plan_History__c
            WHERE (
                ( NSP_Asset__c IN :assetIdSet )
                AND ( NSP_End_Date__c <= TODAY )
            )
        ];
        //link the most recently created client sub plan history to the asset
        Map<Id,NSP_Client_Sub_Plan_History__c> assetClientSubPlanHistoryMap = new Map<Id,NSP_Client_Sub_Plan_History__c>();
        for(NSP_Client_Sub_Plan_History__c clientSubPlanHistoryRec: clientSubPlanHistoryList){
            if(assetClientSubPlanHistoryMap.get(clientSubPlanHistoryRec.NSP_Asset__c) == NULL){
                assetClientSubPlanHistoryMap.put(clientSubPlanHistoryRec.NSP_Asset__c, clientSubPlanHistoryRec);
            }
            else if(clientSubPlanHistoryRec.CreatedDate > assetClientSubPlanHistoryMap.get(clientSubPlanHistoryRec.NSP_Asset__c).CreatedDate){
                assetClientSubPlanHistoryMap.put(clientSubPlanHistoryRec.NSP_Asset__c, clientSubPlanHistoryRec);
            }
        }
        //update the fields on the asset linked to the client sub plan history
        for(Asset eachAssetRecordToUpdate: assetRecordToUpdate){
            NSP_Client_Sub_Plan_History__c clientSubPlanHistory = assetClientSubPlanHistoryMap.get(eachAssetRecordToUpdate.Id);
            if(clientSubPlanHistory != NULL){
                eachAssetRecordToUpdate.NSP_Termination_Date__c = clientSubPlanHistory.NSP_End_Date__c;
                eachAssetRecordToUpdate.Status = NSP_ServiceConstants.TERMINATED;
            }
        }
        //if the asset was already terminated and a future dated client sub plan history was created then update the asset status and termination date
        for(Asset eachNonTermAsset: nonTermAssetToUpdate){
            eachNonTermAsset.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
            eachNonTermAsset.NSP_Termination_Date__c = NULL;
        }
        this.handleDmlOperations( assetRecordToUpdate , nonTermAssetToUpdate );
    }

    // ADO-328811
    private Map<Id,NSP_Client_Sub_Plan_History__c> buildSubPlanHistoryMap( List<NSP_Client_Sub_Plan_History__c> scope ) {
        Map<Id,NSP_Client_Sub_Plan_History__c> subPlanHistoryMap = new Map<Id,NSP_Client_Sub_Plan_History__c>();
        if ( ( scope != null ) && !scope.isEmpty() ) {
            for ( NSP_Client_Sub_Plan_History__c clientSubPlanHistoryRec : scope ) {
                if ( !subPlanHistoryMap.containsKey( clientSubPlanHistoryRec.NSP_Asset__c ) ) {
                    subPlanHistoryMap.put( clientSubPlanHistoryRec.NSP_Asset__c , clientSubPlanHistoryRec );
                }
            }
        }
        return subPlanHistoryMap;
    }

    // helper method to defeat sonar cognitive complexity...
    private void handleDmlOperations( List<Asset> assetRecordToUpdate , List<Asset> nonTermAssetToUpdate ) {
        try {
            if ( ( assetRecordToUpdate != null ) && !assetRecordToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update(
                    assetRecordToUpdate ,
                    NSP_ClientSubPlanHistoryBatch.isAllOrNone
                );
                NSP_ErrorLogHandler.logResults(
                    NSP_ClientSubPlanHistoryBatch.class.getName() ,
                    'handleDmlOperations:update:terminatedAssets' ,
                    results
                );
            }
            if ( ( nonTermAssetToUpdate != null ) && !nonTermAssetToUpdate.isEmpty() ) {
                List<Database.SaveResult> results = Database.update(
                    nonTermAssetToUpdate ,
                    NSP_ClientSubPlanHistoryBatch.isAllOrNone
                );
                NSP_ErrorLogHandler.logResults(
                    NSP_ClientSubPlanHistoryBatch.class.getName() ,
                    'handleDmlOperations:update:nonTerminatedAssets' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ClientSubPlanHistoryBatch.class.getName() ,
                'handleDmlOperations' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionlly static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static ClientSubPlanHistoryBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ClientSubPlanHistoryBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    // is the Schedulable enabled for execution???
    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_ClientSubPlanHistoryBatch.settings != null ) {
                    local = NSP_ClientSubPlanHistoryBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Boolean isAllOrNone {
        private get {
            if ( isAllOrNone == null ) {
                Boolean local = False;
                if ( NSP_ClientSubPlanHistoryBatch.settings != null ) {
                    local = NSP_ClientSubPlanHistoryBatch.settings.IsAllOrNone__c;
                }
                isAllOrNone = local;
            }
            return isAllOrNone;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_ClientSubPlanHistoryBatch.settings != null )
                    && ( NSP_ClientSubPlanHistoryBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_ClientSubPlanHistoryBatch.settings.BatchSize__c.intValue();
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

    //
    // Asset Ownership Skew (July 2024)
    // ~ 76294 ~ 0054x0000057P93AAE ~ Data Migration (PwC)
    // ~ 38755 ~ 0054x0000057MPSAA2 ~ Insperity Integration User
    //
    // ignore specific Asset Owner's to prevent DmlException UNABLE_TO_LOCK_ROW
    //
    private static Set<Id> skewedAssetOwnerIds {
        get {
            if ( skewedAssetOwnerIds == null ) {
                Set<Id> local = new Set<Id>();
                if ( NSP_ClientSubPlanHistoryBatch.settings != null ) {
                    String rawSkewedAssetOwnerIds = NSP_ClientSubPlanHistoryBatch.settings.SkewedAssetOwnerIds__c;
                    if ( String.isNotBlank( rawSkewedAssetOwnerIds ) ) {
                        List<String> splitSkewedAssetOwnerIds = rawSkewedAssetOwnerIds.split( ',' );
                        if ( ( splitSkewedAssetOwnerIds != null ) && !splitSkewedAssetOwnerIds.isEmpty() ) {
                            for ( String splitSkewedAssetOwnerId : splitSkewedAssetOwnerIds ) {
                                if ( String.isNotBlank( splitSkewedAssetOwnerId )
                                    && ( splitSkewedAssetOwnerId InstanceOf Id )
                                    )
                                {
                                    Id skewedAssetOwnerId = Id.valueOf( splitSkewedAssetOwnerId );
                                    if ( skewedAssetOwnerId.getSObjectType() == User.getSObjectType() ) {
                                        local.add( skewedAssetOwnerId );
                                    }
                                }
                            }
                        }
                    }
                }
                skewedAssetOwnerIds = local;
            }
            return skewedAssetOwnerIds;
        }
        private set;
    }

}
//