/**
* Author : Jatin Ahuja
* Created date: 06/02/2022
* Represents test class for AccountGroupMemberTrigger helper
*/
@istest
private class NSP_AccountGroupMemberTriggerHelperTest {

    private static final String ACCOUNT_GROUP_MEMBER_DEFAULTS= 'NSP_TestDataFactory.AccountGroupMemberDefaults';
    private static final String ACCOUNT = 'Account';
    private static final String NSP_TAG = 'nsp_tag__c';
    private static final String RECORD_TYPE_ID = 'RecordTypeId';
    private static final String NAME = 'Name';
    private static final String TEST_ACCOUNT = 'TestAccount';
    private static final String NSP_ACCOUNT_GROUP = 'nsp_account_group__c';
    private static final STring MANUALLY_CREATED = 'Manually_Created';
     
    /**
* Test data for Accounts, Groups and Group members.
* @param N/A. 
* @return void                          
*/
    //setup for test data
    @testSetup
    static void testData() {
        Test.StartTest();
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ACCOUNT_GROUP,MANUALLY_CREATED);
        NSP_Account_Group__c accountGroupRec = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        accountGroupRec.Name = 'Account Health - Test Grp 1';
        accountGroupRec.NSP_Tag__c = 'Test Grp 1';
        accountGroupRec.NSP_Type__c = 'Influencer';
        accountGroupRec.RecordTypeId = manuallyCreatedRecordTypeId;
        INSERT accountGroupRec;
        
        NSP_Account_Group__c controlledAccountGroup = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        controlledAccountGroup.Name = 'Controlled Group - Test Grp 2';
        controlledAccountGroup.NSP_Tag__c = 'Test Grp 2';
        controlledAccountGroup.NSP_Type__c = 'Venture Capital';
        controlledAccountGroup.RecordTypeId = manuallyCreatedRecordTypeId;
        INSERT controlledAccountGroup;
        
        List<NSP_Account_Group__c> lstAccGroups = new List<NSP_Account_Group__c>();
        Id autoCreatedRecordTypeId = Schema.SObjectType.NSP_Account_Group__c.getRecordTypeInfosByName().get('Automatically Created').getRecordTypeId();
        //create account groups and add to lstAccGroups
        for(Integer index=0; index<3; index++){ 
            lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = 'Growth Forecast', NSP_Account__c = 'test'+index, NSP_Type__c = 'Growth Forecast'));
            lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = 'Renewal Probability', NSP_Account__c ='test'+index, NSP_Type__c = 'Renewal Probability'));
            lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = 'Account Health', NSP_Account__c =  'test'+index, NSP_Type__c = 'Account Health'));
        }
        insert lstAccGroups;
        
        //create account
        Account newAcc =  New Account(Name = TEST_ACCOUNT, AccountNumber = '1234',NSP_AIMS_Client__c = '12345678' , NSP_Payroll_employee__c = 33);
        insert newAcc;
        Account newAcc1 =  New Account(Name = 'TestAccount1', AccountNumber = '12345',NSP_AIMS_Client__c = '9876543' , NSP_Payroll_employee__c = 39);
        insert newAcc1;
        
        List<NSP_Account_Group_Member__c> lstAccGrpMembrs = new List<NSP_Account_Group_Member__c>();
        
        for(Integer index=0; index<3; index++){
            lstAccGrpMembrs.add(New NSP_Account_Group_Member__c(NSP_Member_Account__c = newAcc.Id, NSP_Group__c = lstAccGroups.get(index).Id, NSP_Primary__c = false));
        }
        insert lstAccGrpMembrs;
        
        NSP_Account_Group__c accGroup = new NSP_Account_Group__c();
        accGroup.Name = 'Account Health Test';
        insert accGroup;
        
        
        NSP_Account_Group_Member__c accGrpMem  = new NSP_Account_Group_Member__c();
        accGrpMem.NSP_Member_Account__c = newAcc.id;
        accGrpMem.NSP_Group__c = accGroup.Id;
        insert accGrpMem;
        Test.StopTest();
    }
    
    /* After Insert for AccountGroupMemberTrigger it will update the Primary Account on the related Group Name
*/
    @isTest
    static void updateAccountGroupPrimary() {
        List<NSP_Account_Group_Member__c> lstGrPmembrs = [SELECT Id, NSP_Member_Account__c, NSP_Group__c, NSP_Primary__c from NSP_Account_Group_Member__c WHERE NSP_Primary__c = false limit 1];
        lstGrPmembrs[0].NSP_Primary__c = true;
        update lstGrPmembrs;
        
        System.assertEquals([SELECT id,NSP_Primary__c FROM NSP_Account_Group_Member__c WHERE NSP_Primary__c = true LIMIT 1].NSP_Primary__c, true,'Updated Sucessful');
        
        //create account
        Account newAcc =  New Account(Name = 'TestAcc56', AccountNumber = '1678234',NSP_AIMS_Client__c = 'ateammember1');
        insert newAcc;
        
        NSP_Account_Group_Member__c accGrpMem  = lstGrPmembrs[0].clone(false, false, false, false);
        accGrpMem.NSP_Member_Account__c = newAcc.id;
        accGrpMem.NSP_Primary__c = true;
        insert accGrpMem;
        
        Boolean isPrimaryUpdated = [select id,NSP_Primary__c from NSP_Account_Group_Member__c WHERE id =:accGrpMem.id].NSP_Primary__c;
        
        System.assertEquals(isPrimaryUpdated, true,'Updated Sucessful');
        //delete accGrpMem;
        
    }

    @IsTest
    static void testAfterDelete_CreatesSelfGroup_GrowthForecast() {
        insert new AccountGroupMemberTriggerSettings__c(
            IsEnabled__c = true
        );
        Account acc = new Account(
            Name = 'GF Account',
            NSP_AIMS_Client__c = 'AIMS123'
        );
        insert acc;
        Id woRtId = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
        Asset woAsset = new Asset(
            Name = 'WO Asset',
            AccountId = acc.Id,
            RecordTypeId = woRtId,
            Status = 'Active'
        );
        insert woAsset;
        Id autoRtId = Schema.SObjectType.NSP_Account_Group__c
            .getRecordTypeInfosByName()
            .get('Automatically Created')
            .getRecordTypeId();
        NSP_Account_Group__c grp = new NSP_Account_Group__c(
            Name = NSP_ServiceConstants.GROWTH_FORECAST,
            NSP_Type__c = NSP_ServiceConstants.GROWTH_FORECAST,
            RecordTypeId = autoRtId
        );
        insert grp;
        NSP_Account_Group_Member__c gm = new NSP_Account_Group_Member__c(
            NSP_Member_Account__c = acc.Id,
            NSP_Group__c = grp.Id,
            NSP_Primary__c = true
        );
        insert gm;
        Test.startTest();
        delete gm;
        Test.stopTest();
        List<NSP_Account_Group__c> createdGroups = [
            SELECT Id, NSP_Type__c
            FROM NSP_Account_Group__c
            WHERE NSP_Type__c = :NSP_ServiceConstants.GROWTH_FORECAST
            AND RecordTypeId = :autoRtId
        ];
        System.assert(
            createdGroups.size() > 0,
            'Self Growth Forecast group should be created'
        );
        List<NSP_Account_Group_Member__c> createdMembers = [
            SELECT Id, NSP_Member_Account__c, NSP_Primary__c
            FROM NSP_Account_Group_Member__c
            WHERE NSP_Member_Account__c = :acc.Id
        ];
        System.assert(
            createdMembers.size() > 0,
            'Self group member should be created'
        );
    }

    /* this method is for validate the duplicate entry on Account Group Member */
    @isTest
    static void groupDuplicateValidation() {
        try{
            List<NSP_Account_Group_Member__c> lstGrPmembrs = [SELECT Id, NSP_Member_Account__c, NSP_Group__c, NSP_Primary__c from NSP_Account_Group_Member__c WHERE NSP_Primary__c = false limit 1];
            lstGrPmembrs[0].NSP_Primary__c = true;
            update lstGrPmembrs;
            
            //create account group member
            NSP_Account_Group_Member__c accGrpMem  = lstGrPmembrs[0].clone(false, false, false, false);
            accGrpMem.NSP_Primary__c = true;
            insert accGrpMem;
            
            delete accGrpMem;
            undelete accGrpMem;
            
        } catch (DmlException ex) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , ex.getDmlStatusCode(0),'Error Exception');
        } 
        
    }
    
     /* this method is for validate Payroll Employee on Account Group Member */
    @isTest
    static void updateAGMAccountPayrollEmployees() {
        Test.startTest();
        // get Existing account 
        Account acc = [SELECT Id, NSP_Payroll_employee__c FROM Account WHERE Name = 'TestAccount1' LIMIT 1];

       // Update account Group Member with new account
        NSP_Account_Group_Member__c accGroMember = [SELECT Id, NSP_Member_Account__c, NSP_Payroll_Employees__c FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c != null  LIMIT 1];
        accGroMember.NSP_Member_Account__c = acc.Id ;
        update accGroMember;
        
        Test.StopTest();
        NSP_Account_Group_Member__c accGroMemberUpdated = [SELECT Id, NSP_Member_Account__c, NSP_Payroll_Employees__c FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c != null LIMIT 1];
        System.assert(accGroMemberUpdated.NSP_Payroll_Employees__c == acc.NSP_Payroll_employee__c);
        
    }
    
    //Update the Account Group Member record to primary if first member of Account Group
    @IsTest
    static void testDefaultPrimaryFirstAccountGroupMember() {
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ACCOUNT_GROUP,MANUALLY_CREATED);
        List<String> accountGroupFields = new List<String>{'Id',RECORD_TYPE_ID,NAME};
        String query = new NSP_QueryBuilder(NSP_ACCOUNT_GROUP, accountGroupFields)
                        .addFilter(RECORD_TYPE_ID, manuallyCreatedRecordTypeId) 
                        .addFilter(NSP_TAG,'Test Grp 1').build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);
      
        List<String> accountFields = new List<String>{'Id'};
        String accountQuery = new NSP_QueryBuilder(ACCOUNT, accountFields)
            					.addFilter(NAME,TEST_ACCOUNT).build();
        Account accountRecord = Database.query(accountQuery);
        Test.startTest();
        NSP_Account_Group_Member__c accGrpMem = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), ACCOUNT_GROUP_MEMBER_DEFAULTS, false);
        accGrpMem.NSP_Member_Account__c = accountRecord.Id;
        accGrpMem.NSP_Group__c = accGrpRecord.Id;
        INSERT accGrpMem;
        System.assertEquals([SELECT Id, NSP_Primary__c FROM NSP_Account_Group_Member__c WHERE Id =: accGrpMem.Id].NSP_Primary__c, true ,'Added First Member as Primary');
        Test.StopTest();
    }
    
    //Update the Account Group Member record to not default to primary if first member of Account Group
    @IsTest
    static void testNotDefaultPrimaryFirstAccountGroupMember() {
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ACCOUNT_GROUP,MANUALLY_CREATED);
        List<String> accountGroupFields = new List<String>{'Id',RECORD_TYPE_ID,NAME};
        String query = new NSP_QueryBuilder(NSP_ACCOUNT_GROUP, accountGroupFields)
                        .addFilter(RECORD_TYPE_ID, manuallyCreatedRecordTypeId) 
                        .addFilter(NSP_TAG,'Test Grp 2').build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);
      
        List<String> accountFields = new List<String>{'Id'};
        String accountQuery = new NSP_QueryBuilder(ACCOUNT, accountFields)
            					.addFilter(NAME,TEST_ACCOUNT).build();
        Account accountRecord = Database.query(accountQuery);
        Test.startTest();
        NSP_Account_Group_Member__c accGrpMem = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), ACCOUNT_GROUP_MEMBER_DEFAULTS, false);
        accGrpMem.NSP_Member_Account__c = accountRecord.Id;
        accGrpMem.NSP_Group__c = accGrpRecord.Id;
        INSERT accGrpMem;
        System.assertEquals([SELECT Id, NSP_Primary__c FROM NSP_Account_Group_Member__c WHERE Id =: accGrpMem.Id].NSP_Primary__c, true ,'Added First Member as Non Primary');
        Test.StopTest();
    }
    
    //Update the last Account Group Member record to primary if primary member of Account Group is deleted
    @IsTest
    static void testUpdatePrimaryForLastGroupMember() {
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ACCOUNT_GROUP,MANUALLY_CREATED);
        List<String> accountGroupFields = new List<String>{'Id',RECORD_TYPE_ID,NAME};
        String query = new NSP_QueryBuilder(NSP_ACCOUNT_GROUP, accountGroupFields)
                        .addFilter(RECORD_TYPE_ID, manuallyCreatedRecordTypeId) 
                        .addFilter(NSP_TAG,'Test Grp 1').build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);
      
        List<String> accountFields = new List<String>{'Id'};
        String accountQuery = new NSP_QueryBuilder(ACCOUNT, accountFields)
            					.addContainsFilter(NAME,TEST_ACCOUNT).build();
        List<Account> accountList = (List<Account>)Database.query(accountQuery);
        
        Test.startTest();      
        NSP_Account_Group_Member__c accGrpMem1 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), ACCOUNT_GROUP_MEMBER_DEFAULTS, false);
        accGrpMem1.NSP_Member_Account__c = accountList[0].Id;
        accGrpMem1.NSP_Group__c = accGrpRecord.Id;
        INSERT accGrpMem1;
        
        NSP_Account_Group_Member__c accGrpMem2 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), ACCOUNT_GROUP_MEMBER_DEFAULTS, false);
        accGrpMem2.NSP_Member_Account__c = accountList[1].Id;
        accGrpMem2.NSP_Group__c = accGrpRecord.Id;
        INSERT accGrpMem2;
        DELETE accGrpMem1;
        System.assertEquals([SELECT Id, NSP_Primary__c FROM NSP_Account_Group_Member__c WHERE Id =: accGrpMem2.Id].NSP_Primary__c, true ,'Updated Last Member as Primary');
        Test.StopTest();
    }
    
    //Not Update the last Account Group Member record to primary if primary member of Account Group is deleted
    @IsTest
    static void testNotUpdatePrimaryForLastGroupMember() {
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ACCOUNT_GROUP,MANUALLY_CREATED);
        List<String> accountGroupFields = new List<String>{'Id',RECORD_TYPE_ID,NAME};
        String query = new NSP_QueryBuilder(NSP_ACCOUNT_GROUP, accountGroupFields)
                        .addFilter(RECORD_TYPE_ID, manuallyCreatedRecordTypeId) 
                        .addFilter(NSP_TAG,'Test Grp 2').build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);
      
        List<String> accountFields = new List<String>{'Id'};
        String accountQuery = new NSP_QueryBuilder(ACCOUNT, accountFields)
            					.addContainsFilter(NAME,TEST_ACCOUNT).build();
        List<Account> accountList = (List<Account>)Database.query(accountQuery);
        
        Test.startTest();      
        NSP_Account_Group_Member__c accGrpMem1 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), ACCOUNT_GROUP_MEMBER_DEFAULTS, false);
        accGrpMem1.NSP_Member_Account__c = accountList[0].Id;
        accGrpMem1.NSP_Group__c = accGrpRecord.Id;
        INSERT accGrpMem1;
        
        NSP_Account_Group_Member__c accGrpMem2 = (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), ACCOUNT_GROUP_MEMBER_DEFAULTS, false);
        accGrpMem2.NSP_Member_Account__c = accountList[1].Id;
        accGrpMem2.NSP_Group__c = accGrpRecord.Id;
        INSERT accGrpMem2;
        DELETE accGrpMem1;
        System.assertEquals([SELECT Id, NSP_Primary__c FROM NSP_Account_Group_Member__c WHERE Id =: accGrpMem2.Id].NSP_Primary__c, true ,'Not Updated Last Member as Primary');
        Test.StopTest();
    }
    
    /***********************************************************************
    * @Description: This method for testing WX Account Group 
    * if primary account is deleted from Account Group Member then Assign the Primary
    * Account i.e from Asset WX child lowest Number as Primary Group Member
    **************************************************************************/
    @isTest
    static void onUpdatePrimaryAccountForWxAccountGroup(){
        Id wXWARecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WX_WA).getRecordTypeId();
        List<sObject> lstrecords = new List<sObject>();
        for(Integer i = 1; i <= 3; i++){
            Account acc = new Account();
            acc.Name = 'Test Account '+i;
            acc.NSP_OneVoice_External_ID__c = 'TestAccount'+i;
            Account accountRef = new Account(NSP_OneVoice_External_ID__c = 'TestAccount'+i);
            
            Asset asset = new Asset();
           	asset.Name = 'Test Account '+i;
            asset.recordtypeId = wXWARecordTypeId;
            asset.NSP_WX_WA_CHILD_ID__c = i == 1 ? null : i;
            asset.Account = accountRef;
            asset.NSP_WX_WA_Parent_ID__c = '12345';

            lstrecords.add(acc);
            lstrecords.add(asset);
        }
		insert new NSP_Trigger_Switch__c(AccountTrigger__c = True);
        insert lstrecords;
        
        Asset asst = [SELECT Id,AccountId FROM Asset WHERE NSP_WX_WA_CHILD_ID__c = null AND NSP_WX_WA_Parent_ID__c = '12345'];
        asst.NSP_WX_WA_CHILD_ID__c = 1;
        Test.startTest();
        update asst;
        delete [SELECT Id FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c =:asst.AccountId];
        Assert.areEqual('WX Account Group - Test Account 2', [SELECT Name FROM NSP_Account_Group__c WHERE NSP_Type__c = 'WX Account Group' LIMIT 1].Name);
        Test.stopTest();
    }
}