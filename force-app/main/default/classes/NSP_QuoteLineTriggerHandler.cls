public class NSP_QuoteLineTriggerHandler implements NSP_ITriggerHandler {
    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
    /**
* Represents whether the trigger is disabled or not
* @param N/A.  
* @return Boolean             
*                
*/     
    
    public Boolean isDisabled(){
        return TriggerDisabled;
    }
    
    
    /**
* Handles before insert for Quote Line
* @param newList List of New Quote Lines. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    /**
* Handles after insert for Quote Line
* @param newList List of New Quote Lines.
* @param newMap Map of New Quote Lines. 
* @return void             
*                
*/
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        
    }
    
    /**
* Handles before update for Quote Line
* @param newMap Map of New Quote Lines.
* @param oldMap Map of Old Quote Lines. 
* @return void             
*                
*/
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_QuoteLineTriggerHelper qLineHelper= new NSP_QuoteLineTriggerHelper();
        qLineHelper.beforeUpdateDirector((List<SBQQ__QuoteLine__c>)newMap.values());
        
    }
    
    
    /**
* Handles after update for Quote Line
* @param newMap Map of New Quote Lines.
* @param oldMap Map of Old Quote Lines. 
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
* Handles after delete for Quote Line
* @param oldList List of old Quote Lines
* @param oldMap Map of Old Quote Lines
* @return void             
*                
*/ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
}