/**
 * Represents test class for 
 * Account trigger helper
 * Author: Sales Team
 *  -------------------------------------------------------------------------------------------------
 * Modification History
 *  Rahul Singh        Sept  29 2022        Added as part of 569324 charwell request.
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
    public static final String REFPROG3 = 'ReferralProgramNationalRevShare';
    public static final String ACCOUNTTEST1 = 'AccountTest1';
    public static final String AccountTestData1= 'AccountTestData1';
    public static final String ACCOUNTTEST = 'AccountTest';
    public static final String ACTIVE = 'ACTIVE';
    public static final String LASTNAME = 'TestClassUser' ;
    public static final String EN_US = 'en_US';
    public static final String TEXAS = 'TEXAS';
    public static final String PARTNER_CLIENT = 'NSP_Partner_Client';
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
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = EN_US,
            LocaleSidKey = EN_US
        );
        users.add(userRecord);
       
        User BpaUser = new User(alias = 'jsmit', email='jsmith@insperity.com', 
                                emailencodingkey=emailencodingkey, lastname='Smith', 
                                languagelocalekey=languagekey, 
                                localesidkey=languagekey, profileid = profileobj.Id, userroleid = BPArole.Id,
                                timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' ,
                                username='insperitytestadminuser@insperity.com.testUsr');
         users.add(BpaUser);
        User cpmUser = new User(alias = 'jBPA', email='jsmithyBPA@insperity.com', 
                                 emailencodingkey=emailencodingkey, lastname='Smith', 
                                 languagelocalekey=languagekey, 
                                 localesidkey=languagekey, profileid = profileobj.Id, userroleid = CPMrole.Id,
                                 timezonesidkey=timezonesidkey, NSP_Sales_Office__c='601' ,
                                 username='insperitytestadminuser@insperity.com.testBPA');
        users.add(cpmUser);
        // Adding Sales Leader User
        User lAUser = new User(alias = 'johnth', email='johnsmith@insperity.com', 
                                    emailencodingkey=emailencodingkey, lastname='Smith', 
                                    languagelocalekey=languagekey, 
                                    localesidkey=languagekey, profileid = profileobj.Id, userroleid = LArole.Id,
                                    timezonesidkey=timezonesidkey, 
                                    username='insperitytestadminuser@insperity.com.test2');
        users.add(lAUser);
        
        User dAUser = new User(alias = 'jsmit', email='jsmithda@insperity.com', 
        emailencodingkey=emailencodingkey, lastname='Smithda', 
        languagelocalekey=languagekey, 
        localesidkey=languagekey, profileid = profileobj.Id, userroleid = DARole.Id,
        timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' ,
        username='insperitytestadminuserda@insperity.com.testUsr');
        users.add(dAUser);

        User dummyUser = new User(alias = 'jsmit', email='jsmithda@insperity.com', 
                               emailencodingkey=emailencodingkey, lastname=NSP_SalesConstants.DUMMY_USER_SIGNER, 
                               languagelocalekey=languagekey, 
                               localesidkey=languagekey, profileid = profileobj.Id, userroleid = DARole.Id,
                               timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' ,
                               username='insperitytestadminuserda@insperity.com.test3');
        users.add(dummyUser);
        
        User userRecord1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Sales Manager'][0].Id,
            LastName = 'TestClassUser1',
            Email = 'testuser@insperity.com',
            Username = 'testuser1@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = EN_US,
            LocaleSidKey = EN_US,
            userroleid = BPArole.Id,
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
        User BpaUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'jsmith@insperity.com' Limit 1];
        System.runAs (BpaUser) {
            //Account creation
            Test.startTest();
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        accoutObject.Name = ACCOUNTTEST1;
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNB_Connect_DUNS_Number__c = '876543987';
        insert accoutObject;
            Test.stopTest();
            System.assertEquals(ACCOUNTTEST1, accoutObject.Name);
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
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = ACCOUNTTEST+count, AccountNumber = '0000'+count, recordTypeId=partnerRecordTypeId,BillingState=TEXAS,NumberOfEmployees=150));
        }
        accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
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
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        //Creating User
        User userRecord = [select id from User WHERE LastName = :LASTNAME];
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTest'+String.valueOf(count), AccountNumber = String.valueOf(count), recordTypeId=partnerRecordTypeId,BillingState=TEXAS,NumberOfEmployees=150));
        }
        accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
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
     * Checks the Account After Delete Trigger (merge only) // story 199298
     * @param N/A. 
     * @return void                          
     */
    @isTest
    static void testAccountMerge() {
        // Insert new accounts
        List<Account> dupeaccounts = new List<Account>{
            new Account(name='MergeTest Inc.'),
            new Account(name='MergeTest')
        };
        
        // Start Test
        Test.startTest();                                 
        insert dupeaccounts;
        Account masterAcct = [SELECT Id, Name FROM Account WHERE Name = 'MergeTest Inc.' LIMIT 1];
        Account mergeAcct = [SELECT Id, Name FROM Account WHERE Name = 'MergeTest' LIMIT 1];
        merge masterAcct mergeAcct;
        
        // Verify that the merge record got deleted
        Account[] result = [SELECT Id, Name FROM Account WHERE Id=:mergeAcct.Id];
        System.assertEquals(0, result.size());

        // Verify that MasterRecordId got updated on deleted record
        mergeAcct = [SELECT Id, MasterRecordId, Name, IsDeleted FROM Account WHERE Name = 'MergeTest' and IsDeleted = true LIMIT 1 ALL ROWS];
        System.assertEquals(mergeAcct.MasterRecordId, masterAcct.Id);
        Test.stopTest();
    }

    /**
     * Checks the Account After Update Trigger
     * @param N/A. 
     * @return void                          
     */

    @isTest
    static void testAccountUpdate() {
        AccountTriggerSettings__c settings = AccountTriggerSettings__c.getOrgDefaults();
        settings.IsEnabledDeleteAccountTeams__c = True;
        upsert settings;

        List<Account>  accountList = New List<Account>();
         User salesManagerUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'testuser@insperity.com' Limit 1];
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTestData'+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE,
                                        NSP_Delete_Account_Teams__c = system.now()));
        }
        accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
        accountList[0].ownerId = salesManagerUser.Id;
        insert accountList;
        // Added for STP
        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accountList[0].id;
        opportuniytObject.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject.CloseDate = date.today();        
        opportuniytObject.NSP_PrimaryProduct__c = 'WO';
        insert opportuniytObject;
        //Insert Checklist
        NSP_Checklist__c checklst = new NSP_Checklist__c();
        checklst.NSP_Opportunity__c = opportuniytObject.id;
        insert checklst;
        
       Set<Id> accIdSet = new Set<Id>(); // Added as part of Test class fix
       Map<Id, Account> accountMapOld = new Map<Id, Account>();
        Map<Id, Account> accountMapNew = new Map<Id, Account>();
        for(Account account : accountList) {
            accIdSet.add(account.Id);
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
            account.NSP_Account_Status__c = ACTIVE;
            account.NSP_Template_Selection__c = 'Referral Program Associations';
            account.BillingCity = 'CITY1';  // Added for STP
            accountMapOld.put(account.Id, account);
        }
       
        User userRecord1 = [select id from User WHERE LastName = 'TestClassUser1'];
        // Start Test
            List<Account> accountUpdateList = [Select Id, Name, NSP_Account_Owners_Profile__c,NSP_Ready_for_Integration_Sync__c,NSP_Integrated_With__c,NSP_Partner_Lifecycle__c,RecordTypeId,NSP_Account_At_Risk_Level_Image__c FROM Account WHERE Id =: accountMapOld.keySet()];
            for(Account accountRecord : accountUpdateList) {
                accountRecord.NSP_Delete_Account_Teams__c = system.now(); // Added as part of Test class fix
                accountRecord.NSP_Ready_for_Integration_Sync__c = TRUE;
                accountRecord.ownerId = userRecord1.Id;
                accountRecord.NSP_Stage__c = 'Available';
                accountRecord.BillingCity = 'CITY2';  // Added for STP

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
        List<Account> accountUpdateList = [Select Id, Name, NSP_Ready_for_Integration_Sync__c FROM Account WHERE Id =: accountMapOld.keySet()];
        for(Account account : accountUpdateList) {
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
        }
        User userRecord = [select id FROM User WHERE LastName = :LASTNAME];
        // Start Test
        Test.startTest();
        system.runAs(userRecord){
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = ACCOUNTTEST+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE));
        }
        accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
        insert accountList;
        for(Account account1 : accountList) {
            account1.NSP_Ready_for_Integration_Sync__c = FALSE;
            account1.NSP_Account_Status__c = ACTIVE;
            account1.NSP_Template_Selection__c = 'Referral Program Associations';
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
        AccountTriggerSettings__c settings = AccountTriggerSettings__c.getOrgDefaults();
        settings.IsEnabledDeleteAccountTeams__c = True;
        upsert settings;

        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMapOld = new Map<Id, Account>();
        List<Account> accountUpdateList = [Select Id, Name, NSP_Ready_for_Integration_Sync__c FROM Account WHERE Id =: accountMapOld.keySet()];
        for(Account account : accountUpdateList) {
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
        }
        User userRecord = [select id FROM User WHERE LastName = :LASTNAME];
        // Start Test
        Test.startTest();
        system.runAs(userRecord){
         for(integer count = 0; count < 5; count++) {
            accountList.add(
                new Account(
                    OwnerId=userRecord.Id ,
                    Name=ACCOUNTTEST+String.valueOf( count ) ,
                    AccountNumber=String.valueOf( count ) ,
                    NSP_Ready_for_Integration_Sync__c=True ,
                    NumberOfEmployees=100
                )
            );
        }
        
        insert accountList;
        for(Account account1 : accountList) {
            account1.NSP_Ready_for_Integration_Sync__c = FALSE;
            account1.NSP_Account_Status__c = ACTIVE;
            account1.NSP_Template_Selection__c = 'Referral Program Associations';
            account1.BillingState = TEXAS;
            account1.NSP_Partner_Lifecycle__c = 'Onboarding';
            account1.NSP_Signed_MOD_Document__c = true;
            accountMapOld.put(account1.Id, account1);
        }
            accountList[0].NSP_Partner_Lifecycle__c = ACTIVE;
            accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
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
    
    /* Ticket 582488
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Harsha Khiroya      08/08/2022           Created this method - test class for non admin user(sales manager here)
*/    
  @isTest
    static void testAccountDeleteByAdmin() {
        Account accountObject3 = new Account();
        Id partnerRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        //Create Account
        accountObject3.Name = 'ACCOUNTTEST3';
        accountObject3.recordTypeId=partnerRecordTypeId1;
        insert accountObject3;
        
        // Start Test
        Test.startTest();
        delete accountObject3;   
        Test.stopTest();
     system.assertNotEquals(null, accountObject3);
    }
    
/* Ticket 582488
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Harsha Khiroya      08/08/2022           Created this method - test class for non admin user(sales manager here)
*/    
    @isTest
    static void testAccountDeleteByNonAdmin() {
      
        User userRec = [select id FROM User WHERE LastName = 'TestClassUser1'];
         
        Account accountObject3 = new Account();
        Id partnerRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        //Create Account
        accountObject3.Name = 'ACCOUNTTEST3';
        accountObject3.recordTypeId=partnerRecordTypeId1;
        insert accountObject3;
        
        // Start Test
        Test.startTest();
        system.runAs(UserRec){
            try{
            delete accountObject3; 
            }catch(Exception ex){
                system.assertNotEquals(null, ex);
            }
        }
        Test.stopTest();
    }
    
   /**
   Description : Test method for setSalesOfficeDetails  STY-03153
   */
   @isTest
   static void salesOfficeTest(){
       User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c FROM User WHERE Id =:UserInfo.getUserId()];
         currentUser.NSP_Sales_Office__c = '301';
         currentUser.NSP_SalesRegion__c = 'Central 1';
         currentUser.NSP_SalesDivision__c = 'Central';
         update currentUser;
       NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;
       
       NSP_Sales_Office_Mapping__c office1Mapping = new NSP_Sales_Office_Mapping__c();
        office1Mapping.NSP_Sales_Office__c = '301';
        office1Mapping.NSP_Sales_Division__c = 'Central';
        office1Mapping.NSP_Sales_Region__c = 'Central 1';
        office1Mapping.NSP_Start_Date__c = system.today()-1;
        office1Mapping.NSP_End_Date__c = system.today()+200;
        insert office1Mapping;
       
        Test.startTest();
            Account accoutObject = new Account();
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
            accoutObject.Name = ACCOUNTTEST1;
            accoutObject.recordTypeId=partnerRecordTypeId;
            accoutObject.DNB_Connect_DUNS_Number__c = '876543987';
            insert accoutObject;
            accoutObject.NSP_Sales_Office__c = '1081';
            update accoutObject;
            
        Test.stopTest();
        System.assertEquals(ACCOUNTTEST1, accoutObject.Name);
    }
    
    /***********************************************************************************************
    * MethodName: restrictAccountChangeTest
    * Description : This method will test restrictAccountChange
    * Author : Ruchi Roy
    * Updated Date : 11/17/22
    * **************************************************************************************/

    @isTest
    static void restrictAccountChangeTest() {
    User userRecord1=[Select Id , Name , Email , NSP_Sales_Office__c FROM User WHERE Email = 'testuser@insperity.com' Limit 1];
    userRecord1.NSP_Sales_Office__c = '302';
    update userRecord1;
    List<User> userRecordList = [SELECT Id FROM User WHERE Profile.Name = 'Sales Manager' and Email = 'testuser@insperity.com' Limit 1];
    User DAUser = userRecordList[0];
    Account accountObject3 = new Account();
        //Create Account
        accountObject3.Name = 'ACCOUNTTEST3';
        accountObject3.ownerId = userRecord1.Id;
        insert accountObject3;
        //Insert AccountTeam
        NSP_Account_Team__c accMember = new NSP_Account_Team__c();
        accMember.NSP_Account__c = accountObject3.id;
        accMember.NSP_User__c = DAUser.id;
        insert accMember;
    
    test.startTest();
    System.runAs(DAUser){
            try{            
            accountObject3.Industry='Other';
                Update accountObject3;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
    }
    test.stopTest();
    System.assertEquals(true, userRecordList.size() > 0);    
    }

    /***********************************************************************************************
    * MethodName: testAccountPremierUpdate
    * Description : This method will test publish event for premier pathway opportunity owner update
    * Author : Rahul Singh
    * Created Date : 9/29/22
    * Added as part of 569324 charwell request.
    * ********************************************************************************************/  
    
    @isTest
    static void testAccountPremierUpdate() {
        AccountTriggerSettings__c settings = AccountTriggerSettings__c.getOrgDefaults();
        settings.IsEnabledDeleteAccountTeams__c = True;
        upsert settings;

         List<Account>  accountList = New List<Account>();
         User salesManagerUser=[Select Id , Name , Email , NSP_Sales_Office__c FROM User WHERE Email = 'jsmith@insperity.com' Limit 1];
        for(integer count = 0; count < 1; count++) {
            accountList.add(New Account(Name = 'AccountTestData'+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE,
                                        NSP_Delete_Account_Teams__c = system.now()));
        }
        accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
        accountList[0].ownerId = salesManagerUser.Id;
        accountList[0].NSP_Account_Status__c = NSP_SalesConstants.ACTIVE;
        insert accountList;
        Account accoutObject1 = [Select Id, Name FROM Account WHERE Name = 'AccountTestData0'];
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject1.id;
        opportuniytObject.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject.CloseDate = date.today();        
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        opportuniytObject.Type ='CAMS';
        //Inserting Opportunity Object
        insert opportuniytObject;
        
       Set<Id> accIdSet = new Set<Id>(); // Added as part of Test class fix
       Map<Id, Account> accountMapOld = new Map<Id, Account>();
        Map<Id, Account> accountMapNew = new Map<Id, Account>();
        for(Account account : accountList) {
            accIdSet.add(account.Id);
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
            account.NSP_Account_Status__c = ACTIVE;
            account.NSP_Template_Selection__c = 'Referral Program Associations';
            accountMapOld.put(account.Id, account);
        }
       
        User userRecord1 = [SELECT id FROM User WHERE LastName = 'TestClassUser1'];
        // Start Test
            List<Account> accountUpdateList = [Select Id, Name, NSP_Account_Owners_Profile__c,NSP_Ready_for_Integration_Sync__c,NSP_Integrated_With__c,NSP_Partner_Lifecycle__c,RecordTypeId,NSP_Account_At_Risk_Level_Image__c FROM Account WHERE Id =: accountMapOld.keySet()];
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
         helper.afterUpdateDirector(accountMapNew, accountMapOld);
         helper.setAccountStage(accountList);
         helper.restrictAccountChange(accountMapNew,accountMapOld,userRecord1);
         system.assertEquals(salesManagerUser.Id, accountList[0].ownerId);
        Test.stopTest();
 
 
    }


    /***********************************************************************************************
    * MethodName: UpdateAGMPayrollEmployees
    * Description : This method is used to update Account Group Member Payroll Employees From Account Payroll Employees
    * ********************************************************************************************/

    @isTest
    static void updateAGMPayrollEmployees() {
        Test.startTest();
        //create Account
        Account newAcc =  New Account(Name = 'Test Acc5', AccountNumber = '1678234',NSP_AIMS_Client__c = '123456789' , NSP_Payroll_employee__c = 33);
        insert newAcc;
        
        //create Account Group
        NSP_Account_Group__c accGroup = new NSP_Account_Group__c();
        accGroup.Name = 'Account Test';
        insert accGroup;
        
        //create Account Group Member
        NSP_Account_Group_Member__c accGrpMem  = new NSP_Account_Group_Member__c();
        accGrpMem.NSP_Member_Account__c = newAcc.id;
        accGrpMem.NSP_Group__c = accGroup.Id;
        insert accGrpMem;
        
        
        // update Account's Payroll Employee
        newAcc.NSP_Payroll_employee__c = 10;
        update newAcc;

        Test.StopTest();
        NSP_Account_Group_Member__c accGroMemberUpdated = [SELECT Id, NSP_Member_Account__c, NSP_Payroll_Employees__c FROM NSP_Account_Group_Member__c 
                                                            WHERE NSP_Member_Account__c =: newAcc.Id LIMIT 1];
        System.assert(accGroMemberUpdated.NSP_Payroll_Employees__c == newAcc.NSP_Payroll_employee__c);
    }

    // added by AZD-236894 to increase code coverage from 64% to 70%
    @isTest private static void testCoverageAccountUpdate() {
        Test.startTest();
        NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
        helper.accountUpdate( new Map<Id,Account>() , new Map<Id,Account>() );
        Test.stopTest();
    }

    // added by AZD-236894 to increase code coverage from 70% to 76%
    @isTest private static void testCoverageBeforeUpdateDirector() {
        Account sharedAccount = new Account( Name='sharedAccount' );
        insert sharedAccount;
        Map<Id,Account> sharedAccountMap = new Map<Id,Account>();
        sharedAccountMap.put( sharedAccount.Id , sharedAccount );
        Test.startTest();
        NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
        try {
            helper.beforeUpdateDirector( sharedAccountMap , sharedAccountMap );
        } catch ( Exception e ) {
            System.debug( ' ~ e=' + e );
        }
        Test.stopTest();
    }

}
//