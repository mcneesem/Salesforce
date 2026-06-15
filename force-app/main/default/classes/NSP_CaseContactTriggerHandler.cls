public class NSP_CaseContactTriggerHandler implements NSP_ITriggerHandler{
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
     * Handles before insert for Case Contacts
     * @param newList List of New Case Contacts
     * @return void
     *
     */
    public void beforeInsert(List<sObject> newList) {
        // added as a part of STY-03685
	}

    /**
     * Handles after insert for Case Contacts
     * @param newList List of New Case Contacts
     * @param newMap Map of New Case Contacts
     * @return void
     *
     */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
    	 NSP_CaseContactTriggerHelper caseContactTriggerHelperObj = new NSP_CaseContactTriggerHelper();
        caseContactTriggerHelperObj.beforeInsertDirector((List<NSP_Case_Contacts__c>)newList);
        caseContactTriggerHelperObj.afterInsertDirector((List<NSP_Case_Contacts__c>)newList,(Map<Id, NSP_Case_Contacts__c>) newMap);
    }

    /**
     * Handles before update for Case Contacts
     * @param newMap Map of New Case Contacts
     * @param oldMap Map of Old Case Contacts
     * @return void
     *
     */

    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap){

         NSP_CaseContactTriggerHelper caseContactTriggerHelperObj = new NSP_CaseContactTriggerHelper();

    }

    /**
     * Handles after update for Case Contacts
     * @param newMap Map of New Case Contacts
     * @param oldMap Map of Old Case Contacts
     * @return void
     *
     */

    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_CaseContactTriggerHelper caseContactTriggerHelperObj = new NSP_CaseContactTriggerHelper();
        caseContactTriggerHelperObj.afterUpdateDirector((Map<Id, NSP_Case_Contacts__c>) newMap,(Map<Id, NSP_Case_Contacts__c>) oldMap);
        caseContactTriggerHelperObj.beforeUpdateDirector((Map<Id, NSP_Case_Contacts__c>) newMap,(Map<Id, NSP_Case_Contacts__c>) oldMap);
    }

    /**
     * Handles before delete for Case Contacts
     * @param newMap Map of New Case Contacts
     * @param oldMap Map of Old Case Contacts
     * @return void
     *
     */

    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        NSP_CaseContactTriggerHelper caseContactTriggerHelperObj = new NSP_CaseContactTriggerHelper();
        caseContactTriggerHelperObj.beforeDeleteDirector((List<NSP_Case_Contacts__c>)oldList);
    }

    /**
     * Handles after delete for Case Contacts
     * @param newMap Map of New Case Contacts
     * @param oldMap Map of Old Case Contacts
     * @return void
     *
     */

    public void afterDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {

    }

    /**
     * Handles after delete for Case Contacts
     * @param newMap Map of New Case Contacts
     * @param oldMap Map of Old Case Contacts
     * @return void
     *
     */

    public void afterUnDelete(List<sObject> newList, Map<Id, sObject> newMap) {

    }


}