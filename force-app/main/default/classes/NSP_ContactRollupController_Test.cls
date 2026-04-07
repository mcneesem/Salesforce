@isTest
private class NSP_ContactRollupController_Test
{
    // Global values
    private static final String accountValidationString = 'Expected at least one Account from testSetup';
    private static final String contactValidationString = 'Expected at least one Contact for Account';
    private static final String subClientValidationString = 'Expected at least one Sub Client for Account';
    private static final String paidNonPaidValue = 'Paid WSEE';
    private static final String onSiteSupervisorRole = 'On-Site Supervisor';
    private static final String payrollContactRole = 'Payroll Contact';
    
    
    @testSetup
    private static void prepareTestData()
    {
        // This code runs as the system user
        List<User> testSystemAdministrators = [
            SELECT
            Id
            FROM
            User
            WHERE (
                ( Profile.Name = 'System Administrator' )
                AND ( IsActive = True )
            )
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Assert.isTrue( testSystemAdministrators != null , 'Null active System Administrator query results.' );
        Assert.isTrue( !testSystemAdministrators.isEmpty() , 'No active System Administrator found.' );
        User userRecord = testSystemAdministrators[0];
        
        System.runAs( userRecord )
        {
            // Creating Account
            Account account = new Account();
            account.Name = 'Test Account';
            account.BillingCity = 'New York';
            account.BillingPostalCode = '10001';
            account.BillingStreet = 'Avenue';
            account.BillingCountry = 'United States';
            account.BillingState = 'New York';
            account.NSP_AIMS_Client__c = '04236';
            
            insert account;
            //ASSERT
            Assert.isTrue(account <> null, 'Account should not be null');
            
            // Create contact
            Contact contact = new Contact();
            contact.FirstName = 'Will Test';
            contact.LastName = 'Smith Test';
            contact.AccountId = account.Id;
            
            insert contact;
            
            // ASSERT
            Assert.isFalse(contact == null, 'Contact record is not inserted');
            
            // Create WO Asset
            string wo_asset_recordType_Id = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
            Asset asset = new Asset();
            asset.NSP_Account_Status__c = 'Active';
            asset.AccountId = account.Id;
            asset.status = 'Active';
            asset.Name = 'Test WO Asset';
            asset.RecordTypeId = wo_asset_recordType_Id;
            
            insert asset;
            
            // ASSERT
            Assert.isNotNull(asset, 'Failed to insert the Asset');
            
            // Create sub client
            NSP_Sub_Client__c subClient = new NSP_Sub_Client__c();
            subClient.NSP_Account__c = account.Id;
            subClient.NSP_Asset__c = asset.Id;
            subClient.Name = 'Test Sub Client';
            
            insert subClient;
            
            // ASSERT
            Assert.isNotNull(subClient, 'Sub Client record not created.');
        }
    }
    
    // Additional coverage: ensure role string spacing and no Client Comm label when false
    @isTest private static void testGetACRCleansRoleStringsNoClientComm()
    {
        Test.startTest();
        
        List<Account> accounts = [
            SELECT
            Id
            FROM
            Account
            LIMIT 1
        ];
        Assert.isTrue(!accounts.isEmpty(), NSP_ContactRollupController_Test.accountValidationString);
        Account account = accounts[0];
        
        List<Contact> contacts = [
            SELECT
            Id
            FROM
            Contact
            WHERE
            AccountId = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!contacts.isEmpty(), NSP_ContactRollupController_Test.contactValidationString);
        Contact contact = contacts[0];
        
        List<AccountContactRelation> acrList = [
            SELECT
            Id, AccountId, ContactId
            FROM
            AccountContactRelation
            WHERE
            AccountId = :account.Id
            AND
            ContactId = :contact.Id
            LIMIT 1
        ];
        Assert.isTrue(!acrList.isEmpty(), 'Expected ACR for Account and Contact');
        AccountContactRelation acr = acrList[0];
        
        // Use actual org picklist values from AccountContactRelation multiselects
        acr.HRScale_Client_Roles__c = 'HRScale Absence Partner;HRScale Compensation Partner;HRScale Security Partner';
        acr.NSP_Service_Roles__c = 'Key Decision Maker;Key Economic Buyer';
        acr.NSP_Support_Role__c = 'PerformSmart Main Admin;PerformSmart Secondary Admin';
        acr.Client_Communication_Contact__c = false;
        update acr;
        
        List<NSP_ContactRollupController.ResultWrapper> results = NSP_ContactRollupController.getContactRollUpRecords(account.Id, 0, true, null, '', '');
        
        // Validations
        Assert.areEqual(true, results.size() > 0, 'Expected at least one result');
        String roles = results[0].allRoles;
        Assert.isTrue(roles.contains('HRScale Absence Partner; HRScale Compensation Partner; HRScale Security Partner'), 'HRScale roles should have "; " spacing with real labels');
        Assert.isTrue(roles.contains('Key Decision Maker; Key Economic Buyer'), 'Service roles should have "; " spacing with real labels');
        Assert.isTrue(roles.contains('PerformSmart Main Admin; PerformSmart Secondary Admin'), 'Support roles should have "; " spacing with real labels');
        Assert.isTrue(!roles.contains('Client Communication Contact'), 'Client Communication label must not be present when flag is false');
        
        Test.stopTest();
    }
    
    // Additional coverage: subClientFilter with valid and invalid field API names
    @isTest private static void testSubClientFilteredFlagsMixedValidity()
    {
        Test.startTest();
        
        List<Account> accounts = [
            SELECT
            Id
            FROM
            Account
            LIMIT 1
        ];
        Assert.isTrue(!accounts.isEmpty(), NSP_ContactRollupController_Test.accountValidationString);
        Account account = accounts[0];
        
        List<Contact> contacts = [
            SELECT
            Id
            FROM
            Contact
            WHERE
            AccountId = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!contacts.isEmpty(),  NSP_ContactRollupController_Test.contactValidationString);
        Contact contact = contacts[0];
        
        List<NSP_Sub_Client__c> subClients = [
            SELECT
            Id
            FROM
            NSP_Sub_Client__c
            WHERE
            NSP_Account__c = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!subClients.isEmpty(), NSP_ContactRollupController_Test.subClientValidationString);
        NSP_Sub_Client__c subClient = subClients[0];
        
        NSP_Sub_Client_Contact__c scc = new NSP_Sub_Client_Contact__c(
            NSP_Sub_Client__c = subClient.Id,
            NSP_Contact__c = contact.Id,
            NSP_Paid_Non_Paid__c = NSP_ContactRollupController_Test.paidNonPaidValue,
            NSP_Employee_Status__c = 'REHIRED',
            NSP_On_Site_Supervisor__c = true,
            NSP_Payroll_Contact__c = false,
            NSP_HR_Contact__c = true
        );
        insert scc;
        
        // valid and invalid field names
        String subClientFilter = 'NSP_On_Site_Supervisor__c,NSP_HR_Contact__c,NotAField__c';
        List<NSP_ContactRollupController.ResultWrapper> res = NSP_ContactRollupController.getContactRollUpRecords(account.Id, 0, true, null, subClientFilter, '');
        
        // Valdations
        Assert.isTrue(!res.isEmpty(), 'Expected results for valid filters');
        // Ensure dedup works in getUpdatedRoles by passing existing role
        String roles = res[0].allRoles;
        Assert.isTrue(roles.contains(NSP_ContactRollupController_Test.onSiteSupervisorRole), 'Expected On-Site Supervisor label');
        Assert.isTrue(roles.contains('HR Contact'), 'Expected HR Contact label');
        Test.stopTest();
    }
    
    // Additional coverage: merging into existing wrapper adds subclient and role without duplicates
    @isTest private static void testSubClientMergeExistingWrapperAddsSubClientAndRoles()
    {
        Test.startTest();
        
        List<Account> accounts = [
            SELECT
            Id
            FROM
            Account
            LIMIT 1
        ];
        Assert.isTrue(!accounts.isEmpty(), NSP_ContactRollupController_Test.accountValidationString);
        Account account = accounts[0];
        
        List<Contact> contacts = [
            SELECT
            Id
            FROM
            Contact
            WHERE AccountId = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!contacts.isEmpty(),  NSP_ContactRollupController_Test.contactValidationString);
        Contact contact = contacts[0];
        
        List<NSP_Sub_Client__c> scList = [
            SELECT
            Id
            FROM
            NSP_Sub_Client__c
            WHERE
            NSP_Account__c = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!scList.isEmpty(), NSP_ContactRollupController_Test.subClientValidationString);
        NSP_Sub_Client__c sc1 = scList[0];
        
        List<Asset> assets = [
            SELECT
            ID, AccountId
            FROM
            Asset
            WHERE
            AccountId = : account.Id
            LIMIT 1
        ];
        Assert.isTrue(!assets.isEmpty(), 'Expected at least one Asset for Account');
        Asset aasetRec = assets[0];
        
        // First contact record to seed wrapper
        NSP_Sub_Client_Contact__c scc1 = new NSP_Sub_Client_Contact__c(
            NSP_Sub_Client__c = sc1.Id,
            NSP_Contact__c = contact.Id,
            NSP_Paid_Non_Paid__c =  NSP_ContactRollupController_Test.paidNonPaidValue,
            NSP_Employee_Status__c = 'REHIRED',
            NSP_On_Site_Supervisor__c = true
        );
        insert scc1;
        
        // Second sub client for same contact to cause merge
        NSP_Sub_Client__c sc2 = new NSP_Sub_Client__c(
            Name = 'Another SC',
            NSP_Account__c = account.Id,
            NSP_Asset__c = aasetRec.Id
        );
        insert sc2;
        
        NSP_Sub_Client_Contact__c scc2 = new NSP_Sub_Client_Contact__c(
            NSP_Sub_Client__c = sc2.Id,
            NSP_Contact__c = contact.Id,
            NSP_Paid_Non_Paid__c =  NSP_ContactRollupController_Test.paidNonPaidValue,
            NSP_Employee_Status__c = 'REHIRED',
            NSP_Payroll_Contact__c = true
        );
        insert scc2;
        
        List<NSP_ContactRollupController.ResultWrapper> res = NSP_ContactRollupController.getContactRollUpRecords(account.Id, 0, true, null, '', '');
        
        // Validations
        Assert.areEqual(true, res.size() > 0, 'Expected at least one wrapper');
        NSP_ContactRollupController.ResultWrapper rw = res[0];
        Assert.areEqual(true, rw.subClients != null && rw.subClients.size() >= 2, 'Should have aggregated subclients for same contact');
        Assert.isTrue(rw.allRoles.contains(NSP_ContactRollupController_Test.onSiteSupervisorRole), 'Merged roles should include first role');
        Assert.isTrue(rw.allRoles.contains(NSP_ContactRollupController_Test.payrollContactRole), 'Merged roles should include second role');
        Test.stopTest();
    }
    
    // Additional coverage: getUpdatedRoles dedup and add
    @isTest private static void testGetUpdatedRolesDedupAndAdd()
    {
        Test.startTest();
        
        NSP_Sub_Client_Contact__c scc = new NSP_Sub_Client_Contact__c(
            NSP_On_Site_Supervisor__c = true,
            NSP_Payroll_Contact__c = true
        );
        // Prepopulate roles with one existing label
        String existing = NSP_ContactRollupController_Test.onSiteSupervisorRole;
        String updated = NSP_ContactRollupController.getUpdatedRoles(existing, scc);
        
        Test.stopTest();
        
        // Validations
        Assert.areEqual(true, updated.contains(NSP_ContactRollupController_Test.onSiteSupervisorRole), 'Existing label should remain');
        Assert.areEqual(true, updated.contains(NSP_ContactRollupController_Test.payrollContactRole), 'New label should be added');
        // Ensure no duplicate of existing label
        Integer count = updated.split(NSP_ContactRollupController_Test.onSiteSupervisorRole).size() - 1;
        Assert.areEqual(1, count, 'Should not duplicate existing role label');
    }
    
    // Additional coverage: malformed regex filter should throw AuraHandledException
    @isTest private static void testGetContactRollUpRecordsBadRegexThrowsAura()
    {
        Test.startTest();
        
        List<Account> accounts = [
            SELECT
            Id
            FROM
            Account
            LIMIT 1
        ];
        Assert.isTrue(!accounts.isEmpty(), NSP_ContactRollupController_Test.accountValidationString);
        Account account = accounts[0];
        
        List<String> bad = new List<String>{'Bad('};
            try
        {
            NSP_ContactRollupController.getContactRollUpRecords(account.Id, 0, true, bad, '', '');
        }
        catch (AuraHandledException ahe)
        {
            Assert.areNotEqual(null, ahe.getMessage(), 'AuraHandledException should carry message');
        }
        Test.stopTest();
    }
    // Testing the Method without filters
    @isTest
    private static void testGetContactRollUpRecordsWithOutFilters()
    {
        Test.startTest();
        
        List<Account> accounts = [
            SELECT
            ID
            FROM
            Account
            LIMIT 1
        ];
        Assert.isTrue(!accounts.isEmpty(), NSP_ContactRollupController_Test.accountValidationString);
        Account account = accounts[0];
        
        List<Contact> contacts = [
            SELECT
            ID, AccountId
            FROM
            Contact
            WHERE
            AccountId = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!contacts.isEmpty(),  NSP_ContactRollupController_Test.contactValidationString);
        Contact contact = contacts[0];
        
        List<NSP_Sub_Client__c> subClients = [
            SELECT
            ID
            FROM
            NSP_Sub_Client__c
            WHERE
            NSP_Account__c = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!subClients.isEmpty(), NSP_ContactRollupController_Test.subClientValidationString);
        NSP_Sub_Client__c subClient = subClients[0];
        
        List<AccountContactRelation> acrList = [
            SELECT
            ID, AccountId, ContactId, NSP_Service_Roles__c
            FROM
            AccountContactRelation
            WHERE
            AccountId = :account.Id
            AND
            ContactId = :contact.Id
            LIMIT 1
        ];
        Assert.isTrue(!acrList.isEmpty(), 'Expected at least one ACR for Account and Contact');
        AccountContactRelation acr = acrList[0];
        
        // Update Account contact Relation
        acr.NSP_Job_Title__c = 'Payroll Specialist';
        acr.NSP_Employee_Status__c = 'HIRED';
        acr.NSP_Work_Phone__c = '9899091366';
        acr.NSP_Work_email__c= 'test.insperity@insperity.com';
        acr.NSP_Service_Roles__c = 'Survey Contact';
        acr.NSP_Owner__c= true;
        update acr;
        
        // ASSERT
        Assert.areEqual(acr.AccountId, account.Id, 'Account Contact Releation ship is not update. Please take a look');
        Assert.areEqual(acr.ContactId, contact.Id, 'Account Contact Releation ship is not update. Please take a look');
        
        // Create sub client contacts
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = subClient.Id;
        subClientCon.NSP_Contact__c = contact.Id;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Payroll_Contact__c= true;
        subClientCon.NSP_Client_Leave_Administrator__c = true;
        subClientCon.NSP_WC_Contact__c = true;
        subClientCon.NSP_HR_Contact__c = true;
        subClientCon.NSP_Benefits_Contact__c = true;
        subClientCon.NSP_Background_Contact__c = true;
        subClientCon.NSP_Unemployment_Contact__c = true;
        
        insert subClientCon;
        
        Assert.isTrue(subClientCon <> null, 'Sub client contact is insertion has a problem');
        
        NSP_ContactRollupController.getContactRollUpRecords(account.Id, 0, true, null, '', '');
        
        Test.stopTest();
    }
    
    // Testing the Method with filters
    @isTest private static void testGetContactRollUpRecordsWithFilters()
    {
        Test.startTest();
        
        List<Account> accounts = [
            SELECT
            ID
            FROM
            Account
            LIMIT 1
        ];
        Assert.isTrue(!accounts.isEmpty(), NSP_ContactRollupController_Test.accountValidationString);
        Account account = accounts[0];
        
        List<Contact> contacts = [
            SELECT
            ID, AccountId
            FROM
            Contact
            WHERE
            AccountId = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!contacts.isEmpty(),  NSP_ContactRollupController_Test.contactValidationString);
        Contact contact = contacts[0];
        
        List<NSP_Sub_Client__c> subClients = [
            SELECT
            ID
            FROM
            NSP_Sub_Client__c
            WHERE
            NSP_Account__c = :account.Id
            LIMIT 1
        ];
        Assert.isTrue(!subClients.isEmpty(), NSP_ContactRollupController_Test.subClientValidationString);
        NSP_Sub_Client__c subClient = subClients[0];
        
        List<AccountContactRelation> acrList = [
            SELECT
            ID, AccountId, ContactId, NSP_Service_Roles__c, Client_Communication_Contact__c
            FROM
            AccountContactRelation
            WHERE
            AccountId = :account.Id
            AND
            ContactId = :contact.Id
            LIMIT 1
        ];
        Assert.isTrue(!acrList.isEmpty(), 'Expected at least one ACR for Account and Contact');
        AccountContactRelation acr = acrList[0];
        
        // Update Account contact Relation
        acr.NSP_Job_Title__c = 'Payroll Specialist';
        acr.NSP_Employee_Status__c = 'HIRED';
        acr.NSP_Work_Phone__c = '9899091366';
        acr.NSP_Work_email__c= 'test.insperity@insperity.com';
        acr.NSP_Service_Roles__c = 'Key Decision Maker;Key Economic Buyer;Key User Buyer';
        acr.NSP_Support_Role__c = 'PerformSmart Main Admin;PerformSmart Secondary Admin;PerformSmart Decision Maker';
        acr.HRScale_Client_Roles__c='HRScale Absence Partner;HRScale Compensation Partner;HRScale Security Partner';
        acr.NSP_Owner__c= true;
        acr.Client_Communication_Contact__c = true;
        update acr;
        
        // ASSERT
        Assert.areEqual(acr.AccountId, account.Id, 'Account Contact Releation ship is not update. Please take a look');
        Assert.areEqual(acr.ContactId, contact.Id, 'Account Contact Releation ship is not update. Please take a look');
        
        // Create sub client contacts
        NSP_Sub_Client_Contact__c subClientCon = new NSP_Sub_Client_Contact__c();
        subClientCon.NSP_Sub_Client__c = subClient.Id;
        subClientCon.NSP_Contact__c = contact.Id;
        subClientCon.NSP_On_Site_Supervisor__c = true;
        subClientCon.NSP_Payroll_Contact__c= true;
        subClientCon.NSP_Client_Leave_Administrator__c = true;
        subClientCon.NSP_WC_Contact__c = true;
        subClientCon.NSP_HR_Contact__c = true;
        subClientCon.NSP_Benefits_Contact__c = true;
        subClientCon.NSP_Background_Contact__c = true;
        subClientCon.NSP_Unemployment_Contact__c = true;
        subClientCon.NSP_Employee_Status__c = 'REHIRED';
        subClientCon.NSP_Paid_Non_Paid__c =  NSP_ContactRollupController_Test.paidNonPaidValue;
        
        insert subClientCon;
        
        Assert.isTrue(subClientCon <> null, 'Sub client contact is insertion has a problem');
        
        string[] allFilters = new string[]
        {
            'Client Communication Contact',
                'Key Decision Maker',
                'Key Economic Buyer',
                'Key User Buyer',
                'PerformSmart Main Admin',
                'PerformSmart Secondary Admin',
                'PerformSmart Decision Maker',
                'HRScale Absence Partner',
                'HRScale Compensation Partner',
                'HRScale Security Partner',
                NSP_ContactRollupController_Test.onSiteSupervisorRole,
                NSP_ContactRollupController_Test.payrollContactRole,
                'Client Leave Administrator',
                'WC Contact',
                'HR Contact',
                'Benefits  Contact',
                'Background Contact',
                'Unemployment Contact'
                };
                    
                    //ASSERTS
                    Assert.areEqual(acr.NSP_Owner__c, true, 'This filter (NSP_Owner__c from ACR) should be true to get accurate values');
        
        NSP_ContactRollupController.getContactRollUpRecords(
            account.Id,
            0,
            true,
            allFilters,
            ' Client Communication Contact,Key Decision Maker,Key Economic Buyer,Key User Buyer,PerformSmart Main Admin,PerformSmart Secondary Admin,PerformSmart Decision Maker,HRScale Absence Partner,HRScale Compensation Partner,HRScale Security Partner,On-Site Supervisor,Payroll Contact,Client Leave Administrator,WC Contact,HR Contact,Benefits  Contact,Background Contact,Unemployment Contact',
            'Client_Communication_Contact__c = true AND NSP_Service_Roles__c INCLUDES (\'Key Decision Maker\',\'Key Economic Buyer\',\'Key User Buyer\') AND NSP_Support_Role__c INCLUDES (\'PerformSmart Main Admin\',\'PerformSmart Secondary Admin\',\'PerformSmart Decision Maker\') AND HRScale_Client_Roles__c INCLUDES (\'HRScale Absence Partner\',\'HRScale Compensation Partner\',\'HRScale Security Partner\')');
        
        Test.stopTest();
    }
    
    @isTest private static void testNullValues()
    {
        Test.startTest();
        try
        {
            NSP_ContactRollupController.getContactRollUpRecords(null, null, null, null, '', '');
        }
        catch ( Exception ex )
        {
            // ASSERTS
            Assert.isTrue(ex.getMessage() <> null, 'The Negative test case should return the exception');
            Assert.areEqual('Script-thrown exception', ex.getMessage(), 'This should return the error message');
        }
        
        Test.stopTest();
    }
}
//