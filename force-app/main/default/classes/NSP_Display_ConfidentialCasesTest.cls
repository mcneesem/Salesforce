/**
Apex Class Name      :  NSP_Display_ConfidentialCasesTest
Version              :  1.0  
Author               :  Teja Mani                                                                        
Created Date         :   10/19/2022  
Function             :   Represents test class for NSP_Display_ConfidentialCases
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest
private class NSP_Display_ConfidentialCasesTest {
    
    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
    private static final String WXWAPARENTID = '12345';
    private static final String STATUS_ACTIVE = 'Active';
    
    @testSetup
    static void testData() {
        List<case> caseList = new List<Case>();
        List<User> lstUserToInsert = new List<User>();
        User sysAdminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'SystemAdmin',
            Email = 'sysadmin@insperity.com',
            Username = 'sysadmin@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        lstUserToInsert.add(sysAdminUser);
        User PEOUSER1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        lstUserToInsert.add(PEOUSER1);
        User PEOUSER2 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST2',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        lstUserToInsert.add(PEOUSER2);
        insert lstUserToInsert;
        Account newAccount;
        Contact newContact;
        Asset woAsset;
        
        System.runAs (sysAdminUser) {
            newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
            newAccount.NSP_Premier_Pathway_Client__c ='12345ABCDEF';
            insert newAccount;
            
            //create contact
            newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            newContact.Account = newAccount;
            newContact.NSP_Per_ID__c ='ABCDEF12345';
            insert newContact;
            
            woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
            woAsset.AccountId = newAccount.Id;
            woAsset.Status=STATUS_ACTIVE;
            woAsset.recordTypeId = woRecordTypeId;
            woAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.EG100AssetSegment;
            insert woAsset;
        }
        
        System.runAs (PEOUSER1) {
            //create contact
            newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            newContact.Account = newAccount;
            newContact.NSP_Per_ID__c ='ABCDEF123456';
            insert newContact;
            
            Case accNewCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            accNewCase.NSP_Confidential__c = true;
            accNewCase.Status = NSP_ServiceConstants.OPEN;
            accNewCase.AccountId = newAccount.id;
            accNewCase.ClosedDate = System.today();
            caseList.add(accNewCase);
            
            Case conNewCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            conNewCase.NSP_Confidential__c = true;
            accNewCase.ContactId = newContact.id;
            conNewCase.Status = NSP_ServiceConstants.OPEN;
            conNewCase.ClosedDate = System.today();
            caseList.add(conNewCase);
            
            Case assetNewCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            assetNewCase.NSP_Confidential__c = true;
            assetNewCase.AssetId = woAsset.id;
            assetNewCase.Status = NSP_ServiceConstants.OPEN;
            conNewCase.ClosedDate = System.today();
            caseList.add(assetNewCase);
            Database.insert(caseList);
        }
    }
    /**
* @Description: This test method is used to cover getRelatedCases
* @Created date: 10/19/2022. 
* @return void             
*     */
    @isTest
    private static void getAccountRelatedCasesTest(){ 
        
        List<Case> getCaseList = [SELECT Id, AccountId, AssetId, ContactId, Status, NSP_Opened_Date__c, NSP_Confidential__c, ClosedDate FROM Case WHERE AccountId != null LIMIT 1];
        User getPeoUser2 = [SELECT Id, CompanyName FROM User WHERE CompanyName = 'Test2'];
        Test.startTest();
        System.runAs(getPeoUser2){
            List<Case> assertCaseList = NSP_Display_ConfidentialCases.getRelatedCases(NSP_ServiceConstants.OPEN, null, null, getCaseList[0].AccountId, 'Account', '','');
            system.assertEquals(assertCaseList.size()>0, true);
        }
        Test.stopTest();
        system.assert(getCaseList[0].NSP_Confidential__c);
    }
    
    /**
* @Description: This test method is used to cover getRelatedCases
* @Created date: 10/19/2022. 
* @return void             
*     */
    @isTest
    private static void getContactRelatedCasesTest(){ 
        User getPeoUser2 = [SELECT Id, CompanyName  FROM User WHERE CompanyName  = 'Test2'];
        List<Case> getCaseList = [SELECT Id, AccountId, AssetId, ContactId, Status, NSP_Opened_Date__c, NSP_Confidential__c, ClosedDate FROM Case WHERE ContactId != null LIMIT 1];
        Test.startTest();
        System.runAs(getPeoUser2){
            List<Case> assertCaseList  = NSP_Display_ConfidentialCases.getRelatedCases(NSP_ServiceConstants.OPEN, null, null, getCaseList[0].ContactId, 'Contact', '','');
            system.assertEquals(assertCaseList.size()>0, true);
        }
        Test.stopTest();
        system.assert(getCaseList[0].NSP_Confidential__c);
    }
    
    /**
* @Description: This test method is used to cover getRelatedCases
* @Created date: 10/19/2022. 
* @return void             
*     */
    @isTest
    private static void getAssetRelatedCasesTest(){ 
        User getPeoUser2 = [SELECT Id, CompanyName FROM User WHERE CompanyName  = 'Test2'];
        List<Case> getCaseList = [SELECT Id, AccountId, AssetId, ContactId, Status, NSP_Confidential__c, NSP_Opened_Date__c, ClosedDate FROM Case WHERE AssetId != null LIMIT 1];
        Test.startTest();
        System.runAs(getPeoUser2){
            List<Case> assertCaseList = NSP_Display_ConfidentialCases.getRelatedCases(NSP_ServiceConstants.OPEN, null, null, getCaseList[0].AssetId, 'Asset', '','');           
            system.assertEquals(assertCaseList.size()>0, true);
        }
        Test.stopTest();
        
    }

          /**
* @Description: This test method is used to cover getRelatedCases Negative Case
* @Created date: 11/21/2022. 
* @return void             
*     */
@isTest
private static void getAssetRelatedCasesNegativeTest(){ 
    User getPeoUser2 = [SELECT Id, CompanyName FROM User WHERE CompanyName  = 'Test2'];
    List<Case> getCaseList = [SELECT Id, AccountId, AssetId, ContactId, Status, NSP_Confidential__c, NSP_Opened_Date__c, ClosedDate FROM Case WHERE AssetId != null LIMIT 1];
    Test.startTest();
    System.runAs(getPeoUser2){
        List<Case> assertCaseList = NSP_Display_ConfidentialCases.getRelatedCases('', system.today(), system.today(), getCaseList[0].AssetId, 'Asset', '','>');  
        NSP_Display_ConfidentialCases.split(getCaseList, 1);         
        system.assertEquals(assertCaseList.size()>0, false);
    }
    Test.stopTest();
    
}
    
}