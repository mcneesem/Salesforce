/**************************************************************************************************************************
* @description  :  Batch Class to Replicate the trigger based functionality for Product First Pay Date field
* @date 03/08/2023
* Author : Prajwal Hosamani
* Name : NSP_AcntEarliestFirstPayDateUpdateBatch
* Story : STY-03875 - Create Batches for fields that are set view trigger for go-live migrated data
* Version : V1
**************************************************************************************************************************/
public class NSP_AcntEarliestFirstPayDateUpdateBatch implements Schedulable,Database.Batchable<SObject>{
    Id woassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
    Id wxassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( NSP_ServiceConstants.ASSET_SOBJECT_TYPE, 'NSP_Asset_Product');
    Id tsassetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.TIME_ATTENDANCE_ASSET);
    
    //start method
    //This method will query on Asset object with required filter conditions
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        List<String> assetTypes = new List<String>{woassetRecordTypeId,wxassetRecordTypeId,tsassetRecordTypeId};
        List<String> assetFields = new List<String>{'Id','AccountId','NSP_First_Pay_Date__c','NSP_AIMS_First_Pay_Date__c','RecordTypeId'};

        String query = new NSP_QueryBuilder( NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            .addFilter('RecordTypeId', assetTypes, NSP_QueryBuilder.Operator.INCLUDES)
            .build();
        
        return Database.getQueryLocator(query);
    }

    //execute method to populate all the required assets in a map 
    public void execute(Database.BatchableContext bc, List<Asset> AssetList){
        Map<Id,Date> mapOfAccntdToErlstPayDate = new Map<Id,Date>();
        List<Account> accountsToUpdateList = new List<Account>();
        List<Asset> woAssetsToUpdateList = new List<Asset>();
            try{

            for(Asset eachAsset : AssetList){
                if(eachAsset.RecordTypeId == woassetRecordTypeId){
                    eachAsset.NSP_First_Pay_Date__c = eachAsset.NSP_AIMS_First_Pay_Date__c;
                    if(!woAssetsToUpdateList.contains(eachAsset)){
                        woAssetsToUpdateList.add(eachAsset);
                    }
                }
                
                if( eachAsset.NSP_First_Pay_Date__c != null){
                    
                    if(mapOfAccntdToErlstPayDate.get(eachAsset.AccountId) == null){
                        mapOfAccntdToErlstPayDate.put(eachAsset.AccountId, eachAsset.NSP_First_Pay_Date__c); 
                    }
                    else if(mapOfAccntdToErlstPayDate.get(eachAsset.AccountId) > eachAsset.NSP_First_Pay_Date__c){
                            mapOfAccntdToErlstPayDate.put(eachAsset.AccountId, eachAsset.NSP_First_Pay_Date__c);
                    }
                }
            }
            for( Account eachAccount : [ SELECT ID,NSP_Product_First_Pay_Date__c FROM Account WHERE Id IN: mapOfAccntdToErlstPayDate.keySet()]){

                if( eachAccount.NSP_Product_First_Pay_Date__c == null 
                    ||  eachAccount.NSP_Product_First_Pay_Date__c > mapOfAccntdToErlstPayDate.get(eachAccount.Id)){
                        eachAccount.NSP_Product_First_Pay_Date__c = mapOfAccntdToErlstPayDate.get(eachAccount.Id);
                        accountsToUpdateList.add( eachAccount );
                    }
            }
            
            //check if the list is empty and do update 
            if(!accountsToUpdateList.isEmpty()){
                //update the account list 
                List<Database.SaveResult> results = Database.update(accountsToUpdateList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AcntEarliestFirstPayDateUpdateBatch', 'ExecuteMethod', results );
            }

            if(!woAssetsToUpdateList.isEmpty()){
                //update the asset list 
                List<Database.SaveResult> AssetResults = Database.update(woAssetsToUpdateList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AcntEarliestFirstPayDateUpdateBatch', 'ExecuteMethod', AssetResults );
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AcntEarliestFirstPayDateUpdateBatch', 'Execute', ex.getMessage());
        }
    }

    //finsih method
    public void finish(Database.BatchableContext BC){

    }

    //Schedulable execute method to fire the batch class
    public void execute(SchedulableContext scon){
        //To fire the Batchclass
        Database.executeBatch(new NSP_AcntEarliestFirstPayDateUpdateBatch(),50);
    }
}