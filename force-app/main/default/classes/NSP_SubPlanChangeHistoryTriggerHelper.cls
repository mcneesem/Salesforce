/**
* @description  :  Helper class for SubPlanChangeHistory Trigger.
* @date 09/06/2022
* Author : Virendra Kumar
* Name : NSP_SubPlanChangeHistoryTriggerHelper
*/
public class NSP_SubPlanChangeHistoryTriggerHelper {   
    
    /***********************************************************************************************
    * MethodName: syncSPHistoryOnSubplan
    * Description : This method is used to sync SubPlanChangeHistory related fields on to Sub Plan.
    * Params:       List<NSP_Sub_Plan_Change_History__c> SubPlanChangeHistoryList, Boolean isInsert
    * ********************************************************************************************/    
    public void syncSPHistoryOnSubplan(List<NSP_Sub_Plan_Change_History__c> SubPlanChangeHistoryList, Boolean isInsert) {
        
        List<NSP_Plan_SubPlan__c> planSubPlanListToBeUpdated = new List<NSP_Plan_SubPlan__c>();
        Id ChoiceRTId = Schema.SObjectType.NSP_Sub_Plan_Change_History__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.CHOICE_RT_NAME).getRecordTypeId();
        Map<Id, NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryMap = new Map<Id, NSP_Sub_Plan_Change_History__c>();
        
        // Loop to store filtered Sub Plans for SubPlanChangeHistory with Record Type Choice
        for(NSP_Sub_Plan_Change_History__c subPlanChangeHistory : SubPlanChangeHistoryList) {
            if(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c != null && subPlanChangeHistory.RecordTypeId == ChoiceRTId) {
                subPlanChangeHistoryMap.put(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c , subPlanChangeHistory);
            }
        }
        
        
        // Get all Active Sub Plan based on Effective date and update the respective fields
        for(NSP_Plan_SubPlan__c planSubPlan : [SELECT Id, NSP_Auto_Deferral__c, NSP_Status__c, NSP_Original_PE_Date__c, NSP_Plan_Effective_Date__c, NSP_Plan_Subplan_Relationship__c, NSP_Plan_Type__c FROM NSP_Plan_SubPlan__c WHERE NSP_Plan_Effective_Date__c <=: System.today() AND NSP_Status__c =: NSP_ServiceConstants.STATUS_ACTIVE AND Id =:subPlanChangeHistoryMap.keyset()]) { 
            
            if(subPlanChangeHistoryMap.containsKey(planSubPlan.Id)) {
                if(subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Auto_Deferral__c != null && planSubPlan.NSP_Auto_Deferral__c != subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Auto_Deferral__c) {
                    planSubPlan.NSP_Auto_Deferral__c = subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Auto_Deferral__c;
                }
                if(subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Status__c != null && planSubPlan.NSP_Status__c != subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Status__c) {
                    planSubPlan.NSP_Status__c = subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Status__c;
                }
                if(subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Effective_Date__c != null && planSubPlan.NSP_Plan_Effective_Date__c != subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Effective_Date__c) {
                    planSubPlan.NSP_Plan_Effective_Date__c = subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Effective_Date__c;
                }
                if(subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Type__c != null && planSubPlan.NSP_Plan_Type__c != subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Type__c) {
                    planSubPlan.NSP_Plan_Type__c = subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Type__c;
                }
                //Only Update below field in case of Insert 
                if(isInsert && subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Effective_Date__c != null && planSubPlan.NSP_Original_PE_Date__c != subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Effective_Date__c) {
                    planSubPlan.NSP_Original_PE_Date__c = subPlanChangeHistoryMap.get(planSubPlan.Id).NSP_Plan_Effective_Date__c;
                }
                planSubPlanListToBeUpdated.add(planSubPlan);                
            }   
        }
        
        //Trigger update for the Sub Plan
        if(planSubPlanListToBeUpdated.size() > 0) {
            // DML to update Sub Plan
            Database.SaveResult[] srList = Database.update(planSubPlanListToBeUpdated, false);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                         NSP_ErrorLogHandler.logSaveException('NSP_SubPlanChangeHistoryTriggerHelper', 'planSubPlanListToBeUpdated', err.getMessage());
                    }
                }
            }
        }
    }
}