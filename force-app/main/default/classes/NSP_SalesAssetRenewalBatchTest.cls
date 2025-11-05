@isTest
private class NSP_SalesAssetRenewalBatchTest {

    @testSetup
    private static void createData() {
        Account accountRecord = new Account(
            Name = 'Test Account 1'
        );

        Test.startTest();
        insert accountRecord;

        Opportunity opportunityRecord = new Opportunity(
            Name='TestOppty Account',
            AccountId=accountRecord.Id,
            StageName = 'Prospecting',
            CloseDate=system.today().addDays(60),
            Type='New Product'
        );

        insert opportunityRecord;

        Product2 woProductRecord = new Product2(
            Name=System.Label.NSP_ProductNamesForAssetRenewalOpportunities.split(',')[0],
            ProductCode='WORKFORCE OPTIMISATION',
            IsActive=true
        );

        insert woProductRecord;

        //create Asset Record
        Asset assetRecord = new Asset(
            Name='Asset1',
            AccountId = accountRecord.Id,
            NSP_Active_No_Employees__c = 100,
            Product2Id = woProductRecord.Id,
            NSP_Renewal_Date__c = System.today().addDays(Integer.valueOf(System.Label.NSP_Sales_NumberOfDaysBeforeRenewalDate))
        );

        insert assetRecord;

        Test.stopTest();
    }

    @isTest
    private static void salesAssetRenewalBatchExecuteTest() {
        Test.startTest();
        NSP_SalesAssetRenewalBatch batchObject = new NSP_SalesAssetRenewalBatch();
        Database.executeBatch(batchObject,3);
        Test.stopTest();
        List<Opportunity> oppObj = [SELECT Id FROM Opportunity WHERE Name != null limit 1];
        system.assertEquals(oppObj.size(),1);
    }

}
//