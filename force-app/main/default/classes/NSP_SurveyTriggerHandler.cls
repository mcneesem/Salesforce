public class NSP_SurveyTriggerHandler implements NSP_ITriggerHandler {
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
    * Handles before insert for Survey.
    * @param newList List of New Survey. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
    	   
    }
    /**
    * Handles after insert for Survey.
    * @param newList List of Survey.
    * @param newMap Map of Survey.
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> oldMap) {
        NSP_SurveyTriggerHelper helperObj = new NSP_SurveyTriggerHelper();
        helperObj.createCaseFromCSATSurveyResult((List<NSP_Survey__c>) newList, null, (Map<Id, NSP_Survey__c>) oldMap);    
    }
    /**
    * Handles before update for Survey.
    * @param newMap Map of New Survey.
    * @param oldMap Map of Old Survey.
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
    }    
    /**
    * Handles after update for Survey.
    * @param newMap Map of New Survey.
    * @param oldMap Map of Old Survey.
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) { 
        NSP_SurveyTriggerHelper helperObj = new NSP_SurveyTriggerHelper();
        helperObj.createCaseFromCSATSurveyResult(null, (Map<Id, NSP_Survey__c>) newMap, (Map<Id, NSP_Survey__c>) oldMap);    
    } 
    /**
    * Handles before delete for Survey.
    * @param oldList Map of old Survey.
    * @param oldMap Map of OldSurvey.
    * @return void             
    *                
    */
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }

    /**
    * Handles after delete for Survey.
    * @param oldList List of old Survey.
    * @param oldMap Map of Old Survey.
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
}