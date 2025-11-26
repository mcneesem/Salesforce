/**
 * Represents the OnCLMDocumentCreate trigger handler.
 */

public class OnCLMDocumentCreateTriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler  {
    // test w/ OnCLMDocumentCreateTest (100%)
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
     * Handles before insert for CLM_Document.
     * @param newList List of New CLM_Document.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        
    }

    /**
     * Handles after insert for CLM_Document.
     * @param newList List of New CLM_Document.
     * @param newMap Map of New CLM_Document.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
       	 OnCLMDocumentCreateTriggerHelper  helper =  new OnCLMDocumentCreateTriggerHelper();
         helper.afterInsertDocument((Map<Id, CLM_Document__c>) newMap);
    }

    /**
     * Handles before update for CLM_Document.
     * @param newMap Map of New CLM_Document.
     * @param oldMap Map of Old CLM_Document.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }

    /**
     * Handles after update for CLM_Document.
     * @param newMap Map of New CLM_Document.
     * @param oldMap Map of Old CLM_Document. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
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
    * Handles after delete for CLM_Document
    * @param oldList List of old CLM_Document
    * @param oldMap Map of Old CLM_Document
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}