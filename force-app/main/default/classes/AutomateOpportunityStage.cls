// ********************************************************************************************************
// ClassName: AutomateOpportunityStage
// Description: Class for determining Opportunities that may be ready for automatic
//              Stage progression. Looks at Opportunity_Stage_Progression__mdt custom metadata type to
//              determine if an Opportunity is eligible for automatic Stage progression based on its
//              current Stage and Primary Product.
// Params: autoStageOppIds: Set of Ids of Opportunities with Stage criteria changes, making
//                          them possible candidates for automatic Stage progression
// ********************************************************************************************************
public class AutomateOpportunityStage {
    // test w/ AutomateOpportunityStageTest (92%)

    private static final String FAILED = 'Failed Stage Validation';

    public static void automateOpportunityStageAsync( List<Id> autoStageOppIds ) {
        if ( ( autoStageOppIds != null )
            && !autoStageOppIds.isEmpty()
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
           )
        {
            System.enqueueJob( new AutomateOpportunityStageQueueable( autoStageOppIds ) );
        }
    }

    @InvocableMethod( label='Automate Opportunity Stage' description='Automates Opportunity Stage progression' category='Opportunity' )
    public static void automateOpportunityStage( List<Id> autoStageOppIds ) {
        if ( ( autoStageOppIds != null ) && !autoStageOppIds.isEmpty() ) {
            try {
                List<Opportunity> stageAutoOptyList = new List<Opportunity>();
                List<Opportunity> updateOptyList = new List<Opportunity>();
                for ( Opportunity opp : [
                            SELECT
                                Id ,
                                CloseDate ,
                                Fee_Inclusive__c ,
                                NextStep ,
                                NSP_Bid_Status__c ,
                                NSP_Booked_Date__c ,
                                NSP_Bypass_Docusign_Signature__c ,
                                NSP_Client_For_Life__c ,
                                NSP_Closing_Appointment__c ,
                                NSP_CountAsSale__c ,
                                NSP_Forecast_Status__c ,
                                NSP_Number_of_Employees__c ,
                                NSP_Order_Generated__c ,
                                NSP_PrimaryProduct__c ,
                                NSP_Ready_for_Integration_Sync__c ,
                                NSP_TotalAnnualPayroll__c ,
                                OwnerId ,
                                SBQQ__PrimaryQuote__c ,
                                StageName ,
                                Type
                            FROM Opportunity
                            WHERE (
                                ( Id IN :autoStageOppIds )
                                AND ( StageName != null )
                            )
                        ]
                    )
                {
                    stageAutoOptyList = getStageAutoOptyList( stageAutoOptyList , opp );
                }

                // Validate which Opportunity Stage progressions are valid
                if ( !stageAutoOptyList.isEmpty() ) {
                    NSP_ValidateOpportunityStage.validateOpportunityStage( stageAutoOptyList , true );

                    // Prepare the valid ones for update
                    for ( Opportunity checkedOpp : stageAutoOptyList ) {
                        if( checkedOpp.NextStep != FAILED ) {
                            updateOptyList.add( checkedOpp );
                        }
                    }
                }

                // Update Opportunity Stages
                if ( !updateOptyList.isEmpty() ) {
                    Database.update( stageAutoOptyList );
                }

            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException( AutomateOpportunityStage.class.getName() , 'automateOpportunityStage' , e );
            }
        }
    }

    // Returns list of Opportunity records advanced to next Stage based on custom metadata settings
    public static List<Opportunity> getStageAutoOptyList (
        List<Opportunity> stageAutoOptyList ,
        Opportunity opp
        )
    {
        List<Opportunity_Stage_Progression__mdt> optyAutoStages = Opportunity_Stage_Progression__mdt.getAll().values();
        for ( Opportunity_Stage_Progression__mdt stageAuto : optyAutoStages ) {
            if ( ( opp.StageName == stageAuto.Stage__c )
                 && ( opp.NSP_PrimaryProduct__c == stageAuto.Primary_Product__c )
                 && ( stageAuto.Is_Automated__c )
               )
            {
                opp.StageName = stageAuto.Next_Stage__c;
                stageAutoOptyList.add( opp );
                break;
            }
        }
        return stageAutoOptyList;
    }
}
//