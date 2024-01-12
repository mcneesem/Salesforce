/**
 * Apex Class Name : NSP_ServicePlanProjectTaskBatch_Test
 * Function        : Represents test class for NSP_ServicePlanProjectTaskBatch class
 */

@isTest(SeeAllData=false)
public class NSP_ServicePlanProjectTaskBatch_Test {
    @testSetup
    static void testData() {
        
        //Creating Account record
        Account accountRecord = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        accountRecord.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        accountRecord.NSP_First_Pay_Date__c = system.Today();
        INSERT accountRecord;
        
        //Creating Asset record
        String woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset());
        assetRecord.AccountId = accountRecord.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.BTAssetSegment;
        assetRecord.RecordTypeId = woAssetRecordTypeId;
        assetRecord.NSP_Renewal_Date__c = system.Today();
        INSERT assetRecord;
        
        //Creating Account Team record
        NSP_Account_Team__c accountTeamRecord = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c());
        accountTeamRecord.NSP_Account__c = accountRecord.Id;
        accountTeamRecord.NSP_User__c = UserInfo.getUserId();
        accountTeamRecord.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        INSERT accountTeamRecord;
        
        //Creating Sub Client record
        NSP_Sub_Client__c subClientRecord = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c());
        subClientRecord.NSP_Asset__c = assetRecord.Id;
        subClientRecord.NSP_Account__c = accountRecord.Id;
        subClientRecord.NSP_Renewal_Date__c = system.Today();
        subClientRecord.NSP_Client__c = NSP_ServiceConstants.ZERO_ZERO_SUFFIX;
        subClientRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        subClientRecord.NSP_Sub_Client__c = '120000';
        INSERT subClientRecord;
        
        //Creating Project record
        pse__Proj__c projectRecord = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        projectRecord.pse__Account__c = accountRecord.Id;
        projectRecord.TemplateName__c = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
        projectRecord.pse__Is_Template__c = False;
        projectRecord.pse__Project_Status__c = NSP_ServiceConstants.STATUS_ACTIVE;
        projectRecord.pse__Start_Date__c = Date.Today();
        projectRecord.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
        INSERT projectRecord;
    }
    //@ Method Name: testServicePlanProjectTaskBatch
    @IsTest
    static void testServicePlanProjectTaskBatch() {
        Test.startTest();
        Database.executeBatch(new NSP_ServicePlanProjectTaskBatch()); //executes the batch class
        Test.stopTest();
        System.assertEquals(2, [select count() from pse__Project_Task__c WHERE NSP_Category__c =: NSP_ServiceConstants.Client_Management]);
    }
    
    //@ Method Name: testServicePlanProjectTaskBatchNotRun
    @IsTest
    static void testServicePlanProjectTaskBatchNotRun() {
        NSP_Sub_Client__c subClient= [SELECT Id, NSP_Renewal_Date__c FROM NSP_Sub_Client__c WHERE NSP_Account_Status__c =:NSP_ServiceConstants.AIMS_STATUS LIMIT 1];
        subClient.NSP_Renewal_Date__c = system.Today().addDays(1);
        UPDATE subClient;
        Test.startTest();
        Database.executeBatch(new NSP_ServicePlanProjectTaskBatch()); //executes the batch class
        Test.stopTest();
        System.assertEquals(0, [select count() from pse__Project_Task__c WHERE NSP_Category__c =: NSP_ServiceConstants.Client_Management]);
    }
}