/**
* @description  :  Helper class for Project Asset Trigger.
* @date 12/22/2022
* Author : Nischay Jindal
* Name : NSP_ProjectAssetTriggerHelper
*/
public class NSP_ProjectAssetTriggerHelper {

    /***********************************************************************************************
    * MethodName: afterInsertDirector
    * Description : Run on after Insert
    * Params: List<Project_Asset__c>projAssetList
    * ********************************************************************************************/    
    public static void afterInsertDirector(List<Project_Asset__c>projAssetList){

        Set<Id> projectIdSet = new Set<Id>();
        Set<Id> assetIdSet  = new Set<Id>();
        for(Project_Asset__c prjAsset:projAssetList){
            // project Id set 
            projectIdSet.add(prjAsset.Project__c);
            // asset Id set 
            assetIdSet.add(prjAsset.Asset__c);
        }
        if(!projectIdSet.isEmpty()){
             updateAssetFirstPayDate(projectIdSet,assetIdSet,projAssetList);
        }
    }

    
    /***********************************************************************************************
    * MethodName: updateAssetFirstPayDate
    * Description : update Asset first pay date 
    * Story : STY-03479
    * Author :Nischay Jindal 
    * Params: List<Project_Asset__c>projAssetList
    * ********************************************************************************************/     
    public static void updateAssetFirstPayDate(Set<Id> projectIdSet , Set<Id> assetIdSet,List<Project_Asset__c>projAssetList){
        Map<Id,pse__Proj__c> projectMap = new  Map<Id,pse__Proj__c>();
        List<Asset>updateAssetList = new List<Asset>(); 
        Map<Id,Asset> assetMap = new  Map<Id,Asset>();
        List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>();
        Id woAssetRecordTypeId =NSP_GenericRecordType.getRecordTypeId('Asset','WO');
        try{
            if(!projectIdSet.isEmpty()){
                
                // creating project Map 
                for(pse__Proj__c prj: [SELECT Id, Go_Live_Date__c FROM pse__Proj__c WHERE Id IN:projectIdSet]){
                    projectMap.put(prj.Id , prj);
                }   
            }
            if(!assetIdSet.isEmpty()){
                // creating asset Map 
                for(Asset ast : [SELECT Id ,RecordtypeId, NSP_First_Pay_Date__c FROM Asset WHERE Id IN:assetIdSet]){
                    assetMap.put(ast.Id, ast);
                }   
            }
            
            for(Project_Asset__c prjAsset:projAssetList){
                if(assetMap.containsKey(prjAsset.Asset__c) && assetMap.get(prjAsset.Asset__c).RecordTypeId !=woAssetRecordTypeId &&
                   projectMap.containsKey(prjAsset.Project__c) && projectMap.get(prjAsset.Project__c).Go_Live_Date__c!= null ){
                       Asset ast = new Asset();
                       ast.Id = assetMap.get(prjAsset.Asset__c).Id;
                       ast.NSP_First_Pay_Date__c =  projectMap.get(prjAsset.Project__c).Go_Live_Date__c;
                       updateAssetList.add(ast);
                   }
            }
            if(!updateAssetList.isEmpty()){
                upsertResults = Database.Upsert(updateAssetList, false);
                NSP_ErrorLogHandler.logUpsertResultsException('NSP_ProjectAssetTriggerHelper', 'updateAssetFirstPayDate:upsertResults', upsertResults);
            } 
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ProjectAssetTriggerHelper ', 'updateAssetFirstPayDate', ex.getMessage());
        }
        
    }
}