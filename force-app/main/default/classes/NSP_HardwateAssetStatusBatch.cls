/**
* 
Apex Class Name      :  NSP_HardwateAssetStatusBatch
Version              :  1.0                                                                          
Created Date         :  02/21/2023                                                                      
Description    :        This batch class gets all the Hardware Assets where Terminated Date OR Activation Date is populated and Changes the Asset Status for different use cases                                                                      
*--------------------------------------------------------------------------------------------------  
*  Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
Public class NSP_HardwateAssetStatusBatch implements Database.Batchable<sObject>,Schedulable{
    
    //Batch Start--returning Asset Records.
    Public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getqueryLocator([SELECT Id,NSP_Termination_Date__c,NSP_ActivationDate__c,Status FROM Asset WHERE RecordType.Name=:NSP_CPQConstants.HARDWARE_ASSET AND (NSP_Termination_Date__c!=null OR NSP_ActivationDate__c!=null)]);
    }
    //Batch execute
    Public void execute(Database.BatchableContext bc, List<Asset> assets){
        Date today= System.today();
        List<Asset> assetsToUpdate= new List<Asset>();
        for(Asset eachAsset:assets){
            if(eachAsset.Status==NSP_CPQConstants.ACTIVE && eachAsset.NSP_Termination_Date__c < today){
                eachAsset.Status=NSP_CPQConstants.TERMINATED;
                eachAsset.NSP_ActivationDate__c=null;
                eachAsset.NSP_Support__c=false;
                assetsToUpdate.add(eachAsset);
            }
            if(eachAsset.Status==NSP_CPQConstants.TERMINATED && eachAsset.NSP_ActivationDate__c >= today){
                eachAsset.Status=NSP_CPQConstants.ACTIVE;
                eachAsset.NSP_Termination_Date__c=null;
                eachAsset.NSP_Support__c=true;
                assetsToUpdate.add(eachAsset);
            }
        }
        if(assetsToUpdate.size()>0){
            List<Database.SaveResult> results = Database.update(assetsToUpdate,false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_HardwateAssetStatusBatch','execute', results); 
        }
    }
    //Batch finish
    Public void finish(Database.BatchableContext bc){ 
        
    }
    //schedule a batch
    public void execute(SchedulableContext ctx) {
        NSP_HardwateAssetStatusBatch batchObject = new NSP_HardwateAssetStatusBatch();
        Database.executeBatch(batchObject); 
    }
}