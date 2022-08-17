/**
 * Represents the AccountTeamMember trigger handler.
 */

public class NSP_AccountTeamMemberTriggerHandler  implements NSP_ITriggerHandler {

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
     * Handles before insert for AccountTeamMember.
     * @param newList List of New AccountTeamMember.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        NSP_AccountTeamMemberTriggerHelper  accountTeamMemberTriggerHelperObject =  new NSP_AccountTeamMemberTriggerHelper();
        accountTeamMemberTriggerHelperObject.beforeInsertDirector((List<AccountTeamMember>) newList);
    }

    /**
     * Handles after insert for AccountTeamMember.
     * @param newList List of New AccountTeamMember.
     * @param newMap Map of New AccountTeamMember.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_AccountTeamMemberTriggerHelper  accountTeamMemberTriggerHelperObject =  new NSP_AccountTeamMemberTriggerHelper();
        accountTeamMemberTriggerHelperObject.afterInsertDirector((List<AccountTeamMember>) newList, (Map<Id, AccountTeamMember>) newMap);
    }

    /**
     * Handles before update for AccountTeamMember.
     * @param newMap Map of New AccountTeamMember.
     * @param oldMap Map of Old AccountTeamMember.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }

    /**
     * Handles after update for AccountTeamMember.
     * @param newMap Map of New AccountTeamMember.
     * @param oldMap Map of Old AccountTeamMember. 
     * @return void             
     *                
     */ 

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AccountTeamMemberTriggerHelper  accountTeamMemberTriggerHelperObject =  new NSP_AccountTeamMemberTriggerHelper();
        accountTeamMemberTriggerHelperObject.afterUpdateDirector((Map<Id,AccountTeamMember>) newMap,(Map<Id,AccountTeamMember>) oldMap);
    }
    
    /**
     * Handles before delete.
     * @param oldList List, OldMap Map.
     * @return void
     * Added beforeDelete method as this is referred in in NSP_ITriggerHandler
    **/
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
     /**
    * Handles after delete for AccountTeamMember
    * @param oldList List of old AccountTeamMember
    * @param oldMap Map of Old AccountTeamMember
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}