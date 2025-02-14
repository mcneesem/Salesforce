public with sharing class RecordTypeSelectorAction {
    // test w/ RecordTypeSelectorActionTest (100%)

    @InvocableMethod(label='Get Accessible Record Types' description='Returns the Record Types for a given sObjectType which are accessible to the current User.')
    public static List<Response> getAccessibleRecordTypes( List<Request> inputs ) {
        List<Response> outputs = new List<Response>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            Response output = new Response();
            output.accessibleRecordTypes = RecordTypeSelectorController.getAccessibleRecordTypes( inputs[0].objectApiName );
            outputs.add( output );
        }
        return outputs;
    }

    public class Request {
        @InvocableVariable(label='Object API Name' description='API Name of requested sObjectType.' required=true)
        public String objectApiName;
    }

    public class Response {
        @InvocableVariable(label='Accessible Record Types' description='List of accessible Record Types for the request sObjectType.' required=true)
        public List<RecordType> accessibleRecordTypes;
    }

}
//