public with sharing class CheckOpportunityStage {
    // test w/ CheckOpportunityStageTest (100%)

    @InvocableMethod( label='Check Opportunity Stage' description='Checks if User can move Opportunity to specific Stage' category='Opportunity' )
    public static List<CheckStageResponse> checkOpportunityStage( List<CheckStageRequest> inputs ) {
        List<CheckStageResponse> outputs = new List<CheckStageResponse>();
        if( ( inputs != null ) && !inputs.isEmpty() ){
            CheckStageResponse output = new CheckStageResponse();
            output.checkStage = false;
            Id optyId = inputs[0].oppRecordId;
            List<Opportunity> checkStageOptyList = [
                SELECT
                    Id,
                    OwnerId,
                    NSP_Bid_Status__c,
                    NSP_Number_of_Employees__c,
                    NSP_PrimaryProduct__c,
                    NSP_Forecast_Status__c,
                    Fee_Inclusive__c,
                    CloseDate,
                    NSP_CountAsSale__c,
                    NSP_Booked_Date__c,
                    NSP_TotalAnnualPayroll__c,
                    NSP_Bypass_Docusign_Signature__c,
                    NSP_Order_Generated__c,
                    NSP_Client_For_Life__c,
                    StageName,
                    Type
                FROM Opportunity
                WHERE Id = :optyId
            ];

            if(!checkStageOptyList.isEmpty()) {
                checkStageOptyList[0].StageName = inputs[0].stageName;
                NSP_ValidateOpportunityStage.validateOpportunityStage( checkStageOptyList );
                if( !checkStageOptyList[0].hasErrors() ) {
                    output.checkStage = true;
                }
            }
            outputs.add( output );
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