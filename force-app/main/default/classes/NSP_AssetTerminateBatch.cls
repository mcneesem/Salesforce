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

Global class NSP_AssetTerminateBatch implements Schedulable, Database.Batchable<sObject> {

    private static final String ASSET = 'Asset';
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date last30Days = system.Today()-30;
        String finalDate = String.valueOf(last30Days).removeEnd(' 00:00:00');
        Id WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.WO_ASSET_RECORDTYPE); 
        List<String> assetFields = new List<String>{
                'ID',
                'AccountId',
                'RecordTypeId',
                'NSP_Account_Status__c',
                'NSP_Termination_Date__c'                       
                };
                    String assetObjectApiName = ASSET;  
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(assetObjectApiName, assetFields)            								            								
            .addFilter('AccountId', NULL, NSP_QueryBuilder.Operator.NOT_EQUALS,false)
            .addFilter('RecordTypeId', WO_ASSET_RECORDTYPE , NSP_QueryBuilder.Operator.EQUALS,true)
            .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.TERMINATED , NSP_QueryBuilder.Operator.EQUALS, true)
            .addFilter('NSP_Termination_Date__c', finalDate , NSP_QueryBuilder.Operator.LESS_THAN_OR_EQUALS, false)
            .setSecurityEnforce(false);      
        String query = queryBuilder.build();        
        return Database.getQueryLocator(query);                
    }
    global void execute(Database.BatchableContext bc, List<Asset> existAsset){
        Set<Id> accIds = new Set<Id>();
        List<Asset> assetToBeUpdated = new List<Asset>();
        Map<ID,Date> accountIDTermDateMap = new  Map<ID,Date>();
        List<ID> assetRecordIDList = getAssetRecordID();
        
        //Loop through the asset list
        for(Asset asst : existAsset) {
            //get exist account ids
            accIds.add(asst.AccountId);
            //map of account ID and termination date 
            accountIDTermDateMap.put(asst.AccountId, asst.NSP_Termination_Date__c);
        }        
        //update Status AND Termination Date for RT other then WO
        for(Asset asst : [SELECT Id, AccountId, RecordTypeId, Status, NSP_Termination_Date__c FROM Asset WHERE  AccountId =: accIds AND RecordTypeId IN : assetRecordIDList AND NSP_ProductBundle__c =: NSP_ServiceConstants.WoWSAsset AND Status != : NSP_ServiceConstants.TERMINATED]) {
            asst.Status = 'Terminated';
            asst.NSP_Termination_Date__c = accountIDTermDateMap.get(asst.AccountId);
            assetToBeUpdated.add(asst);            
        }
        // update the asset list        
        if(!assetToBeUpdated.isEmpty()) {
            UpdateAsset(assetToBeUpdated);        
        }
    }
    
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_AssetTerminateBatch(),200);
    }
    //finish method of the batch class
    global void finish(Database.BatchableContext bc){
        
    } 
    
    public static List<ID> getAssetRecordID(){       
        List<ID> assetRecordIDList = new List<ID>();
        try{            
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.TIME_ATTENDANCE_ASSET ));        
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.INTEGRA ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.ASSET_RECRUITING_SERVICES ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.XML_ASSET ));
            assetRecordIDList.add(NSP_GenericRecordType.getRecordTypeId(ASSET,NSP_ServiceConstants.LEARNING_DEVELOPMENT ));
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_AssetTerminateBatch', 'getAssetRecordID', ex.getMessage());
        } 
        return assetRecordIDList;
    }
    
    public static void updateAsset(List<Asset> assetToBeUpdated){       
        try{                        
            // update the asset records           
                Database.SaveResult[] result =  Database.update(assetToBeUpdated,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AssetTerminateBatch', 'updateAsset:assetToBeUpdated', result);                                      
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_AssetTerminateBatch', 'updateAsset', ex.getMessage());
        }             
    } 
    
}