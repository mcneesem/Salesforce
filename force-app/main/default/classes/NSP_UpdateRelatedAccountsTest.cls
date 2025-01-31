//
// @Description: This class is used to cover the NSP_UpdateRelatedAccounts Class.
// @createdDate: 01/25/2022
// @story/Defect : DF-01058
//
@isTest(SeeAllData=false)
private class NSP_UpdateRelatedAccountsTest {     
    private static final string ACCOUNT_NAME = 'Test Account';
    private static LeadConversionSettings__c settings = LeadConversionSettings__c.getOrgDefaults();

    @testSetup private static void testData() {
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        settings = settings == null ? LeadConversionSettings__c.getOrgDefaults() : settings;
        accoutObject.Name = ACCOUNT_NAME;
        accoutObject.recordTypeId=partnerRecordTypeId;
        database.insert(accoutObject);
    }

    @isTest private static void updateRelatedAccountsTestOld() {
        settings.Is_Enabled_SOQL_Fix__c = false;
        upsert settings;
        set<String> accIdSet = new set<String>();
        Account acc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :ACCOUNT_NAME
        ];
        accIdSet.add(acc.Id);
        Test.startTest();
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accIdSet);
        Test.stopTest();
        Date assertDate = date.today();
        Account assertAcc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :ACCOUNT_NAME
        ];
        system.assertEquals(assertDate, assertAcc.NSP_Last_Updated__c);
        //
        // for additional code coverage...
        NSP_UpdateRelatedAccounts.updateAccountStatus( accIdSet );
        NSP_UpdateRelatedAccounts.testHandleException( null , 'methodName' );
    }

    @isTest private static void updateRelatedAccountsTestNew() {
        settings.Is_Enabled_SOQL_Fix__c = true;
        upsert settings;
        set<String> accIdSet = new set<String>();
        Account acc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :ACCOUNT_NAME
        ];
        accIdSet.add(acc.Id);
        Test.startTest();
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accIdSet);
        Test.stopTest();
        Date assertDate = date.today();
        Account assertAcc = [
            SELECT Id , NSP_Last_Updated__c 
            FROM Account
            WHERE Name = :ACCOUNT_NAME
        ];
        system.assertEquals(assertDate, assertAcc.NSP_Last_Updated__c);
        //
        // for additional code coverage...
        NSP_UpdateRelatedAccounts.updateAccountStatus( accIdSet );
        NSP_UpdateRelatedAccounts.testHandleException( null , 'methodName' );
    }

}
//