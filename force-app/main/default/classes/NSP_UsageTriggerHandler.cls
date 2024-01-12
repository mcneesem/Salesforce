public class NSP_UsageTriggerHandler implements NSP_ITriggerHandler {
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
* Handles before insert for Usages.
* @param newList List of New Usages.
* @return void
*
*/
    public void beforeInsert(List<sObject> newList) {
        
    }
    
    /**
* Handles after insert for Usages.
* @param newList List of New Usages.
* @param newMap Map of New Usages.
* @return void
*
*/
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        List<blng__Usage__c> usages=new List<blng__Usage__c>((List<blng__Usage__c>) newList);
        //system.debug('from after insert '+usages[0].blng__Status__c+' '+usages[0].blng__Subtotal__c);
    }
    
    /**
* Handles before update for Usages.
* @param newMap Map of New Usages.
* @param oldMap Map of Old Usages.
* @return void
*
*/
    
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }
    
    /**
* Handles after update for Usages.
* @param newMap Map of New Usages.
* @param oldMap Map of Old Usages. 
* @return void
*                
*/
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        Map<Id,blng__Usage__c> usages=new Map<Id,blng__Usage__c>((Map<Id,blng__Usage__c>) newMap);
        Map<Id,blng__Usage__c> oldusages=new Map<Id,blng__Usage__c>((Map<Id,blng__Usage__c>) oldMap);
        for(blng__Usage__c usage:usages.values()){
            blng__Usage__c oldusgae=oldusages.get(usage.Id);
            //system.debug('after update'+usage.blng__Status__c+' '+oldusgae.blng__Status__c+' '+usage.blng__Subtotal__c);
        }
        NSP_UsageTriggerHelper.afterUpdateDirector((Map<Id,blng__Usage__c>) newMap, (Map<Id,blng__Usage__c>) oldMap);
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
* Handles after delete for Usages
* @param oldList List of old Usages
* @param oldMap Map of Usages
* @return void                           
*/ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}