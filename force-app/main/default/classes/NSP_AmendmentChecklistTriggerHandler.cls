/**
 * Represents the Amendment checklist trigger handler.
* Version - STY       - AUTHOR         - DESCRIPTION                                      - TAG
* V1.0    - STY-02109 - Abhishek Kumar - Amendment Chcklist -populating fields from Asset - <STY-02109>
 */
public class NSP_AmendmentChecklistTriggerHandler implements NSP_ITriggerHandler{
	
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
     * Handles before insert for Amendment Checklist.
     * @param newList List of New Amendment Checklist.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        // added as a part of STY-02109
		NSP_AmendmentChecklistTriggerHelper amendmentChecklistTriggerHelperObj = new NSP_AmendmentChecklistTriggerHelper();
        amendmentChecklistTriggerHelperObj.beforeInsertDirector((List<NSP_Amendment_Checklist__c>)newList);
    }
    
    /**
     * Handles after insert for Amendment Checklist.
     * @param newList List of New Amendment Checklist.
     * @param newMap Map of New Amendment Checklist.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    	
    }

    /**
     * Handles before update for Amendment Checklist.
     * @param newMap Map of New Amendment Checklist.
     * @param oldMap Map of Old Amendment Checklist.
     * @return void
     *
     */
 
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap){ 
        // added as a part of STY-02109
        NSP_AmendmentChecklistTriggerHelper amendmentChecklistTriggerHelperObj = new NSP_AmendmentChecklistTriggerHelper();
        amendmentChecklistTriggerHelperObj.beforeUpdateDirector(((Map<Id, NSP_Amendment_Checklist__c>) newMap), ((Map<Id, NSP_Amendment_Checklist__c>) oldMap));
    }
 
    /**
     * Handles after update for Amendment ChecklistAmendment Checklist.
     * @param newMap Map of New Amendment Checklist.
     * @param oldMap Map of Old Amendment Checklist. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    
    /**
     * Handles before delete for Amendment Checklist.
     * @param newMap Map of New Amendment Checklist.
     * @param oldMap Map of Old Amendment Checklist. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Amendment Checklist.
     * @param newMap Map of New Amendment Checklist.
     * @param oldMap Map of Old Amendment Checklist. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Amendment Checklist.
     * @param newMap Map of New Amendment Checklist.
     * @param oldMap Map of Old Amendment Checklist. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
    
}