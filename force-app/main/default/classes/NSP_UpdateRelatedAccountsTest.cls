@isTest
private class NSP_UpdateRelatedAccountsTest {

    @testSetup
    private static void testData() {
        Account sharedAccount = new Account();
        sharedAccount.Name = 'sharedAccount';
        sharedAccount.RecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Account' , 'NSP_Partner_Client' );
        insert sharedAccount;
        //
        AccountTriggerSettings__c accountSettings = AccountTriggerSettings__c.getOrgDefaults();
        accountSettings.IsEnabledQueueable__c = true;
        accountSettings.DelayMinutes__c = 10;
        upsert accountSettings;
    }

    @isTest
    private static void updateRelatedAccountsQueueable() {
        Set<String> accIdSet = new Set<String>();
        Account acc = [
            SELECT Id , NSP_Last_Updated__c
            FROM Account
            WHERE Name = 'sharedAccount'
        ];
        accIdSet.add(acc.Id);
        Test.startTest();
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accIdSet);
        Test.stopTest();
        Date assertDate = date.today();
        Account assertAcc = [
            SELECT Id , NSP_Last_Updated__c
            FROM Account
            WHERE Name = 'sharedAccount'
        ];
        System.assertEquals(assertDate, assertAcc.NSP_Last_Updated__c);
        //
        // for additional code coverage...
        NSP_UpdateRelatedAccounts.updateAccountStatus( accIdSet );
        NSP_UpdateRelatedAccounts.testHandleException( null , 'methodName' );
    }

    @isTest
    private static void updateRelatedAccountsInvocable() {
        Test.startTest();
        List<Account> sharedAccounts = [
            SELECT Id
            FROM Account
            WHERE ( Name = 'sharedAccount' )
        ];
        NSP_UpdateRelatedAccounts.FlowInput input = new NSP_UpdateRelatedAccounts.FlowInput();
        input.accountId = ( sharedAccounts?.isEmpty() ? sharedAccounts[0].Id : null );
        List<NSP_UpdateRelatedAccounts.FlowInput> inputs = new List<NSP_UpdateRelatedAccounts.FlowInput>();
        inputs.add( input );
        NSP_UpdateRelatedAccounts.invoke( inputs );
        Test.stopTest();
    }

}
//