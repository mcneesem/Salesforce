@isTest
private class NSP_AssetTerminateBatch_Test {

    @testSetup
    private static void createTestData() {
        AssetTerminateBatchSettings__c settings = AssetTerminateBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.BatchSize__c = 200;
        settings.IsEnabledRecordTypeRetWo__c = false;
        upsert settings;

        // get Asset RecordTypeId
        Id WO_ASSET_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
        Id TIME_ATTENDANCE_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.TIME_ATTENDANCE_ASSET );
        Id RET_CHOICE_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE );

        // Create Account
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);

         // Create Asset for WO recordtype
        Asset woAsset =(Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAsset.RecordTypeId = WO_ASSET_RECORDTYPE;
        woAsset.Name = 'Test Asset' ;
        woAsset.AccountId = acc.Id ;
        woAsset.NSP_Account_Status__c = NSP_ServiceConstants.TERMINATED;
        woAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        woAsset.NSP_Termination_Date__c = system.Today()-32;
        insert woAsset;

         // Create Asset for Time Attendace recordtype
        Asset timeAttenAsset = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        timeAttenAsset.RecordTypeId = TIME_ATTENDANCE_ASSET;
        timeAttenAsset.Name = 'Test Asset TIME' ;
        timeAttenAsset.AccountId = acc.Id ;
        timeAttenAsset.NSP_Product_Line__c ='Time & Attendance';
        timeAttenAsset.NSP_ProductBundle__c = NSP_ServiceConstants.WoWSAsset;
        insert timeAttenAsset;

        // Create Asset for RET Choice recordtype
        Asset RETChoiceAsset = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        RETChoiceAsset.RecordTypeId = RET_CHOICE_ASSET;
        RETChoiceAsset.Name = 'Test Asset RET' ;
        RETChoiceAsset.AccountId = acc.Id ;
        RETChoiceAsset.NSP_Product_Line__c ='Retirement Services';
        RETChoiceAsset.NSP_ProductBundle__c = NSP_ServiceConstants.WoWSAsset;
        insert RETChoiceAsset;

    }

    private static testMethod void assetBatchRecTypeWoTest() {
        Test.startTest();
        NSP_AssetTerminateBatch assetBatch = new NSP_AssetTerminateBatch();
        database.executeBatch(assetBatch);
        Test.stopTest();
        Asset assetobject = [SELECT Id, Name, NSP_ProductBundle__c, Status FROM Asset WHERE NSP_ProductBundle__c =: NSP_ServiceConstants.WoWSAsset limit 1];
        System.assertEquals(assetobject.Status, 'Terminated');
    }

}
//