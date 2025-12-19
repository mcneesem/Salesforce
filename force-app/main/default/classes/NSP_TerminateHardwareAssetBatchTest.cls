@isTest
private class NSP_TerminateHardwareAssetBatchTest {

    @testSetup
    private static void setupTestData() {
        TerminateHardwareAssetBatchSettings__c settings = TerminateHardwareAssetBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 200;
        upsert settings;

        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        NSP_TestHelper.createProduct('Test Product',true);
        //create an asset
        Asset newAsset = new Asset();
        newAsset.AccountId = acc1.Id;
        newAsset.Name = 'Test Asset';
        newAsset.SerialNumber = '12345';
        insert newAsset;
        //create a subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = acc1.Id;
        subscription.SBQQ__Quantity__c = 1;
        subscription.SBQQ__SubscriptionEndDate__c = System.today().addDays(-1);
        insert subscription;
        //create a support entitlement
        NSP_Support_Entitlement__c entitelment = new NSP_Support_Entitlement__c();
        entitelment.NSP_Covered_Asset__c = newAsset.Id;
        entitelment.NSP_Supported_Subscription__c = subscription.Id;
        entitelment.NSP_Support_Product__c  = 'PerformSmart Traditional';
        insert entitelment;

    }

    @isTest
    private static void testBatchExecution() {
        Test.startTest();
        //execute the batch
        Database.executeBatch(new NSP_TerminateHardwateAssetBatch(), 1);
        Test.stopTest();
        List<Asset> assetsToTerminate=[SELECT Id,Status FROM Asset WHERE Status != null LIMIT 1];
        System.assertEquals(NSP_CPQConstants.TERMINATED, assetsToTerminate[0].Status);
    }

    @isTest
    private static void testSceduleExecution() {
        Test.startTest();
        NSP_TerminateHardwateAssetBatch.schedule();
        Test.stopTest();
    }

}
//