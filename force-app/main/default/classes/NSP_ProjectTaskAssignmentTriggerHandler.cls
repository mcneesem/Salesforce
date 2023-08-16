public with sharing class NSP_ProjectTaskAssignmentTriggerHandler implements NSP_ITriggerHandler{
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
    * Handles before insert for Project Task Assignment
    * @param newList List of New Project Task Assignment. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_ProjectTaskAssignmentTriggerHelper  oProjectTaskAssignmentHelper =  new NSP_ProjectTaskAssignmentTriggerHelper(); 
        oProjectTaskAssignmentHelper.beforeInsertTaskAssignmentFilters((List<pse__Project_Task_Assignment__c>) newList);
    }
    
    /**
    * Handles after insert for Project Task Assignment
    * @param newList List of New Project Task Assignment.
    * @param newMap Map of New Project Task Assignment. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_ProjectTaskAssignmentTriggerHelper  oProjectTaskAssignmentHelper =  new NSP_ProjectTaskAssignmentTriggerHelper(); 
        oProjectTaskAssignmentHelper.afterInsertTaskAssignmentFilters((List<pse__Project_Task_Assignment__c>) newList, (Map<Id, pse__Project_Task_Assignment__c>) newMap);
    }
    
    /**
    * Handles before update for Project Task Assignment
    * @param newMap Map of New Project Task Assignment.
    * @param oldMap Map of Old Project Task Assignment. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ProjectTaskAssignmentTriggerHelper  oProjectTaskAssignmentHelper =  new NSP_ProjectTaskAssignmentTriggerHelper(); 
        oProjectTaskAssignmentHelper.beforeUpdateTaskAssignmentFilters((Map<Id, pse__Project_Task_Assignment__c>) newMap, (Map<Id, pse__Project_Task_Assignment__c>) oldMap);
    }
    
    
    /**
    * Handles after update for Project Task Assignment
    * @param newMap Map of New Project Task Assignment
    * @param oldMap Map of Old Project Task Assignment
    * @return void             
    *                
    */
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ProjectTaskAssignmentTriggerHelper  oProjectTaskAssignmentHelper =  new NSP_ProjectTaskAssignmentTriggerHelper(); 
        oProjectTaskAssignmentHelper.afterUpdateTaskAssignmentfilters((Map<Id, pse__Project_Task_Assignment__c>) newMap, (Map<Id, pse__Project_Task_Assignment__c>) oldMap);
    }

    /**
    * Handles after delete for Project Task Assignment
    * @param oldList List of old Project Task Assignment
    * @param oldMap Map of Old Project Task Assignment
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }

    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    
    }
    
}