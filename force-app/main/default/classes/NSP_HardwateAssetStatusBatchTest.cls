@isTest
private class NSP_HardwateAssetStatusBatchTest {

    @testSetup
    private static void setupTestData() {
        HardwareAssetStatusBatchSettings__c settings = HardwareAssetStatusBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 200;
        upsert settings;

        //Get Hardware asset record type
        Id hardwareAssetRecordTypeId =NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_CPQConstants.HARWARE_ASSET_RECORDTYPE);
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        NSP_TestHelper.createProduct('Test Product',true);
        //create an asset
        Asset newAsset = new Asset();
        newAsset.AccountId = acc1.Id;
        newAsset.Name = 'Test Asset';
        newAsset.SerialNumber = '12345';
        newAsset.Status=NSP_CPQConstants.ACTIVE;
        newAsset.NSP_Termination_Date__c=System.today()-1;
        newAsset.RecordTypeId=hardwareAssetRecordTypeId;
        insert newAsset;

        Asset newAsset1 = new Asset();
        newAsset1.AccountId = acc1.Id;
        newAsset1.Name = 'Test Asset1';
        newAsset1.SerialNumber = '12345678';
        newAsset1.Status=NSP_CPQConstants.TERMINATED;
        newAsset1.NSP_ActivationDate__c=System.today()+1;
        newAsset1.RecordTypeId=hardwareAssetRecordTypeId;
        insert newAsset1;
    }

    @isTest
    private static void testBatchExecution() {
        Test.startTest();
        //execute batch class
        Database.executeBatch(new NSP_HardwateAssetStatusBatch());
        Test.stopTest();
        List<Asset> assetsToTerminate=[SELECT Id,Status FROM Asset WHERE Status=:NSP_CPQConstants.TERMINATED LIMIT 1];
        System.assertEquals(NSP_CPQConstants.TERMINATED, assetsToTerminate[0].Status);
    }

    @isTest
    private static void testSceduleExecution() {
        Test.startTest();
        NSP_HardwateAssetStatusBatch.schedule();
        Test.stopTest();
    }

}
//