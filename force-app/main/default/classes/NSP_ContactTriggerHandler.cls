/**
 * Represents the Contact trigger handler.
 */

public class NSP_ContactTriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler  {
    
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
        NSP_ContactServiceTriggerHelper  contactServiceTriggerHelperObject =  new NSP_ContactServiceTriggerHelper();
        // added as a part of STY-02659
        contactServiceTriggerHelperObject.updateSSNField((List<Contact>) newList, null);

        NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();        
        contactTriggerHelperObject.beforeInsertDirector((List<Contact>) newList);
        
        contactServiceTriggerHelperObject.beforeInsertDirector((List<Contact>) newList);       
       // added as a part of STY-02659
        contactServiceTriggerHelperObject.updateBirthday((List<Contact>) newList, null);
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

        if (!this.hasRun()) {
            if(NSP_hotfix_Switch__c.getOrgDefaults().IsEnabledMarkRun__c){
                this.markRun();
            }
            NSP_ContactServiceTriggerHelper  contactServiceTriggerHelperObject =  new NSP_ContactServiceTriggerHelper();
            // added as a part of STY-02659
            contactServiceTriggerHelperObject.updateSSNField((List<Contact>) newMap.values(), (Map<Id, Contact>) oldMap);

            NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();
            contactTriggerHelperObject.beforeUpdateDirector((Map<Id, Contact>) newMap, (Map<Id, Contact>) oldMap);
        
            contactServiceTriggerHelperObject.beforeUpdateDirector((Map<Id, Contact>) newMap, (Map<Id, Contact>) oldMap);
            // added as a part of STY-02659
            contactServiceTriggerHelperObject.updateBirthday((List<Contact>) newMap.values(), (Map<Id, Contact>) oldMap);
        }
    }

    /**
     * Handles after update for Contact.
     * @param newMap Map of New Contact.
     * @param oldMap Map of Old Contact. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        if (!this.hasRun() || this.timesRun() <2 ) {
            if(NSP_hotfix_Switch__c.getOrgDefaults().IsEnabledMarkRun__c){
                this.markRun();
            }
            NSP_ContactTriggerHelper  contactTriggerHelperObject =  new NSP_ContactTriggerHelper();
            contactTriggerHelperObject.afterUpdateDirector((Map<Id, Contact>) newMap,(Map<Id, Contact>) oldMap);
        }
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