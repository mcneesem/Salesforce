/**
 * Represents test class for 
 * Account trigger helper
 * Author: Sales Team
 */

@isTest(SeeAllData=false)
public class NSP_AccountTriggerHelperTest {

    public static final String REFPROG3 = 'referralprogramiii';
    public static final String ACCOUNTTEST1 = 'AccountTest1';
    public static final String AccountTestData1= 'AccountTestData1';
    public static final String ACCOUNTTEST = 'AccountTest';
    public static final String ACTIVE = 'ACTIVE';
    public static final String LASTNAME = 'TestClassUser' ;
    public static final String EN_US = 'en_US';
    public static final String TEXAS = 'TEXAS';
    @testSetup
    static void testData() {

        //Creating User
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Integration User'][0].Id,
            LastName = LASTNAME,
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = EN_US,
            LocaleSidKey = EN_US,
            NSP_Sales_Office__c = '1401'
        );
        insert userRecord;
        User userRecord1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'][0].Id,
            LastName = 'TestClassUser1',
            Email = 'testuser@test.com',
            Username = 'testuser1@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = EN_US,
            LocaleSidKey = EN_US,
            NSP_Sales_Office__c = '1401'
        );
        insert userRecord1;
        List<Account>  accountList = New List<Account>();

        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTestData'+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE,
                            NSP_Delete_Account_Teams__c = system.now()));
        }
        accountList[0].NSP_Template_Selection__c = REFPROG3;
        accountList[0].ownerId = userRecord.Id;
        insert accountList;
    }
    /**
     * Checks the Account After Insert Trigger
     * @param N/A. 
     * @return void                          
     */

    @isTest
    static void testAccountInsert() {
        //variables to hold test data to be inserted
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = ACCOUNTTEST+count, AccountNumber = '0000'+count, recordTypeId=partnerRecordTypeId,BillingState=TEXAS,NumberOfEmployees=150));
        }
        accountList[0].NSP_Template_Selection__c = REFPROG3;
        accountList[0].NumberOfEmployees = 130;
        accountList[0].NSP_Account_Segment__c = 'Emerging Growth';
        Test.startTest();
        insert accountList;
        for(Account account : accountList) {
            accountMap.put(account.Id, account);
        }
        
        Account account = [SELECT Id, Name, AccountNumber,NSP_Account_Owners_Profile__c FROM Account WHERE Name=:ACCOUNTTEST1 LIMIT 1];
        System.assertEquals(ACCOUNTTEST1, account.Name);
        Test.stopTest();
    }
    
    @isTest
    static void testAccountInsert2() {
        //variables to hold test data to be inserted
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        //Creating User
        User userRecord = [select id from User WHERE LastName = :LASTNAME];
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTest'+String.valueOf(count), AccountNumber = String.valueOf(count), recordTypeId=partnerRecordTypeId,BillingState=TEXAS,NumberOfEmployees=150));
        }
        accountList[0].NSP_Template_Selection__c = REFPROG3;
        accountList[0].NumberOfEmployees = 130;
        accountList[0].NSP_Account_Segment__c = 'Emerging Growth';
        // Start Test
        Test.startTest();
        system.runAs(userRecord){
            insert accountList;
        }
        for(Account account : accountList) {
            accountMap.put(account.Id, account);
        }
        Account account = [SELECT Id, Name, AccountNumber,NSP_Account_Owners_Profile__c FROM Account WHERE Name=:ACCOUNTTEST1 LIMIT 1];
        System.assertEquals(ACCOUNTTEST1, account.Name);
        Test.stopTest();
    }

    /**
     * Checks the Account After Update Trigger
     * @param N/A. 
     * @return void                          
     */

    @isTest
    static void testAccountUpdate() {
        
        List<Account> accountList = [Select Id ,Name, NSP_Ready_for_Integration_Sync__c ,NSP_Account_Status__c,NSP_Template_Selection__c 
										FROM Account WHERE Name Like '%AccountTestData%' ];
        
       Set<Id> accIdSet = new Set<Id>(); // Added as part of Test class fix
       Map<Id, Account> accountMapOld = new Map<Id, Account>();
       
        for(Account account : accountList) {
            accIdSet.add(account.Id);
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
            account.NSP_Account_Status__c = ACTIVE;
            account.NSP_Template_Selection__c = 'referralProgramAF-I';
            accountMapOld.put(account.Id, account);
        }
        Account account = [SELECT Id, Name FROM Account WHERE Name =:AccountTestData1 LIMIT 1];
        system.assertEquals(AccountTestData1, account.Name);
        User userRecord1 = [select id from User WHERE LastName = 'TestClassUser1'];
        // Start Test
            List<Account> accountUpdateList = [Select Id, Name, NSP_Account_Owners_Profile__c,NSP_Ready_for_Integration_Sync__c From Account WHERE Id =: accountMapOld.keySet()];
            for(Account accountRecord : accountUpdateList) {
                accountRecord.NSP_Delete_Account_Teams__c = system.now(); // Added as part of Test class fix
                accountRecord.NSP_Ready_for_Integration_Sync__c = TRUE;
                accountRecord.ownerId = userRecord1.Id;
                accountRecord.NSP_Stage__c = 'Available';
            }
        Test.startTest();
            Update accountUpdateList;
        NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
        helper.setAccountStageWhenOwnerChanged(accountUpdateList);
        helper.updatePublishAccount(accIdSet);
        
        Test.stopTest();
         system.assertEquals(AccountTestData1, account.Name);
    }

    /**
     * Checks the Account After Update Trigger
     * @param N/A. 
     * @return void                          
     */

    @isTest
    static void testAccountUpdateMODTemplate() {
        
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMapOld = new Map<Id, Account>();
        List<Account> accountUpdateList = [Select Id, Name, NSP_Ready_for_Integration_Sync__c From Account WHERE Id =: accountMapOld.keySet()];
        for(Account account : accountUpdateList) {
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
        }
        User userRecord = [select id from User WHERE LastName = :LASTNAME];
        // Start Test
        Test.startTest();
        system.runAs(userRecord){
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = ACCOUNTTEST+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE));
        }
        accountList[0].NSP_Template_Selection__c = REFPROG3;
        insert accountList;
        for(Account account1 : accountList) {
            account1.NSP_Ready_for_Integration_Sync__c = FALSE;
            account1.NSP_Account_Status__c = ACTIVE;
            account1.NSP_Template_Selection__c = 'referralProgramAF-I';
            account1.BillingState = TEXAS;
            accountMapOld.put(account1.Id, account1);
        }
        Update accountList;
    }
        Test.stopTest();
        Account accountchk = [SELECT Id, Name FROM Account WHERE Name= :ACCOUNTTEST1 LIMIT 1];
        system.assertEquals(ACCOUNTTEST1, accountchk.Name);
    }

    @isTest
    static void testhandleTask() {
        
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMapOld = new Map<Id, Account>();
        List<Account> accountUpdateList = [Select Id, Name, NSP_Ready_for_Integration_Sync__c From Account WHERE Id =: accountMapOld.keySet()];
        for(Account account : accountUpdateList) {
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
        }
        User userRecord = [select id from User WHERE LastName = :LASTNAME];
        // Start Test
        Test.startTest();
        system.runAs(userRecord){
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = ACCOUNTTEST+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE,NumberOfEmployees = 100));
        }
        
        insert accountList;
        for(Account account1 : accountList) {
            account1.NSP_Ready_for_Integration_Sync__c = FALSE;
            account1.NSP_Account_Status__c = ACTIVE;
            account1.NSP_Template_Selection__c = 'referralProgramAF-I';
            account1.BillingState = TEXAS;
            account1.NSP_Partner_Lifecycle__c = 'Onboarding';
            account1.NSP_Signed_MOD_Document__c = true;
            accountMapOld.put(account1.Id, account1);
        }
            accountList[0].NSP_Partner_Lifecycle__c = ACTIVE;
            accountList[0].NSP_Template_Selection__c = REFPROG3;
            accountList[0].NumberOfEmployees = 150;
            accountList[0].NSP_Delete_Account_Teams__c = System.now();
            accountList[0].NSP_Stage__c = 'New';
            
        Update accountList;
        NSP_AccountTriggerHelper.handleTaskForPartnerContracts(accountList);
    }
        Test.stopTest();
        Account account = [SELECT Id, Name FROM Account WHERE Name= :ACCOUNTTEST1 LIMIT 1];
        system.assertEquals(ACCOUNTTEST1, account.Name);
    }
}