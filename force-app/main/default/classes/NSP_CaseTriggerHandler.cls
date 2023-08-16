/**
 * Represents the Case trigger handler.
 */
public class NSP_CaseTriggerHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for Case
   * @param newList List of New Case. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        NSP_CaseTriggerHelper caseHelper = new   NSP_CaseTriggerHelper();
        caseHelper.beforeInsertDirector( (List<Case>) newList);
        caseHelper.updateCreatedByDivision((List<Case>)newList);
    }
    
    /**
   * Handles after insert for Case
   * @param newList List of New Case.
   * @param newMap Map of New Case. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_CaseTriggerHelper oCaseHelper = new NSP_CaseTriggerHelper();
        oCaseHelper.afterInsertCaseFilters((List<Case>)newList,(Map<Id, Case>)newMap);
    }
    
  /**
   * Handles before update for Case
   * @param newMap Map of New Case.
   * @param oldMap Map of Old Case. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_CaseTriggerHelper caseHelper = new  NSP_CaseTriggerHelper();
        caseHelper.beforeUpdateDirector(((Map<Id, Case>) newMap), ((Map<Id, Case>) oldMap));
    }
    

     /**
   * Handles after update for Case
   * @param newMap Map of New Case.
   * @param oldMap Map of Old Case. 
   * @return void             
   *                
   */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_CaseTriggerHelper caseHelper = new  NSP_CaseTriggerHelper();
        caseHelper.afterUpdateDirector(((Map<Id, Case>) newMap), ((Map<Id, Case>) oldMap));
    }

    /**
   * Handles after delete for Case
   * @param oldList List of Old Case.
   * @param oldMap Map of Old Case. 
   * @return void             
   *                
   */

    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
     /**
* Handles before delete for Case
* @param oldList List of Old Case.
* @param oldMap Map of Old Case. 
* @return void             
*                
*/
 public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
     
}
}