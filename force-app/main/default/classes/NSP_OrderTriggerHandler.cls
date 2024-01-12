/**
 * Represents the Order trigger handler.
 */
public class NSP_OrderTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for Order
   * @param newList List of New Order. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        
       NSP_OrderTriggerHelper orderHelper = new NSP_OrderTriggerHelper();
       orderHelper.beforeInsertDirector((List<Order>)newList);
      
    }
    
    /**
   * Handles after insert for Order
   * @param newList List of New Order.
   * @param newMap Map of New Order. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_OrderTriggerHelper orderHelper = new NSP_OrderTriggerHelper();
        orderHelper.setProjectDatesForInfightOrders((List<Order>)newList);
    }
    
  /**
   * Handles before update for Order
   * @param newMap Map of New Order.
   * @param oldMap Map of Old Order. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
		NSP_OrderTriggerHelper orderHelper = new NSP_OrderTriggerHelper();
        orderHelper.beforeUpdateDirector((Map<Id, Order>) newMap,(Map<Id, Order>) oldMap);
    }
    

     /**
   * Handles after update for Order
   * @param newMap Map of New Order.
   * @param oldMap Map of Old Order. 
   * @return void             
   *                
   */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_OrderTriggerHelper orderHelper = new NSP_OrderTriggerHelper();
        orderHelper.afterUpdateDirector((Map<Id, Order>) newMap,(Map<Id, Order>) oldMap);
      
    }
    
    /**
   * Handles before delete for Order
   * @param oldList Map of old Order.
   * @param oldMap Map of old Order. 
   * @return void             
   *                
   */
    public void beforeDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
    }
    
    /**
   * Handles before delete for Order
   * @param oldList Map of old Order.
   * @param oldMap Map of old Order. 
   * @return void             
   *                
   */
    public void afterDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
    }
    
    /**
   * Handles after update for Order
   * @param newMap Map of New Order.
   * @param newMap Map of new Order. 
   * @return void             
   *                
   */
    public void afterUnDelete(List<sobject> newList, Map<Id, sObject> newMap){
        
    }
}