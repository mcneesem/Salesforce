/**
Apex Class Name      :  NSP_ProjectAssetTriggerHelperTest
Author               :  Nischay                                                                        
Created Date         :  10/01/23   
Function             :  This class is used as a test class for  NSP_ProjectAssetTriggerHelper
*/

@isTest
public class NSP_ProjectAssetTriggerHelperTest {

    private static final string TESTNUM = '2343' ;

    /**
    * Does test data setup
    * @param N/A. 
    * @return void                          
    */ 
    @testSetup
    public static void testSetupMethod(){
        Account accountRecord = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        accountRecord.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        INSERT accountRecord;
        
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord.AccountId = accountRecord.Id;
        assetRecord.Name = 'Test Integra Asset';
        assetRecord.NSP_Client__c = TESTNUM;
        assetRecord.RecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','Integra');
        INSERT assetRecord;
       
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.Go_Live_Date__c= System.Today();
        oProject.pse__Account__c = accountRecord.Id;
        insert oProject;
        
    }

    /***********************************************************************************************
    * MethodName: updateAssetFirstPayDateTest
    * Description : Unit Test for updateAssetFirstPayDate
    * ********************************************************************************************/    
    @isTest
    public static void updateAssetFirstPayDateTest(){
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'Status',
            'AccountId',
            'Name',
            'NSP_First_Pay_Date__c'
        };
        String queryAsset = new NSP_QueryBuilder('Asset', assetFields)
                         .addFilter('NSP_Client__c', TESTNUM).addLimit(1).build();
        Asset ast = Database.query(queryAsset);

        List<String> projectFields = new List<String>{
            'Id',
            'Go_Live_Date__c'
        };
        String queryPrj = new NSP_QueryBuilder('pse__Proj__c', projectFields)
                            .addFilter('TemplateName__c', 'Middle Market - Implementation').addLimit(1).setSecurityEnforce(false).build();
        pse__Proj__c oProject = Database.query(queryPrj);

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = ast.Id;
        prjAsset.Project__c = oProject.Id;
        
        Test.startTest();
        	insert prjAsset;
        Test.stopTest();
        Asset astUpdated = Database.query(queryAsset);
        system.assertEquals(astUpdated.NSP_First_Pay_Date__c,  System.Today());
        
    }
    
    /***********************************************************************************************
    * MethodName: updateAssetFirstPayDateException
    * Description : Negative Unit Test for updateAssetFirstPayDate
    * ********************************************************************************************/    
    @isTest
    public static void updateAssetFirstPayDateException(){
        
        Asset ast = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        ast.NSP_Client__c='23431';
        ast.NSP_Company_Name__c='test WO company';
        ast.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','WO');
        insert ast;

        List<String> projectFields = new List<String>{
            'Id',
            'Go_Live_Date__c'
        };
        String queryPrj = new NSP_QueryBuilder('pse__Proj__c', projectFields)
                            .addFilter('TemplateName__c', 'Middle Market - Implementation').addLimit(1).setSecurityEnforce(false).build();
        pse__Proj__c oProject = Database.query(queryPrj);

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = ast.Id;
        prjAsset.Project__c = oProject.Id;
        
        Test.startTest();
        	insert prjAsset;
        Test.stopTest();
        
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'Status',
            'AccountId',
            'Name',
            'NSP_First_Pay_Date__c'
        };
        String queryAsset = new NSP_QueryBuilder('Asset', assetFields)
                         .addFilter('NSP_Client__c', TESTNUM).addLimit(1).build();
        Asset astUpdated = Database.query(queryAsset);
        system.assertNotEquals(astUpdated.NSP_First_Pay_Date__c,  System.Today());
        
    }
    
     @IsTest
    static void afterUpdate() {
        new NSP_ProjectAssetTriggerHandler().afterUpdate(null, null);
         System.assert(new NSP_ProjectAssetTriggerHandler().afterUpdate(null, null) == null);
    }
    @IsTest
    static void beforeDelete() {
        new NSP_ProjectAssetTriggerHandler().beforeDelete(null, null);
         System.assert(new NSP_ProjectAssetTriggerHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_ProjectAssetTriggerHandler().afterDelete(null, null);
         System.assert(new NSP_ProjectAssetTriggerHandler().afterDelete(null, null) == null);
    }
}