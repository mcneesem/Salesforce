@isTest
private class NSP_AssetCreationBpsProjectBatch_Test {
    private static final Id TIME_ATTENDANCE_RECORD_TYPE_ID = NSP_GenericRecordType.getRecordTypeId('Asset', 'Time_Attendance');
    private static final Id TES_BPS_RECTYPE_ID = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'TES_BPS');

    @testSetup
    private static void testData() {
        //inserting Account
        Account acct = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acct.Name = 'Account 1';
        acct.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        insert acct;

        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.recordTypeId = TES_BPS_RECTYPE_ID ;
        project.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
        project.TemplateName__c =  NSP_ServiceConstants.ITA_IMPLEMENTATION;
        insert project;

        Project_Account__c projAccounts =  new Project_Account__c();
        projAccounts.Account__c = acct.Id;
        projAccounts.Project__c = project.Id;
        insert projAccounts;

        Asset assetObj = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj.accountId = acct.Id;
        assetObj.name= 'Test';
        assetObj.RecordTypeId = TIME_ATTENDANCE_RECORD_TYPE_ID;
        insert assetObj;
    }

    @isTest
    private static void testAssetCreationBpsProjectBatch() {
        Test.startTest();
        Account acct = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name = 'Account 1'  LIMIT 1];
        acct.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        update acct;
        //Calling the batch for Asset
        Database.executeBatch(new NSP_AssetCreationBpsProjectBatch(),100); //executes the batch class
        Test.stopTest();
        System.assertEquals(1, [select count() FROM Asset WHERE accountId =: acct.Id LIMIT 20]);
    }

    @isTest
    private static void testAssetCreationOnAddProjectAccountBatch() {
        Test.startTest();
        Account acct = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name = 'Account 1'  LIMIT 1];
        acct.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        update acct;

        pse__Proj__c project2 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project2.recordTypeId = TES_BPS_RECTYPE_ID ;
        project2.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
        project2.TemplateName__c =  NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        insert project2;

        Project_Account__c projAccounts2 =  new Project_Account__c();
        projAccounts2.Account__c = acct.Id;
        projAccounts2.Project__c = project2.Id;
        insert projAccounts2;

        //Calling the batch for Asset
        Database.executeBatch(new NSP_AssetCreationBpsProjectBatch(),100); //executes the batch class
        Test.stopTest();
        System.assertEquals([select count() FROM Asset WHERE accountId =: acct.Id LIMIT 20] > 0, true);
    }

    @isTest
    private static void testAssetCreationWithDifferentTemplate() {
        Test.startTest();
        Account acct = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name = 'Account 1'   LIMIT 1];
        acct.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        update acct;

        pse__Proj__c project3 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project3.recordTypeId = TES_BPS_RECTYPE_ID ;
        project3.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
        project3.TemplateName__c =  NSP_ServiceConstants.BT_ENGAGEMENT_PLAN;
        insert project3;

        Project_Account__c projAccounts3 =  new Project_Account__c();
        projAccounts3.Account__c = acct.Id;
        projAccounts3.Project__c = project3.Id;
        insert projAccounts3;

        //Calling the batch for Asset
        Database.executeBatch(new NSP_AssetCreationBpsProjectBatch(),100); //executes the batch class
        Test.stopTest();
        System.assertEquals([select count() FROM Asset WHERE accountId =: acct.Id LIMIT 20] > 0, true);
    }

}
//