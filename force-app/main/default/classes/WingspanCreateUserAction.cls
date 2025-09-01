public with sharing class WingspanCreateUserAction {
    // test w/ WingspanCreateUserActionTest (100%)

    @InvocableMethod(label='Create Wingspan User')
    public static List<Output> createWingspanUser( List<Input> inputs ) {
        Output result = new Output();
        try {
            if ( ( inputs != null ) && ( !inputs.isEmpty() ) ) {
                for ( Input input: inputs ) {
                    result.isUserFound = WingspanRestService.createClientAdmin(
                        input.contactId ,
                        input.recordId ,
                        input.isCheckOnly
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                WingspanCreateUserAction.class.getName() ,
                'createWingspanUser' ,
                e
            );
        }
        return new List<Output>{ result };
    }

    public class Output {
        @InvocableVariable(label='Is User Found?')
        public Boolean isUserFound;
    }

    public class Input {
        @InvocableVariable(label='Stake Holder Contact')
        public Id contactId;
        @InvocableVariable(label='Is Check Only?')
        public Boolean isCheckOnly;
        @InvocableVariable(label='Record Id')
        public Id recordId;
    }

}
//