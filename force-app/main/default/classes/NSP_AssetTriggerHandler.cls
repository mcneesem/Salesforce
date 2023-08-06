/**
 * Represents the Asset trigger handler.
* Version - STY       - AUTHOR     - DESCRIPTION                              - TAG
*
* V2.0    - STY-02841 - Ramya Ravi - TES Asset & RET Asset - AIMS Information - <STY-02841>
 */

public class NSP_AssetTriggerHandler implements NSP_ITriggerHandler {
    // test w/ NSP_AssetTriggerHelperTest

    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;
    public static Boolean restrictProjectCreation = false;

    public NSP_AssetTriggerHandler(){
        NSP_Trigger_Switch__c deactivateProjectCreation = NSP_Trigger_Switch__c.getOrgDefaults();
	    restrictProjectCreation =  deactivateProjectCreation.NSP_DisableServiceAssetFunctionality__c;   
    }
    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     *
     */

    public Boolean isDisabled(){
        return TriggerDisabled;
    }

    /**
     * Handles before insert for Asset.
     * @param newList List of New Asset.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
    	NSP_AssetTriggerHelper assetTriggerHelperObj = new NSP_AssetTriggerHelper();
        assetTriggerHelperObj.beforeInsertDirector((List<Asset>)newList); 
        if(!restrictProjectCreation){
            NSP_AssetServiceTriggerHelper.updatePaperlessBatchDateBeforeInsertOrUpdate((List<Asset>)newList, null); 
            NSP_AssetServiceTriggerHelper oAssetServiceHelper = new NSP_AssetServiceTriggerHelper();
            oAssetServiceHelper.beforeInsertDirector((List<Asset>) newList);   
            //added as part of STY-03529 changes
            NSP_AssetServiceHelper.updateTerminationInformation((List<Asset>)newList, null);     
        }
        NSP_AssetTriggerHelper.updateAssetServiceRegion((List<Asset>) newList);   

    }

    /**
     * Handles after insert for Asset.
     * @param newList List of New Asset.
     * @param newMap Map of New Asset.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_AssetTriggerHelper assetTriggerHelperObj = new NSP_AssetTriggerHelper();
        assetTriggerHelperObj.afterInsertDirector((List<Asset>)newList,(Map<Id, Asset>)newMap);
       
        if(!restrictProjectCreation){
        NSP_AssetServiceTriggerHelper oAssetServiceHelper = new NSP_AssetServiceTriggerHelper();
            oAssetServiceHelper.afterInsertFilter((List<Asset>)newList,(Map<Id,Asset>)newMap);
            //Added as a part of <STY-02841>
            oAssetServiceHelper.afterInsertAsset((List<Asset>)newList,(Map<Id, Asset>)newMap);
            
            //STY-01099 Relate separate accounts into an account group and Identifiy the types of relationships between those accounts so that I can ensure all users have a clear view of how accounts relate, ownership
            new NSP_AssetServiceTriggerHelper().createAccountGroupsForAssets((List<Asset>)newList,(Map<Id,Asset>)newMap);
            //Addes as part of  STY-03289
            NSP_AssetServiceHelper oAssetHelper = new NSP_AssetServiceHelper();
            oAssetHelper.createBPSProject((List<Asset>)newList);
        }

    }

    /**
     * Handles before update for Asset.
     * @param newMap Map of New Asset.
     * @param oldMap Map of Old Asset.
     * @return void
     *
     */
 
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
       NSP_AssetTriggerHelper assetTriggerHelperObj = new NSP_AssetTriggerHelper();
       assetTriggerHelperObj.beforeUpdateDirector((Map<Id, Asset>)newMap,(Map<Id, Asset>)oldMap);
       if(!restrictProjectCreation){
           NSP_AssetServiceTriggerHelper.updatePaperlessBatchDateBeforeInsertOrUpdate((List<Asset>)newMap.Values(), (Map<Id, Asset>)oldMap); 
           NSP_AssetServiceTriggerHelper oAssetServiceHelper = new NSP_AssetServiceTriggerHelper();
            oAssetServiceHelper.beforeUpdateDirector((Map<Id, Asset>) newMap,(Map<Id, Asset>)oldMap);
            //added as part of STY-03529 changes
            NSP_AssetServiceHelper.updateTerminationInformation((List<Asset>)newMap.Values(),(Map<Id, Asset>)oldMap);
       }
        
    }

    /**
     * Handles after update for Asset.
     * @param newMap Map of New Asset.
     * @param oldMap Map of Old Asset. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AssetTriggerHelper assetTriggerHelperObj = new NSP_AssetTriggerHelper();
        assetTriggerHelperObj.afterUpdateDirector((Map<Id, Asset>)newMap,(Map<Id, Asset>)oldMap);        
        if(!restrictProjectCreation){
            NSP_AssetServiceTriggerHelper oAssetServiceHelper = new NSP_AssetServiceTriggerHelper();
            oAssetServiceHelper.afterUpdateFilter((Map<Id, Asset>)newMap,(Map<Id, Asset>)oldMap);
            oAssetServiceHelper.afterUpdateAsset((List<Asset>) newMap.values(),(Map<Id,Asset>)oldMap);   //Added as a part of <STY-02841>
             
            //STY-02726 -> o auto create an iSolved Account Group when an iSolved parent child relationship is identified on the Workforce Acceleration (WX) asset record.
            NSP_AssetServiceTriggerHelper.createWXAssetGroupsonUpdate((List<Asset>) newMap.values(),(Map<Id, Asset>) oldMap);
            //added as part of STY-03529 changes
            NSP_AssetServiceHelper assetServiceHelper = new NSP_AssetServiceHelper();
            assetServiceHelper.clearAssetTerminationSection((List<Asset>)newMap.Values(),(Map<Id, Asset>)oldMap);
        }
        //added as part of STY-03624 changes
        NSP_AssetTriggerHelper.createPlatformEventForAsset((List<Asset>)newMap.Values(),(Map<Id, Asset>)oldMap);   
    }
    
    /**
     * Handles before delete for Asset.
     * @param newMap Map of New Asset.
     * @param oldMap Map of Old Asset. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Asset.
     * @param newMap Map of New Asset.
     * @param oldMap Map of Old Asset. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Asset.
     * @param newMap Map of New Asset.
     * @param oldMap Map of Old Asset. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}
