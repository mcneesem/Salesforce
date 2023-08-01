/**
* Represents the Project Team trigger handler.
*/
public class NSP_ProjectTeamTriggerHandler  implements NSP_ITriggerHandler {

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
    
    public void beforeInsert(List<sObject> newList) {
        // added as a part of STY-03071
        NSP_ProjectTeamTriggerHelper.restrictDuplicateProjectTeamRecords((List < NSP_Project_Team__c > ) newList);
    }
    /**
    * Handles after insert for Project Team
    * @param newList List of New Project Team.
    * @param newMap Map of New Project Team. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        //STY-03167 - project team object enhancement
        NSP_ProjectTeamTriggerHelper.updateProjectOwner((Map<Id, NSP_Project_Team__c>) newMap, null);
        
    }
    
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        // added as a part of STY-03071
        NSP_ProjectTeamTriggerHelper.updateImplementationProfileRoles((Map <Id, NSP_Project_Team__c > ) newMap,(Map <Id, NSP_Project_Team__c > )oldMap);
        //STY-03167 - project team object enhancement
        NSP_ProjectTeamTriggerHelper.updateProjectOwner((Map<Id, NSP_Project_Team__c>) newMap, (Map<Id, NSP_Project_Team__c>) oldMap);
        
    }
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    
    }
}