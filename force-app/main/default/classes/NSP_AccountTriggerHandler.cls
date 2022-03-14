/**
 * Represents the Account trigger handler.
 */

public class NSP_AccountTriggerHandler  implements NSP_ITriggerHandler {

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
     * Handles before insert for Account.
     * @param newList List of New Account.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
		NSP_AccountTriggerHelper  accountTriggerHelperObject =  new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.beforeInsertDirector((List<Account>) newList);
    }

    /**
     * Handles after insert for Account.
     * @param newList List of New Account.
     * @param newMap Map of New Account.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_AccountTriggerHelper  accountTriggerHelperObject =  new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.afterInsertDirector((List<Account>) newList, (Map<Id, Account>) newMap);
        // Share account with owner Sales office Public groups --STY-01786
        NSP_recordSharing.nonBPAAccountSharing((Map<Id, Account>) newMap);
    }

    /**
     * Handles before update for Account.
     * @param newMap Map of New Account.
     * @param oldMap Map of Old Account.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AccountTriggerHelper  accountTriggerHelperObject =  new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.beforeUpdateDirector((Map<Id, Account>) newMap, (Map<Id, Account>) oldMap);
    }

    /**
     * Handles after update for Account.
     * @param newMap Map of New Account.
     * @param oldMap Map of Old Account. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_AccountTriggerHelper  accountTriggerHelperObject =  new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.afterUpdateDirector((Map<Id, Account>) newMap, (Map<Id, Account>) oldMap);
       // Share account with owner Sales office Public groups --STY-01786
        NSP_recordSharing.shareAccountonUpdate((Map<Id, Account>) newMap, (Map<Id, Account>) oldMap);
    }
    /**
    * Handles after delete for Account
    * @param oldList List of old Account
    * @param oldMap Map of Old Account
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}