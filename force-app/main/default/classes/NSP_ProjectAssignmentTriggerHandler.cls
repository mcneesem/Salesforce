public with sharing class NSP_ProjectAssignmentTriggerHandler implements NSP_ITriggerHandler {
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
    * Handles before insert for Project Assignment
    * @param newList List of New Project Assignment. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_ProjectAssignmentTriggerHelper  oProjectAssignmentHelper =  new NSP_ProjectAssignmentTriggerHelper(); 
        oProjectAssignmentHelper.beforeInsertAssignmentFilters((List<pse__Assignment__c>) newList);
    }
    
    /**
    * Handles after insert for Project Assignment
    * @param newList List of New Project Assignment.
    * @param newMap Map of New Project Assignment. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_ProjectAssignmentTriggerHelper  oProjectAssignmentHelper =  new NSP_ProjectAssignmentTriggerHelper(); 
        oProjectAssignmentHelper.afterInsertAssignmentFilters((List<pse__Assignment__c>) newList, (Map<Id, pse__Assignment__c>) newMap);
    }
    
    /**
    * Handles before update for Project Assignment
    * @param newMap Map of New Project Assignment.
    * @param oldMap Map of Old Project Assignment. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ProjectAssignmentTriggerHelper  oProjectAssignmentHelper =  new NSP_ProjectAssignmentTriggerHelper(); 
        oProjectAssignmentHelper.beforeUpdateAssignmentFilters((Map<Id, pse__Assignment__c>) newMap, (Map<Id, pse__Assignment__c>) oldMap);
    }
    
    
    /**
    * Handles after update for Project Assignment
    * @param newMap Map of New Project Assignment
    * @param oldMap Map of Old Project Assignment
    * @return void             
    *                
    */
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ProjectAssignmentTriggerHelper  oProjectAssignmentHelper =  new NSP_ProjectAssignmentTriggerHelper(); 
        oProjectAssignmentHelper.afterUpdateAssignmentfilters((Map<Id, pse__Assignment__c>) newMap, (Map<Id, pse__Assignment__c>) oldMap);
    }

    /**
    * Handles after delete for Project Assignment
    * @param oldList List of old Project Assignment
    * @param oldMap Map of Old Project Assignment
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }


    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    
    }
}