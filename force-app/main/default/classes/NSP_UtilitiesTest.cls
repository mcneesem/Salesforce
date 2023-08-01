@isTest
/**
 * This class contains unit test methods of NSP_Utilities apex class.
 */
private class NSP_UtilitiesTest {

    @IsTest
    static void getAuraException_returnsExceptionWithCorrectMessage(){
        // GIVEN
        String exceptionMessage = 'Name is required field on Account object.';
        RequiredInfoMissingException ex = new RequiredInfoMissingException(exceptionMessage);

        // WHEN
        AuraHandledException auraException = NSP_Utilities.getAuraException(ex);

        // THEN
        System.assertEquals(exceptionMessage, auraException.getMessage(), 'Error message is different.');
    }

    @isTest
    static void getDbErrorRecordsSaveResultTest(){

        List<Account> accList = new List<Account>();

        for (Integer i = 0; i < 3; i++) {
            Account acc = new Account();
            accList.add(acc);
        }

        Database.SaveResult[] saveResult = Database.insert(accList,false);
        List<String> errors = NSP_Utilities.getDbErrorRecords(saveResult);

        System.assert(errors.size()>0);
    }

    @isTest
    static void getDbErrorRecordsDeleteResultTest(){
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            Account acc = new Account(Name='Test'+i);
            accList.add(acc);
        }

        insert accList;
        Account[] accts = [SELECT Id from Account WHERE Name Like 'Test' LIMIT 10];
        Database.DeleteResult[] deleteResult = Database.delete(accts,false);
        System.debug(deleteResult);
        List<String> errors = NSP_Utilities.getDbErrorRecords(deleteResult);

        System.assert(errors.size() == 0);
    }

    @isTest
    static void getDbErrorRecordsUpsertResultTest(){
        List<Account> accList = new List<Account>();

        for (Integer i = 0; i < 3; i++) {
            Account acc = new Account();
            accList.add(acc);
        }
        Database.UpsertResult[] upsertResult = Database.upsert(accList,false);
        List<String> errors = NSP_Utilities.getDbErrorRecords(upsertResult);

        System.assert(errors.size()>0);
    }

    public class RequiredInfoMissingException extends Exception{}
}