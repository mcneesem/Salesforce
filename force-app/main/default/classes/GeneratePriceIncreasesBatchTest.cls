@isTest
private class GeneratePriceIncreasesBatchTest {

    @testSetup
    private static void createTestData() {
        GeneratePriceIncreasesBatchSettings__c sett = new GeneratePriceIncreasesBatchSettings__c();
        sett.IsEnabled__c = true;
        sett.BatchSize__c = 1;
        sett.MonitorEmailAddresses__c = 'test@invalid.com';
        insert sett;

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.Qualifies_For_Price_Increase__c = true;
        insert objproduct;
        
        Account objaccount = NSP_TestHelper.createAccount(true);
        
        Asset astObj = new Asset();
        astObj.Name = 'testAsset';
        astObj.AccountId = objAccount.id;
        astObj.Status = 'Active';
        insert astObj;

        Purchased_Product__c pp = new Purchased_Product__c();
        pp.Product__c = objproduct.id;
        pp.Total_Price__c = 100;
        pp.Retail_Price__c = 100;
        pp.Asset__c = astObj.id;
        insert pp;
    }

    @isTest
    private static void testGeneratePriceIncreasesBatch() {
        Test.startTest();
        GeneratePriceIncreasesBatch.executeBatch();
        Test.stopTest();

        List<Price_Increase__c> piList = [SELECT id FROM Price_Increase__c];
        System.assertEquals(piList.size(),1);
    }

}
//