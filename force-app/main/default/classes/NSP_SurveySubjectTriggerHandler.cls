public with sharing class NSP_SurveySubjectTriggerHandler implements NSP_ITriggerHandler{
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
    * Handles before insert for Survey Subject
    * @param newList List of New Survey Subject. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
    }
    
    /**
    * Handles after insert for Survey Subject
    * @param newList List of New Survey Subject.
    * @param newMap Map of New Survey Subject. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_SurveySubjectTriggerHelper oSurveySubjectHelper = new NSP_SurveySubjectTriggerHelper();
        oSurveySubjectHelper.afterInsertFilter((List<SurveySubject>)newList, (Map<Id,SurveySubject>)newMap);
    }
    
    /**
    * Handles before update for Survey Subjecte
    * @param newMap Map of New Survey Subject.
    * @param oldMap Map of Old Survey Subject. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }
    
    
    /**
    * Handles after update for Survey Subject
    * @param newMap Map of New Survey Subject
    * @param oldMap Map of Old Survey Subject
    * @return void             
    *                
    */
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {

    }

    /**
    * Handles after delete for SurveySubject.
    * @param oldList List of old SurveySubject.
    * @param oldMap Map of Old SurveySubject.
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
    
    /**
    * Handles before delete for SurveySubject.
    * @param oldList List of old SurveySubject.
    * @param oldMap Map of Old SurveySubject.
    * @return void             
    *                
    */
    
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
}