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
        NSP_AccountContactRelationTriggerHelper.beforeUpsertDirector((List<AccountContactRelation>) newList);
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
        accContactTriggerHelperObject.afterInsertJobTitle((List<AccountContactRelation>) newList,(Map<Id, AccountContactRelation>)newMap);
        
        //added as a part of STY-03783 AND STY-03782
        NSP_AccountContactRelationTriggerHelper.createPlatformEventForACR((List<AccountContactRelation>) newList, (Map<Id, AccountContactRelation>) newMap);        
    }

    /**
     * Handles before update for AccountContactRelation.
     * @param newMap Map of New AccountContactRelation.
     * @param oldMap Map of Old AccountContactRelation.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AccountContactRelationTriggerHelper.beforeUpsertDirector((List<AccountContactRelation>) newMap.Values());
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
        accContactTriggerHelperObject.afterUpdateJobTitle((Map<Id, AccountContactRelation>) newMap,(Map<Id, AccountContactRelation>) oldMap);
        //added as a part of STY-03658
        NSP_AccountContactServiceHelper.createExternalUser((Map<Id, AccountContactRelation>) newMap,(Map<Id, AccountContactRelation>) oldMap);
    
        NSP_AccountContactRelationTriggerHelper.createPlatformEventForACR((List<AccountContactRelation>) newMap.Values(), (Map<Id, AccountContactRelation>) oldMap);
      
    }
    
    /**
     * Handles before delete.
     * @param oldList List, OldMap Map.
     * @return void
     * Added beforeDelete method as this is referred in in NSP_ITriggerHandler
    **/
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        //STY-03659 Community - Error Message if Deleting ACR for community user.
        NSP_AccountContactRelationTriggerHelper.restrictDeletingACR((List < AccountContactRelation > ) oldList);
    }
    
    /**
    * Handles after delete for AccountContactRelation
    * @param oldList List of old AccountContactRelation
    * @param oldMap Map of Old AccountContactRelation
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        //STY-03866 remove sharing of projects
        NSP_AccountContactRelationTriggerHelper.afterDeleteDirector((List < AccountContactRelation > ) oldList);
     }
}