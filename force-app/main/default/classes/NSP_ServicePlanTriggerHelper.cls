/***************************************************************************************************
* @Class            : NSP_ServicePlanTriggerHelper
* @Author           : Simran
* @Version History  : 1.0
* @Creation         : 05/8/2023
* @Description      : Represents the Service Plan Trigger Helper
******************************************************************************************************/
public class NSP_ServicePlanTriggerHelper {
    
/**
* Iterates throught the list of new Service Plan and passes the required attributes to other methods.
* @param newList List of New Service Plan.  
* @return void                            
*/
    public void beforeInsertDirector(List<NSP_Service_Plan__c> newList){
        Map<Id, String> mapOfAccountIdAssetCompanyName = new Map<Id, String>();
        Set<Id> accountIdSet = new set<Id>();
        for(NSP_Service_Plan__c servicePlan : newList){
            if(String.isNotBlank(servicePlan.NSP_Account__c)){
                accountIdSet.add(servicePlan.NSP_Account__c);
            }
        }
        if(accountIdSet.size() > 0){
            getAssetCompanyName(newList,accountIdSet);
        }
        
    }
/**
* Iterates throught the Service Plan  map and identifies the records that needs to worked based on various criterias.
* @param newMap Map of New Service Plan. 
* @param oldMap Map of Old Service Plan. 
* @return void             
*                
*/
    public void beforeUpdateDirector(Map<Id, NSP_Service_Plan__c> newMap,Map<Id, NSP_Service_Plan__c> oldMap){
        Set<Id> accountIdSet = new set<Id>();
        for(NSP_Service_Plan__c servicePlan : newMap.values()){
            //updating the Account Lookup on Service plan
            if(servicePlan.NSP_Account__c != oldMap.get(servicePlan.Id).NSP_Account__c){
                if(String.isNotBlank(servicePlan.NSP_Account__c)){
                    accountIdSet.add(servicePlan.NSP_Account__c);
                }else{
                    servicePlan.NSP_Asset_AIMS_Client_Name__c = NSP_ServiceConstants.EMPTY_STRING;
                }
            }
        }
        
        if(!accountIdSet.isEmpty()){
            getAssetCompanyName(newMap.values(),accountIdSet);
        }
    }
    
/* Description : This will update the AIMS Client Name field of Service Plan from the Asset Company Name
*/
    public void getAssetCompanyName(List<NSP_Service_Plan__c> newList, Set<Id> accountIdSet ){
        Id woAssetRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Map<Id, String> mapOfAccountIdAssetCompanyName = new Map<Id, String>();
        List<String> assetStatusList = new List<String>{NSP_ServiceConstants.ASSET_ONBOARDING_STATUS, NSP_ServiceConstants.ASSET_ACTIVE_STATUS};
            
            for(Asset asset :[SELECT Id, NSP_Company_Name__c, AccountId, RecordTypeId, Status
                              FROM Asset 
                              WHERE AccountId IN: accountIdSet AND RecordTypeId =: woAssetRecordType 
                              AND Status IN: assetStatusList]){
                                  mapOfAccountIdAssetCompanyName.put(asset.AccountId, asset.NSP_Company_Name__c);
                              }

        for(NSP_Service_Plan__c servicePlan : newList){
            servicePlan.NSP_Asset_AIMS_Client_Name__c = mapOfAccountIdAssetCompanyName.get(servicePlan.NSP_Account__c);
        }
    }
    
    
}