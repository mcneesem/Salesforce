/**
 * Represents the AccountTeam trigger handler.
 */
public class NSP_AccountTeamTriggerHandler  implements NSP_ITriggerHandler {
	
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
     * Handles before insert for NSP_Account_Team__c.
     * @param newList List of New NSP_Account_Team__c.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        NSP_AccountTeamTriggerHelper  accountTeamMemberTriggerHelperObject =  new NSP_AccountTeamTriggerHelper();
        accountTeamMemberTriggerHelperObject.beforeInsertDirector((List<NSP_Account_Team__c>) newList);
    }

    /**
     * Handles after insert for NSP_Account_Team__c.
     * @param newList List of New NSP_Account_Team__c.
     * @param newMap Map of New NSP_Account_Team__c.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_AccountTeamTriggerHelper  accountTeamMemberTriggerHelperObject =  new NSP_AccountTeamTriggerHelper();
        accountTeamMemberTriggerHelperObject.afterInsertDirector((List<NSP_Account_Team__c>) newList, (Map<Id, NSP_Account_Team__c>) newMap);
        // Share Account with account team member user  Sales office Public groups --STY-01786 
        NSP_recordSharing.accountTeamMembersharing((List<NSP_Account_Team__c>) newList); 
    }

    /**
     * Handles before update for NSP_Account_Team__c.
     * @param newMap Map of New NSP_Account_Team__c.
     * @param oldMap Map of Old NSP_Account_Team__c.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }

    /**
     * Handles after update for NSP_Account_Team__c.
     * @param newMap Map of New NSP_Account_Team__c.
     * @param oldMap Map of Old NSP_Account_Team__c. 
     * @return void             
     *                
     */ 

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AccountTeamTriggerHelper  accountTeamMemberTriggerHelperObject =  new NSP_AccountTeamTriggerHelper();
        accountTeamMemberTriggerHelperObject.afterUpdateDirector((Map<Id,NSP_Account_Team__c>) newMap,(Map<Id,NSP_Account_Team__c>) oldMap);
        // Share Account with account team member user  Sales office Public groups --STY-01786 
        NSP_recordSharing.shareAccountonATMUpdate((Map<Id,NSP_Account_Team__c>) newMap,(Map<Id,NSP_Account_Team__c>) oldMap ); 
    }
}