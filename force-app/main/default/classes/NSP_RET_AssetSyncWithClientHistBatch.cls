//
// @description  :  Batch Class to Syn RET Asset status based on Client subplanchange history
// Story : STY-03794 - RET Automation Retirement Services Asset Status Field Updates
//
public with sharing class NSP_RET_AssetSyncWithClientHistBatch implements ISelfSchedulable , Schedulable , Database.Batchable<SObject> {
    // test w/ NSP_RET_AssetSyncWithClientHistTest (85%)

    private static final String STATUS_ACTIVE = 'Active';

    //
    // Schedulable
    //

    // Schedulable execute method to fire the batch class
    public void execute( SchedulableContext sc ) {
        Database.executeBatch(
            new NSP_RET_AssetSyncWithClientHistBatch() ,
            NSP_RET_AssetSyncWithClientHistBatch.batchSize
        );
    }

    // runs everyday at 12am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_RET_AssetSyncWithClientHistBatch ~ Update Asset Status based on Client Sub Plan History ~ everyday at 12 AM' + suffix ,
            '0 0 0 ? * * *' ,
            new NSP_RET_AssetSyncWithClientHistBatch()
        );
    }

    //
    // Batchable
    //

    //start method to query all RET Asset records (RET choice/ RET WO) with status as Onboarding
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Id recordTypeIdRetChoice = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'RET_Choice' );
        Id recordTypeIdRetWo = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'RET_WO' );
        // Query to get RET Asset records with status as onboarding
        return Database.getQueryLocator(
            [
                SELECT Id , Opportunity__c , AccountId
                FROM Asset
                WHERE (
                    (
                        RecordTypeId IN (
                            :recordTypeIdRetChoice ,
                            :recordTypeIdRetWo
                        )
                    )
                    AND ( Status IN ( 'Onboarding' , 'Terminated' ) )
                )
            ]
        );
    }

    //Execute method to populate plan subplan values from asset to project records
    public void execute( Database.BatchableContext bc , List<Asset> assetList ) {
        try {
            if ( NSP_RET_AssetSyncWithClientHistBatch.isEnabled ) {
                //Variable declarations
                Set<Id> assetIDS = new Set<Id>();
                List<Asset> assetListToUpdate = new List<Asset>();
                Map<Id,Id> mapAssetOpptyID = new Map<Id,Id>();
                Map<Id,Date> opptyToProjDateMap = new Map<Id,Date>();
                Map<Id,Id> mapAssetAccountIds = new Map<Id,Id>();
                Set<Id> accountsWithActiveWO = new Set<Id>();
                Map<Id,NSP_Client_Sub_Plan_History__c> assetToSubplanHistMap = new Map<Id,NSP_Client_Sub_Plan_History__c>();
                //Get list of asset IDs and oppty IDs, Map of <AssetID,OpptID>
                if ( ( assetList != null ) && !assetList.isEmpty() ) {
                    for ( Asset asst: assetList ) {
                        if ( asst != null ) {
                            assetIDS.add( asst.Id );
                            mapAssetOpptyID.putAll(
                                NSP_RET_AssetSyncWithClientHistBatch.getMapAssetOpptyId( asst )
                            );
                            mapAssetAccountIds.putAll(
                                NSP_RET_AssetSyncWithClientHistBatch.getMapAssetAccountIds( asst )
                            );
                        }
                    }
                }
                // Check if Account has Active WO Asset
                accountsWithActiveWO = NSP_RET_AssetSyncWithClientHistBatch.getAccountsWithActiveWO( mapAssetAccountIds.values() );
                // Check if project status is Cancelled / Closed/Lost for project records linked to these opptys
                opptyToProjDateMap = NSP_RET_AssetSyncWithClientHistBatch.getOpptyToProjDateMap( mapAssetOpptyID.values() );
                //Latest Client Sub Plan History per Asset
                assetToSubplanHistMap = NSP_RET_AssetSyncWithClientHistBatch.getAssetToSubplanHistMap( assetIDS );
                // get Backout Asset List
                assetListToUpdate = NSP_RET_AssetSyncWithClientHistBatch.getBackoutAssetList(
                    mapAssetOpptyID ,
                    opptyToProjDateMap
                );
                // get Active Asset list
                assetListToUpdate.addAll(
                    NSP_RET_AssetSyncWithClientHistBatch.getActiveAssetList(
                        assetList ,
                        assetListToUpdate ,
                        assetToSubplanHistMap ,
                        accountsWithActiveWO
                    )
                );
                //Update the Asset record List - DML Update
                this.updateAsset( assetListToUpdate );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_RET_AssetSyncWithClientHistBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    // helper methods
    //

    private static Map<Id,Id> getMapAssetAccountIds( Asset asst ) {
        Map<Id,Id> mapAssetAccountIds = new Map<Id,Id>();
        if ( ( asst != null ) && ( asst.AccountId != null ) ) {
            mapAssetAccountIds.put( asst.Id , asst.AccountId );
        }
        return mapAssetAccountIds;
    }

    private static Map<Id,Id> getMapAssetOpptyId(Asset asst){
        Map<Id,Id> mapAssetOpptyID = new Map<Id,Id>();
        if ( ( asst != null ) && ( asst.Opportunity__c != null ) ) {
            mapAssetOpptyID.put( asst.Id , asst.Opportunity__c );
        }
        return mapAssetOpptyID;
    }

    private void updateAsset( List<Asset> assetListToUpdate ) {
        if ( ( assetListToUpdate != null ) && !assetListToUpdate.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( assetListToUpdate , false );
            NSP_ErrorLogHandler.logResults(
                NSP_RET_AssetSyncWithClientHistBatch.class.getName() ,
                'updateAsset' ,
                results
            );
        }
    }

    // Method to get BackoutAssetList
    private static List<Asset> getBackoutAssetList( Map<Id,Id> mapAssetOpptyID , Map<Id,Date> opptyToProjDateMap ) {
        List<Asset> backoutAssetList = new List<Asset>();
        if ( ( mapAssetOpptyID != null )
            && !mapAssetOpptyID.isEmpty()
            && ( opptyToProjDateMap != null )
            && !opptyToProjDateMap.isEmpty()
            )
        {
            for ( Id assetID : mapAssetOpptyID.keySet() ) {
                Id opptyID =  mapAssetOpptyID.get( assetID );
                Date termdate = null;
                if ( ( opptyToProjDateMap != null ) && opptyToProjDateMap.containsKey( opptyID ) ) {
                    termdate = opptyToProjDateMap.get( opptyID );
                }
                if ( opptyToProjDateMap.containsKey( opptyID ) ) {
                    backoutAssetList.add(
                        NSP_RET_AssetSyncWithClientHistBatch.setAssetFields(
                            assetID ,
                            'Backout' ,
                            termdate
                        )
                    );
                }
            }
        }
        return backoutAssetList;
    }

    // Method to get Active Asset list
    private static List<Asset> getActiveAssetList(
        List<Asset> assetList ,
        List<Asset> backoutAssetList,
        Map<Id,NSP_Client_Sub_Plan_History__c> assetToSubplanHistMap ,
        Set<Id> accountsWithActiveWO
        )
    {
        List<Asset> activeAssetList = new List<Asset>();
        if ( ( assetList != null )
            && ( backoutAssetList != null )
            && ( assetToSubplanHistMap != null )
            )
        {
            for ( Asset eachAsset : assetList ) {
                NSP_Client_Sub_Plan_History__c subplanHist = null;
                if ( ( eachAsset != null )
                    && ( eachAsset.Id != null )
                    && assetToSubplanHistMap.containsKey( eachAsset.Id )
                    && !backoutAssetList.contains( eachAsset )
                    )
                {
                    subplanHist = assetToSubplanHistMap.get( eachAsset.Id );
                }
                activeAssetList.addAll(
                    NSP_RET_AssetSyncWithClientHistBatch.getActiveAssetFromSubPlan(
                        subplanHist ,
                        accountsWithActiveWO
                    )
                );
            }
        }
        return activeAssetList;
    }

    private static List<Asset> getActiveAssetFromSubPlan( NSP_Client_Sub_Plan_History__c subplanHist , Set<Id> accountsWithActiveWO ) {
        List<Asset> activeAssetList = new List<Asset>();
        Date todaysDate = Date.today();
        if ( ( subplanHist != null ) && ( subplanHist.NSP_Start_Date__c != null ) ) {
            Boolean isCurrentSubplan = subplanHist.NSP_Current_Subplan__c;
            Boolean hasEndDateGreaterThanToday  = (
                ( subplanHist.NSP_End_Date__c == null )
                || ( subplanHist.NSP_End_Date__c > todaysDate )
            );
            Boolean hasActiveWO  = (
                ( accountsWithActiveWO != null )
                && accountsWithActiveWO.contains( subplanHist.NSP_Asset__r.AccountId )
            );
            Boolean activeAssetCondition = (
                ( subplanHist.NSP_Start_Date__c <= todaysDate )
                && hasEndDateGreaterThanToday
            );
            Boolean recentSubplanHisCondition = (
                ( ( subplanHist.NSP_Start_Date__c == todaysDate )
                    && hasEndDateGreaterThanToday
                    )
                || ( ( subplanHist.NSP_Start_Date__c < todaysDate )
                    && ( subplanHist.NSP_End_Date__c == null )
                    )
            );
            // Check if start date is today or before today and enddate is null or future and update Asset status to 'Active'
            if ( isCurrentSubplan
                && ( recentSubplanHisCondition
                    || ( hasActiveWO && activeAssetCondition )
                    )
                )
            {
                activeAssetList.add(
                    NSP_RET_AssetSyncWithClientHistBatch.setAssetFields(
                        subplanHist.NSP_Asset__c ,
                        NSP_RET_AssetSyncWithClientHistBatch.STATUS_ACTIVE ,
                        null
                    )
                );
            }
        }
        return activeAssetList;
    }

    //Method to Check if Account has Active WO Asset
    private static Set<Id> getAccountsWithActiveWO( List<Id> accountIDs ) {
        Id recordTypeIdWo = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
        Set<Id> accountsWithActiveWO = new Set<Id>();
        if ( accountIDs != null ) {
            for ( Asset ast : [
                        SELECT Id , AccountId
                        FROM Asset
                        WHERE (
                            ( AccountId IN :accountIDs )
                            AND ( RecordTypeId = :recordTypeIdWo )
                            AND ( Status = :NSP_RET_AssetSyncWithClientHistBatch.STATUS_ACTIVE )
                        )
                    ]
                )
            {
                if ( ( ast != null ) && ( ast.AccountId != null ) ) {
                    accountsWithActiveWO.add( ast.AccountId );
                }
            }
        }
        return accountsWithActiveWO;
    }

    // Method to check if project status is Cancelled / Closed/Lost for project records linked to these opptys
    private static Map<Id,Date> getOpptyToProjDateMap( List<Id> opportunityIDS ){
        Map<Id,Date> opptyToProjDateMap = new Map<Id,Date>();
        if ( opportunityIDS != null ) {
            for ( pse__Proj__c proj : [
                        SELECT Id , pse__Opportunity__c , Project_Cancelled_Date__c
                        FROM pse__Proj__c
                        WHERE (
                            ( pse__Opportunity__c IN :opportunityIDS )
                            AND (
                                pse__Project_Status__c IN (
                                    :NSP_ServiceConstants.PROJECTSTATUSCANCELLED ,
                                    :NSP_ServiceConstants.PROJECTSTATUSCLOSED
                                )
                            )
                        )
                    ]
                )
            {
                if ( ( proj != null ) && ( proj.pse__Opportunity__c != null ) ) {
                    opptyToProjDateMap.put( proj.pse__Opportunity__c , proj.Project_Cancelled_Date__c );
                }
            }
        }
        return opptyToProjDateMap;
    }

    //Method to get latest Client Sub Plan History per Asset
    private static Map<Id,NSP_Client_Sub_Plan_History__c> getAssetToSubplanHistMap( Set<Id> assetIDS ) {
        Map<Id,NSP_Client_Sub_Plan_History__c> assetToSubplanHistMap = new Map<Id,NSP_Client_Sub_Plan_History__c>();
        if ( assetIDS != null ) {
            for ( NSP_Client_Sub_Plan_History__c subplanHist : [
                        SELECT Id , NSP_Asset__c , NSP_Start_Date__c , Createddate , NSP_End_Date__c , NSP_Current_Subplan__c , NSP_Asset__r.AccountId
                        FROM NSP_Client_Sub_Plan_History__c
                        WHERE (
                            ( NSP_Asset__c IN :assetIDS )
                            AND ( NSP_Current_Subplan__c = true )
                        )
                        ORDER BY Createddate DESC
                    ]
                )
            {
                //Consider only the latest if there are more than one NSP_Client_Sub_Plan_History__c
                if ( ( subplanHist != null )
                    && ( subplanHist.NSP_Asset__c != null )
                    && !assetToSubplanHistMap.containsKey( subplanHist.NSP_Asset__c )
                    )
                {
                    assetToSubplanHistMap.put( subplanHist.NSP_Asset__c , subplanHist );
                }
            }
        }
        return assetToSubplanHistMap;
    }

    // Method to set status for Asset records
    private static Asset setAssetFields( Id assetID , String assetStatus , Date terminationDate ) {
        Asset assetUpdate = new Asset();
        assetUpdate.Id = assetID;
        assetUpdate.Status = assetStatus;
        if ( ( assetStatus == NSP_RET_AssetSyncWithClientHistBatch.STATUS_ACTIVE )
            && ( assetUpdate.NSP_Termination_Date__c != null )
            )
        {
            assetUpdate.NSP_Termination_Date__c = null;
        } else if ( terminationDate != null ) {
            assetUpdate.NSP_Termination_Date__c = terminationDate;
        }
        return assetUpdate;
    }

    //
    // custom settings
    //

    private static RETAssetSyncWithClientHistorySettings__c settings {
        private get {
            if ( settings == null ) {
                settings = RETAssetSyncWithClientHistorySettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( NSP_RET_AssetSyncWithClientHistBatch.settings != null
                    && NSP_RET_AssetSyncWithClientHistBatch.settings.IsEnabled__c != null) {
                        local = NSP_RET_AssetSyncWithClientHistBatch.settings.IsEnabled__c;
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
                if ( ( NSP_RET_AssetSyncWithClientHistBatch.settings != null )
                    && ( NSP_RET_AssetSyncWithClientHistBatch.settings.BatchSize__c != null )
                   )
                {
                    local = NSP_RET_AssetSyncWithClientHistBatch.settings.BatchSize__c.intValue();
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

}
//