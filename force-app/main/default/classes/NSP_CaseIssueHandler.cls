/**
* Represents the Case Issue trigger handler.
* Author : Nischay Jindal
* CreatedDate : 26/01/2023
*/
public class NSP_CaseIssueHandler extends NSP_TriggerAction implements NSP_ITriggerHandler {

    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;

    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     *
     */

    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    /**
     * Handles before insert for Case Issue.
     * @param newList List of New Case Issue.
     * @return void
     *
     */
    public void beforeInsert(List < sObject > newList) {
	
    }

    /**
     * Handles after insert for CaseIssue.
     * @param newList List of New CaseIssue.
     * @param newMap Map of New CaseIssue.
     * @return void
     *
     */
    public void afterInsert(List < sObject > newList, Map < Id, sObject > newMap) {

    }

    /**
     * Handles before update for CaseIssue.
     * @param newMap Map of New CaseIssue.
     * @param oldMap Map of Old CaseIssue.
     * @return void
     *
     */

    public void beforeUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        NSP_CaseIssueHelper.beforeUpdateDirector((List < NSP_Case_Issue__c >) newMap.values(), (Map < Id, NSP_Case_Issue__c > ) oldMap);
    }

    /**
     * Handles after update for CaseIssue.
     * @param newMap Map of New CaseIssue.
     * @param oldMap Map of Old CaseIssue. 
     * @return void           
     *                
     */

    public void afterUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
     	NSP_CaseIssueHelper.afterUpdateDirector((List < NSP_Case_Issue__c >) newMap.values(), (Map < Id, NSP_Case_Issue__c > ) oldMap);
    }
    
	/**
	* Handles before delete for CaseIssue.
	* @param oldList List, oldMap of New CaseIssue.
	* @return void
	*/
    public void beforeDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {
	
    }
	
	/**
	* Handles after delete for CaseIssue.
	* @param oldList List, oldMap of New CaseIssue.
	* @return void
	*/
    public void afterDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {}
}