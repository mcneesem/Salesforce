/**
 * Represents the NSP_Sales_Office_Mapping__c trigger handler.
 */
public class NSP_SalesOfficeMappingTriggerHandler  implements NSP_ITriggerHandler {
    
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
     * Handles before insert for NSP_Sales_Office_Mapping__c .
     * @param newList List of New NSP_Sales_Office_Mapping__c .
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        NSP_SalesOfficeMappingTriggerHelper  salesOfficeMappingTriggerHelperObject =  new NSP_SalesOfficeMappingTriggerHelper();
        salesOfficeMappingTriggerHelperObject.beforeInsertDirector((List<NSP_Sales_Office_Mapping__c >) newList);
    }

    /**
     * Handles after insert for NSP_Sales_Office_Mapping__c .
     * @param newList List of New NSP_Sales_Office_Mapping__c .
     * @param newMap Map of New NSP_Sales_Office_Mapping__c .
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        //NSP_SalesOfficeMappingTriggerHelper  salesOfficeMappingTriggerHelperObject =  new NSP_SalesOfficeMappingTriggerHelper();
        //salesOfficeMappingTriggerHelperObject.afterInsertDirector((List<NSP_Sales_Office_Mapping__c >) newList, (Map<Id, NSP_Sales_Office_Mapping__c >) newMap);
        
    }

    /**
     * Handles before update for NSP_Sales_Office_Mapping__c .
     * @param newMap Map of New NSP_Sales_Office_Mapping__c .
     * @param oldMap Map of Old NSP_Sales_Office_Mapping__c .
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SalesOfficeMappingTriggerHelper  salesOfficeMappingTriggerHelperObject =  new NSP_SalesOfficeMappingTriggerHelper();
        salesOfficeMappingTriggerHelperObject.beforeUpdateDirector((Map<Id,NSP_Sales_Office_Mapping__c >) newMap,(Map<Id,NSP_Sales_Office_Mapping__c >) oldMap);
        
    }

    /**
     * Handles after update for NSP_Sales_Office_Mapping__c .
     * @param newMap Map of New NSP_Sales_Office_Mapping__c .
     * @param oldMap Map of Old NSP_Sales_Office_Mapping__c . 
     * @return void             
     *                
     */ 

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    /**
    * Handles after delete for NSP_Sales_Office_Mapping__c .
    * @param oldList List of old NSP_Sales_Office_Mapping__c .
    * @param oldMap Map of Old NSP_Sales_Office_Mapping__c . 
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
}