public class NSP_AdditionalPayrollContactHandler implements NSP_ITriggerHandler{
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
   * Handles before insert for Additional Payroll Contact 
   * @param newList List of New Additional Payroll Contact . 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        NSP_AdditionalPayrollContactHelper AdditionalPayrollContact  = new NSP_AdditionalPayrollContactHelper();
        AdditionalPayrollContact.updateContactEmailAndPhoneOnAdditionalPayrollContact( (List<Additional_Payroll_Contact__c>) newList);
    }
    
    /**
   * Handles after insert for Additional Payroll Contact 
   * @param newList List of New Additional Payroll Contact .
   * @param newMap Map of New Additional Payroll Contact . 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        
    }
    
  /**
   * Handles before update for Additional Payroll Contact 
   * @param newMap Map of New Additional Payroll Contact .
   * @param oldMap Map of Old Additional Payroll Contact .  
   * @return void             
   *                
   */
     public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
         
     } 
    

     /**
   * Handles after update for Additional Payroll Contact 
   * @param newMap Map of New Additional Payroll Contact .
   * @param oldMap Map of Old Additional Payroll Contact . 
   * @return void             
   *                
   */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }

    /**
   * Handles after delete for Additional Payroll Contact 
   * @param oldList List of old Additional Payroll Contact .
   * @param oldMap Map of Old Additional Payroll Contact . 
   * @return void             
   *                
   */

  public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
  }

   /**
* Handles after delete for Additional Payroll Contact 
* @param oldList List of old Additional Payroll Contact .
* @param oldMap Map of Old Additional Payroll Contact . 
* @return void             
*                
*/
public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    
} 

}