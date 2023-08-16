/**
 * Represents the Opportunity trigger handler.
 */
public class NSP_OpportunityTriggerHandler implements NSP_ITriggerHandler{
    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
    public static Boolean runOnce = true;
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
   * Handles before insert for Opportunity
   * @param newList List of New Opportunity. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        if(NSP_OpportunityTriggerHandler.runOnce){
        NSP_OpportunityTriggerHelper  opportunityTriggerHelperObject =  new NSP_OpportunityTriggerHelper();
        opportunityTriggerHelperObject.setTypeforRenewalOpportunity((List<Opportunity>) newList);
        opportunityTriggerHelperObject.beforeInsertDirector((List<Opportunity>) newList);
    }
    }
    
    /**
   * Handles after insert for Opportunity
   * @param newList List of New Opportunity.
   * @param newMap Map of New Opportunity. 
   * @return void             
   *                
   */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        if(NSP_OpportunityTriggerHandler.runOnce){
         NSP_OpportunityTriggerHelper  opportunityTriggerHelperObject =  new NSP_OpportunityTriggerHelper();
            opportunityTriggerHelperObject.afterInsertDirector((List<Opportunity>) newList,(Map<Id, Opportunity>) newMap);
            //Added as part of STY-02066
            NSP_OpportunityTeamMemberAssignment.insertOppTeamMember((List<Opportunity>) newList);
            // Share Opportunity with owner Sales office Public groups --STY-02768 
            NSP_salesOfficeRecordSharing.opportunityRecordSharing((Map<Id, Opportunity>) newMap);
        }
    }
    
  /**
   * Handles before update for Opportunity
   * @param newMap Map of New Opportunity.
   * @param oldMap Map of Old Opportunity. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        if(NSP_OpportunityTriggerHandler.runOnce){
          NSP_OpportunityTriggerHelper  opportunityTriggerHelperObject =  new NSP_OpportunityTriggerHelper();        
          opportunityTriggerHelperObject.beforeUpdateDirector((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap);

          NSP_OpportunityTriggerServiceHelper oppTriggerServiceHelper = new NSP_OpportunityTriggerServiceHelper();
          oppTriggerServiceHelper.beforeUpdateDirector((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap); 
        }     
    }
    

     /**
   * Handles after update for Opportunity
   * @param newMap Map of New Opportunity.
   * @param oldMap Map of Old Opportunity. 
   * @return void             
   *                
   */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        if(NSP_OpportunityTriggerHandler.runOnce){
            NSP_OpportunityTriggerHandler.runOnce = false;
            NSP_OpportunityTriggerHelper  opportunityTriggerHelperObject =  new NSP_OpportunityTriggerHelper();
            NSP_OpportunityTriggerServiceHelper oppTriggerServiceHelper = new NSP_OpportunityTriggerServiceHelper();        
            opportunityTriggerHelperObject.afterUpdateDirector((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap);
            //Added as part of STY-02066
            NSP_OpportunityTeamMemberAssignment.updateAndInsertOppTeamMember((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap);
            // Share Opportunity with owner Sales office Public groups --STY-02768 
            NSP_salesOfficeRecordSharing.shareOpportunityonUpdate((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap);
 
            //Added as part of STY-01602
            oppTriggerServiceHelper.afterUpdateDirector((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap);
        }  
        // added below logic as the runOnce was not executing the creteRewardForContactRole logic from event flow. 
        NSP_OpportunityTriggerHelper  opportunityTriggerHObject =  new NSP_OpportunityTriggerHelper(); 
        opportunityTriggerHObject.creteRewardForContactRole((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap); // added for STY-03287 
        opportunityTriggerHObject.calculateSetUpAndDocupayTax((Map<Id, Opportunity>) newMap,(Map<Id, Opportunity>) oldMap);  

    }
    
    /**
     * Handles before delete.
     * @param oldList List, OldMap Map.
     * @return void
     * Added beforeDelete method as this is referred in in NSP_ITriggerHandler
    **/
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
    /**
    * Handles after delete for Opportunity
    * @param oldList List of old Opportunity
    * @param oldMap Map of Old Opportunity
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}