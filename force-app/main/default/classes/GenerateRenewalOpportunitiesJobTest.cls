@isTest
private class GenerateRenewalOpportunitiesJobTest {
    @testSetup
    private static void setupData() {

        Account accObj = NSP_TestHelper.createAccount(true);
        accObj.NSP_Client_AIMS__c = '1234500';
        accObj.NSP_AIMS_Client__c = '1234500';
        update accObj;

        // Create Asset Record
        Asset assetObj = new Asset();
        assetObj.accountId = accObj.Id;
        assetObj.name = 'asset1';
        assetObj.NSP_Sales_Office__c = '4409';
        assetObj.NSP_Service_Package__c = 'HRScale';
        insert assetObj;

        // Create Asset Record
        Asset assetObj1 = new Asset();
        assetObj1.accountId = accObj.Id;
        assetObj1.name = 'asset1';
        assetObj1.NSP_Sales_Office__c = '4409';
        assetObj1.NSP_Service_Package__c = 'HRScale';
        insert assetObj1;

        List<NSP_Sub_Client__c> subClients = new List<NSP_Sub_Client__c>();

        NSP_Sub_Client__c sc = new NSP_Sub_Client__c(
            NSP_Account__c = accObj.Id,
            NSP_Account_Status__c = 'Active',
            NSP_Client__c = '1234500',
            NSP_Sub_Client__c = '1234500',
            NSP_Renewal_Date__c = Date.newInstance(2025, 12, 25),
            NSP_Benefit_Package_Name__c = 'Independence Select',
            NSP_Asset__c = assetObj.Id
        );
        subClients.add(sc);

        NSP_Sub_Client__c sc1 = new NSP_Sub_Client__c(
            NSP_Account__c = accObj.Id,
            NSP_Account_Status__c = 'Active',
            NSP_Client__c = '1234500',
            NSP_Sub_Client__c = '1234501',
            NSP_Renewal_Date__c = Date.newInstance(2025, 12, 26),
            NSP_Benefit_Package_Name__c = 'Freedom Premier',
            NSP_Asset__c = assetObj1.Id
        );
        subClients.add(sc1);
        NSP_Sub_Client__c sc2 = new NSP_Sub_Client__c(
            NSP_Account__c = accObj.Id,
            NSP_Account_Status__c = 'Active',
            NSP_Client__c = '1234500',
            NSP_Sub_Client__c = '1234506',
            NSP_Renewal_Date__c = Date.newInstance(2025, 12, 26),
            NSP_Benefit_Package_Name__c = 'Freedom Premier',
            NSP_Asset__c = assetObj1.Id
        );
        subClients.add(sc2);

        insert subClients;

        // Sales office mapping -> renewal manager
        NSP_Sales_Office_Mapping__c som = new NSP_Sales_Office_Mapping__c();
        som.NSP_Sales_Office__c = '4409';
        som.Renewal_Manager__c = UserInfo.getUserId();
        insert som;

        Renewal_Opportunity_Settings__c cs = new Renewal_Opportunity_Settings__c(
            SetupOwnerId = UserInfo.getUserId(),
            IsEnabled__c = true,
            BatchSize__c = 50,
            RenewalRecordTypeId__c = Schema.getGlobalDescribe().get( 'Opportunity' )
            .getDescribe()
            .getRecordTypeInfosByDeveloperName()
            .get('Renewal')
            .getRecordTypeId()
        );
        upsert cs;

    }

    @isTest
    private static void testRenewalOpportunityBatch() {
        Test.startTest();
        Database.executeBatch(new GenerateRenewalOpportunitiesJob(12, 2026));
        Test.stopTest();

        Integer cnt = [
            SELECT COUNT()
            FROM Opportunity
        ];

        System.assertEquals(
            2, cnt
        );
    }
}