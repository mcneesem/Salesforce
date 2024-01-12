/**
Apex Class Name      :  NSP_UpdateServiceSegmentOnAccBatch
Version              :  1.0                                                                          
Created Date         :  1/10/2022  
Function             :  Represents batch class for NSP_UpdateServiceSegmentOnAccBatch 
Story                :  STY-02819                                                               
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti Bikkannavar        1/10/2022            First Iteration
*/

public class NSP_UpdateServiceSegmentOnAccBatch implements Schedulable, Database.Batchable < sObject >{
    
    private static Map<Asset, Id> assetAccountMap;
    //get WO asset RT Id
    private static final Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
    //get WX_WA asset RT Id
    private static final Id wxWaAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        List<String> assetFields = new List<String>{'Id', 'Status', 'NSP_Client_Segment_type__c', 'NSP_Product_Segment__c', 'RecordTypeId', 'AccountId'};
        List<String> assetStatus = new List<String>{NSP_ServiceConstants.ASSET_ACTIVE_STATUS, NSP_ServiceConstants.ASSET_ONBOARDING_STATUS};
        List<Id> assetRecordTypes = new List<Id>{woAssetRecordTypeId, wxWaAssetRecordTypeId};
            
        //query all the asset who's status is either 'Active' or 'Onboarding' and are of WO/WX_WO RTs
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Asset', assetFields)
                         .setSecurityEnforce(false)
            			 .addFilter('Status', assetStatus, NSP_QueryBuilder.Operator.INCLUDES)
            			 .addFilter('RecordTypeId', assetRecordTypes, NSP_QueryBuilder.Operator.INCLUDES);
        String query = queryBuilder.build();
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Asset> assetList){
        //set to store all the account Ids
        Set<Id> accIdSet = new Set<Id>();
        //list of accounts to be updated
        List<Account> accountToUpdateList = new List<Account>();
        assetAccountMap = new Map<Asset, Id>();
        try{
            for(Asset asset: assetList){
                accIdSet.add(asset.AccountId);
            }
            for(Asset assRec: [SELECT Id, AccountId, NSP_Client_Segment_type__c, NSP_Product_Segment__c, RecordTypeId 
                               FROM Asset 
                               WHERE AccountId IN: accIdSet]){
                                   //if the acc has an active WO asset map acc and asset
                                   if(assRec.RecordTypeId == woAssetRecordTypeId){
                                       assetAccountMap.put(assRec, assRec.AccountId);
                                   }
                                   //if acc doesn't have active WO asset then map acc and WX asset
                                   else if(assetAccountMap.isEmpty() && assRec.RecordTypeId == wxWaAssetRecordTypeId){
                                       assetAccountMap.put(assRec, assRec.AccountId);
                                   }
                               }
            if(!assetAccountMap.isEmpty()){
                for(Asset assetRec: assetAccountMap.keySet()){
                    Account acc = new Account();
                    acc.Id = assetAccountMap.get(assetRec);
                    //if an account has an active WO asset, populate the service segment on account with client segment
                    if(assetRec.RecordTypeId == woAssetRecordTypeId){
                        acc.NSP_Service_Segment__c = assetRec.NSP_Client_Segment_type__c;
                    }
                    //if it doesnt have an active WO asset and has an active WX_WA asset, populate the service segment on account with product segment
                    else{
                        acc.NSP_Service_Segment__c = assetRec.NSP_Product_Segment__c;
                    }
                    accountToUpdateList.add(acc);
                }
            }
            
            if(!accountToUpdateList.isEmpty()){
                List<Database.SaveResult> results = Database.update(accountToUpdateList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountServiceSegmetUpdateHelper', 'updateServiceSegment', results );
            }
            
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AccountServiceSegmetUpdateHelper', 'updateServiceSegment', ex.getMessage());
        }
    }
        
    public void finish(Database.BatchableContext bc) {
    }
    
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_UpdateServiceSegmentOnAccBatch(),200);
    }
}