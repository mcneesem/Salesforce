@isTest
private class AccountAssetSummaryTest {
    private static final Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'WO' );
    private static final Id wxAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );
    private static final String accountName = 'Test Account';
    private static final String woAssetName = 'WO Asset';

    @testSetup
    private static void testData() {
        Test.startTest();
        AssetTriggerSettings__c settings =  AssetTriggerSettings__c.getInstance( UserInfo.getUserId());
        settings.IsEnabledAccountAssetSummary__c = True;
        upsert settings;
        Account accountObject = new Account();
        accountObject.Name = accountName;
        insert accountObject;
        Asset assetObjWO = new Asset();
        assetObjWO.Name = woAssetName;
        assetObjWO.accountId = accountObject.Id;
        assetObjWO.RecordTypeId = woAssetRecordTypeId;
        assetObjWO.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        assetObjWO.NSP_Product_Line__c = NSP_ServiceConstants.PI_RECRUITING_SERVICES;
        assetObjWO.NSP_Termination_Date__c = date.today();
        insert assetObjWO;
        Test.stopTest();
    }

    @isTest
    private static void insertWXActiveAsset() {
        Test.startTest();
        String assetWO = 'Asset Wo';
        String assetWx = 'Asset Wx';
        Account accountObject = [SELECT Id from Account WHERE Name =: accountName limit 1];
        Asset assetObjWOSS = [SELECT Id from Asset WHERE RecordTypeId =:woAssetRecordTypeId  limit 1];
        assetObjWOSS.NSP_Termination_Date__c = date.today()+1;
        assetObjWOSS.Status = NSP_ServiceConstants.BACKOUT;
        update assetObjWOSS;
        Asset assetObjWX = new Asset();
        assetObjWX.Name = assetWx;
        assetObjWX.accountId = accountObject.Id;
        assetObjWX.RecordTypeId = wxAssetRecordTypeId;
        assetObjWX.NSP_Product_Line__c = NSP_ServiceConstants.PI_RECRUITING_SERVICES;
        assetObjWX.NSP_Termination_Date__c = date.today();
        assetObjWX.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        insert assetObjWX;
        assetObjWX.Status = NSP_ServiceConstants.BACKOUT;
        update assetObjWX;
        Test.stopTest();
        system.assertEquals(assetObjWX.accountId, accountObject.Id);
    }

}
//