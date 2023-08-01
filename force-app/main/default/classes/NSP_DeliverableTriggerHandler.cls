public class NSP_DeliverableTriggerHandler implements NSP_ITriggerHandler {
	
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
     * Handles before insert for Deliverable.
     * @param newList List of New Deliverable.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        NSP_DeliverableTriggerHelper deliverableServiceHelper = new NSP_DeliverableTriggerHelper();
        deliverableServiceHelper.beforeInsertDirector((List<NSP_Deliverable__c>) newList);
    }

    /**
     * Handles after insert for Deliverable.
     * @param newList List of New Deliverable.
     * @param newMap Map of New Deliverable.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    }

    /**
     * Handles before update for Deliverable.
     * @param newMap Map of New Deliverable.
     * @param oldMap Map of Old Deliverable.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_DeliverableTriggerHelper deliverableServiceHelper = new NSP_DeliverableTriggerHelper();
        deliverableServiceHelper.beforeUpdateDirector((Map<Id, NSP_Deliverable__c>) newMap,(Map<Id, NSP_Deliverable__c>)oldMap);
    }

    /**
     * Handles after update for Deliverable.
     * @param newMap Map of New Deliverable.
     * @param oldMap Map of Old Deliverable. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }
    
    /**
     * Handles before delete for Deliverable.
     * @param newMap Map of New Deliverable.
     * @param oldMap Map of Old Deliverable. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Deliverable.
     * @param newMap Map of New Deliverable.
     * @param oldMap Map of Old Deliverable. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    }
    
    /**
     * Handles after delete for Deliverable.
     * @param newMap Map of New Deliverable.
     * @param oldMap Map of Old Deliverable. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}