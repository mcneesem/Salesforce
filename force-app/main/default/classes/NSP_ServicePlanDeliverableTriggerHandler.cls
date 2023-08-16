public class NSP_ServicePlanDeliverableTriggerHandler implements NSP_ITriggerHandler {
	
    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;

    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     */

    public Boolean isDisabled(){
        return TriggerDisabled;
    }

    /**
     * Handles before insert for Service Plan Deliverable.
     * @param newList List of New Service Plan Deliverable.
     * @return void
     */
    public void beforeInsert(List<sObject> newList) {
        NSP_ServicePlanDeliverableTriggerHelper servicePlanDeliverableHelper = new NSP_ServicePlanDeliverableTriggerHelper();
        servicePlanDeliverableHelper.beforeInsertDirector((List<NSP_Service_Plan_Deliverable__c>) newList);
    }

    /**
     * Handles after insert for Service Plan Deliverable.
     * @param newList List of New Service Plan Deliverable.
     * @param newMap Map of New Service Plan Deliverable.
     * @return void
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    }

    /**
     * Handles before update for Service Plan Deliverable.
     * @param newMap Map of New Service Plan Deliverable.
     * @param oldMap Map of Old Service Plan Deliverable.
     * @return void
     */

    public void beforeUpdate(Map<Id, sObject> newMap, Map<Id, sObject> oldMap) {
        NSP_ServicePlanDeliverableTriggerHelper servicePlanDeliverableHelper = new NSP_ServicePlanDeliverableTriggerHelper();
        servicePlanDeliverableHelper.beforeUpdateDirector((Map<Id, NSP_Service_Plan_Deliverable__c>) newMap,(Map<Id, NSP_Service_Plan_Deliverable__c>)oldMap);
    }

    /**
     * Handles after update for Service Plan Deliverable.
     * @param newMap Map of New Service Plan Deliverable.
     * @param oldMap Map of Old Service Plan Deliverable. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap, Map<Id, sObject> oldMap) {
    }
    
    /**
     * Handles before delete for Service Plan Deliverable.
     * @param newMap Map of New Service Plan Deliverable.
     * @param oldMap Map of Old Service Plan Deliverable. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
        new NSP_ServicePlanDeliverableTriggerHelper().beforeDeleteDirector((List<NSP_Service_Plan_Deliverable__c>) oldList);
    }

    /**
     * Handles after delete for Service Plan Deliverable.
     * @param newMap Map of New Service Plan Deliverable.
     * @param oldMap Map of Old Service Plan Deliverable. 
     * @return void           
     */

    public void afterDelete(List<sObject> oldList, Map<Id, sObject> oldMap) {
    }
    
    /**
     * Handles after delete for Service Plan Deliverable.
     * @param newMap Map of New Service Plan Deliverable.
     * @param oldMap Map of Old Service Plan Deliverable. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}