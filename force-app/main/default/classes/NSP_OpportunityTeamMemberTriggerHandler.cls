/**
 * Represents the AccountTeamMember trigger handler.
 */
public class NSP_OpportunityTeamMemberTriggerHandler  implements NSP_ITriggerHandler{
    
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
   
    }

    /**
     * Handles after insert for OpportunityTeamMember.
     * @param newList List of New OpportunityTeamMember.
     * @param newMap Map of New OpportunityTeamMember.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_OpportunityTeamMemberTriggerHelper  oppTeamMemberTriggerHelperObject =  new NSP_OpportunityTeamMemberTriggerHelper();
        oppTeamMemberTriggerHelperObject.afterInsertDirector((List<OpportunityTeamMember>) newList, (Map<Id, OpportunityTeamMember>) newMap);
    }

    /**
     * Handles before update for OpportunityTeamMember.
     * @param newMap Map of New OpportunityTeamMember.
     * @param oldMap Map of Old OpportunityTeamMember.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }

    /**
     * Handles after update for OpportunityTeamMember.
     * @param newMap Map of New OpportunityTeamMember.
     * @param oldMap Map of Old OpportunityTeamMember. 
     * @return void             
     *                
     */ 

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_OpportunityTeamMemberTriggerHelper  oppTeamMemberTriggerHelperObject =  new NSP_OpportunityTeamMemberTriggerHelper();
        oppTeamMemberTriggerHelperObject.afterUpdateDirector((Map<Id,OpportunityTeamMember>) newMap,(Map<Id,OpportunityTeamMember>) oldMap);
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
    * Handles after delete for OpportunityTeamMember
    * @param oldList List of old OpportunityTeamMember
    * @param oldMap Map of Old OpportunityTeamMember
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}