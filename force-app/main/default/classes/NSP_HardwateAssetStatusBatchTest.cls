/**
* Apex Class Name      :  NSP_HardwateAssetStatusBatch
Version              :  1.0                                                                          
Created Date         :  02/21/2023  
Description:This is a test class for NSP_HardwateAssetStatusBatch:
This batch class gets all the Hardware Assets where Terminated Date OR Activation Date is
populated and Changes the Asset Status for different use cases
*/
@isTest
public class NSP_HardwateAssetStatusBatchTest {
    /*Set up method to create test data*/
    @testSetup
    static void setupTestData(){
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
    public static void testBatchExecution() {
        Test.startTest();
        //execute batch class
        Database.executeBatch(new NSP_HardwateAssetStatusBatch());
        Test.stopTest();
        List<Asset> assetsToTerminate=[SELECT Id,Status FROM Asset WHERE Status=:NSP_CPQConstants.TERMINATED LIMIT 1];
        System.assertEquals(NSP_CPQConstants.TERMINATED, assetsToTerminate[0].Status);
    }
}