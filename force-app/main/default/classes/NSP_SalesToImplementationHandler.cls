/**
 * Represents the S2I trigger handler.
* Version - STY       - AUTHOR         - DESCRIPTION                                      - TAG
* V1.0    - STY-02743 - Ramya Ravi - S2I : Creation of new RET Education Record           - <STY-02743>
 */
public class NSP_SalesToImplementationHandler implements NSP_ITriggerHandler{
	
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
     * Handles before insert for S2I.
     * @param newList List of New S2I.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {        		
    }
    
    /**
     * Handles after insert for S2I.
     * @param newList List of New S2I.
     * @param newMap Map of New S2I.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_SalesToImplementationHelper S2IHelperObj = new NSP_SalesToImplementationHelper();
        S2IHelperObj.afterInsert((List<NSP_Sales_to_Implementation__c>)newList);    	
    }

    /**
     * Handles before update for Sales_to_Implementation
     * @param newMap Map of New Sales_to_Implementation
     * @param oldMap Map of Old Sales_to_Implementation
     * @return void
     *
     */
 
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap){ 
        }
 
    /**
     * Handles after update for Sales_to_Implementation
     * @param newMap Map of New Sales_to_Implementation
     * @param oldMap Map of Old Sales_to_Implementation
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SalesToImplementationHelper S2IHelperObj = new NSP_SalesToImplementationHelper();
        S2IHelperObj.afterUpdate(((Map<Id, NSP_Sales_to_Implementation__c>) newMap), ((Map<Id, NSP_Sales_to_Implementation__c>) oldMap)) ;
              
    }    
    /**
     * Handles before delete for Sales_to_Implementation
     * @param newMap Map of New Sales_to_Implementation
     * @param oldMap Map of Old Sales_to_Implementation 
     * @return void           
     *                
     */
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
         }    
    /**
     * Handles after delete for Sales_to_Implementation
     * @param newMap Map of New Sales_to_Implementation
     * @param oldMap Map of Old Sales_to_Implementation
     * @return void           
     *                
     */
    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {       
    }    
    /**
     * Handles after delete for Sales_to_Implementation.
     * @param newMap Map of New Sales_to_Implementation.
     * @param oldMap Map of Old Sales_to_Implementation. 
     * @return void           
     *                
     */
    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {       
    }
    
}