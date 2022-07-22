/**
* Represents the Opportunity Split trigger handler.
*/
public with sharing class NSP_OpportunitySplitTriggerHandler implements NSP_ITriggerHandler{
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
* Handles before insert for Opportunity Split
* @param newList List of New Opportunity Split. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
        NSP_OpportunitySplitTriggerHelper  opportunitySplitTriggerHelperObject =  new NSP_OpportunitySplitTriggerHelper();
        opportunitySplitTriggerHelperObject.beforeInsertDirector((List<NSP_Employee_Split__c>) newList);
    }

    /**
* Handles after insert for Opportunity Split
* @param newList List of New Opportunity Split.
* @param newMap Map of New Opportunity Split. 
* @return void             
*                
*/
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        
    }

    /**
* Handles before update for Opportunity Split
* @param newMap Map of New Opportunity Split.
* @param oldMap Map of Old Opportunity Split. 
* @return void             
*                
*/
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_OpportunitySplitTriggerHelper  opportunitySplitTriggerHelperObject =  new NSP_OpportunitySplitTriggerHelper();        
        opportunitySplitTriggerHelperObject.beforeUpdateDirector((Map<Id, NSP_Employee_Split__c>) newMap,(Map<Id, NSP_Employee_Split__c>) oldMap);
    }

    /**
* Handles after update for Opportunity Split
* @param newMap Map of New Opportunity Split.
* @param oldMap Map of Old Opportunity Split. 
* @return void             
*                
*/
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    
    /**
    * Handles after delete for Opportunity Split.
    * @param oldList List of old Opportunity Split.
    * @param oldMap Map of Old Opportunity Split. 
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}