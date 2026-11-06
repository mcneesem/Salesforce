public with sharing class NSP_ClientGoalsController {
    // test w/ NSP_ClientGoalTriggerHelper_Test (83%)

    // get all active goals from related account
    @AuraEnabled
    public static List<NSP_ClientGoal__c> getClientGoalsList( String rsapId ) {
        List<NSP_ClientGoal__c> clientGoalList = new List<NSP_ClientGoal__c>();
        try {
            NSP_ClientGoalsControllerWrapper wrapper = NSP_ClientGoalsController.getRSAP( rsapId );
            if ( wrapper.RSAPCompletedDate == null ) {
                clientGoalList = [
                    SELECT
                        Id ,
                        Name ,
                        NSP_Goal_Details__c ,
                        NSP_Goal_Type__c ,
                        NSP_Status__c ,
                        NSP_Date__c
                    FROM NSP_ClientGoal__c
                    WHERE (
                        ( NSP_Account__c = :wrapper.accRecordId )
                        AND ( NSP_Status__c = :NSP_ServiceConstants.ActiveClientGoal )
                    )
                ];
            }
            if ( wrapper.RSAPCompletedDate != null ) {
                clientGoalList = [
                    SELECT
                        Id ,
                        Name ,
                        NSP_Goal_Details__c ,
                        NSP_Goal_Type__c ,
                        NSP_Status__c ,
                        NSP_Date__c
                    FROM NSP_ClientGoal__c
                    WHERE (
                        ( NSP_Account__c = :wrapper.accRecordId )
                        AND ( NSP_Status__c = :NSP_ServiceConstants.ActiveClientGoal )
                        AND ( CreatedDate <= :wrapper.RSAPCompletedDate )
                    )
                ];
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
        return clientGoalList;
    }

    // get accountId for the RSAP record
    public static NSP_ClientGoalsControllerWrapper getRSAP( String rsapId ) {
        List<NSP_Relationship_Strategy_Action_Plan__c> records = [
            SELECT
                Id ,
                NSP_Status_Complete_Date__c ,
                NSP_Account__c
            FROM NSP_Relationship_Strategy_Action_Plan__c
            WHERE ( Id = :rsapId )
        ];
        NSP_ClientGoalsControllerWrapper clientGoalWrapper = new NSP_ClientGoalsControllerWrapper();
        if ( !records.isEmpty() ) {
            clientGoalWrapper.accRecordId = records[0].NSP_Account__c;
            clientGoalWrapper.RSAPCompletedDate = records[0].NSP_Status_Complete_Date__c;
        }
        return clientGoalWrapper;
    }

    // creating a Wrapper to store RSAP AccountId and Completed Date
    public class NSP_ClientGoalsControllerWrapper{
        @AuraEnabled
        public Id accRecordId { get; set; }
        @AuraEnabled
        public DateTime RSAPCompletedDate { get; set; }
    }

}
//
