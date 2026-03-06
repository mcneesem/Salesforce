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

    @TestSetup
    private static void prepareTestData()
    {
        // Minimal profile/user to own records if needed
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            Alias = 'tuser',
            Email = 'tuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'tuser-' + System.now().getTime() + '@example.com'
        );
        insert u;
        System.runAs(u) 
        {       
            //Account creation
             Account acc = new Account();
            acc.Name = 'Test Acc';
            
            insert acc;
            
            //Contact creation
            Contact con = new Contact();
            con.AccountId = acc.Id ;
            con.LastName = 'Test con';
            con.FirstName = 'Test First';
            con.NSP_Employee_Status__c = 'HIRED';
            
            insert con;
            
            //Asset creation
            Asset asset = new Asset();
            asset.Name = 'Test Asset' ;
            asset.ContactId = con.Id ;
            asset.AccountId = acc.Id ;
            
            insert asset;
            
            // Case Creation
            Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
            newCaseWithCon.contactId = con.Id;
            newCaseWithCon.NSP_Category__c = NSP_ServiceConstants.HW_SECTION_125;
            newCaseWithCon.SSNVS_Mismatch__c = '1 - SSN not in file (never issued)';
            newCaseWithCon.AccountId = acc.Id;
            
            insert newCaseWithCon;
            
            // Sub Client
            NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
            subClient.NSP_Account__c = acc.Id;
            subClient.NSP_Asset__c = asset.Id ;
            subClient.Name = 'Test Sub Client One';
            subClient.NSP_Account_Status__c = 'Active';
            
            insert subClient;
            
            List<NSP_Sub_Client_Contact__c> subClientContactList = new List<NSP_Sub_Client_Contact__c>();
            // Sub client Contact
            NSP_Sub_Client_Contact__c subClientCon1 = new NSP_Sub_Client_Contact__c();
            subClientCon1.NSP_Sub_Client__c = subClient.Id;
            subClientCon1.NSP_Paid_Non_Paid__c = 'Paid WSEE';
            subClientCon1.NSP_Employee_Status__c = 'HIRED';
            subClientCon1.NSP_Payroll_Contact__c = true;
            subClientCon1.NSP_Work_Email__c = 'test@test.com';
            subClientCon1.NSP_Contact__c = con.Id;
            
            subClientContactList.add(subClientCon1);
            
            NSP_Sub_Client_Contact__c subClientCon2 = new NSP_Sub_Client_Contact__c();
            subClientCon2.NSP_Sub_Client__c = subClient.Id;
            subClientCon2.NSP_Paid_Non_Paid__c = 'Paid WSEE';
            subClientCon2.NSP_Employee_Status__c = 'HIRED';
            subClientCon2.NSP_Payroll_Contact__c = false;
            subClientCon2.NSP_Work_Email__c = '';
            subClientCon2.NSP_Contact__c = con.Id;
            
            subClientContactList.add(subClientCon2);
            
            insert subClientContactList;
            
        } // end runAs
    }
    
    @IsTest
    private static void testGetSubClientAndSubClientContacts_Positive()
    {
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        
        Contact contactObj = [SELECT ID, NSP_Per_ID__c FROM Contact WHERE AccountId = :accountObj.Id LIMIT 1];
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
            ( results != null && !results.isEmpty() ) ? 
            results[0] : 
            new CaseSendSSNVSTeamEmailAction.ActionOutputParams()
        );
        
        Assert.areEqual(1, result.subClientContacts?.size(), 'Email should be sent');
        
    }
    
    @isTest
    private static void testGetSubClientAndSubClientContacts_Negative_ContactTerminated()
    {
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        
        Contact contactObj = [SELECT ID, AccountId, NSP_Employee_Status__c FROM Contact WHERE AccountId = : accountObj.Id LIMIT 1];
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
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        
        List<NSP_Sub_Client_Contact__c> subClientCons = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c, NSP_Contact__c FROM NSP_Sub_Client_Contact__c LIMIT 2];
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
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        NSP_Sub_Client_Contact__c subClientCon = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c != NULL LIMIT 1];
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
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        
        Contact contactObj = [SELECT ID, Workday_Employee_ID__c FROM Contact WHERE AccountId = :accountObj.Id LIMIT 1];
        contactObj.Workday_Employee_ID__c = '12344';
        update contactObj;
        
        NSP_Sub_Client_Contact__c subClientCon = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = NULL LIMIT 1];
        subClientCon.NSP_Employee_Status__c = '';
        subClientCon.NSP_Paid_Non_Paid__c = paidNonPaidString;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Work_Email__c = 'test@example1.com';
        
        update subClientCon;
        
        NSP_Sub_Client_Contact__c subClientCon1 = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c, NSP_Payroll_Contact__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = 'test@test.com' LIMIT 1];
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
    private static void testGetSubClientAndSubClientContacts_Negative_BlankStatus()
    {
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        
        NSP_Sub_Client_Contact__c subClientCon = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = NULL LIMIT 1];
        subClientCon.NSP_Employee_Status__c = '	L.O.A.';
        subClientCon.NSP_Paid_Non_Paid__c = paidNonPaidString;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Work_Email__c = 'test@example2.com';
        
        update subClientCon;
        
        NSP_Sub_Client_Contact__c subClientCon1 = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = 'test@test.com' LIMIT 1];
        subClientCon1.NSP_Work_Email__c = '';
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
        
        Assert.areNotEqual(null, result.errorEntries, 'Status not found error');
        
    }
    
    @isTest
    private static void testGetSubClientAndSubClientContacts_Negative_NotEligibleSCC()
    {
        Case caseObj = [SELECT Id, AccountId, ContactId, SSNVS_Mismatch__c FROM Case WHERE SSNVS_Mismatch__c != NULL  LIMIT 1];
        Account accountObj = [SELECT Id FROM Account WHERE Id = :caseObj.AccountId LIMIT 1];
        
        NSP_Sub_Client_Contact__c subClientCon = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = NULL LIMIT 1];
        subClientCon.NSP_Employee_Status__c = '';
        subClientCon.NSP_Paid_Non_Paid__c = paidNonPaidString;
        subClientCon.NSP_On_Site_Supervisor__c = false;
        subClientCon.NSP_Work_Email__c = 'test@example3.com';
        subClientCon.NSP_Payroll_Contact__c = false;
        
        update subClientCon;
        
        NSP_Sub_Client_Contact__c subClientCon1 = [SELECT ID, NSP_Work_Email__c, NSP_Employee_Status__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Work_Email__c = 'test@test.com' LIMIT 1];
        subClientCon1.NSP_Work_Email__c = '';
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
        
        Assert.areNotEqual(null, result.errorEntries, 'Not Eligible sub client contacts');
        
    }   
}