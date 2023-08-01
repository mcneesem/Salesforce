/**
Apex Class Name      :  NSP_CustomLookUpControllerTest
Version              :  1.0                                                                          
Created Date         :  11/15/2022  
Function             :  Represents test class for NSP_ContactRollupController class
Story                :    STY-02660                                                                  
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest
private class NSP_CustomLookUpControllerTest {
    private static final String PRIMARY_CONTACT_FIRSTNAME = 'Curie';
    private static final String SECONDARY_CONTACT_FIRSTNAME = 'Mrie';
    
    @testSetup
    static void testData() {
        List<Contact> conList = new List<Contact>();
        List<Account> accList = new List<Account>();
        List<Asset> assList = new List<Asset>();
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.Name = 'Mathey Acc';
        accList.add(oAccount);
        Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount1.Name = 'Messy Acc';
        accList.add(oAccount1);
        Database.insert(accList);
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.FirstName = PRIMARY_CONTACT_FIRSTNAME;
        conList.add(oContact);
        Contact oContact1 = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact1.FirstName = SECONDARY_CONTACT_FIRSTNAME;
        conList.add(oContact1);
        Database.insert(conList);
        
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord.AccountId = oAccount.Id;
        assList.add(assetRecord);
        Asset assetRecord1 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetRecord1.AccountId = oAccount1.Id;
        assList.add(assetRecord1);
        Insert assList;
    }

    /**
    * @Description: This test method is used to check the List of Contact records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    @isTest
    private static void fetchLookUpContactTest(){
        List<Account> getAccounts = [SELECT Id, Name FROM Account WHERE Name != '' LIMIT 1];
        Test.startTest();
        List<sObject> getConList = NSP_CustomLookUpController.fetchLookupData(PRIMARY_CONTACT_FIRSTNAME, 'Contact', getAccounts[0].Id, '');
        Test.stopTest();
        system.assertEquals(true, getConList.size() > 0);
    }
    
    /**
    * @Description: This test method is used to check the List of Contact records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchLookUpContactNegativeTest(){
        Test.startTest();
        List<sObject> getConList = NSP_CustomLookUpController.fetchLookupData('', '', '', '');
        Test.stopTest();
        system.assertEquals(false, getConList.size() > 0);
    }

    /**
    * @Description: This test method is used to check the List of Account records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchLookUpAccountTest(){
        Test.startTest();
        List<sObject> getAccList =  NSP_CustomLookUpController.fetchLookupData('Acc', NSP_ServiceConstants.ACCOUNT_OBJECT, '', '');
        Test.stopTest();
        system.assertEquals(true, getAccList.size() > 0);  
    }
    
    /**
    * @Description: This test method is used to check the List of Account records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchLookUpAccountNegativeTest(){
        Test.startTest();
        List<sObject> getAccList =  NSP_CustomLookUpController.fetchLookupData('', '', '', '');
        Test.stopTest();
        system.assertEquals(false, getAccList.size() > 0); 
    }
    
    /**
    * @Description: This test method is used to check the List of Contact ACR records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchLookUpAccountACRTest(){
        List<Contact> getContact = [SELECT Id, Name FROM Contact WHERE AccountId != '' LIMIT 1];
        Test.startTest();
        List<sObject> getAccList =  NSP_CustomLookUpController.fetchLookupData('Acc', NSP_ServiceConstants.ACCOUNT_OBJECT, '', getContact[0].Id);
        Test.stopTest();  
        system.assertEquals(true, getAccList.size() > 0);
    }
    
    /**
    * @Description: This test method is used to check the List of Contact ACR records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchLookUpAccountACRNegativeTest(){
        Test.startTest();
        List<sObject> getAccList =  NSP_CustomLookUpController.fetchLookupData('Acc', '', '', '');
        Test.stopTest();  
        system.assertEquals(false, getAccList.size() > 1);
    }
    
    /**
    * @Description: This test method is used to check the Default Account records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    @isTest
    private static void fetchDefaultAccountRecord(){
        List<Contact> getContacts = [SELECT Id, Name FROM Contact WHERE AccountId != null LIMIT 1];
        Test.startTest();
        sObject getAccountRecord =  NSP_CustomLookUpController.fetchDefaultRecord('', NSP_ServiceConstants.ACCOUNT_OBJECT, getContacts[0].Id);
        Test.stopTest();  
        system.assertEquals(true, getAccountRecord != null);
    }
    
     /**
    * @Description: This test method is used to check the Default Asset records
    * @Created date: 3/4/2023
    * @return void             
    **/
    @isTest
    private static void fetchDefaultAssetRecord(){
        List<String> FIELDS = new List<String>{'Id', 'Name'};
            
        String accQuery = new NSP_QueryBuilder('Account', FIELDS).addFilter('Name', 'Mathey Acc').addLimit(1).setSecurityEnforce(false).build();
        List<Account> getAccounts =  Database.query(accQuery);
        
        String assetQuery = new NSP_QueryBuilder('Asset', FIELDS).addFilter('AccountId', getAccounts[0].Id).addLimit(1).setSecurityEnforce(false).build();
        List<Asset> getAssets =  Database.query(assetQuery);
        
        Test.startTest();
        sObject getAccountRecord =  NSP_CustomLookUpController.fetchDefaultRecord('', 'Asset', getAssets[0].Id);
        Test.stopTest();  
        system.assertEquals(true, getAccounts != null);
    }
    
    /**
    * @Description: This test method is used to check the Default Account records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    @isTest
    private static void fetchDefaultAccountRecordNegativeTest(){
        Test.startTest();
        sObject getAccountRecord =  NSP_CustomLookUpController.fetchDefaultRecord('', NSP_ServiceConstants.ACCOUNT_OBJECT, '');
        Test.stopTest();  
        system.assertEquals(false, getAccountRecord != null);
    }
    
    /**
    * @Description: This test method is used to check the Default Contact records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchDefaultContactRecord(){
        List<Contact> getContacts = [SELECT Id, Name FROM Contact WHERE AccountId != null LIMIT 1];
        Test.startTest();
        sObject getContactRecord =  NSP_CustomLookUpController.fetchDefaultRecord( getContacts[0].Id, 'Contact', '');
        Test.stopTest();  
        system.assertEquals(true, getContactRecord != null);
    }
    
    /**
    * @Description: This test method is used to check the Default Contact records
    * @Created date: 11/15/2022. 
    * @return void             
    **/
    
    @isTest
    private static void fetchDefaultContactRecordNegativeTest(){
        Test.startTest();
        sObject getContactRecord =  NSP_CustomLookUpController.fetchDefaultRecord( '', 'Contact', '');
        Test.stopTest();  
        system.assertEquals(false, getContactRecord != null);
    }
    
}