/**
 * Represents test class for 
 * Account trigger helper
 * Author: Sales Team
 */

@isTest(SeeAllData=false)
public class NSP_AccountTriggerHelperTest {

       /***********************************************************************************************
 Variables
 ********************************************************************************************/
   private static final String emailencodingkey = 'UTF-8';
   private static final String languagekey = 'en_US'; 
   private static final String timezonesidkey = 'America/Los_Angeles';   
   /***********************************************************************************************/    
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

          UserRole BPArole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        UserRole CPMrole = [SELECT Id FROM UserRole WHERE Name='Channel Program Manager'];
         UserRole LArole = [SELECT Id FROM UserRole WHERE Name='Loyalty Advisor'];
         Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
         UserRole DARole = [SELECT Id FROM UserRole WHERE Name = 'District Administrator'];
    List<User> users = new List<User>();
        //Creating User
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Integration User'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        users.add(userRecord);
       
        User BpaUser = new User(alias = 'jsmit', email='jsmith@acmetestusr.com', 
                                emailencodingkey=emailencodingkey, lastname='Smith', 
                                languagelocalekey=languagekey, 
                                localesidkey=languagekey, profileid = profileobj.Id, userroleid = BPArole.Id,
                                timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' ,
                                username='insperitytestadminuser@insperity.com.testUsr');
         users.add(BpaUser);
        User cpmUser = new User(alias = 'jBPA', email='jsmithyBPA@acmetest.com', 
                                 emailencodingkey=emailencodingkey, lastname='Smith', 
                                 languagelocalekey=languagekey, 
                                 localesidkey=languagekey, profileid = profileobj.Id, userroleid = CPMrole.Id,
                                 timezonesidkey=timezonesidkey, NSP_Sales_Office__c='601' ,
                                 username='insperitytestadminuser@insperity.com.testBPA');
        users.add(cpmUser);
        // Adding Sales Leader User
        User lAUser = new User(alias = 'johnth', email='johnsmith@acme.com', 
                                    emailencodingkey=emailencodingkey, lastname='Smith', 
                                    languagelocalekey=languagekey, 
                                    localesidkey=languagekey, profileid = profileobj.Id, userroleid = LArole.Id,
                                    timezonesidkey=timezonesidkey, 
                                    username='insperitytestadminuser@insperity.com.test2');
        users.add(lAUser);
        
        User dAUser = new User(alias = 'jsmit', email='jsmithda@acmetestusr.com', 
        emailencodingkey=emailencodingkey, lastname='Smithda', 
        languagelocalekey=languagekey, 
        localesidkey=languagekey, profileid = profileobj.Id, userroleid = DARole.Id,
        timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' ,
        username='insperitytestadminuserda@insperity.com.testUsr');
        users.add(dAUser);
        
        User userRecord1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'][0].Id,
            LastName = 'TestClassUser1',
            Email = 'testuser@test1.com',
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
        users.add(userRecord1);
        database.insert(users);
         Group gp1= new Group();
        gp1.Name='0302 Phoenix 2';
            Insert gp1;
          GroupMember cpaGm = new GroupMember (UserOrGroupId = cpmUser.Id, GroupId = gp1.Id);
        GroupMember lAGm = new GroupMember (UserOrGroupId = lAUser.Id, GroupId = gp1.Id);
        GroupMember daGm = new GroupMember (UserOrGroupId = dAUser.Id, GroupId = gp1.Id);
        List<GroupMember> groupMemberList= new List<GroupMember>{cpaGm,lAGm,daGm};
            // Inserting Group Members
            Insert groupMemberList;
      
    }
     /***********************************************************************************************
* MethodName: setChannelPartnerAndLoyaltyAdvisor
* Description : This method is used to populate CPM and LA on Account on insertion based on BPA sales office group
* ********************************************************************************************/
 @isTest
    static void setChannelPartnerAndLoyaltyAdvisorTest() {
        User BpaUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'jsmith@acmetestusr.com' Limit 1];
        System.runAs (BpaUser) {
            //Account creation
            Test.startTest();
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = ACCOUNTTEST1;
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNBoptimizer__DNB_D_U_N_S_Number__c = '876543987';
        insert accoutObject;
            Test.stopTest();
            System.assertEquals(ACCOUNTTEST1, accoutObject.Name);
        }
    }
    
    
       /***********************************************************************************************
* MethodName: restrictAccountChange
* Description : This method is used to allow DA to edit Account,  if the DA is in the same public group as the Account owner.
* ********************************************************************************************/
@isTest
static void restrictAccountChangeTest() {
    User BpaUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'jsmith@acmetestusr.com' Limit 1];
    System.runAs (BpaUser) {
        //Account creation
        Test.startTest();
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = ACCOUNTTEST1;
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNBoptimizer__DNB_D_U_N_S_Number__c = '876543123';
        accoutObject.NumberOfEmployees = 130;
        insert accoutObject;
        Test.stopTest();
        System.assertEquals(ACCOUNTTEST1, accoutObject.Name);
    }
    User daUser = [Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'jsmithda@acmetestusr.com' Limit 1];
    System.runAs (daUser) {
        Account getBPAUserAccount = [SELECT Id, NumberOfEmployees FROM Account WHERE NumberOfEmployees = 130 LIMIT 1];
        getBPAUserAccount.NumberOfEmployees = 140;
    }
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
        List<Account>  accountList = New List<Account>();
         User salesManagerUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'testuser@test1.com' Limit 1];
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTestData'+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE,
                                        NSP_Delete_Account_Teams__c = system.now()));
        }
        accountList[0].NSP_Template_Selection__c = REFPROG3;
        accountList[0].ownerId = salesManagerUser.Id;
        insert accountList;
        
       Set<Id> accIdSet = new Set<Id>(); // Added as part of Test class fix
       Map<Id, Account> accountMapOld = new Map<Id, Account>();
        Map<Id, Account> accountMapNew = new Map<Id, Account>();
        for(Account account : accountList) {
            accIdSet.add(account.Id);
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
            account.NSP_Account_Status__c = ACTIVE;
            account.NSP_Template_Selection__c = 'referralProgramAF-I';
            accountMapOld.put(account.Id, account);
        }
       
        User userRecord1 = [select id from User WHERE LastName = 'TestClassUser1'];
        // Start Test
            List<Account> accountUpdateList = [Select Id, Name, NSP_Account_Owners_Profile__c,NSP_Ready_for_Integration_Sync__c,NSP_Integrated_With__c,NSP_Partner_Lifecycle__c,RecordTypeId,NSP_Account_At_Risk_Level_Image__c From Account WHERE Id =: accountMapOld.keySet()];
            for(Account accountRecord : accountUpdateList) {
                accountRecord.NSP_Delete_Account_Teams__c = system.now(); // Added as part of Test class fix
                accountRecord.NSP_Ready_for_Integration_Sync__c = TRUE;
                accountRecord.ownerId = userRecord1.Id;
                accountRecord.NSP_Stage__c = 'Available';
                 accountMapNew.put(accountRecord.Id, accountRecord);
            }
         Update accountUpdateList;
        Test.startTest();
           
        NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
        helper.setAccountStageWhenOwnerChanged(accountUpdateList);
        helper.updatePublishAccount(accIdSet);
         helper.afterUpdateDirector(accountMapNew, accountMapOld);
         system.assertEquals(salesManagerUser.Id, accountList[0].ownerId);
        Test.stopTest();
 
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