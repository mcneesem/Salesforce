/**
* Represents the Sub Client trigger handler.
* Created by : Hemali Patel
* Created Date : 8/11/2021
*/
public class NSP_SubClientTriggerHandler implements NSP_ITriggerHandler{
    
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
* Handles before insert for Sub Client
* @param newList List of New Sub Client. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
    }
    
    /**
* Handles after insert for Sub Client
* @param newList List of New Sub Client.
* @param newMap Map of New Sub Client. 
* @return void             
*                
*/
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        NSP_SubClientTriggerHelper subClientTriggerObj = new NSP_SubClientTriggerHelper();
        subClientTriggerObj.afterInsertDirector((List<NSP_Sub_Client__c>)newList,(Map<Id, NSP_Sub_Client__c>)newMap);
    }
    
    /**
* Handles before update for Sub Client
* @param newMap Map of New Sub Client.
* @param oldMap Map of Old Sub Client. 
* @return void             
*                
*/
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        
        
        
    }
    
    
    /**
* Handles after update for Sub Client
* @param newMap Map of New Sub Client.
* @param oldMap Map of Old Sub Client. 
* @return void             
*                
*/
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_SubClientTriggerHelper subClientTriggerObj = new NSP_SubClientTriggerHelper();
        subClientTriggerObj.afterUpdateDirector((Map<Id, NSP_Sub_Client__c>)newMap,(Map<Id, NSP_Sub_Client__c>)oldMap);
        
    }
}