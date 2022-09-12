/**
 * Represents the SBQQ__Quote__c trigger handler.
 */
public class NSP_QuoteTriggerHandler implements NSP_ITriggerHandler{
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
 * Handles before insert for Quote
 * @param newList List of New Quote. 
 * @return void             
 *                
 */
  public void beforeInsert(List<sObject> newList) {
      
    NSP_QuoteTriggerHelper  QuoteTriggerHelperObject =  new NSP_QuoteTriggerHelper();  
    QuoteTriggerHelperObject.beforeInsertDirector((List<SBQQ__Quote__c>)newList);
    
  }
  
  /**
 * Handles after insert for Quote
 * @param newList List of New Quote.
 * @param newMap Map of New Quote. 
 * @return void             
 *                
 */
  public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    
  }
  
/**
 * Handles before update for Quote
 * @param newMap Map of New Quote.
 * @param oldMap Map of Old Quote. 
 * @return void             
 *                
 */
  public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    
    
      NSP_QuoteTriggerHelper  QuoteTriggerHelperObject =  new NSP_QuoteTriggerHelper();        
      QuoteTriggerHelperObject.beforeUpdateDirector((Map<Id, SBQQ__Quote__c>) newMap,(Map<Id, SBQQ__Quote__c>) oldMap);
 }
  

   /**
 * Handles after update for Quote
 * @param newMap Map of New Quote.
 * @param oldMap Map of Old Quote. 
 * @return void             
 *                
 */
  public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
 
      NSP_QuoteTriggerHelper  QuoteTriggerHelperObject =  new NSP_QuoteTriggerHelper();        
      QuoteTriggerHelperObject.afterUpdateDirector((Map<Id, SBQQ__Quote__c>) newMap,(Map<Id, SBQQ__Quote__c>) oldMap);
       
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
    * Handles after delete for Quote
    * @param oldList List of old Quote
    * @param oldMap Map of Old Quote
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}