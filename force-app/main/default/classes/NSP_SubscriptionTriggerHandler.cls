/**
 * Represents the Subscription trigger handler.
 */

public class NSP_SubscriptionTriggerHandler  implements NSP_ITriggerHandler  {
    
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
     * Handles before insert for Subscription.
     * @param newList List of New Subscriptions.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
	
         NSP_SubscriptionTriggerHelper subscriptionTriggerHelperObject =  new NSP_SubscriptionTriggerHelper();
        subscriptionTriggerHelperObject.beforeInsertDirector((List<SBQQ__Subscription__c>) newList);
    }

    /**
     * Handles after insert for Subscriptions.
     * @param newList List of New Subscriptions.
     * @param newMap Map of New Subscriptions.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
		
        NSP_SubscriptionTriggerHelper subscriptionTriggerHelperObject =  new NSP_SubscriptionTriggerHelper();
        subscriptionTriggerHelperObject.afterInsertDirector((List<SBQQ__Subscription__c>) newList);
    }

    /**
     * Handles before update for Subscriptions.
     * @param newMap Map of New Subscriptions.
     * @param oldMap Map of Old Subscriptions.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SubscriptionTriggerHelper subscriptionTriggerHelperObject =  new NSP_SubscriptionTriggerHelper();
        subscriptionTriggerHelperObject.beforeUpdateDirector((Map<Id, SBQQ__Subscription__c>) newMap,(Map<Id, SBQQ__Subscription__c>) oldMap);
    }

    /**
     * Handles after update for Subscriptions.
     * @param newMap Map of New Subscriptions.
     * @param oldMap Map of Old Subscriptions. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

    }

    /**
    * Handles after delete for Subscriptions
    * @param oldList List of old Subscriptions
    * @param oldMap Map of Subscriptions
    * @return void                           
    */ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

    /**
* Handles before delete for Subscriptions
* @param oldList List of old Subscriptions
* @param oldMap Map of Subscriptions
* @return void                           
*/ 
public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
}
}