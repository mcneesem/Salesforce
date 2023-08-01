/**
* @description  :  Batch Class to update Ret Education Record sync with Associated Asset.
* @date 10/13/2022
* Author : Abhishek Kumar
* Name : NSP_RetEducationRecSyncBatch
*/
public class NSP_RetEducationRecSyncBatch implements Schedulable,Database.Batchable<SObject>{
    
    //start
    public Database.QueryLocator start(Database.BatchableContext bc){

        //query to get Ret Ed rec with Education Client and no subplan or lead parent   
        String query = 'SELECT Id, NSP_Subplan__c, NSP_Education_Client__c, NSP_Lead_Parent__c FROM AssetRETEducationAssociation__c ' ;
        query += 'WHERE NSP_Education_Client__c != Null AND ( NSP_Subplan__c = Null OR NSP_Lead_Parent__c = NULL )';

        return Database.getQueryLocator(query);
    }
    
    //Execute
    public void execute(Database.BatchableContext bc, List<AssetRETEducationAssociation__c> retEdRecList){
        Set<Id> assetIds = new Set<Id>();
        Map<Id, Id> assetIdToPlanSubPlanIDMap = new Map<Id,Id>();
        try{
            //iterate through all Ret Ed rec to get asset Ids
            for(AssetRETEducationAssociation__c eachRetEdRec : retEdRecList){
                assetIds.add(eachRetEdRec.NSP_Education_Client__c);
            }
            
            //map all planSubplan with asset id as key 
            for( NSP_Plan_SubPlan__c eachPlanSubPlanRec : [SELECT Id,NSP_Subplan_Lead_Parent__c FROM NSP_Plan_SubPlan__c WHERE NSP_Subplan_Lead_Parent__c IN : assetIds] ){
                if(assetIdToPlanSubPlanIDMap.get(eachPlanSubPlanRec.NSP_Subplan_Lead_Parent__c) == Null){
                    assetIdToPlanSubPlanIDMap.put(eachPlanSubPlanRec.NSP_Subplan_Lead_Parent__c , eachPlanSubPlanRec.Id );
                }
            }

            //update Ret Ed list with subplan and leadparent
            for(AssetRETEducationAssociation__c eachRetEdRec : retEdRecList){
                if( assetIdToPlanSubPlanIDMap.get(eachRetEdRec.NSP_Education_Client__c) != Null ){
                    eachRetEdRec.NSP_Subplan__c = assetIdToPlanSubPlanIDMap.get(eachRetEdRec.NSP_Education_Client__c);
                }
                eachRetEdRec.NSP_Lead_Parent__c = eachRetEdRec.NSP_Education_Client__c;
                
            }

            //update the ret ed list 
            if( ! retEdRecList.isEmpty()){
                Database.update(retEdRecList);
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_RetEducationRecSyncBatch', 'ExecuteMethod', ex.getMessage());
        }
    }

    //finish
    public void finish(Database.BatchableContext bc){
        
    }
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_RetEducationRecSyncBatch(),200);
    }
}