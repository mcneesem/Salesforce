public class NSP_UsageSummaryTriggerHandler implements NSP_ITriggerHandler {
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
* Handles before insert for Usage Summary.
* @param newList List of New Usage Summaries.
* @return void
*
*/
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    /**
* Handles after insert for Usage Summary.
* @param newList List of New Usage Sumamries.
* @param newMap Map of New Usage Summaries.
* @return void
*
*/
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        
        
    }
    
    /**
* Handles before update for Usage Summary.
* @param newMap Map of New Usage Summaries.
* @param oldMap Map of Old Usage Summaries.
* @return void
*
*/
    
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_UsageSummaryTriggerHelper usageHelper= new NSP_UsageSummaryTriggerHelper();
        usageHelper.beforeUpdateDirector((Map<Id, blng__UsageSummary__c>) newMap,(Map<Id, blng__UsageSummary__c>) oldMap);
    }
    
    /**
* Handles after update for Usage Summary.
* @param newMap Map of New Usage Summaries.
* @param oldMap Map of Old Usage Summaries. 
* @return void
*                
*/
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_UsageSummaryTriggerHelper usageHelper= new NSP_UsageSummaryTriggerHelper();
        usageHelper.afterUpdateDirector((Map<Id, blng__UsageSummary__c>) newMap,(Map<Id, blng__UsageSummary__c>) oldMap);
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
* Handles after delete for Usage Summary
* @param oldList List of old Usage Summaries
* @param oldMap Map of Usage Summaries
* @return void                           
*/ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}