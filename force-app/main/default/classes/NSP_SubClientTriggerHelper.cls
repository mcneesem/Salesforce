/**
 * Represents the Sub Client trigger helper which handles all the logic.
 * Created by : Hemali Patel
 * Created Date : 6/11/2021
*/

public class NSP_SubClientTriggerHelper {
	
    /**
     * Iterates throught the list of new NSP_Sub_Client__c and passes the required attributes to other methods.
     * @param newList List of New NSP_Sub_Client__c.
     * @return void
     *                
     */
    public void beforeInsertDirector(List<NSP_Sub_Client__c> newList){
        Set<String> aimsClientStr = new Set<String>();
        List<NSP_Sub_Client__c> newSubClientToPopulateAsset = new List<NSP_Sub_Client__c>();
        
        for(NSP_Sub_Client__c subClientObj : newList){
            if(!String.isBlank(subClientObj.NSP_Client__c)){
            	aimsClientStr.add(subClientObj.NSP_Client__c);
                newSubClientToPopulateAsset.add(subClientObj);
            }
        }
        
        /*
        if(aimsClientStr.size() > 0){
            populateAssetIdOnSubClient(newSubClientToPopulateAsset,aimsClientStr);
        } */
            
    }	
    
    /**
     * Iterates throught the list of new NSP_Sub_Client__c and passes the required attributes to other methods.
     * @param newList List of New NSP_Sub_Client__c.
     * @param newMap List of New NSP_Sub_Client__c.
     * @return void
     *                
     */
	public void afterInsertDirector(List<NSP_Sub_Client__c> newList, Map<Id, NSP_Sub_Client__c> newMap) {

		Set<Id> assetIdSet = new Set<Id>();
        
        for(NSP_Sub_Client__c subClientObj : newList){
            assetIdSet.add(subClientObj.NSP_Asset__c);
        }
        
        if(assetIdSet.size() > 0){
            populateStatusAndStatusDateOnAsset(assetIdSet);
        }
            
        
        //Set<String> subClientAIMSClientIdSetWithUnionEmployees = new Set<String>();
        // if(subClientObj.NSP_Union_Employees__c)
        //   subClientAIMSClientIdSetWithUnionEmployees.add(subClientObj.NSP_Client__c);
      
        
       /* if(subClientAIMSClientIdSetWithUnionEmployees.size() > 0){
          //  setUnionEmployeesOnAsset(subClientAIMSClientIdSetWithUnionEmployees);
        }*/
            
    }
    
    
     /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */

    public void afterUpdateDirector(Map<Id, NSP_Sub_Client__c> newMap,Map<Id, NSP_Sub_Client__c> oldMap) {
        
        //Set<String> subClientAIMSClientIdSetWithUnionEmployees = new Set<String>();
        Set<Id> assetId = new Set<Id>();
        for(NSP_Sub_Client__c subClientObj : newMap.values()){
           // if(subClientObj.NSP_Union_Employees__c && !oldMap.get(subClientObj.Id).NSP_Union_Employees__c)
             //   subClientAIMSClientIdSetWithUnionEmployees.add(subClientObj.NSP_Client__c);
           if(subClientObj.NSP_Account_Status__c != oldMap.get(subClientObj.Id).NSP_Account_Status__c ||
              subClientObj.NSP_Account_Status_Date__c != oldMap.get(subClientObj.Id).NSP_Account_Status_Date__c || 
              subClientObj.NSP_Asset__c != oldMap.get(subClientObj.Id).NSP_Asset__c){
                 assetId.add(subClientObj.NSP_Asset__c); 
              }
        }
        
        if(assetId.size() > 0){
            populateStatusAndStatusDateOnAsset(assetId);
        }
        
        /*if(subClientAIMSClientIdSetWithUnionEmployees.size() > 0){
            setUnionEmployeesOnAsset(subClientAIMSClientIdSetWithUnionEmployees);
        }*/
        
        //for tracking history
        //NSP_SObjectFieldHistoryHelper objectFieldHistoryHelper = new NSP_SObjectFieldHistoryHelper();
        //objectFieldHistoryHelper.fieldHistoryLogData((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
    }
    
    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */

    /*public void setUnionEmployeesOnAsset(Set<String> subClientIdSet) {
        
        List<Asset> assetList = [SELECT Id,NSP_Union_Employees__c from Asset where 
                                 NSP_Client__c IN: subClientIdSet AND 
                                 NSP_Union_Employees__c = false];     
        
        for(Asset oAsset : assetList){
            oAsset.NSP_Union_Employees__c = true;
        }
        
        if(assetList.size() > 0)
        	update assetList;
    }*/
    
    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */
    /*public void populateAssetIdOnSubClient(List<NSP_Sub_Client__c> newSubClientList, Set<String> aimsClient){
        Map<String,Id> assetClientMap = new Map<String,Id>();
        List<Asset> assetList = [Select Id from Asset where NSP_Client__c IN: aimsClient];
        
        for(Asset assetObj : assetList){
            assetClientMap.put(assetObj.NSP_Client__c,assetObj.Id);
        }
        
        for(NSP_Sub_Client__c subClientObj : newSubClientList){
            subClientObj.NSP_Asset__c = assetClientMap.get(subClientObj.NSP_Client__c);
        }
        
    }*/
    
    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */
    public void populateStatusAndStatusDateOnAsset(Set<Id> assetId){
        
        List<Asset> assetList = [SELECT Id,(Select Id,NSP_Account_Status__c,NSP_Account_Status_Date__c from Sub_Clients__r order by createddate asc limit 1) 
                                     FROM Asset WHERE Id in: assetId];
        
        for(Asset assetObj : assetList){
            assetObj.NSP_Account_Status__c = assetObj.Sub_Clients__r[0].NSP_Account_Status__c;
            assetObj.NSP_Account_Status_Date__c = assetObj.Sub_Clients__r[0].NSP_Account_Status_Date__c;
        }
        
        update assetList;
        
    }
}