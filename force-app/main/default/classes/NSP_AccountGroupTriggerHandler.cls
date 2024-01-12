/**
 * Represents the Account Group handler.
 */

public class NSP_AccountGroupTriggerHandler  implements NSP_ITriggerHandler{
	
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

    /**
     * Handles before insert for Account Group.
     * @param newList List of New Account Group.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        //STY-01099 Account Group Name will be defaulted to be "group type + primary Account Name " + "Tag"
        new NSP_AccountGroupTriggerHelper().beforeUpdateGroupName((List<NSP_Account_Group__c>) newList, null);
    }

    /**
     * Handles after insert for Account Group.
     * @param newList List of New Account Group.
     * @param newMap Map of New Account Group.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    	
    	
    }

    /**
     * Handles before update for Account Group.
     * @param newMap Map of New Account Group.
     * @param oldMap Map of Old Account Group.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        //STY-01099 Account Group Name will be defaulted to be "group type + primary Account Name " + "Tag"
        new NSP_AccountGroupTriggerHelper().beforeUpdateGroupName((List<NSP_Account_Group__c>) newMap.values(),(Map<Id, NSP_Account_Group__c>) oldMap);
        //STY-02787 GroupType should not be changed
        new NSP_AccountGroupTriggerHelper().groupTypeValidation((List<NSP_Account_Group__c>) newMap.values(),(Map<Id, NSP_Account_Group__c>) oldMap);
    }
    
    /**
     * Handles after update for Account Group.
     * @param newMap Map of New Account Group.
     * @param oldMap Map of Old Account Group. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        new NSP_AccountGroupTriggerHelper().afterUpdate((Map<Id,NSP_Account_Group__c>)newMap, (Map<Id,NSP_Account_Group__c>)oldMap );
    }
    
    /**
     * Handles before delete for Account Group.
     * @param newMap Map of New Account Group.
     * @param oldMap Map of Old Account Group. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Account Group.
     * @param newMap Map of New Account Group.
     * @param oldMap Map of Old Account Group. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
       
    }
    
    /**
     * Handles after delete for Account Group.
     * @param newMap Map of New Account Group.
     * @param oldMap Map of Old Account Group. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}