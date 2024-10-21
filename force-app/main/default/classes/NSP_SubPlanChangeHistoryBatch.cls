/**
* @description  :  Batch Class to sync Sub Plan fields from SubPlanChangeHistory to Active Sub Plan of Type WO.
* @date 09/08/2022
* Author : Virendra Kumar
* Name : NSP_SubPlanChangeHistoryBatch
*/
global class NSP_SubPlanChangeHistoryBatch implements Database.Batchable<sObject> , Schedulable {
    private static final string[] RECORD_TYPES = Label.Sub_Plan_Change_History_Batch_Record_Types.split(',');
    

    /***********************************************************************************************
    * MethodName: start
    * Description : Get All Sub Plan Change history record with Active Sub Plan of Type WO and Effective Date should be less than or equal to today.
    * Params:       Database.BatchableContext bc
    * ********************************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id, NSP_Auto_Deferral__c, NSP_Status__c, NSP_Plan_Effective_Date__c, 
                                         NSP_Plan_Subplan_Relationship__c, NSP_Plan_Type__c,
                                         Auto_Enroll_Effective_Date__c, Auto_Escalate__c, Escalation_Max__c, Is_QACA__c, Is_Mandatory__c,
                                         Allows_LT_Employer_Contributions__c, LTPT_Effective_Date__c, LTPT_Term_Date__c, 
                                         Exemption_Type__c, Exemption_Date__c,
                                         NSP_Plan_Subplan_Relationship__r.NSP_Auto_Deferral__c, NSP_Plan_Subplan_Relationship__r.NSP_Status__c, 
                                         NSP_Plan_Subplan_Relationship__r.NSP_Plan_Effective_Date__c, NSP_Plan_Subplan_Relationship__r.NSP_Original_PE_Date__c, 
                                         NSP_Plan_Subplan_Relationship__r.NSP_Plan_Type__c, NSP_Plan_Subplan_Relationship__r.Auto_Enroll_Effective_Date__c, 
                                         NSP_Plan_Subplan_Relationship__r.Auto_Escalate__c, NSP_Plan_Subplan_Relationship__r.Escallation_Max__c, 
                                         NSP_Plan_Subplan_Relationship__r.Is_QACA__c, NSP_Plan_Subplan_Relationship__r.Is_Mandatory__c, 
                                         NSP_Plan_Subplan_Relationship__r.Allows_LT_Employer_Contributions__c, 
                                         NSP_Plan_Subplan_Relationship__r.LTPT_Effective_Date__c, NSP_Plan_Subplan_Relationship__r.LTPT_Term_Date__c, 
                                         NSP_Plan_Subplan_Relationship__r.Exemption_Type__c, NSP_Plan_Subplan_Relationship__r.Exemption_Date__c 
                                         FROM 
                                         NSP_Sub_Plan_Change_History__c WHERE RecordType.DeveloperName  =:RECORD_TYPES AND                                          
                                         NSP_Plan_Effective_Date__c <= TODAY ORDER BY CREATEDDATE DESC]); 
    }
    
    /***********************************************************************************************
    * MethodName: execute
    * Description : Sync Sub Plan fields from Sub Plan history.
    * Params:       Database.BatchableContext bc, List<NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryList
    * ********************************************************************************************/ 
    global Void execute(Database.BatchableContext bc, List<NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryList) { 
        
        Map<Id, NSP_Plan_SubPlan__c> planSubPlanToBeUpdatedMap = new Map<Id, NSP_Plan_SubPlan__c>();
        
        Sub_Plan_Change_History_Batch_Setting__c subPlanHistoryBatchSetting = Sub_Plan_Change_History_Batch_Setting__c.getInstance(UserInfo.getUserId());
        
        for(NSP_Sub_Plan_Change_History__c subPlanChangeHistory : subPlanChangeHistoryList){
            
            if(!planSubPlanToBeUpdatedMap.containsKey(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c))
            {
                //sync the sub plan field if those are not null
                NSP_Plan_SubPlan__c planSubPlan = new NSP_Plan_SubPlan__c();
                planSubPlan.Id = subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c;
                
                if(subPlanChangeHistory.NSP_Auto_Deferral__c != null && subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Auto_Deferral__c != subPlanChangeHistory.NSP_Auto_Deferral__c) {
                    planSubPlan.NSP_Auto_Deferral__c = subPlanChangeHistory.NSP_Auto_Deferral__c;
                }
                
                if(subPlanChangeHistory.NSP_Status__c != null && subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Status__c != subPlanChangeHistory.NSP_Status__c) {
                    planSubPlan.NSP_Status__c = subPlanChangeHistory.NSP_Status__c;
                }
                
                if(subPlanChangeHistory.NSP_Plan_Effective_Date__c != null && subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Plan_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Effective_Date__c) {
                    planSubPlan.NSP_Plan_Effective_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
                }
                
                if(subPlanChangeHistory.NSP_Plan_Type__c != null && subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Plan_Type__c != subPlanChangeHistory.NSP_Plan_Type__c) {
                    planSubPlan.NSP_Plan_Type__c = subPlanChangeHistory.NSP_Plan_Type__c;
                }
                
                if(subPlanChangeHistory.NSP_Plan_Effective_Date__c != null && subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.NSP_Original_PE_Date__c != subPlanChangeHistory.NSP_Plan_Effective_Date__c) {
                    planSubPlan.NSP_Original_PE_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
                }
                
                // New field changes
                if(subPlanHistoryBatchSetting <> null)
                {
                    if(subPlanHistoryBatchSetting.IsEnabledRetFields__c)
                    {
                        if ( subPlanChangeHistory.Auto_Enroll_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Auto_Enroll_Effective_Date__c )
                        {
                            planSubPlan.Auto_Enroll_Effective_Date__c = subPlanChangeHistory.Auto_Enroll_Effective_Date__c;
                            
                        }
                        if ( subPlanChangeHistory.Auto_Escalate__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Auto_Escalate__c )
                        {
                            planSubPlan.Auto_Escalate__c = subPlanChangeHistory.Auto_Escalate__c;
                            
                        }
                        if ( subPlanChangeHistory.Escalation_Max__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Escallation_Max__c )
                        {
                            planSubPlan.Escallation_Max__c = subPlanChangeHistory.Escalation_Max__c;
                            
                        }
                        if ( subPlanChangeHistory.Is_QACA__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Is_QACA__c )
                        {
                            planSubPlan.Is_QACA__c = subPlanChangeHistory.Is_QACA__c;
                            
                        }
                        if ( subPlanChangeHistory.Is_Mandatory__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Is_Mandatory__c )
                        {
                            planSubPlan.Is_Mandatory__c = subPlanChangeHistory.Is_Mandatory__c;
                            
                        }
                        if ( subPlanChangeHistory.Allows_LT_Employer_Contributions__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Allows_LT_Employer_Contributions__c )
                        {
                            planSubPlan.Allows_LT_Employer_Contributions__c = subPlanChangeHistory.Allows_LT_Employer_Contributions__c;
                            
                        }
                        if ( subPlanChangeHistory.LTPT_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.LTPT_Effective_Date__c )
                        {
                            planSubPlan.LTPT_Effective_Date__c = subPlanChangeHistory.LTPT_Effective_Date__c;
                            
                        }
                        if ( subPlanChangeHistory.LTPT_Term_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.LTPT_Term_Date__c )
                        {
                            planSubPlan.LTPT_Term_Date__c = subPlanChangeHistory.LTPT_Term_Date__c;
                            
                        }
                        if ( subPlanChangeHistory.Exemption_Type__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Exemption_Type__c )
                        {
                            planSubPlan.Exemption_Type__c = subPlanChangeHistory.Exemption_Type__c;
                            
                        }
                        if ( subPlanChangeHistory.Exemption_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Exemption_Date__c )
                        {
                            planSubPlan.Exemption_Date__c = subPlanChangeHistory.Exemption_Date__c;
                            
                        }
                    }
                }
                
                planSubPlanToBeUpdatedMap.put(planSubPlan.Id, planSubPlan);  
            }
            
        }
        if(planSubPlanToBeUpdatedMap.size() > 0) {
          // DML to update Sub Plan
            Database.SaveResult[] srList = Database.update(planSubPlanToBeUpdatedMap.values(), false);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        
                        NSP_ErrorLogHandler.logSaveException('NSP_SubPlanChangeHistoryTriggerHelper', 'planSubPlanToBeUpdated', err.getMessage());
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