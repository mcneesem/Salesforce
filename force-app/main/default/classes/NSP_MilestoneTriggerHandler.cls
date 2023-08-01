//Using class without sharing for apex sharing to work for non admin users
public without sharing class NSP_MilestoneTriggerHandler implements NSP_ITriggerHandler{
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
    * Handles before insert for Milestone
    * @param newList List of New Milestone. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_MilestoneTriggerHelper milestoneHelper = new NSP_MilestoneTriggerHelper();
        milestoneHelper.updateRecordType((List<pse__Milestone__c>)newList);
        // added as a part of STY-02129
         milestoneHelper.updateTargetDate((List<pse__Milestone__c>)newList);
         // added as a part of STY-02725
         milestoneHelper.checkDuplicateMilestone((List<pse__Milestone__c>)newList);
    }
    
    /**
    * Handles after insert for Milestone
    * @param newList List of New Milestone.
    * @param newMap Map of New Milestone. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_MilestoneTriggerHelper.afterInsertDirector((List<pse__Milestone__c>) newList , (Map<Id,pse__Milestone__c>)newMap);
    }
    
    /**
    * Handles before update for Milestone
    * @param newMap Map of New Milestone.
    * @param oldMap Map of Old Milestone. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_MilestoneTriggerHelper oMilestoneHelper = new NSP_MilestoneTriggerHelper();
        oMilestoneHelper.handleMilestoneCompletion((Map<Id,pse__Milestone__c>)newMap,(Map<Id,pse__Milestone__c>)oldMap);
    }
    
    
    /**
    * Handles after update for Milestone
    * @param newMap Map of New Milestone
    * @param oldMap Map of Old Milestone
    * @return void             
    *                
    */
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        // added as a part of STY-03785
        NSP_MilestoneTriggerHelper.afterUpdateDirector((List<pse__Milestone__c>) newMap.values(), (Map<Id,pse__Milestone__c>)oldMap);
    
    }

    /**
    * Handles after delete for Milestone
    * @param oldList List of old Milestone
    * @param oldMap Map of Old Milestone
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }

    /**
* Handles before delete for Milestone
* @param oldList List of old Milestone
* @param oldMap Map of Old Milestone
* @return void             
*                
*/
    
public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    
}
}