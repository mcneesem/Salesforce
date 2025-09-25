public with sharing class CheckOpportunityStage {
    // test w/ CheckOpportunityStageTest (100%)
    private static final String FAILED = 'Failed Stage Validation';

    @InvocableMethod( label='Check Opportunity Stage' description='Checks if User can move Opportunity to specific Stage' category='Opportunity' )
    public static List<CheckStageResponse> checkOpportunityStage( List<CheckStageRequest> inputs ) {

        List<CheckStageResponse> outputs = new List<CheckStageResponse>();

        if( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( CheckStageRequest input : inputs ) {
                CheckStageResponse output = new CheckStageResponse();
                output.checkStage = false;
                Id optyId = input.oppRecordId;
                if( optyId != null ) {
                    List<Opportunity> opps = [
                        SELECT
                            Id ,
                            CloseDate ,
                            Fee_Inclusive__c ,
                            NextStep ,
                            NSP_Account_Segment__c ,
                            NSP_AddonType__c ,
                            NSP_BidNumber__c ,
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
                        WHERE ( Id = :optyId )
                        LIMIT 1
                    ];
                    if ( ( opps != null ) && !opps.isEmpty() ) {
                        opps[0].StageName = input.stageName;
                        NSP_ValidateOpportunityStage.validateOpportunityStage( opps , true );

                        if( opps[0].NextStep != FAILED ) {
                            output.checkStage = true;
                        }
                    }
                }
                outputs.add( output );
            }
        }
        return outputs;
    }
    public class CheckStageRequest {
        @InvocableVariable(label='Opportunity Id' description='Opportunity record' required=true)
        public Id oppRecordId;
        @InvocableVariable(label='Stage' description='Stage Name' required=true)
        public String stageName;
    }
    public class CheckStageResponse {
        @InvocableVariable(label='Stage Check Result' description='Stage Check Result' required=true)
        public Boolean checkStage;
    }
}