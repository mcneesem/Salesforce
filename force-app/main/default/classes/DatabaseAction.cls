public with sharing class DatabaseAction {
    // test w/ DatabaseActionTest (87%)

    @InvocableMethod(label='Database Action' description='Performs DML operations on sObject records.')
    public static void performDmlOperation( List<Request> requests ) {
        try {
            if ( ( requests != null ) && !requests.isEmpty() ) {
                for ( Request req : requests ) {
                    if ( String.isNotBlank( req.flowApiName )
                        && String.isNotBlank( req.operation )
                        && ( req.records != null )
                        && !req.records.isEmpty()
                        )
                    {
                        if ( req.operation == 'INSERT' ) {
                            List<Database.SaveResult> results = Database.insert( req.records , false );
                            NSP_ErrorLogHandler.logResults(
                                DatabaseAction.class.getName() ,
                                'performDmlOperation:insert:' + req.flowApiName ,
                                results
                            );
                        } else if ( req.operation == 'UPDATE' ) {
                            List<Database.SaveResult> results = Database.update( req.records , false );
                            NSP_ErrorLogHandler.logResults(
                                DatabaseAction.class.getName() ,
                                'performDmlOperation:update:' + req.flowApiName ,
                                results
                            );
                        } else if ( req.operation == 'DELETE' ) {
                            List<Database.DeleteResult> results = Database.delete( req.records , false );
                            NSP_ErrorLogHandler.logResults(
                                DatabaseAction.class.getName() ,
                                'performDmlOperation:delete:' + req.flowApiName ,
                                results
                            );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                DatabaseAction.class.getName() ,
                'performDmlOperation' ,
                e
            );
        }
    }

    public class Request {
        @InvocableVariable(label='Flow API Name' description='For logging purposes.' required=true)
        public String flowApiName;
        @InvocableVariable(label='Operation' description='INSERT, UPDATE, or DELETE.' required=true)
        public String operation;
        @InvocableVariable(label='Records' description='Campaign Member Status records.' required=true)
        public List<sObject> records;
    }

}
//