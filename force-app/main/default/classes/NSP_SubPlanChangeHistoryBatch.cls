//
// @description  :  Batch Class to sync Sub Plan fields from SubPlanChangeHistory to Active Sub Plan of Type WO.
// @date 09/08/2022
// Author : Virendra Kumar
// Name : NSP_SubPlanChangeHistoryBatch
//
global class NSP_SubPlanChangeHistoryBatch implements Database.Batchable<sObject> , Schedulable {

    //
    // MethodName: start
    // Description : Get All Sub Plan Change history record with Active Sub Plan of Type WO and Effective Date should be less than or equal to today.
    // Params: Database.BatchableContext bc
    //
    global Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id, NSP_Auto_Deferral__c, NSP_Status__c, NSP_Plan_Effective_Date__c,
                    NSP_Plan_Subplan_Relationship__c, NSP_Plan_Type__c,
                    Auto_Enroll_Effective_Date__c, Auto_Escalate__c, Escalation_Max__c, Is_QACA__c, Is_Mandatory__c,
                    Allows_LT_Employer_Contributions__c, LTPT_Effective_Date__c, LTPT_Term_Date__c, Exception_Type__c, Exception_Date__c,
                    NSP_Plan_Subplan_Relationship__r.Id, NSP_Plan_Subplan_Relationship__r.NSP_Auto_Deferral__c,
                    NSP_Plan_Subplan_Relationship__r.NSP_Status__c, NSP_Plan_Subplan_Relationship__r.NSP_Plan_Effective_Date__c,
                    NSP_Plan_Subplan_Relationship__r.NSP_Original_PE_Date__c, NSP_Plan_Subplan_Relationship__r.NSP_Plan_Type__c,
                    NSP_Plan_Subplan_Relationship__r.Auto_Enroll_Effective_Date__c, NSP_Plan_Subplan_Relationship__r.Auto_Escalate__c,
                    NSP_Plan_Subplan_Relationship__r.Escallation_Max__c, NSP_Plan_Subplan_Relationship__r.Is_QACA__c,
                    NSP_Plan_Subplan_Relationship__r.Is_Mandatory__c, NSP_Plan_Subplan_Relationship__r.Allows_LT_Employer_Contributions__c,
                    NSP_Plan_Subplan_Relationship__r.LTPT_Effective_Date__c, NSP_Plan_Subplan_Relationship__r.LTPT_Term_Date__c,
                    NSP_Plan_Subplan_Relationship__r.Exception_Type__c, NSP_Plan_Subplan_Relationship__r.Exception_Date__c
                FROM NSP_Sub_Plan_Change_History__c
                WHERE (
                    ( RecordType.DeveloperName = :NSP_ServiceConstants.WO_RT_NAME )
                    AND ( NSP_Plan_Effective_Date__c <= TODAY )
                )
                ORDER BY CREATEDDATE DESC
            ]
        );
    }

    //
    // MethodName: execute
    // Description : Sync Sub Plan fields from Sub Plan history.
    // Params: Database.BatchableContext bc, List<NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryList
    //
    global void execute( Database.BatchableContext bc , List<NSP_Sub_Plan_Change_History__c> subPlanChangeHistoryList ) {
        Map<Id,NSP_Plan_SubPlan__c> planSubPlanToBeUpdated = new Map<Id,NSP_Plan_SubPlan__c>();
        for ( NSP_Sub_Plan_Change_History__c subPlanChangeHistory : subPlanChangeHistoryList) {
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
            if ( subPlanChangeHistory.Auto_Enroll_Effective_Date__c != null
                && subPlanChangeHistory.Auto_Enroll_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Auto_Enroll_Effective_Date__c
                )
            {
                planSubPlan.Auto_Enroll_Effective_Date__c = subPlanChangeHistory.Auto_Enroll_Effective_Date__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Auto_Escalate__c != null
                && subPlanChangeHistory.Auto_Escalate__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Auto_Escalate__c
                )
            {
                planSubPlan.Auto_Escalate__c = subPlanChangeHistory.Auto_Escalate__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Escalation_Max__c != null
                && subPlanChangeHistory.Escalation_Max__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Escallation_Max__c
                )
            {
                planSubPlan.Escallation_Max__c = subPlanChangeHistory.Escalation_Max__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Is_QACA__c != null
                && subPlanChangeHistory.Is_QACA__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Is_QACA__c
                )
            {
                planSubPlan.Is_QACA__c = subPlanChangeHistory.Is_QACA__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Is_Mandatory__c != null
                && subPlanChangeHistory.Is_Mandatory__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Is_Mandatory__c
                )
            {
                planSubPlan.Is_Mandatory__c = subPlanChangeHistory.Is_Mandatory__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Allows_LT_Employer_Contributions__c != null
                && subPlanChangeHistory.Allows_LT_Employer_Contributions__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Allows_LT_Employer_Contributions__c
                )
            {
                planSubPlan.Allows_LT_Employer_Contributions__c = subPlanChangeHistory.Allows_LT_Employer_Contributions__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.LTPT_Effective_Date__c != null
                && subPlanChangeHistory.LTPT_Effective_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.LTPT_Effective_Date__c
                )
            {
                planSubPlan.LTPT_Effective_Date__c = subPlanChangeHistory.LTPT_Effective_Date__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.LTPT_Term_Date__c != null
                && subPlanChangeHistory.LTPT_Term_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.LTPT_Term_Date__c
                )
            {
                planSubPlan.LTPT_Term_Date__c = subPlanChangeHistory.LTPT_Term_Date__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Exception_Type__c != null
                && subPlanChangeHistory.Exception_Type__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Exception_Type__c
                )
            {
                planSubPlan.Exception_Type__c = subPlanChangeHistory.Exception_Type__c;
                isModified = true;
            }
            if ( subPlanChangeHistory.Exception_Date__c != null
                && subPlanChangeHistory.Exception_Date__c != subPlanChangeHistory.NSP_Plan_Subplan_Relationship__r.Exception_Date__c
                )
            {
                planSubPlan.Exception_Date__c = subPlanChangeHistory.Exception_Date__c;
                isModified = true;
            }
            if ( isModified ) {
                planSubPlan.Id = subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c;
                planSubPlanToBeUpdated.put( subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c , planSubPlan );
            }
        }
        if ( planSubPlanToBeUpdated.size() > 0 ) {
            Database.SaveResult[] srList = Database.update( planSubPlanToBeUpdated.values() , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubPlanChangeHistoryBatch.class.getName() ,
                'execute' ,
                srList
            );
        }
    }

    //
    // MethodName: finish
    // Description :
    // Params: Database.BatchableContext bc
    //
    global void finish( Database.BatchableContext bc ) {
    }

    //
    // MethodName: execute
    // Description : To Schedule NSP_SubPlanChangeHistoryBatch Class
    // Params: Database.SchedulableContext bc
    //
    global void execute( System.SchedulableContext sc ) {
        Database.executeBatch( new NSP_SubPlanChangeHistoryBatch() , 200 );
    }

}