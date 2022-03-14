/**
* Represents the Lead trigger handler.
*/
public class NSP_LeadTriggerHandler implements NSP_ITriggerHandler{
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
* Handles before insert for lead
* @param newList List of New leads. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
        
        NSP_LeadTriggerHelper  LeadTriggerHelperObject =  new NSP_LeadTriggerHelper();
        LeadTriggerHelperObject.beforeInsertDirector((List<Lead>) newList);
        
    }    
    /**
* Handles after insert for lead
* @param newList List of New leads.
* @param newMap Map of New leads. 
* @return void             
*                
*/
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
     // Share Lead with owner Sales office Public groups --STY-01786   
     NSP_recordSharing.nonBPALeadSharing(newList);
    }
    
    /**
* Handles before update for lead
* @param newMap Map of New leads.
* @param oldMap Map of Old leads. 
* @return void             
*                
*/
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
        NSP_LeadTriggerHelper  LeadTriggerHelperObject =  new NSP_LeadTriggerHelper();
        
        LeadTriggerHelperObject.beforeUpdateDirector((Map<Id, Lead>) newMap,(Map<Id, Lead>) oldMap);
    }
    
    
    /**
* Handles after update for lead
* @param newMap Map of New leads.
* @param oldMap Map of Old leads. 
* @return void             
*                
*/
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
         NSP_LeadTriggerHelper  LeadTriggerHelperObject =  new NSP_LeadTriggerHelper();
        LeadTriggerHelperObject.afterUpdateDirector((Map<Id, Lead>) newMap,(Map<Id, Lead>) oldMap);
        // Share Lead with owner Sales office Public groups --STY-01786  
        NSP_recordSharing.shareLeadsonUpdate((Map<Id, Lead>) newMap,(Map<Id, Lead>) oldMap);
    }

    /**
    * Handles after delete for lead
    * @param oldList List of old lead
    * @param oldMap Map of Old lead
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
  
}