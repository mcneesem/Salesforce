@isTest
private class NSP_SingleRelatedListControllerTest {

    @testSetup
    private static void testData() {
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;
    }

    @isTest
    private static void testHistoryTrackingAView() {
        String jsonData = '{\"fields\":\"NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,\\tNSP_Modified_By__r.Name\",\"relatedFieldApiName\":\"NSP_Sobject_Record_Id__c\",\"recordId\":\"00111000028nQgoAAE\",\"numberOfRecords\":50001,\"sobjectApiName\":\"NSP_SObjects_History_Tracking__b\",\"sortedBy\":\"NSP_Modified_Date__c\",\"sortedDirection\":\"ASC\"}';
        Test.startTest();
        String output = NSP_SingleRelatedListController.initData(jsonData);
        Test.stopTest();
        system.assertNotEquals(null, output);
        NSP_SingleRelatedListController.testGetFieldLabel( 'Name' );
        NSP_SingleRelatedListController.testGetFieldLabel( 'Name' );
        NSP_SingleRelatedListController.testGetRecords( jsonData );
    }

    @isTest
    private static void testDeleteRecord() {
        List<Account> accountList = [SELECT ID FROM ACCOUNT WHERE NAME = 'Test Account' ];
        Test.startTest();
        Boolean result = NSP_SingleRelatedListController.deleteRecord(accountList[0].id);
        Test.stopTest();
        system.assertEquals(true, result);
    }

    @isTest
    private static void testDeleteNullRecord() {
        Boolean exceptionThrown = false;
        try{
            Test.startTest();
            Boolean result = NSP_SingleRelatedListController.deleteRecord(null);
            Test.stopTest();
        }catch (Exception excep){
          exceptionThrown = true;
        }finally{
           system.assertEquals(true, exceptionThrown, 'Expected an exception to be thrown, but there was no exception');
        }
    }

    @isTest
    private static void testIncorrectJSONFile() {
        Boolean exceptionThrown = false;
        try{
            String jsonData = '{\"fields\":\"NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,\\tNSP_Modified_By__r.Name\",\"relatedFieldApiName\":\"NSP_Sobject_Record_Id__c\",\"recordId\":\"00111000028nQgoAAE\",\"numberOfRecords\":"50001",\"sobjectApiName\":\"NSP_SObjects_History_Tracking__b\",\"sortedBy\":\"NSP_Modified_Date__c\",\"sortedDirection\":\"ASC\"}';
            Test.startTest();
            String output = NSP_SingleRelatedListController.initData(jsonData);
            Test.stopTest();
        }catch (Exception excep){
          exceptionThrown = true;
        }finally{
           system.assertEquals(true, exceptionThrown, 'Expected an exception to be thrown, but there was no exception');
        }
    }

    @isTest
    private static void testHistoryTrackingIP() {
        String jsonData = '{\"fields\":\"NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,\\tNSP_Modified_By__r.Name\",\"relatedFieldApiName\":\"NSP_Sobject_Record_Id__c\",\"recordId\":\"00111000028nQgoAAE\",\"numberOfRecords\":50001,\"sobjectApiName\":\"NSP_IP_History_Tracking__b\",\"sortedBy\":\"NSP_Modified_Date__c\",\"sortedDirection\":\"ASC\"}';
        Test.startTest();
        List<Map<String,Object>> records = NSP_SingleRelatedListController.getIPHistoryRecords(jsonData);
        Test.stopTest();
        system.assertNotEquals(null, records);
    }

    @isTest
    private static void testHistoryTrackingIPNegative() {
        Test.startTest();
        try{
            List<Map<String,Object>> records = NSP_SingleRelatedListController.getIPHistoryRecords(null);
        } catch(AuraHandledException ex) {
            System.assertEquals( 'Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    private static void testHistoryTrackingIPPeriodHistory() {
        Account testAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        testAccount1.Name = 'Test Account 1' ;
        insert testAccount1;

        Asset dummyAsset = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        dummyAsset.NSP_Client__c = 'null';
        insert dummyAsset;

        Implementation_Profile__c ipRec1 = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        ipRec1.Account__c = testAccount1.Id;
        ipRec1.NSP_Assignment_Notes__c = 'Test';
        ipRec1.NSP_Asset__c = dummyAsset.Id;
        insert ipRec1;

        Implementation_Pay_Period__c payPeriod = (Implementation_Pay_Period__c) NSP_TestDataFactory.createSObject(new Implementation_Pay_Period__c(), 'NSP_TestDataFactory.ImplementationProfileAutomationsDefaults', false);
        payPeriod.NSP_Implementation_Profile__c = ipRec1.Id;
        insert payPeriod;

        Test.startTest();
        try {
            NSP_SingleRelatedListController.RecordsWrapper records = NSP_SingleRelatedListController.getImplementationPayPeriodHistory(payPeriod.Id,0);
            system.assertEquals(1, records.lstRecords.size());
        } catch(AuraHandledException ex) {
            System.assertEquals( 'Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    private static void testHistoryTrackingIPPeriodHistoryNegative() {
        Test.startTest();
        try {
            String jsonData = '{\"fields\":\"NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,\\tNSP_Modified_By__r.Name\",\"relatedFieldApiName\":\"NSP_Sobject_Record_Id__c\",\"recordId\":\"00111000028nQgoAAE\",\"numberOfRecords\":50001,\"sobjectApiName\":\"NSP_IP_History_Tracking__b\",\"sortedBy\":\"NSP_Modified_Date__c\",\"sortedDirection\":\"ASC\"}';
            NSP_SingleRelatedListController.RecordsWrapper records = NSP_SingleRelatedListController.getImplementationPayPeriodHistory('',0);
        } catch(AuraHandledException ex) {
            System.assertEquals( 'Script-thrown exception', ex.getMessage());
        }
        Test.stopTest();
    }


    @isTest
    private static void testgetRelatedClients() {
        Account testAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        testAccount1.Name = 'Test Account 1' ;
        insert testAccount1;

        Asset dummyAsset = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        dummyAsset.NSP_Client__c = 'null';
        insert dummyAsset;

        Implementation_Profile__c ipRec1 = (Implementation_Profile__c)NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c(), 'NSP_TestDataFactory.ImplementationProfileDefaults', false);
        ipRec1.Account__c = testAccount1.Id;
        ipRec1.NSP_Assignment_Notes__c = 'Test';
        ipRec1.NSP_Asset__c = dummyAsset.Id;
        insert ipRec1;

        final NSP_IP_History_Tracking__b oht = new NSP_IP_History_Tracking__b();
        oht.NSP_Field_Label__c = 'Related Clients';
        oht.NSP_Field_Name__c = 'NSP_Related_Clients__c';
        oht.NSP_Sobject_Record_Id__c  = String.valueOf(ipRec1.Id);
        oht.NSP_Old_Value__c = testAccount1.Id;
        oht.NSP_New_Value__c = testAccount1.Id;
        oht.NSP_Modified_By__c = UserInfo.getUserId();
        oht.NSP_Modified_Date__c = System.today();

        Test.startTest();
        List<Map<String,Object>> lstRecords = NSP_SingleRelatedListController.getRelatedClients(new List<NSP_IP_History_Tracking__b>{oht});
        Map<String,Object> ipTrackingrRecord = lstRecords[0];
        system.assertEquals(ipTrackingrRecord.get('NSP_Old_Value__c'), 'Test Account 1');

        Test.stopTest();
    }

}
//