// 2022-11-04 ~ STY-03665 ~ Srushti ~ Batch Class to update Asset record fields from client sub plan history record.
public class NSP_ClientSubPlanHistoryBatch implements Database.Batchable<sObject>, Schedulable {
    // test w/ NSP_ClientSubPlanHistoryBatchTest (96%)

    public NSP_ClientSubPlanHistoryBatch() {
        // intentionally blank...
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
                SELECT Id , NSP_Start_Date__c , NSP_End_Date__c , NSP_Asset__c , NSP_Asset__r.RecordTypeId , CreatedDate
                FROM NSP_Client_Sub_Plan_History__c
                WHERE (
                    ( NSP_Asset__c != null )
                    AND (
                        ( NSP_Asset__r.RecordTypeId = :retChoiceAssetRecordTypeId )
                        OR ( NSP_Asset__r.RecordTypeId = :retWOAssetRecordTypeId )
                    )
                )
                WITH SECURITY_ENFORCED
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<NSP_Client_Sub_Plan_History__c> scope ) {
        Set<Id> assetIdSet =  new Set<Id>();
        Set<Id> nonTermAssetIdSet = new Set<Id>();
        Map<Id, NSP_Client_Sub_Plan_History__c> assetClientSubPlanHistoryMap = new Map<Id, NSP_Client_Sub_Plan_History__c>();
        //Iterate through the list of client sub plan history and add asset Ids and remove those assets which will not be terminating
        for(NSP_Client_Sub_Plan_History__c clientSubPlanHistoryRec: scope){
            assetIdSet.add(clientSubPlanHistoryRec.NSP_Asset__c);
            if(clientSubPlanHistoryRec.NSP_Start_Date__c >= date.today() && clientSubPlanHistoryRec.NSP_End_Date__c == NULL){
                assetIdSet.remove(clientSubPlanHistoryRec.NSP_Asset__c);
                nonTermAssetIdSet.add(clientSubPlanHistoryRec.NSP_Asset__c);
            }
        }
        List<Asset> assetRecordToUpdate = [SELECT Id, NSP_Termination_Date__c, Status FROM Asset WHERE Id IN: assetIdSet];
        List<Asset> nonTermAssetToUpdate = [SELECT Id, NSP_Termination_Date__c, Status FROM Asset WHERE Id IN: nonTermAssetIdSet];
        List<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList = [
            SELECT Id , NSP_Start_Date__c , CreatedDate , NSP_End_Date__c , NSP_Asset__c
            FROM NSP_Client_Sub_Plan_History__c
            WHERE (
                NSP_Asset__c IN :assetIdSet
                AND NSP_End_Date__c <= TODAY
            )
        ];
        //Link the most recently created client sub plan history to the asset 
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
        if(!assetRecordToUpdate.isEmpty()){
            Database.update(assetRecordToUpdate);
        }
        //if the asset was already terminated and a future dated client sub plan history was created then update the asset status and termination date
        for(Asset eachNonTermAsset: nonTermAssetToUpdate){
            eachNonTermAsset.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
            eachNonTermAsset.NSP_Termination_Date__c = NULL;
        }
        if(!nonTermAssetToUpdate.isEmpty()){
            Database.update(nonTermAssetToUpdate);
        }
    }

    public void finish( Database.BatchableContext bc ) {
        // intentionally blank...
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        if ( NSP_ClientSubPlanHistoryBatch.isEnabled ) {
            Database.executeBatch(
                new NSP_ClientSubPlanHistoryBatch() ,
                NSP_ClientSubPlanHistoryBatch.batchSize
            );
        }
    }

    public static String schedule() {
        return System.schedule(
            NSP_ClientSubPlanHistoryBatch.class.getName()
                + ' ~ Update the status of the Retirement Services assets considering associated client subplan history records'
                + ' ~ Schedule to run everyday 2 AM'
                + ( Test.isRunningTest() ? ' ~ TEST' : '' ) ,
            '0 0 2 * * ? *' , // every day at 02:00 AM
            new NSP_ClientSubPlanHistoryBatch()
        );
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

}
//