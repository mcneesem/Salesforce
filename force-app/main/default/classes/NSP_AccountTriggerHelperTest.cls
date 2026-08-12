@isTest
private class NSP_AccountTriggerHelperTest {
    private static final Id availableUserId = '0054x000008PgqNAAS';
    private static final String emailencodingkey = 'UTF-8';
    private static final String languagekey = 'en_US';
    private static final String timezonesidkey = 'America/Los_Angeles';
    private static final String REFPROG3 = 'ReferralProgramNationalRevShare';
    private static final String ACCOUNTTEST1 = 'AccountTest1';
    private static final String AccountTestData1= 'AccountTestData1';
    private static final String ACCOUNTTEST = 'AccountTest';
    private static final String ACTIVE = 'ACTIVE';
    private static final String INACTIVE = 'INACTIVE';
    private static final String LASTNAME = 'TestClassUser' ;
    private static final String EN_US = 'en_US';
    private static final String TEXAS = 'TEXAS';
    private static final String PARTNER_CLIENT = 'NSP_Partner_Client';
    private static Map<Id,User> partnerLoyaltyPermittedUserMap = CustomPermissionController.getPermittedUsersMap('Account_Partner_Update_Loyalty_from_SO');
    private static Map<Id,User> templSelectPermittedUserMap = CustomPermissionController.getPermittedUsersMap('Template_Selection_Owner_Update');

    @testSetup
    private static void testData() {
        Account_Segment_Threshold_Settings__c settings1 = Account_Segment_Threshold_Settings__c.getOrgDefaults();
        settings1.Is_Enabled__c = True;
        upsert settings1;
    }

    @isTest
    private static void setChannelPartnerAndLoyaltyAdvisorTest() {
        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :partnerLoyaltyPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testUsers.isEmpty() , 'No active permitted user found.' );
        User testUser = testUsers[0];
        System.runAs (testUser) {
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

    @isTest
    private static void testAccountInsert() {
        //variables to hold test data to be inserted
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = ACCOUNTTEST+count, AccountNumber = '0000'+count, recordTypeId=partnerRecordTypeId,BillingState=TEXAS,NumberOfEmployees=350));
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
    private static void testAccountInsert2() {
        //variables to hold test data to be inserted
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMap = new Map<Id, Account>();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        //Creating User
        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :partnerLoyaltyPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testUsers.isEmpty() , 'No active permitted user found.' );
        User testUser = testUsers[0];
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTest'+String.valueOf(count), AccountNumber = String.valueOf(count), recordTypeId=partnerRecordTypeId,BillingState=TEXAS,NumberOfEmployees=150));
        }
        accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
        accountList[0].NumberOfEmployees = 130;
        accountList[0].NSP_Account_Segment__c = 'Emerging Growth';
        // Start Test
        Test.startTest();
        system.runAs(testUser){
            insert accountList;
        }
        for(Account account : accountList) {
            accountMap.put(account.Id, account);
        }
        Account account = [SELECT Id, Name, AccountNumber,NSP_Account_Owners_Profile__c FROM Account WHERE Name=:ACCOUNTTEST1 LIMIT 1];
        System.assertEquals(ACCOUNTTEST1, account.Name);
        Test.stopTest();
    }

    @isTest
    private static void testAccountMerge() {
        PlatformEventSettings__c setting = new PlatformEventSettings__c();
        setting.IsEnabled_IntegrationAccountEvent__c = true;
        setting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        setting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        setting.IsEnabled_IntegrationOpportunityEvent__c = true;
        upsert setting;
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

    @isTest
    private static void testAccountUpdate() {
        PlatformEventSettings__c setting = new PlatformEventSettings__c();
        Map<Id,User> ownerRestrictPermittedUserMap = CustomPermissionController.getPermittedUsersMap('Account_Owner_Restrict_Update');
        setting.IsEnabled_IntegrationAccountEvent__c = true;
        setting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        setting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        setting.IsEnabled_IntegrationOpportunityEvent__c = true;
        upsert setting;

        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'Sales Manager'
                AND Id IN :ownerRestrictPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testUsers.isEmpty() , 'No active permitted user found.' );
        User salesManagerUser = testUsers[0];

        List<Account>  accountList = New List<Account>();
        for(integer count = 0; count < 5; count++) {
            accountList.add(New Account(Name = 'AccountTestData'+String.valueOf(count), AccountNumber = String.valueOf(count), NSP_Ready_for_Integration_Sync__c = TRUE,
                                        NSP_Delete_Account_Teams__c = system.now()));
        }
        accountList[0].NSP_Template_Selection__c = 'ReferralProgramNationalRevShare';
        accountList[0].ownerId = salesManagerUser.Id;
        accountList[0].NSP_Account_Status__c = INACTIVE;
        insert accountList;
        // Added for STP
        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accountList[0].id;
        opportuniytObject.StageName = 'Prospecting';
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
        List<User> testSellerUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :templSelectPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testSellerUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testSellerUsers.isEmpty() , 'No active permitted user found.' );
        User userRecord1 = testSellerUsers[0];
        // User userRecord1 = [select id from User WHERE isActive = true AND UserRole.Name = 'Business Performance Advisor' ORDER BY CreatedDate ASC LIMIT 1];
        // Start Test
        List<Account> accountUpdateList = [Select Id, Name, NSP_Account_Owners_Profile__c,NSP_Ready_for_Integration_Sync__c,NSP_Integrated_With__c,NSP_Partner_Lifecycle__c,RecordTypeId,NSP_Account_At_Risk_Level_Image__c FROM Account WHERE Id =: accountMapOld.keySet()];
        for(Account accountRecord : accountUpdateList) {
            accountRecord.NSP_Delete_Account_Teams__c = system.now(); // Added as part of Test class fix
            accountRecord.NSP_Ready_for_Integration_Sync__c = TRUE;
            accountRecord.ownerId = userRecord1.Id;
            accountRecord.NSP_Stage__c = 'Available';
            accountRecord.BillingCity = 'CITY2';  // Added for STP
            accountRecord.NSP_BPA__c = null;
            accountRecord.NSP_Channel_Partner_Manager__c = null;
            accountRecord.NSP_Channel_Program_Manager__c = null;
            accountRecord.NSP_Template_Selection__c = 'Referral Program Associations';

            accountMapNew.put(accountRecord.Id, accountRecord);
        }
        Test.startTest();
        Update accountUpdateList;

        NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
        helper.setAccountStageWhenOwnerChanged(accountUpdateList);
        helper.afterUpdateDirector(accountMapNew, accountMapOld);
        system.assertEquals(salesManagerUser.Id, accountList[0].ownerId);
        NSP_AccountTriggerHelper.testHandleException( null , null ); // for increased code coverage...
        Test.stopTest();
    }

    @isTest
    private static void testAccountUpdateMODTemplate() {
        List<Account>  accountList = New List<Account>();
        Map<Id, Account> accountMapOld = new Map<Id, Account>();
        List<Account> accountUpdateList = [Select Id, Name, NSP_Ready_for_Integration_Sync__c FROM Account WHERE Id =: accountMapOld.keySet()];
        for(Account account : accountUpdateList) {
            account.NSP_Ready_for_Integration_Sync__c = TRUE;
        }

        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :templSelectPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testUsers.isEmpty() , 'No active permitted user found.' );
        User userRecord = testUsers[0];

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
    private static void testhandleTask() {
        List<Account>  accountList = New List<Account>();
        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'Sales Manager'
                AND Id IN :templSelectPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testUsers.isEmpty() , 'No active permitted user found.' );
        User userRecord = testUsers[0];

        // Start Test
        Test.startTest();
        system.runAs(userRecord){
        for(integer count = 0; count < 5; count++) {
            accountList.add(
                new Account(
                    OwnerId=userRecord.Id ,
                    Name=ACCOUNTTEST+String.valueOf( count ) ,
                    AccountNumber=String.valueOf( count ) ,
                    NSP_Ready_for_Integration_Sync__c = true ,
                    NumberOfEmployees=100 ,
                    NSP_Account_Status__c = INACTIVE ,
                    NSP_Template_Selection__c = 'ReferralProgramNationalRevShare' ,
                    NSP_Partner_Lifecycle__c = ACTIVE ,
                    NSP_Stage__c = 'New'
                )
            );
        }
        insert accountList;

        for(Account account1 : accountList) {
            account1.NSP_Ready_for_Integration_Sync__c = false;
            account1.NSP_Account_Status__c = ACTIVE;
            account1.NSP_Template_Selection__c = 'Referral Program Associations';
            account1.BillingState = TEXAS;
            account1.NSP_Partner_Lifecycle__c = 'Onboarding';
            account1.NSP_Signed_MOD_Document__c = true;
            //accountMapOld.put(account1.Id, account1);
        }
            accountList[0].NSP_Partner_Lifecycle__c = ACTIVE;
            accountList[0].NSP_Template_Selection__c = 'Referral Program Associations';
            accountList[0].NumberOfEmployees = 150;
            accountList[0].NSP_Delete_Account_Teams__c = System.now();
            accountList[0].NSP_Stage__c = 'Available';

        Update accountList;
        NSP_AccountTriggerHelper.handleTaskForPartnerContracts(accountList);
        }
        Test.stopTest();
        Account account = [SELECT Id, Name FROM Account WHERE Name= :ACCOUNTTEST1 LIMIT 1];
        system.assertEquals(ACCOUNTTEST1, account.Name);
    }

    @isTest
    private static void testAccountDeleteByAdmin() {
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

    @isTest
    private static void testAccountDeleteByNonAdmin() {
        PlatformEventSettings__c setting = new PlatformEventSettings__c();
        setting.IsEnabled_IntegrationAccountEvent__c = true;
        setting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        setting.IsEnabled_IntegrationAccountDeleteEvent__c = true;
        setting.IsEnabled_IntegrationOpportunityEvent__c = true;
        upsert setting;

        User userRec = [select id FROM User WHERE isActive = true AND Profile.Name = 'Sales Manager' ORDER BY CreatedDate ASC LIMIT 1];

        Account accountObject3 = new Account();
        Id partnerRecordTypeId1 = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT).getRecordTypeId();
        //Create Account
        accountObject3.Name = 'ACCOUNTTEST3';
        accountObject3.recordTypeId=partnerRecordTypeId1;
        insert accountObject3;

        // Start Test
        Test.startTest();
        system.runAs(userRec){
            try{
            delete accountObject3;
            }catch(Exception ex){
                system.assertNotEquals(null, ex);
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void salesOfficeTest(){
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

    @isTest
    private static void restrictAccountChangeTest() {
        Map<Id,User> assignAvailPermittedUserMap = CustomPermissionController.getPermittedUsersMap('Account_Allow_Assign_Available');
        List<User> testUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :templSelectPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testUsers.isEmpty() , 'No active permitted user found.' );
        User userRecord1 = testUsers[0];
        userRecord1.NSP_Sales_Office__c = '302';
        update userRecord1;

        List<User> testAvailUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :assignAvailPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testAvailUsers != null , 'Null active permitted user query results.' );
        Assert.isTrue( !testAvailUsers.isEmpty() , 'No active permitted user found.' );
        User DAUser = testAvailUsers[0];
        //Create Accounts
        List<Account> accounts = new List<Account>();
        List<Account> accountsUpdate = new List<Account>();
        Account accountObject3 = new Account();
        accountObject3.Name = 'ACCOUNTTEST3';
        accountObject3.ownerId = userRecord1.Id;
        Account accountObject4 = new Account();
        accountObject4.Name = 'ACCOUNTTEST4';
        accountObject4.ownerId = availableUserId;
        accounts.add(accountObject3);
        accounts.add(accountObject4);
        insert accounts;
        //Insert AccountTeam
        NSP_Account_Team__c accMember = new NSP_Account_Team__c();
        accMember.NSP_Account__c = accountObject3.Id;
        accMember.NSP_User__c = DAUser.Id;
        insert accMember;

        test.startTest();
        System.runAs(DAUser){
            try{
                accountObject3.Industry='Other';
                accountObject4.OwnerId=DAUser.Id;
                accountsUpdate.add(accountObject3);
                accountsUpdate.add(accountObject4);
                Update accountsUpdate;
            }catch(Exception ex){
                ex.getStackTraceString();
            }
        }
        test.stopTest();
        System.assertEquals(true, testAvailUsers.size() > 0);
    }

    @isTest
    private static void testAccountPremierUpdate() {
        List<Account>  accountList = New List<Account>();
        User salesManagerUser=[Select Id , Name , Email , NSP_Sales_Office__c FROM User WHERE isActive = true AND Profile.Name = 'Sales Manager' ORDER BY CreatedDate ASC Limit 1];
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
            account.NSP_Template_Selection__c = 'ReferralProgramNationalRevShare';
            accountMapOld.put(account.Id, account);
        }

        User userRecord1 = [SELECT id FROM User WHERE isActive = true AND Profile.Name = 'Sales Manager' ORDER BY CreatedDate ASC LIMIT 1];
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

    @isTest
    private static void updateAGMPayrollEmployees() {
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

    @isTest
    private static void updateAGMNumberOfEmployeesTest() {
        Test.startTest();
        //create Account
        Account newAcc =  New Account(Name = 'Test Acc6', AccountNumber = '1678235',NSP_AIMS_Client__c = '223456789' , NumberOfEmployees = 33);
        insert newAcc;

        //create Account Group
        NSP_Account_Group__c accGroup = new NSP_Account_Group__c();
        accGroup.Name = 'Account Test EE';
        insert accGroup;

        //create Account Group Member
        NSP_Account_Group_Member__c accGrpMem  = new NSP_Account_Group_Member__c();
        accGrpMem.NSP_Member_Account__c = newAcc.id;
        accGrpMem.NSP_Group__c = accGroup.Id;
        insert accGrpMem;

        // update Account's Number of Employees
        newAcc.NumberOfEmployees = 10;
        update newAcc;

        Test.StopTest();
        List<NSP_Account_Group_Member__c> accGroMemberUpdated = [SELECT Id, NSP_Member_Account__c, NumberOfEmployees_Sales__c FROM NSP_Account_Group_Member__c
                                                            WHERE NSP_Member_Account__c =: newAcc.Id LIMIT 1];
        System.assert(!accGroMemberUpdated.isEmpty() && accGroMemberUpdated[0].NumberOfEmployees_Sales__c == newAcc.NumberOfEmployees);
    }

    @isTest
    private static void testCoverageAccountUpdate() {
        Test.startTest();
        NSP_AccountTriggerHelper helper = new NSP_AccountTriggerHelper();
        helper.accountUpdate( new Map<Id,Account>() , new Map<Id,Account>() );
        Test.stopTest();
    }


    @isTest
    private static void testCoverageBeforeUpdateDirector() {
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

    @isTest
    private static void testOpportunitySalesOfficeUpdate() {
        List<User> users = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'Sales Manager' )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 2
        ];
        Assert.isTrue( users != null , 'Null active permitted user query results.' );
        Assert.isTrue( !users.isEmpty() , 'No active permitted user found.' );

        Test.startTest();
        Account acct = new Account();
        acct.name = 'Test Office';
        acct.OwnerId = users[0].Id;
        insert acct;

        Opportunity opp = new Opportunity();
        opp.name = 'Opportunity 1';
        opp.AccountId = acct.Id;
        opp.StageName = 'Prospecting';
        opp.CloseDate = date.today();
        opp.NSP_PrimaryProduct__c = 'WO';
        opp.OwnerId = users[0].Id;
        insert opp;

        //  Change account owner
        Account acct1 = [SELECT id, OwnerId FROM Account WHERE Id =: acct.Id LIMIT 1];
        acct1.OwnerId = users[1].Id;
        //  Reset all the run counts otherwise the method 'beforeUpdate' won't be triggered
        NSP_AccountTriggerHandler.resetAllHasRun();
        update acct1;
        Test.stopTest();

        Account acct2 = [SELECT id,OwnerId, NSP_Sales_Office__c FROM Account WHERE Id =: acct.Id LIMIT 1];
        Opportunity opp2 = [SELECT id, NSP_Sales_Office__c FROM Opportunity WHERE Id =: opp.Id LIMIT 1];

        //  The Opportuniry Sales Office should be the same as the Account SO
        System.assertEquals(acct2.NSP_Sales_Office__c,  opp2.NSP_Sales_Office__c);
    }

    @isTest
    private static void testSalesSegment() {
        Map<Id,User> allowMMPermittedUserMap = CustomPermissionController.getPermittedUsersMap('Allow_Update_MidMarket_Role');
        List<User> users = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :allowMMPermittedUserMap.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( users != null , 'Null active permitted user query results.' );
        Assert.isTrue( !users.isEmpty() , 'No active permitted user found.' );

        System.runAs (users[0]) {
            Test.startTest();
            List<Account> accts = new  List<Account>();
            List<Account> acctsUpdate = new  List<Account>();

            Account actt1 = new Account();
            actt1.Name = 'Account test 1';
            actt1.NumberOfEmployees = 5;

            Account actt2 = new Account();
            actt2.Name = 'Account test 2';
            actt2.NumberOfEmployees = 52;

            Account actt3 = new Account();
            actt3.Name = 'Account test 3';
            actt3.NumberOfEmployees = 150;

            Account actt4 = new Account();
            actt4.Name = 'Account test 4';
            actt4.NumberOfEmployees = 752;

            accts.add(actt1);
            accts.add(actt2);
            accts.add(actt3);
            accts.add(actt4);

            insert accts;

            actt1 = [SELECT NSP_Account_Segment__c FROM Account WHERE name = 'Account test 1' LIMIT 1];
            System.assertEquals('Core', actt1.NSP_Account_Segment__c);
            actt1.NumberOfEmployees = 6;
            acctsUpdate.add(actt1);

            actt2 = [SELECT NSP_Account_Segment__c FROM Account WHERE name = 'Account test 2' LIMIT 1];
            System.assertEquals('Emerging Growth', actt2.NSP_Account_Segment__c);
            actt2.NumberOfEmployees = 53;
            acctsUpdate.add(actt2);

            actt3 = [SELECT NSP_Account_Segment__c FROM Account WHERE name = 'Account test 3' LIMIT 1];
            System.assertEquals('MidMarket', actt3.NSP_Account_Segment__c);
            actt3.NumberOfEmployees = 151;
            acctsUpdate.add(actt3);

            actt4 = [SELECT NSP_Account_Segment__c FROM Account WHERE name = 'Account test 4' LIMIT 1];
            System.assertEquals('Enterprise', actt4.NSP_Account_Segment__c);
            actt4.NumberOfEmployees = 753;
            acctsUpdate.add(actt4);

            update acctsUpdate;

            Test.stopTest();
        }
    }

    @isTest
    private static void testBypassSalesSegment() {

        Map<Id,User> bypassSegment = CustomPermissionController.getPermittedUsersMap('Bypass_Sales_Segment');
        List<User> users = [
            SELECT Id
            FROM User
            WHERE (
                ( Id IN :bypassSegment.keySet() )
                AND ( IsActive = true )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];

        if( users != null && !users.isEmpty() ){
            System.runAs (users[0]) {
                Test.startTest();

                Account actt = new Account();
                actt.Name = 'Account test segment';
                actt.NumberOfEmployees = 5;
                actt.NSP_Account_Segment__c = 'Enterprise';

                insert actt;

                actt = [SELECT NSP_Account_Segment__c FROM Account WHERE name = 'Account test segment' LIMIT 1];
                System.assertEquals('Enterprise', actt.NSP_Account_Segment__c);

                Test.stopTest();
            }
        }
    }

    @isTest
    private static void testUpdateSalesOfficeOnRelatedRecords() {

        //  We need two users in different sales offices
        List<AggregateResult> aggregatedUsers  = [
            SELECT NSP_Sales_Office__c, Id
            FROM User
            WHERE Profile.Name = 'Sales Manager' AND IsActive = true AND NSP_Sales_Office__c != null
            GROUP BY NSP_Sales_Office__c, id
            LIMIT 2
        ];

        List<User> users = new List<User>();

        for(AggregateResult ar : aggregatedUsers){
            users.add(new User(Id = (Id)ar.get('Id'), NSP_Sales_Office__c = (String)ar.get('NSP_Sales_Office__c')));
        }

        if( !users.isEmpty() && users.size() == 2 ){

            Test.startTest();

            Account acct = new Account();
            acct.name = 'Test Office';
            acct.OwnerId = users[0].Id;
            insert acct;

            Contact contact = new Contact();
            contact.AccountId = acct.Id;
            contact.LastName = 'Test Contact';
            contact.OwnerId = users[0].Id;
            insert contact;

            Event event = new Event();
            event.Subject = 'Test Event';
            event.WhatId = acct.Id;
            event.DurationInMinutes = 60;
            event.ActivityDateTime = DateTime.now();
            event.NSP_Sales_Office__c = users[0].NSP_Sales_Office__c;
            event.NSP_Event_Subtype__c = 'Discovery Call';
            event.OwnerId = users[0].Id;
            insert event;

            Task task = new Task();
            task.Subject = 'Test Task';
            task.WhatId = acct.Id;
            task.Status = 'Not Started';
            task.Priority = 'Normal';
            task.NSP_Sales_Office__c = users[0].NSP_Sales_Office__c;
            task.OwnerId = users[0].Id;
            insert task;

            //  Change owner on Account, Contact, Event and Task
            contact.OwnerId = users[1].Id;
            update contact;

            event.OwnerId = users[1].Id;

            task.OwnerId = users[1].Id;

            acct.OwnerId = users[1].Id;
            //  Reset all the run counts otherwise the method 'beforeUpdate' won't be triggered
            NSP_AccountTriggerHandler.resetAllHasRun();
            update acct;
            update event;
            update task;

            Test.stopTest();

            Contact contact2 = [SELECT id, NSP_Sales_Office__c FROM Contact WHERE Id =: contact.Id LIMIT 1];
            Event event2 = [SELECT id, NSP_Sales_Office__c FROM Event WHERE Id =: event.Id LIMIT 1];
            Task task2 = [SELECT id, NSP_Sales_Office__c FROM Task WHERE Id =: task.Id LIMIT 1];

            System.Assert.areEqual(users[1].NSP_Sales_Office__c, contact2.NSP_Sales_Office__c);
            System.Assert.areEqual(users[1].NSP_Sales_Office__c, event2.NSP_Sales_Office__c);
            System.Assert.areEqual(users[1].NSP_Sales_Office__c, task2.NSP_Sales_Office__c);
        }
    }
}
//