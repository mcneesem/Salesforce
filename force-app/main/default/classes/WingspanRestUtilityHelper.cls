public with sharing class WingspanRestUtilityHelper {
    // test w/ WingspanRestUtilityHelperTest (96%)
    public class Output {
        @InvocableVariable(label = 'User Found?')
        public Boolean userFound;
    }
    
    public class Input {
        @InvocableVariable(label = 'Stake Holder Contact')
        public Id contactId;
        @InvocableVariable(label = 'Validate Contact?')
        public Boolean validateContact;
        @InvocableVariable(label = 'Create Contact in Wingspan?')
        public Boolean createContact;
        @InvocableVariable(label = 'Record ID')
        public Id recordId;
    }
    
    @InvocableMethod(label = 'Check Contact in Wingspan')
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
                WingspanRestUtilityHelper.class.getName() ,
                'wingspanApiDirector' ,
                e
            );
        }finally{
            //insert logs after all API calls are made
            WingspanRestUtility.insertLogs();
        }
        
        return new List<Output>{result};
	}
    
    //method to direct API calls
    private static Output handleApiCalls( Input input ){
        //initiate empty output
        Output result = new Output();
        result.userFound = true;
        String createdUserId = '';
        
        if( ( input.contactId !=null ) 
           && ( input.validateContact != null )
           && ( input.createContact != null )
           && ( input.recordId != null ) 
           && ( input.validateContact == True )
          ){
              //validate contact in Wingspan Server
              result.userfound = WingspanRestUtility.getUserByEmail( input.contactId, input.recordId );
              if( ( input.createContact == True ) && ( !result.userfound ) ){
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