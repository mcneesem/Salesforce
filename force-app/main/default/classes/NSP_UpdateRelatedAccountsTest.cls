@isTest
private class NSP_UpdateRelatedAccountsTest {     
    private static final string ACCOUNT_NAME = 'Test Account';

    @testSetup
    private static void testData() {
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        //
        LeadConversionSettings__c leadSettings = LeadConversionSettings__c.getOrgDefaults();
        leadSettings.Is_Enabled_SOQL_Fix__c = true;
        upsert leadSettings;
        //
        accoutObject.Name = NSP_UpdateRelatedAccountsTest.ACCOUNT_NAME;
        accoutObject.recordTypeId=partnerRecordTypeId;
        database.insert(accoutObject);
        //
        AccountTriggerSettings__c accountSettings = AccountTriggerSettings__c.getOrgDefaults();
        accountSettings.IsEnabledFuture__c = true;
        accountSettings.IsEnabledQueueable__c = true;
        accountSettings.DelayMinutes__c = 10;
        upsert accountSettings;
    }

    @isTest
    private static void updateRelatedAccountsTestOld() {
        AccountTriggerSettings__c accountSettings = AccountTriggerSettings__c.getOrgDefaults();
        accountSettings.IsEnabledQueueable__c = false;
        upsert accountSettings;
        //
        LeadConversionSettings__c leadSettings = LeadConversionSettings__c.getOrgDefaults();
        leadSettings.Is_Enabled_SOQL_Fix__c = false;
        upsert leadSettings;
        //
        set<String> accIdSet = new set<String>();
        Account acc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :NSP_UpdateRelatedAccountsTest.ACCOUNT_NAME
        ];
        accIdSet.add(acc.Id);
        Test.startTest();
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accIdSet);
        Test.stopTest();
        Date assertDate = date.today();
        Account assertAcc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :NSP_UpdateRelatedAccountsTest.ACCOUNT_NAME
        ];
        System.assertEquals(assertDate, assertAcc.NSP_Last_Updated__c);
        //
        // for additional code coverage...
        NSP_UpdateRelatedAccounts.updateAccountStatus( accIdSet );
        NSP_UpdateRelatedAccounts.testHandleException( null , 'methodName' );
    }

    @isTest
    private static void updateRelatedAccountsTestNew() {
        set<String> accIdSet = new set<String>();
        Account acc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :NSP_UpdateRelatedAccountsTest.ACCOUNT_NAME
        ];
        accIdSet.add(acc.Id);
        Test.startTest();
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accIdSet);
        Test.stopTest();
        Date assertDate = date.today();
        Account assertAcc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :NSP_UpdateRelatedAccountsTest.ACCOUNT_NAME
        ];
        System.assertEquals(assertDate, assertAcc.NSP_Last_Updated__c);
        //
        // for additional code coverage...
        NSP_UpdateRelatedAccounts.updateAccountStatus( accIdSet );
        NSP_UpdateRelatedAccounts.testHandleException( null , 'methodName' );
    }

}
//