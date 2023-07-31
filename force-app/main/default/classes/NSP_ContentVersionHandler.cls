/**
* Represents the NSP_ContentVersionHandler handler.
* CreatedDate : 10/1/2022
*/
public class NSP_ContentVersionHandler implements NSP_ITriggerHandler {  
    
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
* Handles before insert for ContentVersion
* @param newList List of New ContentVersion. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
        NSP_ContentVersionTriggerHelper  conVerTriggerObjHelper =  new NSP_ContentVersionTriggerHelper();
        conVerTriggerObjHelper.beforeInsertDirector(newList);
    }
    
    /**
* Handles after insert for ContentVersion
* @param newList List of New ContentVersion.
* @param newMap Map of New ContentVersion. 
* @return void             
*                
*/
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        
    }
    
    /**
* Handles before update for ContentVersion
* @param newMap Map of New ContentVersion.
* @param oldMap Map of Old ContentVersion. 
* @return void             
*                
*/
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_ContentVersionTriggerHelper  conVerTriggerObjHelper =  new NSP_ContentVersionTriggerHelper();
        conVerTriggerObjHelper.beforeUpdateDirector((Map<Id, ContentVersion>) newMap,(Map<Id, ContentVersion>) oldMap);
        
        
    }
    
    
    /**
* Handles after update for ContentVersion
* @param newMap Map of New ContentVersion.
* @param oldMap Map of Old ContentVersion. 
* @return void             
*                
*/
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
        
    }
    /**
* Handles after delete for ContentVersion
* @param oldList List of old ContentVersion
* @param oldMap Map of Old ContentVersion
* @return void             
*                
*/ 
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

    /**
* Handles after delete for ContentVersion
* @param oldList List of old ContentVersion
* @param oldMap Map of Old ContentVersion
* @return void             
*                
*/ 
 public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
    
} 
    
}