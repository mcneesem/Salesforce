/**
* Represents the SubPlanChangeHistory trigger handler.
* Created by : Virendra Kumar
* Created Date : 9/2/2022
*/
public class NSP_SubPlanChangeHistoryTriggerHandler implements NSP_ITriggerHandler{
    
    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
    
    /**
    * Represents whether the trigger is disabled or not
    * @param N/A.  
    * @return Boolean             
    *                
    */     
    public Boolean isDisabled(){
        return TriggerDisabled;
    }
    
    
    /**
    * Handles before insert for SubPlanChangeHistory
    * @param newList List of New SubPlanChangeHistory. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {       
    }
    
    /**
    * Handles after insert for SubPlanChangeHistory
    * @param newList List of New SubPlanChangeHistory.
    * @param newMap Map of New SubPlanChangeHistory. 
    * @return void             
    *                
	*/
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) { 
        NSP_SubPlanChangeHistoryTriggerHelper subPlanChangeHistoryTriggerObj = new NSP_SubPlanChangeHistoryTriggerHelper();
        subPlanChangeHistoryTriggerObj.syncSPHistoryOnSubplan((List<NSP_Sub_Plan_Change_History__c>)newList, true);
    }
    
    /**
    * Handles before update for SubPlanChangeHistory
    * @param newMap Map of New SubPlanChangeHistory.
    * @param oldMap Map of Old SubPlanChangeHistory. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }
    
    
    /**
    * Handles after update for SubPlanChangeHistory
    * @param newMap Map of New SubPlanChangeHistory.
    * @param oldMap Map of Old SubPlanChangeHistory. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SubPlanChangeHistoryTriggerHelper subPlanChangeHistoryTriggerObj = new NSP_SubPlanChangeHistoryTriggerHelper();
        subPlanChangeHistoryTriggerObj.syncSPHistoryOnSubplan((List<NSP_Sub_Plan_Change_History__c>)newMap.Values(), false);
    }
     /**
    * Handles after delete for SubPlanChangeHistory
    * @param oldList List of old SubPlanChangeHistory
    * @param oldMap Map of Old SubPlanChangeHistory
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

     /**
* Handles before delete for SubPlanChangeHistory
* @param oldList List of old SubPlanChangeHistory
* @param oldMap Map of Old SubPlanChangeHistory
* @return void             
*                
*/ 
 public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
}
}