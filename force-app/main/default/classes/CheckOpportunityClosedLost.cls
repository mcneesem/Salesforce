public with sharing class CheckOpportunityClosedLost {
    // test w/ CheckOpportunityStageTest (100%)

    @InvocableMethod( label='Check Opportunity Closed Lost' description='Checks if User can move Opportunity to Closed Lost' category='Opportunity' )
    public static List<CheckStageResponse> checkOpportunityClosedLost( List<CheckStageRequest> inputs ) {
        List<CheckStageResponse> outputs = new List<CheckStageResponse>();

        if( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( CheckStageRequest input : inputs ) {
                CheckStageResponse output = new CheckStageResponse();
                output.checkStage = false;
                Id optyId = input.oppRecordId;
                if( optyId != null ) {
                    List<Opportunity> opps = [
                        SELECT
                            Id,
                            CloseDate,
                            Fee_Inclusive__c,
                            NSP_Account_Segment__c,
                            NSP_AddonType__c,
                            NSP_Booked_Date__c,
                            NSP_BidNumber__c,
                            NSP_Bid_Status__c,
                            NSP_Bypass_Docusign_Signature__c,
                            NSP_Client_For_Life__c,
                            NSP_Closing_Appointment__c,
                            NSP_CountAsSale__c,
                            NSP_Forecast_Status__c,
                            NSP_Number_of_Employees__c,
                            NSP_Order_Generated__c,
                            NSP_PrimaryProduct__c,
                            NSP_TotalAnnualPayroll__c,
                            OwnerId,
                            SBQQ__PrimaryQuote__c,
                            StageName,
                            Type
                        FROM Opportunity
                        WHERE Id = :optyId
                        LIMIT 1
                    ];

                    if( ( opps != null ) && !opps.isEmpty() ) {
                        Map<Id,User> opportunityOwnerRoleMap = NSP_ValidateOpportunityStage.getUserRole( new List<Id>{ opps[0].OwnerId } );
                        output.checkStage = NSP_ValidateOpportunityStage.checkClosedLostStageCriteria( opps[0] , opportunityOwnerRoleMap );
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
    }

    public class CheckStageResponse {
        @InvocableVariable(label='Stage Check Result' description='Stage Check Result' required=true)
        public Boolean checkStage;
    }
}