public class NSP_TimeCardTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for TimeCard 
   * @param newList List of New TimeCard . 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        NSP_TimeCardTriggerHelper TimeCard = new NSP_TimeCardTriggerHelper();
        TimeCard.UpdateTimeCardStatus( (List<pse__Timecard_Header__c>) newList);
    }
    
    /**
   * Handles after insert for TimeCard 
   * @param newList List of New TimeCard .
   * @param newMap Map of New TimeCard . 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        
    }
    
  /**
   * Handles before update for TimeCard 
   * @param newMap Map of New TimeCard .
   * @param oldMap Map of Old TimeCard . 
   * @return void             
   *                
   */
     public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    } 
    

     /**
   * Handles after update for TimeCard 
   * @param newMap Map of New TimeCard .
   * @param oldMap Map of Old TimeCard . 
   * @return void             
   *                
   */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }

    /**
    * Handles after delete for TimeCard
    * @param oldList List of old TimeCard
    * @param oldMap Map of Old TimeCard
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }

     /**
 * Handles before delete for TimeCard
 * @param oldList List of old TimeCard
 * @param oldMap Map of Old TimeCard
 * @return void             
 *                
 */
 
 public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
     
}

}