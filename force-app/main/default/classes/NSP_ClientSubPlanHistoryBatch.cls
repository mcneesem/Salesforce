/**
 *  Version - STY           - DESCRIPTION                                      - TAG
 * 	V1.0					Batch Class to update Asset 						<STY-03665>
 * 							record fields from client sub plan history record.
 * 
* @date 11/04/2022
* Name : NSP_ClientSubPlanHistoryBatch
*/

public class NSP_ClientSubPlanHistoryBatch implements Schedulable, Database.Batchable < sObject > {
	public Database.QueryLocator start(Database.BatchableContext bc) {
        //get RET_Choice Asset Record Type Id
        Id retChoiceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
        //get RET_WO Asset Record Type Id
        Id retWOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_WO');
        List<String> clientSubPlanHistoryFields = new List<String>{
            'NSP_Start_Date__c',
            'NSP_End_Date__c',
            'NSP_Asset__c',
            'CreatedDate',
            'NSP_Asset__r.RecordTypeId'
        };
        String clientSubPlanHistoryObjectApiName = 'NSP_Client_Sub_Plan_History__c';
        //query to get the client sub plan history records where start date is in future and end date is less than or equal to today
    	NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(clientSubPlanHistoryObjectApiName, clientSubPlanHistoryFields);
        queryBuilder.setSecurityEnforce(false);
        String query = queryBuilder.build();
        query += ' WHERE NSP_Asset__c != NULL AND (NSP_Asset__r.RecordTypeId =: retChoiceAssetRecordTypeId OR NSP_Asset__r.RecordTypeId =: retWOAssetRecordTypeId)';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<NSP_Client_Sub_Plan_History__c> scope){
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
        List<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList = [SELECT Id, NSP_Start_Date__c, CreatedDate, NSP_End_Date__c, NSP_Asset__c FROM NSP_Client_Sub_Plan_History__c WHERE NSP_Asset__c IN: assetIdSet AND NSP_End_Date__c <= TODAY];
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
    public void finish(Database.BatchableContext bc) {

    }
        public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_ClientSubPlanHistoryBatch(),200);
    }
    }