/**
 * Represents the AcccountContactRelation trigger handler.
 */

public class NSP_AccountContactRelationTriggerHandler implements NSP_ITriggerHandler {
	
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
     * Handles before insert for AccountContactRelation.
     * @param newList List of New AccountContactRelation.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
    }

    /**
     * Handles after insert for AccountContactRelation.
     * @param newList List of New AccountContactRelation.
     * @param newMap Map of New AccountContactRelation.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_AccountContactRelationTriggerHelper  accContactTriggerHelperObject =  new NSP_AccountContactRelationTriggerHelper();
        accContactTriggerHelperObject.afterInsertDirector((List<AccountContactRelation>) newList,(Map<Id, AccountContactRelation>) newMap);
    }

    /**
     * Handles before update for AccountContactRelation.
     * @param newMap Map of New AccountContactRelation.
     * @param oldMap Map of Old AccountContactRelation.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }

    /**
     * Handles after update for AccountContactRelation.
     * @param newMap Map of New AccountContactRelation.
     * @param oldMap Map of Old AccountContactRelation. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AccountContactRelationTriggerHelper  accContactTriggerHelperObject =  new NSP_AccountContactRelationTriggerHelper();
        accContactTriggerHelperObject.afterUpdateDirector((Map<Id, AccountContactRelation>) newMap,(Map<Id, AccountContactRelation>) oldMap);
    }
}