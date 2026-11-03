/**
* @description  : controller for nsp_ShowActiveClientGoalsOnRSAP lwc
* @author Harsha Khiroya
* @date 02/06/2022
* Name : NSP_ClientGoalsController
*/
public with sharing class NSP_ClientGoalsController {

    //get all active goals from related account
    @AuraEnabled
    public static List<NSP_ClientGoal__c> getClientGoalsList(String rsapId) {
        List<NSP_ClientGoal__c> clientGoalList = new  List<NSP_ClientGoal__c>();
        try{
            NSP_ClientGoalsControllerWrapper RSAPWrapper = getRSAP(rsapId);
            String ClientGoals;
            if(RSAPWrapper.RSAPCompletedDate==null){
                clientGoalList= [SELECT Id, Name, NSP_Goal_Details__c,NSP_Goal_Type__c, NSP_Status__c,NSP_Date__c FROM NSP_ClientGoal__c WHERE NSP_Account__c =: RSAPWrapper.accRecordId AND
                                 NSP_Status__c = :NSP_ServiceConstants.ActiveClientGoal];
            }
            if(RSAPWrapper.RSAPCompletedDate!=null){
                clientGoalList= [SELECT Id, Name, NSP_Goal_Details__c,NSP_Goal_Type__c, NSP_Status__c,NSP_Date__c FROM NSP_ClientGoal__c WHERE NSP_Account__c =: RSAPWrapper.accRecordId AND
                                 NSP_Status__c = :NSP_ServiceConstants.ActiveClientGoal  AND createdDate <=: RSAPWrapper.RSAPCompletedDate  ];
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }

        return clientGoalList;
    }

    //get accountId for the RSAP record
    public static NSP_ClientGoalsControllerWrapper getRSAP(String rsapId){
        List<NSP_Relationship_Strategy_Action_Plan__c> RSAP  = [SELECT Id, NSP_Status_Complete_Date__c,NSP_Account__c FROM
                                                                NSP_Relationship_Strategy_Action_Plan__c WHERE Id = :rsapId];

        NSP_ClientGoalsControllerWrapper clientGoalWrapper = new NSP_ClientGoalsControllerWrapper();
        if(!RSAP.isEmpty()){
            clientGoalWrapper.accRecordId = RSAP[0].NSP_Account__c;
            clientGoalWrapper.RSAPCompletedDate = RSAP[0].NSP_Status_Complete_Date__c;
        }

        return clientGoalWrapper;
    }

    // creating a Wrapper to store RSAP AccountId and Completed Date
    public class NSP_ClientGoalsControllerWrapper{
        @AuraEnabled
        public Id accRecordId{get;set;}
        @AuraEnabled
        public DateTime RSAPCompletedDate{get;set;}
    }

}