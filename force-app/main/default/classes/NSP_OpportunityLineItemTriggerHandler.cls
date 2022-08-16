/**
 * Represents the OpportunityLineItem trigger handler.
 */
public class NSP_OpportunityLineItemTriggerHandler implements NSP_ITriggerHandler {
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
   * Handles before insert for OpportunityLineItem
   * @param newList List of New OpportunityLineItem. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
                
         NSP_OpportunityLineItemTriggerHelper  oliHelperObject =  new NSP_OpportunityLineItemTriggerHelper();
        oliHelperObject.beforeInsertDirector((List<OpportunityLineItem>) newList);
       
        //system.debug('before insert');
    }    
    /**
   * Handles after insert for OpportunityLineItem
   * @param newList List of New OpportunityLineItem.
   * @param newMap Map of New OpportunityLineItem. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_OpportunityLineItemTriggerHelper  oliHelperObject =  new NSP_OpportunityLineItemTriggerHelper();
        try{
        oliHelperObject.afterInsertDirector((List<OpportunityLineItem>) newList);
        }
        catch(Exception ex){
          NSP_CustomException.LogException(ex);
        }
        
    }
    
  /**
   * Handles before update for OpportunityLineItem
   * @param newMap Map of New OpportunityLineItem.
   * @param oldMap Map of Old OpportunityLineItem. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
        NSP_OpportunityLineItemTriggerHelper  oliHelperObject =  new NSP_OpportunityLineItemTriggerHelper();
       oliHelperObject.beforeUpdateDirector((Map<Id, OpportunityLineItem>) newMap,(Map<Id, OpportunityLineItem>) oldMap);
    }
    

     /**
   * Handles after update for OpportunityLineItem
   * @param newMap Map of New OpportunityLineItem.
   * @param oldMap Map of Old OpportunityLineItem. 
   * @return void             
   *                
   */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
       // system.debug('inside after update');
       NSP_OpportunityLineItemTriggerHelper  oliHelperObject =  new NSP_OpportunityLineItemTriggerHelper();
       oliHelperObject.afterUpdateDirector((Map<Id, OpportunityLineItem>) newMap,(Map<Id, OpportunityLineItem>) oldMap);
        
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
    * Handles after delete for OpportunityLineItem
    * @param oldList List of old OpportunityLineItem
    * @param oldMap Map of Old OpportunityLineItem
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}