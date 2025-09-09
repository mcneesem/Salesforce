public with sharing class CheckOpportunityStage {
    // test w/ CheckOpportunityStageTest (100%)

    @InvocableMethod( label='Check Opportunity Stage' description='Checks if User can move Opportunity to specific Stage' category='Opportunity' )
    public static List<CheckStageResponse> checkOpportunityStage( List<CheckStageRequest> inputs ) {
        List<CheckStageResponse> outputs = new List<CheckStageResponse>();
        List<Opportunity> checkStageOptyList = new List<Opportunity>();
        if( ( inputs != null ) && !inputs.isEmpty() ){
            CheckStageResponse output = new CheckStageResponse();
            output.checkStage = false;
            Opportunity opty = inputs[0].oppRecord;
            opty.StageName = inputs[0].stageName;
            checkStageOptyList.add( opty );
            NSP_ValidateOpportunityStage.validateOpportunityStage( checkStageOptyList );
            for ( Opportunity opp : checkStageOptyList ) {
                if( !opp.hasErrors() ) {
                    output.checkStage = true;
                }
            }
            outputs.add( output );
        }
        return outputs;
    }

    public class CheckStageRequest {
        @InvocableVariable(label='Opportunity' description='Opportunity record' required=true)
        public Opportunity oppRecord;
        @InvocableVariable(label='Stage' description='Stage Name' required=true)
        public String stageName;
    }

    public class CheckStageResponse {
        @InvocableVariable(label='Stage Check Result' description='Stage Check Result' required=true)
        public Boolean checkStage;
    }
}