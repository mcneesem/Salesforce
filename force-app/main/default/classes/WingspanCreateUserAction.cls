public with sharing class WingspanCreateUserAction {
    // test w/ WingspanCreateUserActionTest (79%)

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
        
        if( ( input.contactId !=null ) 
           && ( input.recordId != null )
          ){
              //validate contact in Wingspan Server
              result.isUserFound = WingspanRestUtility.getUserByEmail( input.contactId, input.recordId, input.isCheckOnly );
              if( ( !input.isCheckOnly ) && ( !result.isUserFound ) ){
                  //create contact in Wingspan Server
                  createdUserId = WingspanRestUtility.createClientAdmin( input.contactId, input.recordId );
                  if( !String.isBlank( createdUserId ) ){
                      //Associate Admin in Wingspan Server
                      WingspanRestUtility.linkAdminToCHUB( createdUserId, input.recordId );
                  }
              }
          }
        return result;
    }

}