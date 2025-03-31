
@isTest
private class SalesVisualIndicatorHelperTest {

    @isTest
    static void testGetAccount() {
        Test.startTest();
        Account acct = new  Account();
        acct.Name = 'Test Workday';
        acct.NSP_Current_Provider__c = 'Workday';
        insert acct;

        SalesVisualIndicatorHelper.AccountWrapper accountWrapper = SalesVisualIndicatorHelper.getAccount(acct.id);
        Test.stopTest();

        Assert.areEqual(true, accountWrapper.isWorkday);
    }
}