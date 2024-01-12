/**
Apex Class Name      :  NSP_SalesToImplementationBatch
Version              :  1.0                                                                          
Created Date         :  02/03/2023
Function             :  This batch runs update Asset attached to Account
Story                :  STY-02198                                                                  
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Virendra Kumar            02/03/2023              First Iteration
*/

global class NSP_SalesToImplementationBatch implements Database.Batchable<sObject>, Schedulable{
    
    global Database.QueryLocator start(Database.BatchableContext bC){
        return Database.getQueryLocator([SELECT Id, NSP_Client__c, NSP_Asset__c FROM NSP_Sales_to_Implementation__c WHERE NSP_Client__c != null AND  NSP_Asset__c = null]);
        
    }
    
    global void execute(Database.BatchableContext bC, List<NSP_Sales_to_Implementation__c> salesToImpList){
        
        // get RET WO/Choice RecordTypeIds  
        Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE).getRecordTypeId();
        Id choiceRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE).getRecordTypeId();
        
        Set<Id> accIds = new Set<Id>();
        Map<Id, Id> accIdsByAssetIds = new Map<Id, Id>();
        List<NSP_Sales_to_Implementation__c> salesToImplementToBeUpdated = new List<NSP_Sales_to_Implementation__c>();
        
        // store Account Ids Associated Sales to Implementation
        for(NSP_Sales_to_Implementation__c sImplements : salesToImpList) {
            accIds.add(sImplements.NSP_Client__c);
        }
        
        // get Asset Object data Associated to Account 
        if(!accIds.isEmpty()) {
            for(Asset assets : [SELECT Id, AccountId FROM Asset WHERE AccountId =: accIds AND  Status =:NSP_ServiceConstants.ASSET_ACTIVE_STATUS AND (RecordTypeId =:woRecordTypeId OR RecordTypeId =:choiceRecordTypeId)]) {
                accIdsByAssetIds.put(assets.AccountId, assets.Id);
            }
        }
        
        // Update Asset field based on account
        if(!accIdsByAssetIds.isEmpty()) {
            for(NSP_Sales_to_Implementation__c salesImplements : salesToImpList) {
                if(accIdsByAssetIds.containsKey(salesImplements.NSP_Client__c)) {
                    salesImplements.NSP_Asset__c = accIdsByAssetIds.get(salesImplements.NSP_Client__c);
                    salesToImplementToBeUpdated.add(salesImplements);
                }
            }
        }
        if(!salesToImplementToBeUpdated.isEmpty()) {
            update salesToImplementToBeUpdated;
        }
    }
    
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_SalesToImplementationBatch(),200);
    }
    
    global void finish(Database.BatchableContext bC){} 
    
}