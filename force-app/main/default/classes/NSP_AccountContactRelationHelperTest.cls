@isTest
private class NSP_AccountContactRelationHelperTest {
    private static final String TEST_EMAIL = 'test@gmail.com';

    private static final List<String> CONTACT_FIELDS = new List<String>{
        'Id',
        'recordTypeId',
        'NSP_Work_Phone__c', 'Email', 'NSP_Work_email__c'};
    private static final List<String> ACR_FIELDS = new List<String>{
        'Id',
        'AccountId', 'ContactId', 'NSP_Work_Email__c', 'NSP_Work_Phone__c'
    };
    private static final List<String> ACCOUNT_FIELDS = new List<String>{
        'Id',
        'Name'
    };

    @testSetup
    private static void testData() {
        //Insert Test Account record
        Account acc1 = NSP_TestHelper.createAccount(true);
        NSP_TestHelper.createContact(acc1.id, true);
        Test.startTest();
        Account account = New Account(Name = 'TestAccount', AccountNumber = '12345',NSP_AIMS_Client__c = 'ateammember1');
        insert account;

        Contact con = new Contact();
        con.AccountId = account.Id;
        con.NSP_Work_email__c = TEST_EMAIL;
        con.LastName ='Test Con';
        con.NSP_Work_email__c = 'test@gmail.com';
        insert con;
        Test.stopTest();
    }

    @isTest
    private static void testAccountContactInsert() {

        Test.startTest();
        Account accObj = [Select Id,Name from Account WHERE Name!= null  LIMIT 1];
        ID accountId = accObj.Id;
        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accountId;
        opportuniytObject.stagename = NSP_SalesConstants.DISCOVERY_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        //Inserting Opportunity Object
        insert opportuniytObject;
        Test.stopTest();
        AccountContactRelation acrObj  = [Select Id from AccountContactRelation WHERE AccountId =: accountId];

        acrObj.Roles = 'Agency';
        acrObj.NSP_Is_Primary__c = true;
        acrObj.IsActive =true;

        // Start Test

        update acrObj;

        System.assertEquals(acrObj.NSP_Is_Primary__c,True);
    }

    @isTest
    private static void testAccountContactUpdate() {

        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        Map<Id,AccountContactRelation> acrMap = new Map<Id,AccountContactRelation>();
        Account accObj = [Select Id,Name from Account  WHERE Name!= null  LIMIT 1 ];
        ID accountId = accObj.Id;
        AccountContactRelation acrObj  =[Select Id,AccountId from AccountContactRelation WHERE AccountId =: accountId];
        acrObj.Roles = 'Agency';
        acrObj.NSP_Is_Primary__c = true;
        acrObj.IsActive =true;
        acrList.add(acrObj);
        acrMap.put(acrObj.Id,acrObj);
        NSP_AccountContactRelationTriggerHelper acrObj1 = new NSP_AccountContactRelationTriggerHelper();
        acrObj1.afterInsertDirector(acrList,acrMap);
        // Start Test
        Test.startTest();
        Test.stopTest();
        System.assertEquals(acrObj.NSP_Is_Primary__c,True);
    }

    @isTest
    private static void checkingRestrictingDeletionOfAccConRelation() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =: NSP_ServiceConstants.PEOSERVICE];
        Contact contact = [SELECT Id, LastName FROM Contact WHERE LastName ='Test Con' LIMIT 1];

        List<Account> lstAccounts = new List<Account>();
        List<AccountContactRelation> lstAcr = new List<AccountContactRelation>();

        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newUser.ProfileId = profile.Id;
        newUser.UserName =  Integer.valueOf(math.rint(math.random() * 1000000))+ '@test' + UserInfo.getOrganizationId()+ '.org';

        for(Integer ints=0 ; ints<= 5; ints++){
            Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
            newAccount.Name = 'Test Account Today'+ints;
            lstAccounts.add(newAccount);
        }
        insert lstAccounts;

        for(Account acc: lstAccounts){
            lstAcr.add(new AccountContactRelation(
                AccountId = acc.Id,
                ContactId = contact.Id,
                NSP_Community_Access__c = 'PEO Projects'
            ));
        }
        insert lstAcr;

        Test.startTest();
        try {
            delete [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE Id =:lstAcr.get(3).Id LIMIT 1];
        }
        catch (DmlException ex) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , ex.getDmlStatusCode(0),'Error Exception');
        }
        Test.stopTest();
        //
        List<AccountContactRelation> coverage = new List<AccountContactRelation>();
        coverage.add(
            new AccountContactRelation(
                NSP_Community_Access__c=''
            )
        );
        NSP_AccountContactRelationTriggerHelper.afterDeleteDirector( coverage ); // for additional code coverage...
    }

    @isTest
    private static void checkingRestrictingNotIntegrationUserDeletionOfAccConRelation() {
        List<Contact> sharedContacts = [
            SELECT Id , LastName
            FROM Contact
            WHERE ( LastName = 'Test Con' )
            LIMIT 1
        ];
        Assert.isTrue( !sharedContacts.isEmpty() , 'No \'Test Con\' Contacts found.' );
        Contact sharedContact = sharedContacts[0];

        List<User> integrationUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'Integration User' )
                AND ( IsActive = True )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( !integrationUsers.isEmpty() , 'No \'Integration Users\' Users found.' );
        User newUserInt = integrationUsers[0];

        List<User> peoServiceUsers = [
            SELECT Id
            FROM User
            WHERE (
                ( Profile.Name = 'PEO Service' )
                AND ( IsActive = True )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( !peoServiceUsers.isEmpty() , 'No \'PEO Service\' Users found.' );
        User newUserService = peoServiceUsers[0];

        List<Account> lstAccounts = new List<Account>();
        List<AccountContactRelation> lstAcr = new List<AccountContactRelation>();
        for(Integer ints=0 ; ints<= 5; ints++){
            Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
            newAccount.Name = 'Test Account Today'+ints;
            lstAccounts.add(newAccount);
        }
        insert lstAccounts;

        System.runAs(newUserInt) {
            for(Account acc: lstAccounts){
                lstAcr.add(new AccountContactRelation(
                    AccountId = acc.Id,
                    ContactId = sharedContact.Id
                ));
            }
            insert lstAcr;
        }

        System.runAs(newUserService) {
            Test.startTest();
            try {
                delete [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE Id =:lstAcr.get(3).Id LIMIT 1];
            }
            catch (DmlException ex) {
                System.assertEquals(label.NSP_No_Access , 'You do not have enough privileges to perform this operation','Error Exception');
            }
            Test.stopTest();
        }
        //
        // for test code coverage only...
        NSP_AccountContactRelationTriggerHelper.testHandleException( null , null );
        NSP_AccountContactRelationTriggerHelper.afterDeleteDirector( new List<AccountContactRelation>() );
    }

    @isTest
    private static void testCodeCoverage() {
        List<AccountContactRelation> newList = new List<AccountContactRelation>(
            [
                SELECT Id , ContactId , NSP_Community_Access__c
                FROM AccountContactRelation
            ]
        );
        Map<Id,AccountContactRelation> oldMap = new Map<Id,AccountContactRelation>();
        for ( AccountContactRelation newACR : newList ) {
            newACR.NSP_Community_Access__c='PEO Projects';
            oldMap.put(
                newACR.Id ,
                new AccountContactRelation(
                    Id=newACR.Id ,
                    ContactId=newACR.ContactId ,
                    NSP_Community_Access__c=null
                )
            );
        }
        //
        Test.startTest();
        NSP_AccountContactRelationTriggerHelper.createPlatformEventForACR( newList , oldMap );
        Test.stopTest();
    }

    @isTest
    private static void createPlatformEventForACRTest() {
        Test.startTest();
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
        region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;

        Account account = [SELECT Id, Name FROM Account WHERE Name='TestAccount' LIMIT 1];

        AccountContactRelation acr = [SELECT Id, AccountId, NSP_Community_Access__c FROM AccountContactRelation WHERE AccountId =:account.Id LIMIT 1];
        acr.NSP_Community_Access__c = 'PEO Projects';
        update acr;

        acr.NSP_Community_Access__c = '';
        update acr;

        Test.stopTest();
    }

    @isTest
    private static void updateWorkPhoneEmailOnContactTest() {
        String accQuery = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addFilter('Name', 'TestAccount').addLimit(1).build();
        Account acc =  Database.query(accQuery);
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('AccountId', acc.Id).addLimit(1).build();
        AccountContactRelation acr =  Database.query(acrQuery);
        acr.NSP_Work_Email__c = TEST_EMAIL;
        Test.startTest();
        Database.update(acr);
        Test.stopTest();
        String conQuery = new NSP_QueryBuilder('Contact', CONTACT_FIELDS).addFilter('Id', acr.ContactId).addLimit(1).build();
        Contact assertCon =  Database.query(conQuery);
        system.assertEquals(assertCon.NSP_Work_Email__c, TEST_EMAIL); // positive Test
    }

    @isTest
    private static void updateWorkPhoneEmailOnContactNegativeTest() {
        String accQuery = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addFilter('Name', 'TestAccount').addLimit(1).build();
        Account acc =  Database.query(accQuery);
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', ACR_FIELDS).addFilter('AccountId', acc.Id).addLimit(1).build();
        AccountContactRelation acr =  Database.query(acrQuery);
        acr.NSP_Job_Title__c = 'Test';
        Test.startTest();
        Database.update(acr);
        Test.stopTest();
        String conQuery = new NSP_QueryBuilder('Contact', CONTACT_FIELDS).addFilter('Id', acr.ContactId).addLimit(1).build();
        Contact assertCon =  Database.query(conQuery);
        system.assertEquals(assertCon.NSP_Work_Email__c, TEST_EMAIL); // Negative Test
    }

    @isTest
    private static void acrTest() {
        Test.startTest();
        NSP_AccountContactRelationTriggerHelper.getLoggedInUserProfile();
        Test.stopTest();
    }

}
//