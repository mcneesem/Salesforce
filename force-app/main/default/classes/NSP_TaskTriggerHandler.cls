public class NSP_TaskTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for Task
   * @param newList List of New Task. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        if(NSP_TaskTriggerHandler.runOnce){
            NSP_TaskTriggerHelper  taskTriggerHelperObject =  new NSP_TaskTriggerHelper();  
            taskTriggerHelperObject.beforeInsertDirector((List<Task>)newList);
        }
    }
    
       /**
   * Handles after insert for Task
   * @param newList List of New Task.
   * @param newMap Map of New Task. 
   * @return void             
   *                
   */
  public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
    NSP_TaskTriggerHelper  taskTriggerHelperObject =  new NSP_TaskTriggerHelper();
    taskTriggerHelperObject.afterInsertDirector((List<Task>) newList,(Map<Id, Task>) newMap);
   
}
    
  /**
   * Handles before update for Event
   * @param newMap Map of New Event.
   * @param oldMap Map of Old Event. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        if(NSP_TaskTriggerHandler.runOnce){
            NSP_TaskTriggerHelper  taskTriggerHelperObject =  new NSP_TaskTriggerHelper();        
            taskTriggerHelperObject.beforeUpdateDirector((Map<Id, Task>) newMap,(Map<Id, Task>) oldMap);
            
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
    NSP_TaskTriggerHelper  taskTriggerHelperObject =  new NSP_TaskTriggerHelper();     
    taskTriggerHelperObject.afterUpdateDirector((Map<Id, Task>) newMap,(Map<Id, Task>) oldMap);
}


    /**
   * Handles before delete for Contract
   * @param oldList Map of old Contract.
   * @param oldMap Map of old Contract. 
   * @return void             
   *                
   */
   public void afterDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
    }

}