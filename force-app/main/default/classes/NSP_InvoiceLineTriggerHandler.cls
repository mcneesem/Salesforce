public class NSP_InvoiceLineTriggerHandler implements NSP_ITriggerHandler {
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
* Handles before insert for Invoice Line.
* @param newList List of New Invoice Lines.
* @return void
*
*/
    public void beforeInsert(List<sObject> newList) {
        NSP_InvoiceLineTriggerHelper.beforeInsertDirector((list<blng__InvoiceLine__c>) newList);
    }
    
    /**
* Handles after insert for Invoice Line.
* @param newList List of New Invoice Lines.
* @param newMap Map of New Invoice Lines.
* @return void
*
*/
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_InvoiceLineTriggerHelper.afterInsertDirector((list<blng__InvoiceLine__c>) newList);
    }
    
    /**
* Handles before update for Invoice Line.
* @param newMap Map of New Invoice Lines.
* @param oldMap Map of Old Invoice Lines.
* @return void
*
*/
    
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_InvoiceLineTriggerHelper.beforeUpdateDirector((Map<Id, blng__InvoiceLine__c>) newMap,(Map<Id, blng__InvoiceLine__c>) oldMap);
    }
    
    /**
* Handles after update for Invoice Line.
* @param newMap Map of New Invoice Lines.
* @param oldMap Map of Old Invoice Lines. 
* @return void
*                
*/
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_InvoiceLineTriggerHelper.afterUpdateDirector((Map<Id, blng__InvoiceLine__c>) newMap,(Map<Id, blng__InvoiceLine__c>) oldMap);
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
* Handles after delete for Invoice Line
* @param oldList List of old Invoice Lines
* @param oldMap Map of Invoice Lines
* @return void                           
*/ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}