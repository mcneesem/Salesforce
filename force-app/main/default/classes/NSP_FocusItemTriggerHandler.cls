/**
* Represents the Focus Item trigger handler.
V2.0   -   Ramya Ravi  - 02/01/2023 -  Asset pick will only allow active Assets related to the Accounts in the Account Group - <STY-03807>
*/
public class NSP_FocusItemTriggerHandler implements NSP_ITriggerHandler{
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
    * Handles before insert for Focus Item
    * @param newList List of New Focus Item. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
            //Added as part of <STY-03807>
          NSP_FocusItemTriggerHelper.beforeInsertDirector((List<NSP_Focus_Item__c>)newList);
   }
    
    /**
    * Handles after insert for Focus Item
    * @param newList List of New Focus Item.
    * @param newMap Map of New Focus Item. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
        //Added as part of STY-01437
        NSP_FocusItemTriggerHelper.afterInsertDirector((List<NSP_Focus_Item__c>)newList,(Map<Id, NSP_Focus_Item__c>)newMap);
    }
    
    /**
    * Handles before update for Focus Item
    * @param newMap Map of New Focus Item.
    * @param oldMap Map of Old Focus Item. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
          //Added as part of <STY-03807>
          NSP_FocusItemTriggerHelper.beforeUpdateDirector((Map<Id, NSP_Focus_Item__c>)newMap, (Map<Id, NSP_Focus_Item__c>) oldMap);
   }
    
    
    /**
    * Handles after update for Focus Item
    * @param newMap Map of New Focus Item.
    * @param oldMap Map of Old Focus Item. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }
    
    /**
    * Handles after delete for Focus Item
    * @param oldList List of Old Focus Item.
    * @param oldMap Map of Old Focus Item. 
    * @return void             
    *                
    */
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
    
    /**
    * Handles before delete for Focus Item
    * @param oldList List of Old Focus Item.
    * @param oldMap Map of Old Focus Item. 
    * @return void             
    *                
    */
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}