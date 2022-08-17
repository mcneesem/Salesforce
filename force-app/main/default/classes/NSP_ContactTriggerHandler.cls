/**
 * Represents the Contact trigger handler.
 */

public class NSP_ContactTriggerHandler  implements NSP_ITriggerHandler  {
    
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
     * Handles before insert for Contact.
     * @param newList List of New Contact.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();
        contactTriggerHelperObject.beforeInsertDirector((List<Contact>) newList);
    }

    /**
     * Handles after insert for Contact.
     * @param newList List of New Contact.
     * @param newMap Map of New Contact.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();
        contactTriggerHelperObject.afterInsertDirector((List<Contact>) newList, (Map<Id, Contact>) newMap);
    }

    /**
     * Handles before update for Contact.
     * @param newMap Map of New Contact.
     * @param oldMap Map of Old Contact.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();
        contactTriggerHelperObject.beforeUpdateDirector((Map<Id, Contact>) newMap, (Map<Id, Contact>) oldMap);
    }

    /**
     * Handles after update for Contact.
     * @param newMap Map of New Contact.
     * @param oldMap Map of Old Contact. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();
        contactTriggerHelperObject.afterUpdateDirector((Map<Id, Contact>) newMap,(Map<Id, Contact>) oldMap);
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
    * Handles after delete for Contact
    * @param oldList List of old Contact
    * @param oldMap Map of Old Contact
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}