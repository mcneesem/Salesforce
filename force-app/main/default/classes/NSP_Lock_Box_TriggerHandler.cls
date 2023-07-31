/**
 * Represents the Lock Box trigger handler.
 */

public class NSP_Lock_Box_TriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler  {
    
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
     * Handles before insert for Lock Box records.
     * @param newList List of New Lock Box records.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
	
        NSP_Lock_Box_TriggerHelper lockboxTriggerHelperObject =  new NSP_Lock_Box_TriggerHelper();
        lockboxTriggerHelperObject.beforeInsertDirector((List<NSP_Lock_Box__c>) newList);
    }

    /**
     * Handles after insert for Lock Box Records.
     * @param newList List of New Lock Box Records.
     * @param newMap Map of New Lock Box Records.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
		
        //subscriptionTriggerHelperObject.afterInsertDirector((List<SBQQ__Subscription__c>) newList);
    }

    /**
     * Handles before update for Lock Box Records.
     * @param newMap Map of New Lock Box Records.
     * @param oldMap Map of Old Lock Box Records.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

        NSP_Lock_Box_TriggerHelper lockboxTriggerHelperObject =  new NSP_Lock_Box_TriggerHelper();
        lockboxTriggerHelperObject.beforeUpdateDirector((Map<Id, NSP_Lock_Box__c>) newMap,(Map<Id, NSP_Lock_Box__c>) oldMap);
        
    }

    /**
     * Handles after update for Lock Box Records.
     * @param newMap Map of New Lock Box Records.
     * @param oldMap Map of Old Lock Box Records. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

        NSP_Lock_Box_TriggerHelper lockboxTriggerHelperObject =  new NSP_Lock_Box_TriggerHelper();
        if (!this.hasRun()) {
            this.markRun();
        lockboxTriggerHelperObject.afterUpdateDirector((Map<Id, NSP_Lock_Box__c>) newMap,(Map<Id, NSP_Lock_Box__c>) oldMap);
        }
    }

    /**
    * Handles after delete for Lock Box Records
    * @param oldList List of old Lock Box Records
    * @param oldMap Map of Lock Box Records
    * @return void             
    *                
    */ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

      /**
  * Handles after delete for Lock Box Records
  * @param oldList List of old Lock Box Records
  * @param oldMap Map of Lock Box Records
  * @return void             
  *                
  */ 
  public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
}
}