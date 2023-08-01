/**
* Created date: 03/09/2023
* Represents test class for NSP_AccountGroupMemberController helper
*/
@IsTest
public with sharing class NSP_AccountGroupMemberController_Test {
    /**
    * Test data for Accounts, Groups and Group members.
    * @param N/A. 
    * @return void                          
    */
    //setup for test data
    @testSetup
    static void testData() {
        Test.startTest();
        //insert account
        Account accoutObject = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accoutObject.Name = 'account';
        accoutObject.Phone = '11223344';
        accoutObject.NSP_AIMS_Client__c = '11223344';
        insert accoutObject; 

        Account accoutObject2 = new Account();
        accoutObject2.Name = 'account2';
        accoutObject2.Phone = '11223355';
        accoutObject2.NSP_AIMS_Client__c = '11223355';
        insert accoutObject2;
        // insert account group
        Id autoCreatedRecordTypeId = Schema.SObjectType.NSP_Account_Group__c.getRecordTypeInfosByName().get('Automatically Created').getRecordTypeId();
        NSP_Account_Group__c accountGroupRec = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        accountGroupRec.Name = 'Account Health - Test Grp 1';
        accountGroupRec.NSP_Tag__c = 'Test Grp 1';
        accountGroupRec.NSP_Type__c = 'Account Health';
        accountGroupRec.NSP_Account__c = accoutObject.name;
        accountGroupRec.RecordTypeId = autoCreatedRecordTypeId;
        INSERT accountGroupRec;
        
        NSP_Account_Group__c controlledAccountGroup = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        controlledAccountGroup.Name = 'Controlled Group - Test Grp 2';
        controlledAccountGroup.NSP_Tag__c = 'Test Grp 2';
        controlledAccountGroup.NSP_Type__c = 'Controlled Group';
        controlledAccountGroup.RecordTypeId = autoCreatedRecordTypeId;
        INSERT controlledAccountGroup;
        //insert account group member
        NSP_Account_Group_Member__c accGrpMem = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        accGrpMem.NSP_Member_Account__c = accoutObject.Id;
        accGrpMem.NSP_Group__c = accountGroupRec.Id;
        INSERT accGrpMem;

        NSP_Account_Group_Member__c accGrpMem2 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        accGrpMem2.NSP_Member_Account__c = accoutObject.Id;
        accGrpMem2.NSP_Group__c = controlledAccountGroup.Id;
        INSERT accGrpMem2;

        NSP_Account_Group__c growthForecastAcc1 = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        growthForecastAcc1.Name = 'Growth Forecast - Test Grp 1';
        growthForecastAcc1.NSP_Tag__c = 'Test Grp 2';
        growthForecastAcc1.NSP_Type__c = NSP_ServiceConstants.GROWTH_FORECAST;
        growthForecastAcc1.NSP_Account__c = accoutObject.name;
        growthForecastAcc1.RecordTypeId = autoCreatedRecordTypeId;
        INSERT growthForecastAcc1;
        
        NSP_Account_Group__c groupRenewalAcc1 = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        groupRenewalAcc1.Name = 'Renewal Probability - Test Grp 1';
        groupRenewalAcc1.NSP_Tag__c = 'Test Grp 2';
        groupRenewalAcc1.NSP_Type__c = NSP_ServiceConstants.RENEWAL_PROBABILITY;
        groupRenewalAcc1.NSP_Account__c = accoutObject.name;
        groupRenewalAcc1.RecordTypeId = autoCreatedRecordTypeId;
        INSERT groupRenewalAcc1;
        
        NSP_Account_Group_Member__c acc1GrpMem1 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        acc1GrpMem1.NSP_Member_Account__c = accoutObject.Id;
        acc1GrpMem1.NSP_Group__c = growthForecastAcc1.Id;
        acc1GrpMem1.NSP_Primary__c = true;
        INSERT acc1GrpMem1;
        
        NSP_Account_Group_Member__c acc2GrpMem1 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        acc2GrpMem1.NSP_Member_Account__c = accoutObject2.Id;
        acc2GrpMem1.NSP_Group__c = growthForecastAcc1.Id;
        acc2GrpMem1.NSP_Primary__c = false;
        INSERT acc2GrpMem1;
        
        NSP_Account_Group_Member__c acc2Renewal = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        acc2Renewal.NSP_Member_Account__c = accoutObject2.Id;
        acc2Renewal.NSP_Group__c = groupRenewalAcc1.Id;
        acc2Renewal.NSP_Primary__c = false;
        INSERT acc2Renewal;
        
        NSP_Account_Group_Member__c acc2AccHealth = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        acc2AccHealth.NSP_Member_Account__c = accoutObject2.Id;
        acc2AccHealth.NSP_Group__c = accountGroupRec.Id;
        acc2AccHealth.NSP_Primary__c = false;
        INSERT acc2AccHealth;
        
        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        Asset asset1 = new Asset();
        asset1.recordtypeId = wORecordTypeId;
        asset1.AccountId = accoutObject2.Id;
        asset1.Name = 'account2 Asset';
        INSERT asset1;
        Test.stopTest();
    }

    /** Test Account Group Functionality for Controlled Group */
    @IsTest
    static void testfetchAccountGroupMemberRecords() {
        Test.startTest();
        List<String> accountGroupFields = new List<String>{'Id','RecordTypeId','Name'};
        String query = new NSP_QueryBuilder('NSP_Account_Group__c', accountGroupFields)
                        .addFilter('NSP_Type__c','Controlled Group').build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);
        Map<String, List<NSP_Account_Group_Member__c>> accGrp = NSP_AccountGroupMemberController.fetchAccountGroupMemberRecords(accGrpRecord.Id);
        Assert.areEqual(1, accGrp.size());
        System.assert(accGrp.size() == 1);
        Test.stopTest();
    }

    /** Test Account Group Functionality for Account Health Group */
    @IsTest
    static void testfetchControlledGrpAccountGroupMemberRecords() {
        Test.startTest();
        List<String> accountGroupFields = new List<String>{'Id','RecordTypeId','Name'};
        String query = new NSP_QueryBuilder('NSP_Account_Group__c', accountGroupFields)
                        .addFilter('NSP_Type__c','Account Health').build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);
        Map<String, List<NSP_Account_Group_Member__c>> accGrp = NSP_AccountGroupMemberController.fetchAccountGroupMemberRecords(accGrpRecord.Id);
        Assert.areEqual(1, accGrp.size());
        System.assert(accGrp.size() == 1);
        Test.stopTest();
    }

    /** Test Account Group Functionality to create self group */
    @IsTest
    static void testCreateSelfGroup() {
        Test.startTest();
        List<String> accountFields = new List<String>{'Id','Name'};
        String accQuery = new NSP_QueryBuilder('Account', accountFields)
                        .addFilter('Name','account2').build();
        Account accRecord = Database.query(accQuery);
        
        List<String> accountGrpMemberFields = new List<String>{'Id','NSP_Member_Account__c', 'NSP_ByPassValidation__c', 'NSP_Type__c'};
        String accMemberQuery = new NSP_QueryBuilder('NSP_Account_Group_Member__c', accountGrpMemberFields)
                        .addFilter('NSP_Type__c',NSP_ServiceConstants.GROWTH_FORECAST)
            			.addFilter('NSP_Primary__c',false).build();
        NSP_Account_Group_Member__c accGroupMember = Database.query(accMemberQuery);
        
        //CreateSelfGroup for Growth Forecast
        NSP_AccountGroupMemberController.createSelfGroup(accGroupMember.Id, accGroupMember.NSP_Member_Account__c, NSP_ServiceConstants.GROWTH_FORECAST, accRecord.Name);
        
        List<String> accountGrpFields = new List<String>{'Id','Name', 'NSP_Account__c', 'NSP_Type__c'};
        String accGrpQuery = new NSP_QueryBuilder('NSP_Account_Group__c', accountGrpFields)
                        .addFilter('NSP_Type__c', NSP_ServiceConstants.GROWTH_FORECAST)
            			.addFilter('NSP_Account__c','account2').build();
        NSP_Account_Group__c accGrp = Database.query(accGrpQuery);
        System.assertEquals(accGrp.NSP_Type__c, NSP_ServiceConstants.GROWTH_FORECAST);
        
        //CreateSelfGroup for Account Health
        String accHealthGroupQuery = new NSP_QueryBuilder('NSP_Account_Group_Member__c', accountGrpMemberFields)
                        .addFilter('NSP_Type__c',NSP_ServiceConstants.ACCOUNT_HEALTH)
            			.addFilter('NSP_Primary__c',false).build();
        NSP_Account_Group_Member__c healthAccGroup = Database.query(accHealthGroupQuery);
        NSP_AccountGroupMemberController.createSelfGroup(healthAccGroup.Id, healthAccGroup.NSP_Member_Account__c, NSP_ServiceConstants.ACCOUNT_HEALTH, accRecord.Name);
        
       // List<String> accountGrpFields = new List<String>{'Id','Name', 'NSP_Account__c', 'NSP_Type__c'};
        String acchealthGrpQueryAcc2 = new NSP_QueryBuilder('NSP_Account_Group__c', accountGrpFields)
                        .addFilter('NSP_Type__c', NSP_ServiceConstants.ACCOUNT_HEALTH)
            			.addFilter('NSP_Account__c','account2').build();
        NSP_Account_Group__c acc2HealthGrp = Database.query(acchealthGrpQueryAcc2);
        System.assertEquals(acc2HealthGrp.NSP_Type__c, NSP_ServiceConstants.ACCOUNT_HEALTH);        
        
        Test.stopTest();
    }
    
    //test method to verify Self Account Group 
    //Testing scenario for negative testing
    @IsTest
    static void testIsSelfAccountGroup() {
        Test.startTest();
        
        List<String> groupFields = new List<String>{'Id','Name', 'NSP_Account__c'};
        String accQuery = new NSP_QueryBuilder('NSP_Account_Group__c', groupFields)
                        .addFilter('NSP_Type__c','Account Health').build();
        NSP_Account_Group__c groupRecord = Database.query(accQuery);        
		Boolean isSelfGroup = NSP_AccountGroupMemberController.isSelfAccountGroup(groupRecord.id, 'account2');
      
        System.assertEquals(isSelfGroup, false);        
        Test.stopTest();
    }
}