@isTest
private class NSP_AccountTerminationBatch_Test {
    private static final String OPP_TYPE = 'CAMS';
    private static final List<String> ASSET_FIELDS = new List<String>{
        'Id',
        'Status',
        'Account.NSP_Sales_Service_Account_Status__c'
    };

    @testSetup
    private static void setupTestData() {
        AccountTerminationBatchSettings__c sett = new AccountTerminationBatchSettings__c();
        sett.IsEnabled__c = true;
        sett.BatchSize__c = 100;
        insert sett;

        //Account creation
        Account accRecord = NSP_TestHelper.createAccount(true);
        Account accRecord2 = NSP_TestHelper.createAccount(true);
        Account accRecord3 = NSP_TestHelper.createAccount(true);
        List<Asset> assetList = new List<Asset>();
        //Create Asset
        Asset assetObj = new Asset();
        assetObj.accountId = accRecord.Id;
        assetObj.NSP_Client__c = 'asset1';
        assetObj.name = 'asset1';
        assetObj.Status = 'Terminated';
        assetObj.Termination_Date__c = system.today()-31;
        assetList.add(assetObj);
        //Create Asset
        Asset assetObj1 = new Asset();
        assetObj1.accountId = accRecord.Id;
        assetObj1.NSP_Client__c = 'asset2';
        assetObj1.name = 'asset2';
        assetObj1.Status = 'Terminated';
        assetObj1.Termination_Date__c = system.today().addDays(-30);
        assetList.add(assetObj1);

        Asset assetObj3 = new Asset();
        assetObj3.accountId = accRecord2.Id;
        assetObj3.RecordTypeId = '0124x0000019l8yAAA';
        assetObj3.NSP_Client__c = 'asset3';
        assetObj3.name = 'asset3';
        assetObj3.Status = 'Active';
        assetList.add(assetObj3);

        Asset assetObj4 = new Asset();
        assetObj4.accountId = accRecord2.Id;
        assetObj4.NSP_Client__c = 'asset4';
        assetObj4.name = 'asset4';
        assetObj4.RecordTypeId = '0124x0000019l8yAAA';
        assetList.add(assetObj4);

        Asset assetObj5 = new Asset();
        assetObj5.accountId = accRecord3.Id;
        assetObj5.RecordTypeId = '0124x0000019l8yAAA';
        assetObj5.NSP_Client__c = 'asset5';
        assetObj5.name = 'asset5';
        assetObj5.Status = 'Active';
        assetList.add(assetObj5);
        insert assetList;

        Opportunity  opportuniytObject = NSP_TestHelper.createOpenOpportunity(accRecord.Id, OPP_TYPE, false);
        opportuniytObject.StageName = NSP_ServiceConstants.CLOSED_WON;
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.CloseDate = Date.newInstance(2025,6,25);
        insert opportuniytObject;

        Opportunity  opportuniytObject1 = NSP_TestHelper.createOpenOpportunity(accRecord.Id, OPP_TYPE, false);
        opportuniytObject1.StageName = NSP_ServiceConstants.CLOSED_WON;
        opportuniytObject1.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject1.NSP_Number_of_Employees__c = 100;
        opportuniytObject1.CloseDate = Date.newInstance(2025,6,25);
        insert opportuniytObject1;
    }

    @isTest
    private static void terminateAccount() {
        List<Asset> astList = [SELECT RecordTypeName__c, Status, Name, NSP_Client__c,NSP_Termination_Date__c,Account.NSP_Sales_Service_Account_Status__c  FROM Asset WHERE NSP_Client__c IN ('asset3','asset5')];
        try{
            test.startTest();
            NSP_AccountTerminationBatch.schedule();
            astList[0].Status = 'Terminated';
            astList[1].Status = 'Terminated';
            update astList;
            astList[0].Termination_Date__c = system.today().addDays(-30);
            astList[1].Termination_Date__c = system.today().addDays(-30);
            update astList;
            NSP_AccountTerminationBatch batchSch = new NSP_AccountTerminationBatch('Asset');
            Database.executeBatch(batchSch, 100);
            batchSch.execute(null);
            test.stopTest();
            String query1 = new NSP_QueryBuilder('Asset', ASSET_FIELDS)
                           .addFilter('NSP_Client__c', 'asset5' ).addLimit(1).build();
            Asset asst = Database.query( query1 );
        } catch(Exception ex){
            System.debug( ' ~ ex=' + ex );
        }
    }

    @isTest
    private static void lostAccountCheckTest() {
        List<Asset> assetList = [SELECt Id FROM Asset];
        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity];
        Test.startTest();
        NSP_AccountTerminationBatch.lostAccountCheck(assetList, oppList);
        Test.stopTest();
    }

}
//