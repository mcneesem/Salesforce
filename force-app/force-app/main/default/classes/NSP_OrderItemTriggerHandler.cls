/**
 * Represents the OrderItem trigger handler.
 */
    public class NSP_OrderItemTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for OrderItem
   * @param newList List of New OrderItem. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        
       
      
    }
    
    /**
   * Handles after insert for OrderItem
   * @param newList List of New OrderItem.
   * @param newMap Map of New OrderItem. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
         NSP_OrderItemTriggerHelper orderItemHelper = new NSP_OrderItemTriggerHelper();
         orderItemHelper.processOrderItemForScholarshipCS((Map<Id, OrderItem>) newMap);
    }
    
  /**
   * Handles before update for OrderItem
   * @param newMap Map of New OrderItem.
   * @param oldMap Map of Old OrderItem. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
          
    }
    

     /**
   * Handles after update for OrderItem
   * @param newMap Map of New OrderItem.
   * @param oldMap Map of Old OrderItem. 
   * @return void             
   *                
   */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
      
    }
    
    /**
   * Handles before delete for OrderItem
   * @param oldList Map of old OrderItem.
   * @param oldMap Map of old OrderItem. 
   * @return void             
   *                
   */
    public void beforeDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
    }
    
    /**
   * Handles before delete for OrderItem
   * @param oldList Map of old OrderItem.
   * @param oldMap Map of old OrderItem. 
   * @return void             
   *                
   */
    public void afterDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
    }
    
    /**
   * Handles after update for OrderItem
   * @param newMap Map of New OrderItem.
   * @param newMap Map of new OrderItem. 
   * @return void             
   *                
   */
    public void afterUnDelete(List<sobject> newList, Map<Id, sObject> newMap){
        
    }
}