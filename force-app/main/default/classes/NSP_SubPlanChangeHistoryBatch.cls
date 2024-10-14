/**
* @description  :  Batch Class to sync Sub Plan fields from SubPlanChangeHistory to Active Sub Plan of Type WO.
* @date 09/08/2022
* Author : Virendra Kumar
* Name : NSP_SubPlanChangeHistoryBatch
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
                    Id , NSP_Auto_Deferral__c , NSP_Status__c , NSP_Plan_Effective_Date__c ,
                    NSP_Plan_Subplan_Relationship__c , NSP_Plan_Type__c ,
                    Auto_Enroll_Effective_Date__c , Auto_Escalate__c , Escalation_Max__c ,
                    Is_QACA__c , Is_Mandatory__c , Allows_LT_Employer_Contributions__c ,
                    LTPT_Effective_Date__c , LTPT_Term_Date__c , Exemption_Type__c , Exemption_Date__c
                FROM NSP_Sub_Plan_Change_History__c
                WHERE (
                    RecordType.DeveloperName = :NSP_ServiceConstants.WO_RT_NAME
                    AND NSP_Plan_Effective_Date__c <= TODAY
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
        
        List<NSP_Plan_SubPlan__c> planSubPlanToBeUpdated = new List<NSP_Plan_SubPlan__c>();
        Map<Id, NSP_Sub_Plan_Change_History__c> subPlanHistBySubPlan = new map<Id,NSP_Sub_Plan_Change_History__c>(); 
        
        Boolean isEnabledRetFields = false;
        Sub_Plan_Change_History_Batch_Setting__c settings = Sub_Plan_Change_History_Batch_Setting__c.getInstance( UserInfo.getUserId() );
        if ( settings != null ) {
            isEnabledRetFields = settings.IsEnabledRetFields__c;
        }

        for(NSP_Sub_Plan_Change_History__c subPlanHis : subPlanChangeHistoryList) {
            if(subPlanHistBySubPlan.containsKey(subPlanHis.NSP_Plan_Subplan_Relationship__c)) {
                continue;
            } else {
                subPlanHistBySubPlan.put(subPlanHis.NSP_Plan_Subplan_Relationship__c, subPlanHis);
            }
        }
        Map<Id,NSP_Plan_SubPlan__c> existingSubPlan = new  Map<Id,NSP_Plan_SubPlan__c>(
            [
                SELECT
                    Id , NSP_Auto_Deferral__c , NSP_Status__c , NSP_Plan_Effective_Date__c ,
                    NSP_Original_PE_Date__c , NSP_Plan_Type__c , Auto_Enroll_Effective_Date__c ,
                    Auto_Escalate__c , Escallation_Max__c , Is_QACA__c , Is_Mandatory__c ,
                    Allows_LT_Employer_Contributions__c , LTPT_Effective_Date__c ,
                    LTPT_Term_Date__c , Exemption_Type__c , Exemption_Date__c
                FROM NSP_Plan_SubPlan__c
                WHERE ( Id = :subPlanHistBySubPlan.keyset() )
            ]
        );
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
            if ( isEnabledRetFields ) {
                if ( subPlanChangeHistory.Auto_Enroll_Effective_Date__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Auto_Enroll_Effective_Date__c ) {
                    planSubPlan.Auto_Enroll_Effective_Date__c = subPlanChangeHistory.Auto_Enroll_Effective_Date__c;
                }
                if ( subPlanChangeHistory.Auto_Escalate__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Auto_Escalate__c ) {
                    planSubPlan.Auto_Escalate__c = subPlanChangeHistory.Auto_Escalate__c;
                }
                if ( subPlanChangeHistory.Escalation_Max__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Escallation_Max__c ) {
                    planSubPlan.Escallation_Max__c = subPlanChangeHistory.Escalation_Max__c;
                }
                if ( subPlanChangeHistory.Is_QACA__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Is_QACA__c ) {
                    planSubPlan.Is_QACA__c = subPlanChangeHistory.Is_QACA__c;
                }
                if ( subPlanChangeHistory.Is_Mandatory__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Is_Mandatory__c ) {
                    planSubPlan.Is_Mandatory__c = subPlanChangeHistory.Is_Mandatory__c;
                }
                if ( subPlanChangeHistory.Allows_LT_Employer_Contributions__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Allows_LT_Employer_Contributions__c ) {
                    planSubPlan.Allows_LT_Employer_Contributions__c = subPlanChangeHistory.Allows_LT_Employer_Contributions__c;
                }
                if ( subPlanChangeHistory.LTPT_Effective_Date__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).LTPT_Effective_Date__c ) {
                    planSubPlan.LTPT_Effective_Date__c = subPlanChangeHistory.LTPT_Effective_Date__c;
                }
                if ( subPlanChangeHistory.LTPT_Term_Date__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).LTPT_Term_Date__c ) {
                    planSubPlan.LTPT_Term_Date__c = subPlanChangeHistory.LTPT_Term_Date__c;
                }
                if ( subPlanChangeHistory.Exemption_Type__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Exemption_Type__c ) {
                    planSubPlan.Exemption_Type__c = subPlanChangeHistory.Exemption_Type__c;
                }
                if ( subPlanChangeHistory.Exemption_Date__c != existingSubPlan.get(subPlanChangeHistory.NSP_Plan_Subplan_Relationship__c).Exemption_Date__c ) {
                    planSubPlan.Exemption_Date__c = subPlanChangeHistory.Exemption_Date__c;
                }
            }
            planSubPlanToBeUpdated.add( planSubPlan );
        }
        // Condition to check for the Map before performing the DML
        if ( !planSubPlanToBeUpdated.isEmpty() ) {
            Database.SaveResult[] results = Database.update( planSubPlanToBeUpdated , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubPlanChangeHistoryBatch.class.getName() ,
                'execute' ,
                results
            );
        }
    }

    /***********************************************************************************************
    * MethodName: finish
    * Description : 
    * Params:       Database.BatchableContext bc
    * ********************************************************************************************/ 
    global Void finish( Database.BatchableContext bc ) {
    }

    /***********************************************************************************************
    * MethodName: execute
    * Description : To Schedule NSP_SubPlanChangeHistoryBatch Class
    * Params:       Database.SchedulableContext bc
    * ********************************************************************************************/ 
    global Void execute( SchedulableContext sc ) {
        Database.executeBatch( new NSP_SubPlanChangeHistoryBatch() , 200 );
    }

}