/**
* @description  :  Batch Class to sync Sub Plan fields from SubPlanChangeHistory to Active Sub Plan of Type WO.
* @date 09/08/2022
* Author : Virendra Kumar
* Name : NSP_SubPlanChangeHistoryBatch
* Last Modified Name : Prakash Jada
* Last Modified Description: Implemented the killer switch to stop the execution of old logic. Included more fields for data update.
*/
global class NSP_SubPlanChangeHistoryBatch implements Database.Batchable<sObject> , Schedulable {
    
    /***********************************************************************************************
    * MethodName: start
    * Description : Get All Sub Plan Change history record with Active Sub Plan of Type WO and Effective Date should be less than or equal to today.
    * Params:       Database.BatchableContext bc
    * ********************************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                Id, NSP_Auto_Deferral__c, NSP_Status__c, NSP_Plan_Effective_Date__c,
                NSP_Plan_Subplan_Relationship__c, NSP_Plan_Type__c,
                Auto_Enroll_Effective_Date__c, Auto_Escalate__c, Escalation_Max__c, Is_QACA__c, Is_Mandatory__c,
                Allows_LT_Employer_Contributions__c, LTPT_Effective_Date__c, LTPT_Term_Date__c, Exemption_Type__c, Exemption_Date__c,
                NSP_Plan_Subplan_Relationship__r.Id, NSP_Plan_Subplan_Relationship__r.NSP_Auto_Deferral__c,
                NSP_Plan_Subplan_Relationship__r.NSP_Status__c, NSP_Plan_Subplan_Relationship__r.NSP_Plan_Effective_Date__c,
                NSP_Plan_Subplan_Relationship__r.NSP_Original_PE_Date__c, NSP_Plan_Subplan_Relationship__r.NSP_Plan_Type__c,
                NSP_Plan_Subplan_Relationship__r.Auto_Enroll_Effective_Date__c, NSP_Plan_Subplan_Relationship__r.Auto_Escalate__c,
                NSP_Plan_Subplan_Relationship__r.Escallation_Max__c, NSP_Plan_Subplan_Relationship__r.Is_QACA__c,
                NSP_Plan_Subplan_Relationship__r.Is_Mandatory__c, NSP_Plan_Subplan_Relationship__r.Allows_LT_Employer_Contributions__c,
                NSP_Plan_Subplan_Relationship__r.LTPT_Effective_Date__c, NSP_Plan_Subplan_Relationship__r.LTPT_Term_Date__c,
                NSP_Plan_Subplan_Relationship__r.Exemption_Type__c, NSP_Plan_Subplan_Relationship__r.Exemption_Date__c
                FROM NSP_Sub_Plan_Change_History__c
                WHERE (
                    ( RecordType.DeveloperName = :NSP_ServiceConstants.WO_RT_NAME )
                    AND ( NSP_Plan_Effective_Date__c <= TODAY )
                )
                ORDER BY CREATEDDATE DESC
            ]
        ); 
    }
    
    /***********************************************************************************************
    * MethodName: execute
    * Description : Sync Sub Plan fields from Sub Plan history.
    * Params:       Database.BatchableContext bc, List<NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryList
    * ********************************************************************************************/ 
    global Void execute(Database.BatchableContext bc, List<NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryList) { 
        // Getting the custom setting record to excute the killer logic
        Sub_Plan_Change_History_Batch_Setting__c subPlanHistoryBatchSetting = Sub_Plan_Change_History_Batch_Setting__c.getInstance(UserInfo.getUserId());
        if(subPlanHistoryBatchSetting != null)
        {
            // Activate the killer switch to execute the new logic
            if(subPlanHistoryBatchSetting.Killer_Switch__c)
            {
                Map<Id, NSP_Plan_SubPlan__c> planSubPlanToBeUpdated = new Map<Id, NSP_Plan_SubPlan__c>();
                
                for ( NSP_Sub_Plan_Change_History__c subPlanChangeHistory : subPlanChangeHistoryList) {
                    // Condition to check if the Map already has the Sub Plan ID
                    if(!planSubPlanToBeUpdated.containsKey(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c))
                    {
                        Boolean isModified = false;
                        NSP_Plan_SubPlan__c planSubPlan = new NSP_Plan_SubPlan__c();
                        if ( subPlanChangeHistory.NSP_Auto_Deferral__c != null
                            && subPlanChangeHistory.NSP_Auto_Deferral__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Auto_Deferral__c
                           )
                        {
                            planSubPlan.NSP_Auto_Deferral__c = subPlanChangeHistory.NSP_Auto_Deferral__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.NSP_Status__c != null
                            && subPlanChangeHistory.NSP_Status__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Status__c
                           )
                        {
                            planSubPlan.NSP_Status__c = subPlanChangeHistory.NSP_Status__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.NSP_Plan_Effective_Date__c != null
                            && subPlanChangeHistory.NSP_Plan_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Plan_Effective_Date__c
                           )
                        {
                            planSubPlan.NSP_Plan_Effective_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.NSP_Plan_Type__c != null
                            && subPlanChangeHistory.NSP_Plan_Type__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Plan_Type__c
                           )
                        {
                            planSubPlan.NSP_Plan_Type__c = subPlanChangeHistory.NSP_Plan_Type__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.NSP_Plan_Effective_Date__c != null
                            && subPlanChangeHistory.NSP_Plan_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Original_PE_Date__c
                           )
                        {
                            planSubPlan.NSP_Original_PE_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Auto_Enroll_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Auto_Enroll_Effective_Date__c )
                        {
                            planSubPlan.Auto_Enroll_Effective_Date__c = subPlanChangeHistory.Auto_Enroll_Effective_Date__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Auto_Escalate__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Auto_Escalate__c )
                        {
                            planSubPlan.Auto_Escalate__c = subPlanChangeHistory.Auto_Escalate__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Escalation_Max__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Escallation_Max__c )
                        {
                            planSubPlan.Escallation_Max__c = subPlanChangeHistory.Escalation_Max__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Is_QACA__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Is_QACA__c )
                        {
                            planSubPlan.Is_QACA__c = subPlanChangeHistory.Is_QACA__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Is_Mandatory__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Is_Mandatory__c )
                        {
                            planSubPlan.Is_Mandatory__c = subPlanChangeHistory.Is_Mandatory__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Allows_LT_Employer_Contributions__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Allows_LT_Employer_Contributions__c )
                        {
                            planSubPlan.Allows_LT_Employer_Contributions__c = subPlanChangeHistory.Allows_LT_Employer_Contributions__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.LTPT_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.LTPT_Effective_Date__c )
                        {
                            planSubPlan.LTPT_Effective_Date__c = subPlanChangeHistory.LTPT_Effective_Date__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.LTPT_Term_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.LTPT_Term_Date__c )
                        {
                            planSubPlan.LTPT_Term_Date__c = subPlanChangeHistory.LTPT_Term_Date__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Exemption_Type__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Exemption_Type__c )
                        {
                            planSubPlan.Exemption_Type__c = subPlanChangeHistory.Exemption_Type__c;
                            isModified = true;
                        }
                        if ( subPlanChangeHistory.Exemption_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Exemption_Date__c )
                        {
                            planSubPlan.Exemption_Date__c = subPlanChangeHistory.Exemption_Date__c;
                            isModified = true;
                        }
                        // Condition to check for the Sub Plan Record Changes 
                        if ( isModified ) {
                            planSubPlan.Id = subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c;
                            planSubPlanToBeUpdated.put( planSubPlan.Id , planSubPlan );
                        }
                    }// UNIQUE SUB PLAN LOGIC END - SUB PLAN MAP TO HAVE THE DATA FROM LATEST HISTORY RECORD
                }
                // Condition to check for the Map before performing the DML
                if ( planSubPlanToBeUpdated.size() > 0 ) {
                    Database.SaveResult[] srList = Database.update( planSubPlanToBeUpdated.values() , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_SubPlanChangeHistoryBatch.class.getName() ,
                        'execute' ,
                        srList
                    );
                }
            }// KILLER SWITCH END
            else
            {
                List<NSP_Plan_SubPlan__c> planSubPlanToBeUpdated = new List<NSP_Plan_SubPlan__c>();
                Map<Id, NSP_Sub_Plan_Change_History__c> subPlanHistBySubPlan = new map<Id,NSP_Sub_Plan_Change_History__c>(); 
                
                for(NSP_Sub_Plan_Change_History__c subPlanHis : subPlanChangeHistoryList) {
                    if(subPlanHistBySubPlan.containsKey(subPlanHis.NSP_Plan_Subplan_Relationship__c)) {
                        continue;
                    }else {
                        subPlanHistBySubPlan.put(subPlanHis.NSP_Plan_Subplan_Relationship__c, subPlanHis);
                    }            
                }
                Map<Id, NSP_Plan_SubPlan__c> existingSubPlan = new  Map<Id, NSP_Plan_SubPlan__c>([SELECT Id, NSP_Auto_Deferral__c,NSP_Status__c, NSP_Plan_Effective_Date__c, NSP_Original_PE_Date__c, NSP_Plan_Type__c FROM NSP_Plan_SubPlan__c WHERE Id =: subPlanHistBySubPlan.keyset()]);
                
                for(NSP_Sub_Plan_Change_History__c subPlanChangeHistory : subPlanHistBySubPlan.values()){
                    
                    //sync the sub plan field if those are not null
                    NSP_Plan_SubPlan__c planSubPlan = new NSP_Plan_SubPlan__c();
                    planSubPlan.Id = existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Id;
                    
                    if(subPlanChangeHistory.NSP_Auto_Deferral__c != null && existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).NSP_Auto_Deferral__c != subPlanChangeHistory.NSP_Auto_Deferral__c) {
                        planSubPlan.NSP_Auto_Deferral__c = subPlanChangeHistory.NSP_Auto_Deferral__c;
                    }
                    
                    if(subPlanChangeHistory.NSP_Status__c != null && existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).NSP_Status__c != subPlanChangeHistory.NSP_Status__c) {
                        planSubPlan.NSP_Status__c = subPlanChangeHistory.NSP_Status__c;
                    }
                    
                    if(subPlanChangeHistory.NSP_Plan_Effective_Date__c != null && existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).NSP_Plan_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Effective_Date__c) {
                        planSubPlan.NSP_Plan_Effective_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
                    }
                    
                    if(subPlanChangeHistory.NSP_Plan_Type__c != null && existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).NSP_Plan_Type__c != subPlanChangeHistory.NSP_Plan_Type__c) {
                        planSubPlan.NSP_Plan_Type__c = subPlanChangeHistory.NSP_Plan_Type__c;
                    }
                    
                    if(subPlanChangeHistory.NSP_Plan_Effective_Date__c != null && existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).NSP_Original_PE_Date__c != subPlanChangeHistory.NSP_Plan_Effective_Date__c) {
                        planSubPlan.NSP_Original_PE_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
                    }
                    
                    planSubPlanToBeUpdated.add(planSubPlan);                
                }
                if(planSubPlanToBeUpdated.size() > 0) {
                    // DML to update Sub Plan
                    Database.SaveResult[] srList = Database.update(planSubPlanToBeUpdated, false);
                    
                    // Iterate through each returned result
                    for (Database.SaveResult sr : srList) {
                        if (sr.isSuccess()) {
                            continue;
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                
                                NSP_ErrorLogHandler.logSaveException('NSP_SubPlanChangeHistoryTriggerHelper', 'planSubPlanToBeUpdated', err.getMessage());
                            }
                        }
                    }
                } 
            }
        }
    }
    
    /***********************************************************************************************
    * MethodName: finish
    * Description : 
    * Params:       Database.BatchableContext bc
    * ********************************************************************************************/ 
    global Void finish(Database.BatchableContext bc) {
    }
    
    /***********************************************************************************************
    * MethodName: execute
    * Description : To Schedule NSP_SubPlanChangeHistoryBatch Class
    * Params:       Database.SchedulableContext bc
    * ********************************************************************************************/ 
    global Void execute(System.SchedulableContext Sc) {
        Database.executeBatch(new NSP_SubPlanChangeHistoryBatch(), 200);
    }
}