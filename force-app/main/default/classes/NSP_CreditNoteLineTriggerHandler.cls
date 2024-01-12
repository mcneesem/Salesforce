public class NSP_CreditNoteLineTriggerHandler implements NSP_ITriggerHandler {
    
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
* Handles before insert for Credit Note Line.
* @param newList List of New Credit Note Lines.
* @return void
*
*/
    public void beforeInsert(List<sObject> newList) {
        NSP_CreditNoteLineTriggerHelper credLineHelper= new NSP_CreditNoteLineTriggerHelper();
        credLineHelper.beforeInsertDirector((List<blng__CreditNoteLine__c>) newList);
    }
    
    /**
* Handles after insert for Credit Note Line.
* @param newList List of New Credit Note Lines.
* @param newMap Map of New Credit Note Lines.
* @return void
*
*/
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_CreditNoteLineTriggerHelper credLineHelper= new NSP_CreditNoteLineTriggerHelper();
        credLineHelper.afterInsertDirector((Map<Id, blng__CreditNoteLine__c>) newMap);
        
    }
    
    /**
* Handles before update for Credit Note Line.
* @param newMap Map of New Credit Note Lines.
* @param oldMap Map of Old Credit Note Lines.
* @return void
*
*/
    
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_CreditNoteLineTriggerHelper credLineHelper= new NSP_CreditNoteLineTriggerHelper();
        credLineHelper.beforeUpdateDirector((Map<Id, blng__CreditNoteLine__c>) newMap,(Map<Id, blng__CreditNoteLine__c>) oldMap);
    }
    
    /**
* Handles after update for Credit Note Line.
* @param newMap Map of New Credit Note Lines.
* @param oldMap Map of Old Credit Note Lines. 
* @return void
*                
*/
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_CreditNoteLineTriggerHelper credLineHelper= new NSP_CreditNoteLineTriggerHelper();
        credLineHelper.afterUpdateDirector((Map<Id, blng__CreditNoteLine__c>) newMap,(Map<Id, blng__CreditNoteLine__c>) oldMap);
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
* Handles after delete for Credit Note Line
* @param oldList List of old Credit Note Lines
* @param oldMap Map of Credit Note Lines
* @return void                           
*/ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
}