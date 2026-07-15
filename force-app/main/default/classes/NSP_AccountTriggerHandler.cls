/**
 * Represents the Account trigger handler.
 */
public class NSP_AccountTriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler {

    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;

    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     *
     */

    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    /**
     * Handles before insert for Account.
     * @param newList List of New Account.
     * @return void
     *
     */
    public void beforeInsert(List < sObject > newList) {
        NSP_AccountTriggerHelper accountTriggerHelperObject = new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.beforeInsertDirector((List < Account > ) newList);
    }

    /**
     * Handles after insert for Account.
     * @param newList List of New Account.
     * @param newMap Map of New Account.
     * @return void
     *
     */
    public void afterInsert(List < sObject > newList, Map < Id, sObject > newMap) {

        NSP_AccountTriggerHelper accountTriggerHelperObject = new NSP_AccountTriggerHelper();
        if (!this.hasRun()) {
            this.markRun();
            accountTriggerHelperObject.afterInsertDirector((List < Account > ) newList, (Map < Id, Account > ) newMap);
             // Added as a part of STY-02768
             NSP_salesOfficeRecordSharing.accountRecordSharing((Map < Id, Account > ) newMap);
        }
    }

    /**
     * Handles before update for Account.
     * @param newMap Map of New Account.
     * @param oldMap Map of Old Account.
     * @return void
     *
     */

    public void beforeUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        NSP_AccountTriggerHelper accountTriggerHelperObject = new NSP_AccountTriggerHelper();
       
         if (!this.hasRun() ) {
            this.markRun();
            accountTriggerHelperObject.beforeUpdateDirector((Map < Id, Account > ) newMap, (Map < Id, Account > ) oldMap);
            accountTriggerHelperObject.accountUpdate((Map < Id, Account > ) newMap, (Map < Id, Account > ) oldMap);
			
        }
    }

    /**
     * Handles after update for Account.
     * @param newMap Map of New Account.
     * @param oldMap Map of Old Account. 
     * @return void           
     *                
     */

    public void afterUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        NSP_AccountTriggerHelper accountTriggerHelperObject = new NSP_AccountTriggerHelper();

        if (!this.hasRun() || this.timesRun() <2 ) {
            this.markRun();
            accountTriggerHelperObject.afterUpdateDirector((Map < Id, Account > ) newMap, (Map < Id, Account > ) oldMap);
            // Added as a part of STY-02768
            NSP_salesOfficeRecordSharing.shareAccountonUpdate((Map < Id, Account > ) newMap, (Map < Id, Account > ) oldMap);

        }
        //added as part of STY-02846 changes
        NSP_AccountTriggerHelper.updateAGMPayrollEmployees((Map<Id, Account>)newMap, (Map<Id, Account>)oldMap);
        
    }
    
/**
* Handles before delete for Account.
* @param oldList List, oldMap of New Account.
* @return void
* Ticket 582488
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Ruchi Roy         08/08/2022           Created this method
*/
    public void beforeDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {
        NSP_AccountTriggerHelper accountTriggerHelperObject = new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.restrictDelete((List < Account >) oldList, (Map < Id, Account > ) oldMap);
    }
    
    public void afterDelete(List < sObject > oldList, Map < Id, sObject > oldMap) { // story 199298
        NSP_AccountTriggerHelper accountTriggerHelperObject = new NSP_AccountTriggerHelper();
        accountTriggerHelperObject.afterDeleteDirector((List < Account >) oldList, (Map < Id, Account > ) oldMap);
    }
}