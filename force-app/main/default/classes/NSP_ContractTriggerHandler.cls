/************
 * Represents the Contract trigger handler.
 */

public class NSP_ContractTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for Contract
   * @param newList List of New Contract. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        
        NSP_ContractTriggerHelper  contractTriggerHelperObject =  new NSP_ContractTriggerHelper();  
        contractTriggerHelperObject.beforeInsertDirector((List<Contract>)newList);
      
    }
    
    /**
   * Handles after insert for Contract
   * @param newList List of New Contract.
   * @param newMap Map of New Contract. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {

        NSP_ContractTriggerHelper  contractTriggerHelperObject =  new NSP_ContractTriggerHelper(); 
        contractTriggerHelperObject.afterInsertDirector((List<Contract>)newList);
    }
    
  /**
   * Handles before update for Contract
   * @param newMap Map of New Contract.
   * @param oldMap Map of Old Contract. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
        NSP_ContractTriggerHelper  contractTriggerHelperObject =  new NSP_ContractTriggerHelper();        
        contractTriggerHelperObject.beforeUpdateDirector((Map<Id, Contract>) newMap,(Map<Id, Contract>) oldMap);
       
 
    }
    

     /**
   * Handles after update for Contract
   * @param newMap Map of New Contract.
   * @param oldMap Map of Old Contract. 
   * @return void             
   *                
   */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
     
        NSP_ContractTriggerHelper  contractTriggerHelperObject =  new NSP_ContractTriggerHelper();        
        contractTriggerHelperObject.afterUpdateDirector((Map<Id, Contract>) newMap,(Map<Id, Contract>) oldMap);
       
    }
    
    /**
   * Handles before delete for Contract
   * @param oldList Map of old Contract.
   * @param oldMap Map of old Contract. 
   * @return void             
   *                
   */
    public void beforeDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
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
    
    /**
   * Handles after update for Contract
   * @param newList Map of New Contract.
   * @param oldMap Map of new Contract. 
   * @return void             
   *                
   */
    public void afterUnDelete(List<sobject> newList, Map<Id, sObject> newMap){
        
    }
}