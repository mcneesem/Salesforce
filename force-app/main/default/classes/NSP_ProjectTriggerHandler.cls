/**
* Represents the project trigger handler.
*/
public class NSP_ProjectTriggerHandler implements NSP_ITriggerHandler {
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
    * Handles before insert for project
    * @param newList List of New project. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_ProjectTriggerHelper  projectTriggerHelperObject =  new NSP_ProjectTriggerHelper(); 
        projectTriggerHelperObject.beforeInsertDirector((List<pse__Proj__c>) newList);
        
    }
    /**
    * Handles after insert for project
    * @param newList List of New project.
    * @param newMap Map of New project. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> oldMap) {
        NSP_ProjectTriggerHelper  projectTriggerHelperObject =  new NSP_ProjectTriggerHelper();
        projectTriggerHelperObject.afterInsertDirector((list<pse__Proj__c>) newList,  (Map<Id, pse__Proj__c>) oldMap); 
    } 
    
    /**
    * Handles before update for project
    * @param newMap Map of New project.
    * @param oldMap Map of Old project. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ProjectTriggerHelper  projectTriggerHelperObject =  new NSP_ProjectTriggerHelper(); 
        projectTriggerHelperObject.beforeUpdateDirector((Map<Id, pse__Proj__c>)newMap,(Map<Id, pse__Proj__c>)oldMap);
    }    
    /**
    * Handles after update for project
    * @param newMap Map of New project.
    * @param oldMap Map of Old project. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) { 
        Map<Id, pse__Proj__c> newProjectMap =  (Map<Id, pse__Proj__c>) newMap;
        Map<Id, pse__Proj__c> oldProjectMap =  (Map<Id, pse__Proj__c>) oldMap;
        
        NSP_ProjectTriggerHelper  projectTriggerHelperObject =  new NSP_ProjectTriggerHelper(); 
        projectTriggerHelperObject.afterUpdateDirector((Map<Id, pse__Proj__c>)newMap,(Map<Id, pse__Proj__c>)oldMap);
        //Added as part of STY-02859
        NSP_ProjBlngTriggerHelper projBlngTriggerHelper = new NSP_ProjBlngTriggerHelper();
        projBlngTriggerHelper.onProjectDateUpdates(newProjectMap.values(),oldProjectMap);
        NSP_ProjBlngTriggerHelper.updateBackOutOnOrder((Map<Id, pse__Proj__c>) newMap,(Map<Id, pse__Proj__c>) oldMap);
    } 
    /**
    * Handles before delete for project
    * @param oldList Map of old project.
    * @param oldMap Map of Old project. 
    * @return void             
    *                
    */
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        // Added as part of STY-04554
        NSP_ProjectTriggerHelper  projectTriggerHelperObject =  new NSP_ProjectTriggerHelper(); 
        projectTriggerHelperObject.handleBeforeDeleteOfProjTemp((List<pse__Proj__c>)oldList);
    }

    /**
   * Handles after delete for Project
   * @param oldList List of Old Project.
   * @param oldMap Map of Old Project. 
   * @return void             
   *                
   */

    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {

    }
}