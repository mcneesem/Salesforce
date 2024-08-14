/**
Apex Class Name      :  NSP_ContactRollupController_Test
Version              :  1.0                                                                          
Created Date         :  6/9/2022  
Function             :  Represents test class for NSP_ContactRollupController class
Story                :                                                                      
Modification Log     : Modified by Prakash Jada for better code coverage and optimized the test class to run faster                                                                             
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindu                      7/4/2022            First Iteration
*/


@isTest(SeeAllData = false)
private class NSP_ContactRollupController_Test {

    @testSetup private static void prepareTestData() {
        // This code runs as the system user
        List<User> testSystemAdministrators = [
            SELECT Id
            FROM User
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
        
        System.runAs( userRecord ) {
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

    // Testing the Method without filters
    @isTest private static void Test_Get_Contact_Roll_Up_Records_With_Out_Filters() {
        Test.startTest();
        
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact contact = [SELECT ID,AccountId FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        NSP_Sub_Client__c subClient = [SELECT ID FROM NSP_Sub_Client__c WHERE NSP_Account__c = :account.Id LIMIT 1];
        AccountContactRelation acr = [SELECT ID, AccountId, ContactId, NSP_Service_Roles__c 
                                       FROM AccountContactRelation WHERE AccountId = :account.Id AND ContactId = :contact.Id LIMIT 1];
        // Update Account contact Relation
        acr.NSP_Job_Title__c = 'Payroll Specialist';
        acr.NSP_Employee_Status__c = 'HIRED';
        acr.NSP_Work_Phone__c = '9899091366';
        acr.NSP_Work_email__c= 'test.insperity@insperity.com';
        acr.NSP_Service_Roles__c = 'Survey Contact';
        acr.NSP_Support_Role__c = 'Time & Attendance Main Admin';
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
    @isTest private static void Test_Get_Contact_Roll_Up_Records_With_Filters() {
        Test.startTest();
        
        Account account = [SELECT ID FROM Account LIMIT 1];
        Contact contact = [SELECT ID,AccountId FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        NSP_Sub_Client__c subClient = [SELECT ID FROM NSP_Sub_Client__c WHERE NSP_Account__c = :account.Id LIMIT 1];
        AccountContactRelation acr = [SELECT ID, AccountId, ContactId, NSP_Service_Roles__c 
                                       FROM AccountContactRelation WHERE AccountId = :account.Id AND ContactId = :contact.Id LIMIT 1];
        // Update Account contact Relation
        acr.NSP_Job_Title__c = 'Payroll Specialist';
        acr.NSP_Employee_Status__c = 'HIRED';
        acr.NSP_Work_Phone__c = '9899091366';
        acr.NSP_Work_email__c= 'test.insperity@insperity.com';
        acr.NSP_Service_Roles__c = 'Survey Contact';
        acr.NSP_Support_Role__c = 'Time & Attendance Main Admin';
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
        
        string[] allFilters = new string[]{'Owner', 'Time & Attendance Main Admin', 'On-Site Supervisor'};
            
        //ASSERTS
        Assert.areEqual(acr.NSP_Owner__c, true, 'This filter (NSP_Owner__c from ACR) should be true to get accurate values');
        Assert.areEqual(acr.NSP_Support_Role__c, 'Time & Attendance Main Admin', 'This filter (NSP_Support_Role__c from ACR) should be true to get accurate values');
        Assert.areEqual(subClientCon.NSP_On_Site_Supervisor__c, true, 'This filter (NSP_On_Site_Supervisor__c from Sub client contact) should be true to get accurate values');
        
        NSP_ContactRollupController.getContactRollUpRecords(account.Id, 0, true, allFilters, 'NSP_On_Site_Supervisor__c = true', ' NSP_Owner__c = true AND NSP_Support_Role__c INCLUDES (\'Time & Attendance Main Admin\')');        
        
        Test.stopTest();
    }

    @isTest private static void Test_Null_Values() {
        Test.startTest();
        try {
            NSP_ContactRollupController.getContactRollUpRecords(null, null, null, null, '', '');
        } catch ( Exception ex ) {
            // ASSERTS
            Assert.isTrue(ex.getMessage() <> null, 'The Negative test case should return the exception');
            Assert.areEqual('Script-thrown exception', ex.getMessage(), 'This should return the error message');
        }
        
        Test.stopTest();
    }

}
//