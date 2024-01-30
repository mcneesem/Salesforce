/**
 * Represents the Event trigger handler.
 */
public class NSP_EventTriggerHandler implements NSP_ITriggerHandler {
   
    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
    public static Boolean runOnce = true;
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
   * Handles before insert for Event
   * @param newList List of New Event. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
         if(NSP_EventTriggerHandler.runOnce){
            NSP_EventTriggerHelper  eventTriggerHelperObject =  new NSP_EventTriggerHelper();  
            eventTriggerHelperObject.beforeInsertDirector((List<Event>)newList);
        }
        
    }
    
    /**
   * Handles after insert for Event
   * @param newList List of New Event.
   * @param newMap Map of New Event. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        if(NSP_EventTriggerHandler.runOnce){
            NSP_EventTriggerHelper  eventTriggerHelperObject =  new NSP_EventTriggerHelper();
            eventTriggerHelperObject.afterInsertDirector((List<Event>) newList,(Map<Id, Event>) newMap);
        }
    }
    
  /**
   * Handles before update for Event
   * @param newMap Map of New Event.
   * @param oldMap Map of Old Event. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
        if(NSP_EventTriggerHandler.runOnce){
            NSP_EventTriggerHelper  eventTriggerHelperObject =  new NSP_EventTriggerHelper();        
            eventTriggerHelperObject.beforeUpdateDirector((Map<Id, Event>) newMap,(Map<Id, Event>) oldMap);
            
        }
    }
    

     /**
   * Handles after update for Event
   * @param newMap Map of New Event.
   * @param oldMap Map of Old Event. 
   * @return void             
   *                
   */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        if(NSP_EventTriggerHandler.runOnce){
            NSP_EventTriggerHandler.runOnce = false;
            NSP_EventTriggerHelper  eventTriggerHelperObject =  new NSP_EventTriggerHelper();        
            eventTriggerHelperObject.afterUpdateDirector((Map<Id, Event>) newMap,(Map<Id, Event>) oldMap);
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
    * Handles after delete for Event
    * @param oldList List of old Event
    * @param oldMap Map of Old Event
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
         NSP_EventTriggerHelper  eventTriggerHelperObject =  new NSP_EventTriggerHelper();        
         eventTriggerHelperObject.afterDeleteDirector((List<Event>) oldList,(Map<Id, Event>) oldMap);   
    }

}