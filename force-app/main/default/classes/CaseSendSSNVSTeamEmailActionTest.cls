@IsTest
private class CaseSendSSNVSTeamEmailActionTest
{
    /**
    * Test data covers:
    * - Account, Contact, Asset
    * - Case with Contact
    * - NSP_Sub_Client__c with Active status
    * - NSP_Sub_Client_Contact__c qualifying for query (email present, Paid WSEE/Active Non-Paid, HIRED)
    */

    // LOCAL VARIABLES
    private static final String emailBodyString = 'Body with token {!varCase.SSNVS_Mismatch__c} and other text';
    private static final String resultMessageString = 'Results should not be null';
    private static final String paidNonPaidString = 'Active Non-Paid User';

    private static final String caseSetupAssertMessage = 'Expected one Case from setup';
    private static final String accountSetupAssertMessage = 'Expected one Account from setup';
    private static final String contactSetupAssertMessage = 'Expected one Contact from setup';
    private static final String sccSetupAssertMessage = 'Expected one SCC without email';
    private static final String sccSetupEmailAssertMessage = 'Expected seeded SCC with test@test.com';

    @TestSetup
    private static void prepareTestData()
    {
        // Account creation
        Account acc = new Account();
        acc.Name = 'Test Acc';

        insert acc;

        // Contact creation
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.LastName = 'Test con';
        con.FirstName = 'Test First';
        con.NSP_Employee_Status__c = 'HIRED';

        insert con;

        // Asset creation
        Asset asset = new Asset();
        asset.Name = 'Test Asset';
        asset.ContactId = con.Id;
        asset.AccountId = acc.Id;

        insert asset;

        // Case Creation
        Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCaseWithCon.ContactId = con.Id;
        newCaseWithCon.NSP_Category__c = NSP_ServiceConstants.HW_SECTION_125;
        newCaseWithCon.SSNVS_Mismatch__c = '1 - SSN not in file (never issued)';
        newCaseWithCon.AccountId = acc.Id;
        insert newCaseWithCon;

        // Sub Client
        NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
        subClient.NSP_Asset__c = asset.Id;
        subClient.NSP_Account__c = acc.Id;
        subClient.Name = 'Test Sub Client One';
        subClient.NSP_Account_Status__c = 'Active';

        insert subClient;

        // Sub client Contacts
        List<NSP_Sub_Client_Contact__c> subClientContacts = new List<NSP_Sub_Client_Contact__c>();
        NSP_Sub_Client_Contact__c subClientCon1 = new NSP_Sub_Client_Contact__c();
        subClientCon1.NSP_Sub_Client__c = subClient.Id;
        subClientCon1.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon1.NSP_Employee_Status__c = 'HIRED';
        subClientCon1.NSP_Payroll_Contact__c = true;
        subClientCon1.NSP_Work_Email__c = 'test@test.com';
        subClientCon1.NSP_Contact__c = con.Id;

        subClientContacts.add(subClientCon1);

        NSP_Sub_Client_Contact__c subClientCon2 = new NSP_Sub_Client_Contact__c();
        subClientCon2.NSP_Sub_Client__c = subClient.Id;
        subClientCon2.NSP_Paid_Non_Paid__c = 'Paid WSEE';
        subClientCon2.NSP_Employee_Status__c = 'HIRED';
        subClientCon2.NSP_Payroll_Contact__c = true;
        subClientCon2.NSP_Work_Email__c = '';
        subClientCon2.NSP_Contact__c = con.Id;

        subClientContacts.add(subClientCon2);

        insert subClientContacts;
    }

    @IsTest
    private static void testGetSubClientAndSubClientContacts_Positive()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<Contact> contactList = [SELECT Id, NSP_Per_ID__c
                                     FROM Contact
                                     WHERE AccountId = :accountObj.Id LIMIT 1];
        Assert.areEqual(1, contactList.size(), contactSetupAssertMessage);
        Contact contactObj = contactList[0];
        contactObj.NSP_Per_ID__c = '1234';
        update contactObj;

        List<NSP_Sub_Client_Contact__c> subClientContacts = [SELECT Id, NSP_Work_Email__c, NSP_Employee_Status__c, NSP_Contact__c
                                                         FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = NULL LIMIT 1];
        Assert.areNotEqual(null, subClientContacts, 'All sub client contacts should be there to send the email');
        NSP_Sub_Client_Contact__c subClientContact = subClientContacts[0];
        subClientContact.NSP_Work_Email__c = 'test@example.com';
        update subClientContact;
        
        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, accountObj.Id, 'Account should persist');
        Assert.areNotEqual(null, caseObj.Id, 'Case should persist');
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            (results != null && !results.isEmpty()) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areEqual(2, result.subClientContacts?.size(), 'Email should be sent');

    }
    
        @IsTest
    private static void testGetSubClientAndSubClientContacts_Negative_No_Email()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<Contact> contactList = [SELECT Id, NSP_Per_ID__c
                                     FROM Contact
                                     WHERE AccountId = :accountObj.Id LIMIT 1];
        Assert.areEqual(1, contactList.size(), contactSetupAssertMessage);
        Contact contactObj = contactList[0];
        contactObj.NSP_Per_ID__c = '1234';
        update contactObj;
        
        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, accountObj.Id, 'Account should persist');
        Assert.areNotEqual(null, caseObj.Id, 'Case should persist');
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            (results != null && !results.isEmpty()) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areNotEqual(null, result.errorEntries, 'Error is required before sending the success email');

    }

    @isTest
    private static void testGetSubClientAndSubClientContacts_Negative_ContactTerminated()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<Contact> contactList = [SELECT Id, AccountId, NSP_Employee_Status__c
                                     FROM Contact
                                     WHERE AccountId = :accountObj.Id LIMIT 1];
        Assert.areEqual(1, contactList.size(), contactSetupAssertMessage);
        Contact contactObj = contactList[0];
        contactObj.NSP_Employee_Status__c = 'Terminated';
        update contactObj;

        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            ( results != null && !results.isEmpty() ) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areNotEqual(null, result.errorEntries, 'Expecting no contacts found');

    }

    @isTest
    private static void testGetSubClientAndSubClientContacts_Negative_NotMatchedSCC()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<NSP_Sub_Client_Contact__c> subClientCons = [SELECT Id, NSP_Work_Email__c, NSP_Employee_Status__c, NSP_Contact__c
                                                         FROM NSP_Sub_Client_Contact__c LIMIT 2];
        for( NSP_Sub_Client_Contact__c scc : subClientCons )
        {
            scc.NSP_Contact__c = null;
        }

        update subClientCons;

        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            ( results != null && !results.isEmpty() ) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areNotEqual(null, result.errorEntries, 'Expecting no contacts found');

    }

    @isTest
    private static void testGetSubClientAndSubClientContacts_Negative_BlankWorkEmail()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<NSP_Sub_Client_Contact__c> subClientConList = [SELECT Id, NSP_Work_Email__c, NSP_Employee_Status__c
                                                            FROM NSP_Sub_Client_Contact__c
                                                            WHERE NSP_Work_Email__c != NULL LIMIT 1];
        Assert.areEqual(1, subClientConList.size(), 'Expected one SCC with email');
        NSP_Sub_Client_Contact__c subClientCon = subClientConList[0];
        subClientCon.NSP_Work_Email__c = '';
        update subClientCon;

        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            ( results != null && !results.isEmpty() ) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areNotEqual(null, result.errorEntries, 'Expecting Blank email error');

    }

    @isTest
    private static void testGetSubClientAndSubClientContacts_Positive_ActiveNonPaid()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<Contact> contactList = [SELECT Id, Workday_Employee_ID__c
                                     FROM Contact
                                     WHERE AccountId = :accountObj.Id LIMIT 1];
        Assert.areEqual(1, contactList.size(), contactSetupAssertMessage);
        Contact contactObj = contactList[0];
        contactObj.Workday_Employee_ID__c = '12344';
        update contactObj;

        List<NSP_Sub_Client_Contact__c> subClientConListA = [SELECT Id, NSP_Work_Email__c, NSP_Employee_Status__c
                                                             FROM NSP_Sub_Client_Contact__c
                                                             WHERE NSP_Work_Email__c = NULL LIMIT 1];
        Assert.areEqual(1, subClientConListA.size(), sccSetupAssertMessage);
        NSP_Sub_Client_Contact__c subClientCon = subClientConListA[0];
        subClientCon.NSP_Employee_Status__c = '';
        subClientCon.NSP_Paid_Non_Paid__c = paidNonPaidString;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Work_Email__c = 'test@example1.com';

        update subClientCon;

        List<NSP_Sub_Client_Contact__c> subClientConListB = [SELECT Id, NSP_Work_Email__c, NSP_Employee_Status__c, NSP_Payroll_Contact__c
                                                             FROM NSP_Sub_Client_Contact__c
                                                             WHERE NSP_Work_Email__c = 'test@test.com' LIMIT 1];
        Assert.areEqual(1, subClientConListB.size(), sccSetupEmailAssertMessage);
        NSP_Sub_Client_Contact__c subClientCon1 = subClientConListB[0];
        subClientCon1.NSP_Payroll_Contact__c = false;
        update subClientCon1;

        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            ( results != null && !results.isEmpty() ) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areEqual(1, result.subClientContacts?.size(), 'Email should be sent');

    }
    
        @isTest
    private static void testGetSubClientAndSubClientContacts_Negative_NotEligibleSSC()
    {
        List<Case> caseList = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c
                               FROM Case
                               WHERE SSNVS_Mismatch__c != NULL LIMIT 1];
        Assert.areEqual(1, caseList.size(), caseSetupAssertMessage);
        Case caseObj = caseList[0];

        List<Account> accList = [SELECT Id
                                 FROM Account
                                 WHERE Id = :caseObj.AccountId LIMIT 1];
        Assert.areEqual(1, accList.size(), accountSetupAssertMessage);
        Account accountObj = accList[0];

        List<NSP_Sub_Client_Contact__c> subClientConList = [SELECT Id, NSP_Work_Email__c, NSP_Payroll_Contact__c, NSP_Employee_Status__c
                                                            FROM NSP_Sub_Client_Contact__c];
        for(NSP_Sub_Client_Contact__c subClientContact : subClientConList)
        {
            subClientContact.NSP_Payroll_Contact__c = false;
        }
        
        update subClientConList;

        List<CaseSendSSNVSTeamEmailAction.ActionInputParams> inputParams = new List<CaseSendSSNVSTeamEmailAction.ActionInputParams>();
        CaseSendSSNVSTeamEmailAction.ActionInputParams actionInputParams = new CaseSendSSNVSTeamEmailAction.ActionInputParams();
        actionInputParams.accountId = accountObj.Id;
        actionInputParams.caseObj = caseObj;
        actionInputParams.emailSubject = 'TestSubject';
        actionInputParams.emailBody= emailBodyString;
        inputParams.add(actionInputParams);

        Test.startTest();
        List<CaseSendSSNVSTeamEmailAction.ActionOutputParams> results =
            CaseSendSSNVSTeamEmailAction.getSubClientAndSubClientContacts(inputParams);
        Test.stopTest();

        // VALIDATION
        Assert.areNotEqual(null, results, resultMessageString);

        CaseSendSSNVSTeamEmailAction.ActionOutputParams result = (
            ( results != null && !results.isEmpty() ) ?
            results[0] :
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );

        Assert.areNotEqual(null, result.errorEntries, 'Not Eligible SSC records');

    }
}