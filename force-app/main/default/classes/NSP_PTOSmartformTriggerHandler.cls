public class NSP_PTOSmartformTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for NSP_PTO_Smartform__c
   * @param newList List of New NSP_PTO_Smartform__c. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        NSP_PTOSmartformTriggerHelper PTOSmartforms   = new NSP_PTOSmartformTriggerHelper();
        PTOSmartforms.beforeInsertMethod( (List<NSP_PTO_Smartform__c>) newList);
    }
    
    /**
   * Handles after insert for NSP_PTO_Smartform__c
   * @param newList List of New NSP_PTO_Smartform__c.
   * @param newMap Map of New NSP_PTO_Smartform__c. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_PTOSmartformTriggerHelper PTOSmartforms = new NSP_PTOSmartformTriggerHelper();
        PTOSmartforms.afterInsertMethod( (List<NSP_PTO_Smartform__c>) newList, ((Map<Id, NSP_PTO_Smartform__c>) newMap));
    }
    
  /**
   * Handles before update for NSP_PTO_Smartform__c
   * @param newMap Map of New NSP_PTO_Smartform__c.
   * @param oldMap Map of Old NSP_PTO_Smartform__c. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_PTOSmartformTriggerHelper PTOHelper = new  NSP_PTOSmartformTriggerHelper();
        PTOHelper.beforeUpdateMethod(((Map<Id, NSP_PTO_Smartform__c>) newMap), ((Map<Id, NSP_PTO_Smartform__c>) oldMap));
    }
    

     /**
   * Handles after update for NSP_PTO_Smartform__c
   * @param newMap Map of New NSP_PTO_Smartform__c.
   * @param oldMap Map of Old NSP_PTO_Smartform__c. 
   * @return void             
   *                
   */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

    }

    /**
   * Handles after delete for NSP_PTO_Smartform__c
   * @param oldList List of Old NSP_PTO_Smartform__c.
   * @param oldMap Map of Old NSP_PTO_Smartform__c. 
   * @return void             
   *                
   */

    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }

      /**
 * Handles before delete for NSP_PTO_Smartform__c
 * @param oldList List of Old NSP_PTO_Smartform__c.
 * @param oldMap Map of Old NSP_PTO_Smartform__c. 
 * @return void             
 *                
 */
  public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
      
}
}