/**
* Represents the client goal trigger handler.
*/
public class NSP_ClientGoalTriggerHandler implements NSP_ITriggerHandler {
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
    * Handles before insert for client goal
    * @param newList List of New client goal. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
          
    }
    /**
    * Handles after insert for client goal
    * @param newList List of New client goal.
    * @param newMap Map of New client goal. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> oldMap) {
        NSP_ClientGoalTriggerHelper  clientGoalTriggerHelperObject =  new NSP_ClientGoalTriggerHelper();
        clientGoalTriggerHelperObject.afterInsertDirector((list<NSP_ClientGoal__c>) newList);
        
    }
    /**
    * Handles before update for client goal
    * @param newMap Map of New client goal.
    * @param oldMap Map of Old client goal. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
         
    }    
    /**
    * Handles after update for client goal
    * @param newMap Map of New client goal.
    * @param oldMap Map of Old client goal. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {  
       	NSP_ClientGoalTriggerHelper  clientGoalTriggerHelperObject =  new NSP_ClientGoalTriggerHelper();
        clientGoalTriggerHelperObject.afterUpdateDirector((Map<Id, NSP_ClientGoal__c>) newMap,(Map<Id, NSP_ClientGoal__c>) oldMap);
    } 
    /**
    * Handles before delete for client goal
    * @param oldList Map of old client goal.
    * @param oldMap Map of Old client goal. 
    * @return void             
    *                
    */
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }

   /**
   * Handles after delete for Client Goal.
   * @param oldList List of Old Client Goal.
   * @param oldMap Map of Old Client Goal.
   * @return void             
   *                
   */

    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
            
    }
}