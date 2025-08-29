public with sharing class WingspanCreateUserAction {
    // test w/ WingspanCreateUserActionTest (100%)

    public class Output {
        @InvocableVariable(label = 'User Found?')
        public Boolean isUserFound;
    }

    public class Input {
        @InvocableVariable(label = 'Stake Holder Contact')
        public Id contactId;
        @InvocableVariable(label = 'Check Only?')
        public Boolean isCheckOnly;
        @InvocableVariable(label = 'Record ID')
        public Id recordId;
    }

    @InvocableMethod(label = 'Create Wingspan User')
    public static List<Output> wingspanApiDirector(List<Input> inputs){
        Output result = new Output();
        
        try{
            if( ( inputs != null ) && ( !inputs.isEmpty() ) ){
                for(Input input: inputs){
                    result = handleApiCalls( input );
                }
            }
        }catch (exception e){
            NSP_ErrorLogHandler.logException(
                WingspanCreateUserAction.class.getName() ,
                'wingspanApiDirector' ,
                e
            );
        }
        
        return new List<Output>{result};
    }

    //method to direct API calls
    private static Output handleApiCalls( Input input ){
        //initiate empty output
        Output result = new Output();
        result.isUserFound = true;
        String createdUserId = '';
        
        result.isUserFound = WingspanRestService.createClientAdmin( input.contactId, input.recordId, input.isCheckOnly );
        
        return result;
    }

}