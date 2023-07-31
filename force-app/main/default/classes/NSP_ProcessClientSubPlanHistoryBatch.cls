/**
* @description  : Batch Class to process lead parent info on plan subplan and asset for story STY-03796
* @author Sumit
* @date 23/12/2022
* Name : NSP_ProcessClientSubPlanHistoryBatch
*/
public class NSP_ProcessClientSubPlanHistoryBatch implements Database.Batchable<sObject>,Schedulable {
    // schedulable ecexute method
    public void execute(SchedulableContext SC) {
        //execute the batch with batch size 10.
        NSP_ProcessClientSubPlanHistoryBatch bch = new NSP_ProcessClientSubPlanHistoryBatch();
		Database.executeBatch(bch,Integer.valueof(system.label.NSP_ClientSubPlanHistoryBatchSize)); 
   }
    
    //Querying the data from client sub plan history which has Start date as today and current subplan
    public Database.QueryLocator start(Database.BatchableContext bc){
        set<Id> recordTypeIdSet = new set<Id>();
        recordTypeIdSet.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE)); // RET Choice Recordtype
        recordTypeIdSet.add(NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE)); // RET WO Recordtype
        return Database.getQueryLocator([SELECT Id,NSP_Start_Date__c,NSP_Future_Lead_Parent__c,NSP_Current_Subplan__c,NSP_Plan_Subplan_Relationship__c,NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c,NSP_Asset__c,NSP_Asset__r.NSP_Client_is_Lead_Parent__c from NSP_Client_Sub_Plan_History__c 
                                         WHERE (NSP_Future_Lead_Parent__c = TODAY OR NSP_Start_Date__c = TODAY)
                                         AND NSP_Asset__r.RecordTypeId In :  recordTypeIdSet
                                         AND NSP_Active_Date__c = true]);
    }
    
    public void execute(Database.BatchableContext bc, list<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList){
        set<id> assetIdset = new set<id>();
        //list<Asset> assetUpdateList = new  list<Asset>();
        Map<Id,Asset> assetUpdateMap = new Map<Id,Asset>();
        list<NSP_Client_Sub_Plan_History__c> chsUpdateList = new  list<NSP_Client_Sub_Plan_History__c>();
        
        for(NSP_Client_Sub_Plan_History__c eachCSH : clientSubPlanHistoryList){
            if(!eachCSH.NSP_Current_Subplan__c){ // if CSH is not current subplan
                eachCSH.NSP_Current_Subplan__c = true; 
                chsUpdateList.add(eachCSH);
            }
            
            if(eachCSH.NSP_Future_Lead_Parent__c != null && eachCSH.NSP_Future_Lead_Parent__c == system.today()){ // asset added as lead parent 
                if(eachCSH.NSP_Asset__r.NSP_Client_is_Lead_Parent__c){ // if asset is already marked as client is lead parent
                    assetIdset.add(eachCSH.NSP_Asset__c);
                }else{
                    Asset eachAsset = New Asset(Id = eachCSH.NSP_Asset__c); // Set Data on Asset
                    eachAsset.NSP_Client_is_Lead_Parent__c = true;
                    eachAsset.NSP_RET_lead_parent__c = null;
                    eachAsset.NSP_Process_Order_Change__c = false;
                    eachAsset.NSP_Change_Order_Process_Contract_Status__c = null;
                    //assetUpdateList.add(eachAsset);
                    assetUpdateMap.put(eachAsset.Id,eachAsset);
                }
            }
            else if(eachCSH.NSP_Start_Date__c != null && eachCSH.NSP_Start_Date__c == system.today() && eachCSH.NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c != null){ // for asset added as memeber and not lead parent
                Asset eachAsset = New Asset(Id = eachCSH.NSP_Asset__c); // Set Data on Asset
                eachAsset.NSP_Client_is_Lead_Parent__c = false;
                eachAsset.NSP_RET_lead_parent__c = eachCSH.NSP_Plan_Subplan_Relationship__r.NSP_Subplan_Lead_Parent__c;
                eachAsset.NSP_Process_Order_Change__c = false;
                eachAsset.NSP_Change_Order_Process_Contract_Status__c = null;
                assetUpdateMap.put(eachAsset.Id,eachAsset);
                //assetUpdateList.add(eachAsset);
            }
            
        }
        
        if(chsUpdateList.Size() > 0){
            // update current subplan on clint sub plan history
            List<Database.SaveResult> assetResults = Database.update(chsUpdateList,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessClientSubPlanHistoryBatch', 'ExecuteMethod', assetResults ); //log the result
        }
        
        if(assetIdset.Size() > 0){
            NSP_ProcessAssetforLeadParent.processLeadParent(assetIdset); // call the  processLeadParent 
        }
        
        if(assetUpdateMap.size() > 0){
            // update asset
            List<Database.SaveResult> assetResults = Database.update(assetUpdateMap.Values(),false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_ProcessClientSubPlanHistoryBatch', 'ExecuteMethod', assetResults ); //log the result
        }
    }
    
     public void finish(Database.BatchableContext bc){
    }
}