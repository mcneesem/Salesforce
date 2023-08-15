/**
* @description  : test class for NSP_DeleteMergeCaseBatch
* @author Prakash Dalvi
* @date 07/08/2023
* Name : NSP_DeleteMergeCaseBatch_Test
*/

@isTest
private class NSP_DeleteMergeCaseBatch_Test {
    
    private static final String ACCOUNT_DEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASE_DEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    
    @testSetup
    static void setupDataForMergeBatch(){
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNT_DEFAULTS, true);
        Case asssetCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASE_DEFAULTS, true);        
    }
    
    /*
    * Test method to test NSP_DeleteMergeCaseBatch class
    * @ param N/A
    * @return void
    */
    @isTest
    private static void testDeleteMergeCasesBatch() {
        
        Case caseRecord = [SELECT Id, status, caseNumber FROM Case WHERE Id != null limit 1];
        String caseRecordNumber = caseRecord.CaseNumber;
        Test.startTest();
        caseRecord.Status = 'Merged';
        update caseRecord;
        Database.executeBatch(new NSP_DeleteMergeCaseBatch());
        Test.stopTest();
        Assert.areEqual(0, [SELECT count() FROM Case WHERE caseNumber =: caseRecordNumber]);
        
    }

}