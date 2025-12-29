@isTest
private class NSP_CustomExceptionTest {

    //
    // DEPRECATED ~ see NSP_ErrorLogHandler
    //

    @isTest
    private static void createAccount() {
        try {
            Account accountObj = new Account();
            insert accountObj;
            system.assertNotEquals( accountObj , null );
        } catch ( Exception ex ) {
            NSP_CustomException.LogException( ex );
        }
    }

}
//