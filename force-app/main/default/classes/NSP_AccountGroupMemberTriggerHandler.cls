/**
 * Represents the AccountGroupMember handler.
 */
public class NSP_AccountGroupMemberTriggerHandler implements NSP_ITriggerHandler{
	
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
     * Handles before insert for AccountGroupMember.
     * @param newList List of New AccountGroupMember.
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        //STY-02787 Account and Group Relation Duplicate validations
        new NSP_AccountGroupMemberTriggerHelper().validateDuplicapteGroupMembers((List<NSP_Account_Group_Member__c>) newList);
        //added as part of STY-02846 changes
        NSP_AccountGroupMemberTriggerHelper.updateAGMAccountPayrollEmployees((List<NSP_Account_Group_Member__c>) newList, null);
    }

    /**
     * Handles after insert for AccountGroupMember.
     * @param newList List of New AccountGroupMember.
     * @param newMap Map of New AccountGroupMember.
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        //STY-01099 Account Group Name will be defaulted to be "group type + primary Account Name " + "Tag" Account is set to primary
        new NSP_AccountGroupMemberTriggerHelper().afterInsertIsPrimary((List<NSP_Account_Group_Member__c>)newList, null);
        //Added as part of STY-03316
        NSP_AccountGroupMemberTriggerHelper.afterInsertDirector((List<NSP_Account_Group_Member__c>) newList, (Map<Id, NSP_Account_Group_Member__c>) newMap);
    }

    /**
     * Handles before update for AccountGroupMember.
     * @param newMap Map of New AccountGroupMember.
     * @param oldMap Map of Old AccountGroupMember.
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        //added as part of STY-02846 changes
        NSP_AccountGroupMemberTriggerHelper.updateAGMAccountPayrollEmployees((List<NSP_Account_Group_Member__c>) newMap.values(), (Map<Id,NSP_Account_Group_Member__c>) oldMap);
        
    }

    /**
     * Handles after update for AccountGroupMember.
     * @param newMap Map of New AccountGroupMember.
     * @param oldMap Map of Old AccountGroupMember. 
     * @return void           
     *                
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        //STY-01099 Account Group Name will be defaulted to be "group type + primary Account Name " + "Tag" Account is set to primary
        new NSP_AccountGroupMemberTriggerHelper().afterInsertIsPrimary((List<NSP_Account_Group_Member__c>) newMap.values(), (Map<Id,NSP_Account_Group_Member__c>) oldMap);
    }
    
    /**
     * Handles before delete for AccountGroupMember.
     * @param newMap Map of New AccountGroupMember.
     * @param oldMap Map of Old AccountGroupMember. 
     * @return void           
     *                
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) { 
        new NSP_AccountGroupMemberTriggerHelper().preventDeleteForWXAccountGroupMembers((List<NSP_Account_Group_Member__c>) oldList);
        NSP_AccountGroupMemberTriggerHelper.preventAccountGroupsDeleting((List<NSP_Account_Group_Member__c>) oldList);
    }
    
    /**
     * Handles after delete for AccountGroupMember.
     * @param newMap Map of New AccountGroupMember.
     * @param oldMap Map of Old AccountGroupMember. 
     * @return void           
     *                
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        //Added as part of STY-03316
    	NSP_AccountGroupMemberTriggerHelper.afterDeleteDirector((List<NSP_Account_Group_Member__c>) oldList, (Map<Id,NSP_Account_Group_Member__c>) oldMap);
        NSP_AccountGroupMemberTriggerHelper.afterDeleteCreateSelfGroup((List<NSP_Account_Group_Member__c>) oldList); 
    }
    
    /**
     * Handles after delete for AccountGroupMember.
     * @param newMap Map of New AccountGroupMember.
     * @param oldMap Map of Old AccountGroupMember. 
     * @return void           
     *                
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {
       
    }
}