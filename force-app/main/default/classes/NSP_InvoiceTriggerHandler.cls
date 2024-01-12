/**
 * Represents the Invoice trigger handler.
 */

public class NSP_InvoiceTriggerHandler  extends NSP_TriggerAction implements NSP_ITriggerHandler  {
    
    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;

    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     *
     */

    public Boolean isDisabled(){
        return TriggerDisabled;
    }

    /**
     * Handles before insert for Invoice.
     * @param newList List of New Invoices.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {

    }

    /**
     * Handles after insert for Invoices.
     * @param newList List of New Invoices.
     * @param newMap Map of New Invoices.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
		

    }

    /**
     * Handles before update for Invoices.
     * @param newMap Map of New Invoices.
     * @param oldMap Map of Old Invoices.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_InvoiceTriggerHelper invoiceTriggerObj = new NSP_InvoiceTriggerHelper();
        invoiceTriggerObj.beforeUpdateDirector((Map<Id, blng__Invoice__c>)newMap,(Map<Id, blng__Invoice__c>)oldMap);
  

    }

    /**
     * Handles after update for Invoices.
     * @param newMap Map of New Invoices.
     * @param oldMap Map of Old Invoices. 
     * @return void
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        if (!this.hasRun()) {
            this.markRun();
        NSP_InvoiceTriggerHelper invoiceTriggerObj = new NSP_InvoiceTriggerHelper();
        invoiceTriggerObj.afterUpdateDirector((Map<Id, blng__Invoice__c>)newMap,(Map<Id, blng__Invoice__c>)oldMap);
        }
    }

    /**
    * Handles after delete for Invoices
    * @param oldList List of old Invoices
    * @param oldMap Map of Invoices
    * @return void                           
    */ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

      /**
  * Handles before delete for Invoices
  * @param oldList List of old Invoices
  * @param oldMap Map of Invoices
  * @return void                           
  */ 
  public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
}
}