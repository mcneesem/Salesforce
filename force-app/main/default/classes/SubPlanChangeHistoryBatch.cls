/**
* Author				: Prakash Jada
* Created Date 			: Oct 21, 2024
* Description			: Update Sup Plan Records from Sub Plan History Records
* Azure Story 			: ADO-314621
* Last Modified Date 	: 
* Last Modified By: 
* Test Coverage         : 91%
*/
global class SubPlanChangeHistoryBatch implements Database.Batchable<sObject> , Schedulable
{
    /***********************************************************************************************
	* MethodName: start
	* Params	: Database.BatchableContext bc
	* ********************************************************************************************/ 
    global Database.QueryLocator start(Database.BatchableContext bc) 
    {
        return Database.getQueryLocator(
            [
                SELECT
                Id , NSP_Auto_Deferral__c , NSP_Status__c , NSP_Plan_Effective_Date__c ,
                NSP_Original_PE_Date__c , NSP_Plan_Type__c , Auto_Enroll_Effective_Date__c ,
                Auto_Escalate__c , Escallation_Max__c , Is_QACA__c , Is_Mandatory__c ,
                Allows_LT_Employer_Contributions__c , LTPT_Effective_Date__c , LTPT_Term_Date__c ,
                Exemption_Type__c , Exemption_Date__c ,
                (
                    SELECT
                    Id , NSP_Auto_Deferral__c , NSP_Status__c , NSP_Plan_Effective_Date__c ,
                    NSP_Plan_Subplan_Relationship__c , NSP_Plan_Type__c , Auto_Enroll_Effective_Date__c ,
                    Auto_Escalate__c , Escalation_Max__c , Is_QACA__c , Is_Mandatory__c ,
                    Allows_LT_Employer_Contributions__c , LTPT_Effective_Date__c ,
                    LTPT_Term_Date__c , Exemption_Type__c , Exemption_Date__c
                    FROM Sub_Plan_Change_Historys__r
                    WHERE ( NSP_Plan_Effective_Date__c <= TODAY )
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                )
                FROM NSP_Plan_SubPlan__c
                WHERE (
                    Id IN (
                        SELECT NSP_Plan_Subplan_Relationship__c
                        FROM NSP_Sub_Plan_Change_History__c
                        WHERE ( NSP_Plan_Effective_Date__c <= TODAY )
                    )
                )
            ]
        ); 
    }
    
    /***********************************************************************************************
	* MethodName: execute
	* Description : Sync Sub Plan fields from Sub Plan history.
	* Params:       Database.BatchableContext bc, List<NSP_Plan_SubPlan__c> Sub Plan Records
	* ********************************************************************************************/ 
    global Void execute(Database.BatchableContext bc, List<NSP_Plan_SubPlan__c> subPlanChangeList)
    { 
        
        Map<Id, NSP_Plan_SubPlan__c> planSubPlanToBeUpdatedMap = new Map<Id, NSP_Plan_SubPlan__c>();
        
        if(subPlanChangeList?.size() > 0)
        {
            for(NSP_Plan_SubPlan__c subPlanChange : subPlanChangeList)
            { 
                NSP_Sub_Plan_Change_History__c subPlanChangeHistory =  null;
                
                if(subPlanChange.Sub_Plan_Change_Historys__r?.size() > 0)
                {
                    subPlanChangeHistory = subPlanChange.Sub_Plan_Change_Historys__r;
                }
                
                if(subPlanChangeHistory <> null)
                {
                    NSP_Plan_SubPlan__c modifiedSubPlan = setSubPlanFields(subPlanChange, subPlanChangeHistory); // line to modify
                    
                    if(modifiedSubPlan <> null)
                    {
                        planSubPlanToBeUpdatedMap.put(modifiedSubPlan.Id, modifiedSubPlan); 
                    }
                }
            }
            
            if(planSubPlanToBeUpdatedMap?.size() > 0) 
            {
                // DML to update Sub Plan
                Database.SaveResult[] srList = Database.update(planSubPlanToBeUpdatedMap.values(), false);
                
                // Iterate through each returned result
                for (Database.SaveResult sr : srList)
                {
                    if (!sr.isSuccess()) 
                    {
                        // Operation failed, so get all errors                
                        for(Database.Error err : sr.getErrors()) 
                        {
                            
                            NSP_ErrorLogHandler.logSaveException(
                                'NSP_SubPlanChangeHistoryTriggerHelper', 
                                'planSubPlanToBeUpdated', 
                                err.getMessage()
                            );
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
	* Description : To Schedule SubPlanChangeHistoryBatch Class
	* Params:       Database.SchedulableContext bc
	* ********************************************************************************************/ 
    global Void execute(System.SchedulableContext Sc) {
        Database.executeBatch(new SubPlanChangeHistoryBatch(), 200);
    }
    
   /***********************************************************************************************
	* MethodName	: execute
	* Description 	: Mapping the fields
	* Params		:       NSP_Plan_SubPlan__c, NSP_Sub_Plan_Change_History__c
	* ********************************************************************************************/
    public static NSP_Plan_SubPlan__c setSubPlanFields(NSP_Plan_SubPlan__c subPlan, NSP_Sub_Plan_Change_History__c subPlanChangeHistory)
    {
        
        //sync the sub plan field if those are not null
        NSP_Plan_SubPlan__c planSubPlan = new NSP_Plan_SubPlan__c();
        Boolean isModified = false;
        
        planSubPlan.Id = subPlan.Id;
        if(subPlanChangeHistory.NSP_Auto_Deferral__c != null && subPlanChangeHistory.NSP_Auto_Deferral__c != subPlan.NSP_Auto_Deferral__c) 
        {
            planSubPlan.NSP_Auto_Deferral__c = subPlanChangeHistory.NSP_Auto_Deferral__c;
            isModified = true;
        }
        
        if(subPlanChangeHistory.NSP_Status__c != null && subPlanChangeHistory.NSP_Status__c != subPlan.NSP_Status__c) 
        {
            planSubPlan.NSP_Status__c = subPlanChangeHistory.NSP_Status__c;
            isModified = true;
        }
        
        if(subPlanChangeHistory.NSP_Plan_Effective_Date__c != null && subPlanChangeHistory.NSP_Plan_Effective_Date__c != subPlan.NSP_Plan_Effective_Date__c) 
        {
            planSubPlan.NSP_Plan_Effective_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
            isModified = true;
        }
        
        if(subPlanChangeHistory.NSP_Plan_Type__c != null && subPlanChangeHistory.NSP_Plan_Type__c != subPlan.NSP_Plan_Type__c) 
        {
            planSubPlan.NSP_Plan_Type__c = subPlanChangeHistory.NSP_Plan_Type__c;
            isModified = true;
        }
        
        if(subPlanChangeHistory.NSP_Plan_Effective_Date__c != null && subPlanChangeHistory.NSP_Plan_Effective_Date__c != subPlan.NSP_Original_PE_Date__c) 
        {
            planSubPlan.NSP_Original_PE_Date__c = subPlanChangeHistory.NSP_Plan_Effective_Date__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Auto_Enroll_Effective_Date__c != null && subPlanChangeHistory.Auto_Enroll_Effective_Date__c != subPlan.Auto_Enroll_Effective_Date__c )
        {
            planSubPlan.Auto_Enroll_Effective_Date__c = subPlanChangeHistory.Auto_Enroll_Effective_Date__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Auto_Escalate__c != null && subPlanChangeHistory.Auto_Escalate__c != subPlan.Auto_Escalate__c )
        {
            planSubPlan.Auto_Escalate__c = subPlanChangeHistory.Auto_Escalate__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Escalation_Max__c != null && subPlanChangeHistory.Escalation_Max__c != subPlan.Escallation_Max__c )
        {
            planSubPlan.Escallation_Max__c = subPlanChangeHistory.Escalation_Max__c;
            isModified = true;
        }
        if (subPlanChangeHistory.Is_QACA__c != null && subPlanChangeHistory.Is_QACA__c != subPlan.Is_QACA__c )
        {
            planSubPlan.Is_QACA__c = subPlanChangeHistory.Is_QACA__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Is_Mandatory__c != null && subPlanChangeHistory.Is_Mandatory__c != subPlan.Is_Mandatory__c )
        {
            planSubPlan.Is_Mandatory__c = subPlanChangeHistory.Is_Mandatory__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Allows_LT_Employer_Contributions__c != null && subPlanChangeHistory.Allows_LT_Employer_Contributions__c != subPlan.Allows_LT_Employer_Contributions__c )
        {
            planSubPlan.Allows_LT_Employer_Contributions__c = subPlanChangeHistory.Allows_LT_Employer_Contributions__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.LTPT_Effective_Date__c != null && subPlanChangeHistory.LTPT_Effective_Date__c != subPlan.LTPT_Effective_Date__c )
        {
            planSubPlan.LTPT_Effective_Date__c = subPlanChangeHistory.LTPT_Effective_Date__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.LTPT_Term_Date__c != null && subPlanChangeHistory.LTPT_Term_Date__c != subPlan.LTPT_Term_Date__c )
        {
            planSubPlan.LTPT_Term_Date__c = subPlanChangeHistory.LTPT_Term_Date__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Exemption_Type__c != null && subPlanChangeHistory.Exemption_Type__c != subPlan.Exemption_Type__c )
        {
            planSubPlan.Exemption_Type__c = subPlanChangeHistory.Exemption_Type__c;
            isModified = true;
        }
        
        if (subPlanChangeHistory.Exemption_Date__c != null && subPlanChangeHistory.Exemption_Date__c != subPlan.Exemption_Date__c )
        {
            planSubPlan.Exemption_Date__c = subPlanChangeHistory.Exemption_Date__c;
            isModified = true;
        }
        
        if(isModified)
        {
            return planSubPlan;
        }
        
        return null;
    }
}