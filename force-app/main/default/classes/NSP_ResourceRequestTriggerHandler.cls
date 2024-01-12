public class NSP_ResourceRequestTriggerHandler implements NSP_ITriggerHandler{
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
     * Handles before insert for Resource Request.
     * @param newList List of Resource Request.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        
		
    }
    
    /**
     * Handles after insert for Resource Request.
     * @param newList List of New Resource Request.
     * @param newMap Map of New Resource Request.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        //added as a part of STY-02212 and STY-02255
    	NSP_ResourceRequestTriggerHelper resourceRequestTriggerHelperObj = new NSP_ResourceRequestTriggerHelper();
        resourceRequestTriggerHelperObj.afterInsertDirector((List<pse__Resource_Request__c>) newList, (Map<Id, pse__Resource_Request__c>) newMap);
    }

    /**
     * Handles before update for Resource Request.
     * @param newMap Map of New Resource Request.
     * @param oldMap Map of Old Resource Request.
     * @return void
     *
     */
 
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap){ 
        
    }
 
    /**
     * Handles after update for Resource Request.
     * @param newMap Map of New Resource Request.
     * @param oldMap Map of Old Resource Request. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        //added as a part of STY-02212 and STY-02255
        NSP_ResourceRequestTriggerHelper resourceRequestTriggerHelperObj = new NSP_ResourceRequestTriggerHelper();
        resourceRequestTriggerHelperObj.afterUpdateDirector((Map<Id, pse__Resource_Request__c>) newMap, (Map<Id, pse__Resource_Request__c>) oldMap);
    }
    
    /**
     * Handles before delete for Resource Request.
     * @param newMap Map of New Resource Request.
     * @param oldMap Map of Old Resource Request. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Resource Request.
     * @param newMap Map of New Resource Request.
     * @param oldMap Map of Old Resource Request. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Resource Request.
     * @param newMap Map of New Resource Request.
     * @param oldMap Map of Old Resource Request. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}