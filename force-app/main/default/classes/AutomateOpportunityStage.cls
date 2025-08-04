// ********************************************************************************************************
//  ClassName:      AutomateOpportunityStage
//  Description :   Class for determining and validating Opportunities that may be ready for automatic 
//                  Stage progression. Returns List or Map of Opportunities that should move to next Stage.
// 
//  Params:         autoStageOppIds:    Set of Ids of Opportunities with Stage criteria changes, making 
//                                      them possible candidates for automatic Stage progression
//                 
// ********************************************************************************************************

public inherited sharing class AutomateOpportunityStage {
    // test w/ AutomateOpportunityStageTest (92%)

    public static void automateOpportunityStageAsync(List<Id> autoStageOppIds) {
        if ( ( autoStageOppIds != null )
            && !autoStageOppIds.isEmpty()
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
           )
        {
            System.enqueueJob(new AutomateOpportunityStageQueueable(autoStageOppIds));
        }
    }

    @InvocableMethod(label='Automate Opportunity Stage' description='Automates Opportunity Stage progression' category='Opportunity')
    public static void automateOpportunityStage(List<Id> autoStageOppIds) {
        if ( ( autoStageOppIds != null ) && !autoStageOppIds.isEmpty() ) {
            List<Opportunity> stageAutoOpptyList = new List<Opportunity>(); // oppty records eligible for automatic Stage progression
            List<Opportunity_Stage_Progression__mdt> optyAutoStages = [ SELECT Primary_Product__c, Stage__c, Next_Stage__c
                                                                        FROM Opportunity_Stage_Progression__mdt
                                                                        WHERE Is_Automated__c = true ];

            try{
                for(Opportunity opp : [SELECT Id, NSP_Ready_for_Integration_Sync__c, OwnerId, StageName, NSP_PrimaryProduct__c, NSP_Number_of_Employees__c, Type, 
                                        NSP_Bid_Status__c, Fee_Inclusive__c, NSP_Order_Generated__c, NSP_Bypass_Docusign_Signature__c, NSP_Closing_Appointment__c, 
                                        NSP_Client_For_Life__c, NSP_Forecast_Status__c, NSP_TotalAnnualPayroll__c, NSP_Booked_Date__c, NSP_CountAsSale__c, 
                                        CloseDate FROM Opportunity WHERE ID IN: autoStageOppIds]) {
                    if(optyAutoStages != null && !optyAutoStages.isEmpty() && opp.StageName != null) {
                        for(Opportunity_Stage_Progression__mdt stageAuto:optyAutoStages) {
                            if(opp.StageName == stageAuto.Stage__c && opp.NSP_PrimaryProduct__c == stageAuto.Primary_Product__c) {
                                opp.StageName = stageAuto.Next_Stage__c;
                                stageAutoOpptyList.add(opp);
                            }
                        }
                    }
                }
                if(!stageAutoOpptyList.isEmpty()) {
                    Database.update(stageAutoOpptyList);
                }
            } catch (Exception e) {
                NSP_ErrorLogHandler.logException( AutomateOpportunityStage.class.getName() , 'automateOpportunityStage' , e );
            }
        }
    }
}