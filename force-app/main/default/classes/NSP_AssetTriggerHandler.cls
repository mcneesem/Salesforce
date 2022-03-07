/**
 * Represents the Asset trigger handler.
 */

public class NSP_AssetTriggerHandler implements NSP_ITriggerHandler{
	
    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;

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
    }

    /**
     * Handles after insert for Asset.
     * @param newList List of New Asset.
     * @param newMap Map of New Asset.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        
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