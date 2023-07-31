public class NSP_ClientSubPlanHistTriggerHandler implements NSP_ITriggerHandler{
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
     * Handles before insert for Client Sub Plan History.
     * @param newList List of New Client Sub Plan History.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        // added as a part of STY-02660
		NSP_ClientSubPlanHistTriggerHelper clientSubPlanHistoryTriggerHelperObj = new NSP_ClientSubPlanHistTriggerHelper();
        clientSubPlanHistoryTriggerHelperObj.beforeInsertDirector((List<NSP_Client_Sub_Plan_History__c>)newList);
    }
    
    /**
     * Handles after insert for Client Sub Plan History.
     * @param newList List of New Client Sub Plan History.
     * @param newMap Map of New Client Sub Plan History.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    	
    }

    /**
     * Handles before update for Client Sub Plan History.
     * @param newMap Map of New Client Sub Plan History.
     * @param oldMap Map of Old Client Sub Plan History.
     * @return void
     *
     */
 
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap){ 
        
    }
 
    /**
     * Handles after update for Client Sub Plan History.
     * @param newMap Map of New Client Sub Plan History.
     * @param oldMap Map of Old Client Sub Plan History. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    
    /**
     * Handles before delete for Client Sub Plan History.
     * @param newMap Map of New Client Sub Plan History.
     * @param oldMap Map of Old Client Sub Plan History. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Client Sub Plan History.
     * @param newMap Map of New Client Sub Plan History.
     * @param oldMap Map of Old Client Sub Plan History. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Client Sub Plan History.
     * @param newMap Map of New Client Sub Plan History.
     * @param oldMap Map of Old Client Sub Plan History. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}