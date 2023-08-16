/**
Apex Class Name      :  NSP_AssetFLSACaseCreationBatchTest for NSP_AssetFLSACaseCreationBatch
Version              :  1.0                                                                          
Created Date         :  1/9/2022   
Function             :  Test class for NSP_AssetFLSACaseCreationBatch 
Story                :  STY-02080                                                                     
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti                     1/9/2022          First Iteration
*/

@isTest
public class NSP_AssetFLSACaseCreationBatchTest {
	
    /***********************************************************************************************
    * MethodName: setUpTestData
    * Description : Test Data Method
    * ********************************************************************************************/
    @testSetup
    private static void setUpTestData(){
        Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
        List<Account> accList = new List<Account>();
        List<Asset> assetList = new List<Asset>();
        List<NSP_Sub_Client__c> subClientList = new List<NSP_Sub_Client__c>();
        
        User newUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Division = 'FLSA',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert newUser;
        
        system.runAs(newUser){
        //create account record
        Account acct1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acct1.NSP_Sales_Office__c = '4499';
        accList.add(acct1);
        
        Account acct2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acct2.Name = 'Test FLSA Account';
        accList.add(acct2);
        
        Database.insert(accList);
        
        Asset assetRecord0 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord0.AccountId = acct2.Id;
        assetRecord0.NSP_Client_Segment_type__c = NSP_ServiceConstants.EG100AssetSegment;
        assetRecord0.RecordTypeId = WOAssetRecordTypeId;
        assetRecord0.NSP_AIMS_First_Pay_Date__c = System.today().addDays(-30);
        assetRecord0.NSP_Unique_Active_Employee__c = 80;
        assetList.add(assetRecord0);
        
        Asset assetRecord1 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord1.AccountId = acct1.Id;
        assetRecord1.NSP_Client_Segment_type__c = NSP_ServiceConstants.EG100AssetSegment;
        assetRecord1.RecordTypeId = WOAssetRecordTypeId;
        assetRecord1.NSP_AIMS_First_Pay_Date__c = System.today().addDays(-24);
        assetRecord1.NSP_Unique_Active_Employee__c = 80;
        assetList.add(assetRecord1);
        
        Asset assetRecord2 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord2.AccountId = acct1.Id;
        assetRecord2.NSP_Client_Segment_type__c = NSP_ServiceConstants.MMAssetSegment;
        assetRecord2.RecordTypeId = WOAssetRecordTypeId;
        assetRecord2.NSP_AIMS_First_Pay_Date__c = System.today().addDays(-24);
        assetList.add(assetRecord2);
        
        Asset assetRecord3 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord3.AccountId = acct1.Id;
        assetRecord3.NSP_Client_Segment_type__c = NSP_ServiceConstants.MMEAssetSegment;
        assetRecord3.RecordTypeId = WOAssetRecordTypeId;
        assetRecord3.NSP_AIMS_First_Pay_Date__c = System.today().addDays(-24);
        assetList.add(assetRecord3);
        
        Database.insert(assetList);
        
        NSP_Sub_Client__c subClient1 = (NSP_Sub_Client__c)NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClient1.NSP_Account__c = acct1.Id;
        subClient1.NSP_Asset__c = assetRecord1.Id;
        subClientList.add(subClient1);
        
        NSP_Sub_Client__c subClient2 = (NSP_Sub_Client__c)NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClient2.NSP_Account__c = acct1.Id;
        subClient2.NSP_Asset__c = assetRecord2.Id;
        subClientList.add(subClient2);
        
        NSP_Sub_Client__c subClient3 = (NSP_Sub_Client__c)NSP_TestDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClient3.NSP_Account__c = acct1.Id;
        subClient3.NSP_Asset__c = assetRecord3.Id;
        subClientList.add(subClient3);
        
        Database.insert(subClientList);
        
        //create an account team record
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Account__c = acct1.Id;
        accTeam.NSP_Role__c = NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR;
        accTeam.NSP_User__c = UserInfo.getUserId();
        Database.insert(accTeam);
        
        //create another account team record
        NSP_Account_Team__c accTeam1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam1.NSP_Account__c = acct1.Id;
        accTeam1.NSP_Role__c = NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT;
        accTeam1.NSP_User__c = UserInfo.getUserId();
        Database.insert(accTeam1);
        
        //create FLSA mapping record
        NSP_BPA_Mapping__c bpaMapping = (NSP_BPA_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_BPA_Mapping__c(), 'NSP_TestDataFactory.fLSAMappingDefaults', false);
        bpaMapping.NSP_Sales_Office__c = '504';
        bpaMapping.NSP_FLSA_Specialist__c = UserInfo.getUserId();
        Database.insert(bpaMapping);
        
        NSP_BPA_Mapping__c bpaMapping1 = (NSP_BPA_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_BPA_Mapping__c(), 'NSP_TestDataFactory.fLSAMappingDefaults', false);
        bpaMapping1.NSP_BPA__c = UserInfo.getUserId();
        bpaMapping1.NSP_FLSA_Specialist__c = UserInfo.getUserId();
        Database.insert(bpaMapping1);
        }
    }
    
    
    /***********************************************************************************************
    * MethodName: testCaseCreation
    * Description : Test method to check if cases are created
    * Parameters : N/A
    * return : void
    *********************************************************************************************/
    
    @isTest
    private static void testCaseCreation(){
        test.startTest();
        Database.executeBatch(new NSP_AssetFLSACaseCreationBatch());
        test.stopTest();
        List<String> accFields = new List<String>{'Id', 'NSP_Sales_Office__c'};
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accFields)
                         .setSecurityEnforce(false)
            			 .addFilter('NSP_Sales_Office__c', '4499')
            			 .addLimit(1);
        String query = queryBuilder.build();    
        Account acct = Database.query(query);
        
        List<String> caseFields = new List<String>{'Id', 'AccountId'};
        NSP_QueryBuilder caseQueryBuilder = new NSP_QueryBuilder('Case', caseFields)
            								.setSecurityEnforce(false)
            								.addFilter('AccountId', acct.Id)
        									.addLimit(1);
        String caseQuery = caseQueryBuilder.build();
        List<Case> caseRecList = (List<Case>)Database.query(caseQuery);
        
        System.assertEquals(1, caseRecList.size());
    }
    
    /***********************************************************************************************
    * MethodName: negativeTestCaseCreation
    * Description : Negative Test method
    * Parameters : N/A
    * return : void
    *********************************************************************************************/
    @isTest
    private static void negativeTestCaseCreation(){
        Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
        
        List<String> accFields = new List<String>{'Id', 'NSP_Sales_Office__c'};
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accFields)
                         .setSecurityEnforce(false)
            			 .addFilter('Name', 'Test FLSA Account')
            			 .addLimit(1);
        String query = queryBuilder.build();    
        Account acct = Database.query(query);
        
        List<String> assetFields = new List<String>{
            'NSP_Client_Segment_type__c',
            'NSP_Unique_Active_Employee__c',
            'RecordTypeId',
            'AccountId'
        };
            
        NSP_QueryBuilder assetQueryBuilder = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            								.addFilter('RecordTypeId', WOAssetRecordTypeId)
            								.addFilter('NSP_Client_Segment_type__c', NSP_ServiceConstants.EG100AssetSegment)
            								.addFilter('AccountId', acct.Id)
            								.setSecurityEnforce(false)
            								.addLimit(1);
        String assetQuery = assetQueryBuilder.build();
        Asset assetRec = Database.query(assetQuery);
        assetRec.NSP_AIMS_First_Pay_Date__c = System.today().addDays(-1);
        
		test.startTest();
        Database.update(assetRec);
        Database.executeBatch(new NSP_AssetFLSACaseCreationBatch());
        test.stopTest();        
        
        List<String> caseFields = new List<String>{'Id', 'AccountId'};
        NSP_QueryBuilder caseQueryBuilder = new NSP_QueryBuilder('Case', caseFields)
            								.setSecurityEnforce(false)
            								.addFilter('AccountId', acct.Id)
        									.addLimit(1);
        String caseQuery = caseQueryBuilder.build();
        List<Case> caseRecList = (List<Case>)Database.query(caseQuery);
        
        System.assertEquals(0, caseRecList.size());

    }
}