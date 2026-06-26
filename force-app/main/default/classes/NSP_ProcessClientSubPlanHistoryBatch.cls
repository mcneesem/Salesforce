public class NSP_ProcessClientSubPlanHistoryBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_ProcessClientSubPlanHistoryBatchTest (98%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_ProcessClientSubPlanHistoryBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F at 8pm central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_ProcessClientSubPlanHistoryBatch ~ process lead parent info on plan subplan and asset ~ M-F at 8 PM' + suffix ,
            '0 0 20 ? * MON-FRI *' ,
            new NSP_ProcessClientSubPlanHistoryBatch()
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
        if ( NSP_ProcessClientSubPlanHistoryBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_ProcessClientSubPlanHistoryBatch() ,
                NSP_ProcessClientSubPlanHistoryBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        //Querying the data from client sub plan history which has Start date as today and current subplan
        Set<Id> recordTypeIdSet = new Set<Id>();
        recordTypeIdSet.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE ) ); // RET Choice Recordtype
        recordTypeIdSet.add( NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE ) ); // RET WO Recordtype
        return Database.getQueryLocator(
            [
                SELECT
                    Id , NSP_Start_Date__c , NSP_Future_Lead_Parent__c ,
                    NSP_Current_Subplan__c , NSP_Plan_Subplan_Relationship__c ,
                    NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c ,
                    NSP_Asset__c , NSP_Asset__r.NSP_Client_is_Lead_Parent__c
                FROM NSP_Client_Sub_Plan_History__c
                WHERE (
                    (
                        NSP_Future_Lead_Parent__c <= TODAY
                        OR NSP_Start_Date__c = TODAY
                    )
                    AND NSP_Asset__r.RecordTypeId IN :recordTypeIdSet
                    AND NSP_Active_Date__c = true
                    AND Processed_Client_Subplan_History__c = false
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList ) {
        if ( NSP_ProcessClientSubPlanHistoryBatch.isEnabled ) {
            Set<Id> assetIdset = new Set<Id>();
            Map<Id,Asset> assetUpdateMap = new Map<Id,Asset>();
            List<NSP_Client_Sub_Plan_History__c> chsUpdateList = new List<NSP_Client_Sub_Plan_History__c>();
            for ( NSP_Client_Sub_Plan_History__c eachCSH : clientSubPlanHistoryList ) {
                if ( NSP_ProcessClientSubPlanHistoryBatch.isEnabledCurrentSubPlan ) {
                    eachCSH.Processed_Client_Subplan_History__c = true;
                    if ( !eachCSH.NSP_Current_Subplan__c ) {
                        // if CSH is not current subplan
                        eachCSH.NSP_Current_Subplan__c = true;
                    }
                    chsUpdateList.add( eachCSH );
                }
                if ( eachCSH.NSP_Future_Lead_Parent__c != null
                    && eachCSH.NSP_Future_Lead_Parent__c <= System.today()
                    )
                {
                    // asset added as lead parent
                    if ( eachCSH.NSP_Asset__r.NSP_Client_is_Lead_Parent__c ) {
                        // if asset is already marked as client is lead parent
                        assetIdset.add( eachCSH.NSP_Asset__c );
                    } else {
                        Asset eachAsset = New Asset( Id=eachCSH.NSP_Asset__c ); // Set Data on Asset
                        eachAsset.NSP_Client_is_Lead_Parent__c = true;
                        eachAsset.NSP_RET_lead_parent__c = null;
                        eachAsset.NSP_Process_Order_Change__c = false;
                        eachAsset.NSP_Change_Order_Process_Contract_Status__c = null;
                        assetUpdateMap.put( eachAsset.Id , eachAsset );
                    }
                } else if ( eachCSH.NSP_Start_Date__c != null
                    && eachCSH.NSP_Start_Date__c == System.today()
                    && eachCSH.NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c != null
                    && eachCSH.NSP_Asset__c != eachCSH.NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c
                    )
                {
                    // for asset added as memeber and not lead parent
                    Asset eachAsset = New Asset( Id=eachCSH.NSP_Asset__c ); // Set Data on Asset
                    eachAsset.NSP_Client_is_Lead_Parent__c = false;
                    eachAsset.NSP_RET_lead_parent__c = eachCSH.NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c;
                    eachAsset.NSP_Process_Order_Change__c = false;
                    eachAsset.NSP_Change_Order_Process_Contract_Status__c = null;
                    assetUpdateMap.put( eachAsset.Id , eachAsset );
                }
            }
            this.handleDmlOperations( chsUpdateList , assetIdset , assetUpdateMap );
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private void handleDmlOperations(
        List<NSP_Client_Sub_Plan_History__c> chsUpdateList ,
        Set<Id> assetIdset ,
        Map<Id,Asset> assetUpdateMap
        )
    {
        if ( ( chsUpdateList != null ) && !chsUpdateList.isEmpty() ) {
            // update current subplan on clint sub plan history
            List<Database.SaveResult> results = Database.update( chsUpdateList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProcessClientSubPlanHistoryBatch.class.getName() ,
                'execute:update:NSP_Client_Sub_Plan_History__c' ,
                results
            );
        }
        if ( ( assetIdset != null ) && !assetIdset.isEmpty() ) {
            NSP_ProcessAssetforLeadParent.processLeadParent( assetIdset );
        }
        if ( ( assetUpdateMap != null ) && !assetUpdateMap.isEmpty() ) {
            // update asset
            List<Database.SaveResult> results = Database.update( assetUpdateMap.values() , false );
            NSP_ErrorLogHandler.logResults(
                NSP_ProcessClientSubPlanHistoryBatch.class.getName() ,
                'execute:update:Asset' ,
                results
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static ProcessClientSubPlanHistoryBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ProcessClientSubPlanHistoryBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_ProcessClientSubPlanHistoryBatch.settings != null ) {
                    local = NSP_ProcessClientSubPlanHistoryBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Boolean isEnabledCurrentSubPlan {
        private get {
            if ( isEnabledCurrentSubPlan == null ) {
                Boolean local = False;
                if ( NSP_ProcessClientSubPlanHistoryBatch.settings != null ) {
                    local = NSP_ProcessClientSubPlanHistoryBatch.settings.IsEnabledCurrentSubPlan__c;
                }
                isEnabledCurrentSubPlan = local;
            }
            return isEnabledCurrentSubPlan;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_ProcessClientSubPlanHistoryBatch.settings != null )
                    && ( NSP_ProcessClientSubPlanHistoryBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_ProcessClientSubPlanHistoryBatch.settings.BatchSize__c.intValue();
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