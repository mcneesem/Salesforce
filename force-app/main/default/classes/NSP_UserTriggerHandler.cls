/**
* Represents the User trigger handler.
*/
public class NSP_UserTriggerHandler implements NSP_ITriggerHandler{
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
* Handles before insert for Quote
* @param newList List of New Quote. 
* @return void             
*                
*/
    public void beforeInsert(List<sObject> newList) {
        NSP_UserTriggerHelper  userTriggerHelperObject =  new NSP_UserTriggerHelper();
        userTriggerHelperObject.beforeInsertUser((List<User>) newList); 
    }
    
    /**
* Handles after insert for Quote
* @param newList List of New Quote.
* @param newMap Map of New Quote. 
* @return void             
*                
*/
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_UserTriggerHelper  userTriggerHelperObject =  new NSP_UserTriggerHelper();
        userTriggerHelperObject.afterInsertUser((List<User>) newList); 
    }
    
    /**
* Handles before update for Quote
* @param newMap Map of New Quote.
* @param oldMap Map of Old Quote. 
* @return void             
*                
*/
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_UserTriggerHelper  userTriggerHelperObject =  new NSP_UserTriggerHelper();
        userTriggerHelperObject.beforeUpdateUser((Map<Id, User>) newMap, (Map<Id, User>) oldMap);    
    }
    /**
* Handles after update for Quote
* @param newMap Map of New Quote.
* @param oldMap Map of Old Quote. 
* @return void             
*                
*/
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        // Added as a part of STY-02768
        NSP_userSalesOfficeRecordSharing.ownerSalesofficeSharing((Map<Id, User>) newMap, (Map<Id, User>) oldMap);
        NSP_UserTriggerHelper  userTriggerHelperObject =  new NSP_UserTriggerHelper();
        userTriggerHelperObject.afterUpdateUser((Map<Id, User>) newMap, (Map<Id, User>) oldMap);
        //NSP_portalUserSharing.shareProjects((List<User>) newMap.values());

        // Added as a part of STY-02108
        NSP_UserTriggerHelper.updateAssetServiceRegion((Map<Id, User>) newMap, (Map<Id, User>) oldMap);
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
    * Handles after delete for Quote.
    * @param oldList List of old Quote.
    * @param oldMap Map of Old Quote. 
    * @return void             
    *                
    */ 
     public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}