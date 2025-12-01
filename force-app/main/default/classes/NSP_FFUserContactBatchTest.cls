/**
* @description  :  Test Class to NSP_FFUserContactBatch.
* @date 16/01/2023
* Author : Nischay Jindal
* Name : NSP_FFUserContactBatchTest
*/
@IsTest
public class NSP_FFUserContactBatchTest { 
    // Used to correlate User and Contact records created in @testSetup
    private static final String USER_EMPLOYEE_NUMBER = '12449';

    /***********************************************************************************************
    * MethodName: testData
    * Description : Creating test data for NSP_FFUserContactBatchTest
    * Notes:
    *   - Uses @TestSetup so data is created once and shared read-only across tests
    *   - Ensures user-level custom setting exists for the running user context
    *   - Seeds Region, Account, and Contact records required by batch logic
    * ********************************************************************************************/
    @TestSetup
    private static void testData(){
        List<User> users = new List<User>();
        UserRole userRole = NSP_sObjectSelector.selectUserRoleByName('Business Performance Advisor');
        
        User primaryUser = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        primaryUser.userRoleId = userRole.Id;
        primaryUser.EmployeeNumber = USER_EMPLOYEE_NUMBER;
        primaryUser.NSP_FF_User_Count__c = 0;
        primaryUser.NSP_IS_FF_User__c = False;
        primaryUser.NSP_Employee_Per_ID__c = USER_EMPLOYEE_NUMBER;
        users.add(primaryUser);
        
        User bpaUser = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        bpaUser.userRoleId = userRole.Id;
        bpaUser.email = 'jsmithyUserBPA@insperity.com';
        bpaUser.username = 'insperitytestadminuser@insperity.com.testBPA';
        //Updated 
        bpaUser.NSP_Financial_Force_User__c = 'Full Access';
        bpaUser.NSP_FF_User_Count__c = 0;
        bpaUser.EmployeeNumber ='3333';
        bpaUser.NSP_Employee_Per_ID__c = '3333';
        bpaUser.NSP_IS_FF_User__c = False;
        users.add(bpaUser);
        
        User secondaryBpaUser = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        secondaryBpaUser.userRoleId = userRole.Id;
        secondaryBpaUser.email = 'jsmithyUserBPA@insperity.com';
        secondaryBpaUser.username = 'insperitytestadminuser@insperity.com.testBPAS';
        users.add(secondaryBpaUser);
        insert users;
        
        System.runAs (primaryUser) {
            // Insert custom setting
            FF_User_Contact_Batch_Setting__c customSettingRec = new FF_User_Contact_Batch_Setting__c(
                SetupOwnerId = primaryUser.Id,
                SoqlDaysLimit__c = '5'
            );
            insert customSettingRec;
            
            //Insert Test Account record
            pse__Region__c region = new pse__Region__c();
            region.Name = 'United States';
            insert region;
            
            Account testAccount = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
            testAccount.Name = 'testAccount';
            insert testAccount;
            
            //create contact
            Contact testContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            testContact.AccountId = testAccount.Id;
            testContact.Email = 'test@pwc.com';
            testContact.NSP_Per_ID__c = USER_EMPLOYEE_NUMBER;
            testContact.pse__Is_Resource__c =True;
            testContact.pse__Is_Resource_Active__c = True;
            insert testContact;   
        } 
    }
    /***********************************************************************************************
    * MethodName: updateFFUserTest
    * Description : Unit Test 
    * ********************************************************************************************/
    @IsTest
    private static void updateFFUserTest(){
        // Arrange
        List<pse__Region__c> regions = [
            SELECT Id, Name
            FROM pse__Region__c
            WHERE Name = 'United States'
            LIMIT 1
        ];
        Assert.isTrue(regions.size() == 1, 'Expected one Region to exist');
        
        List<User> usersQ = [
            SELECT Id, NSP_IS_FF_User__c, EmployeeNumber, NSP_Employee_Per_ID__c,
                   NSP_Financial_Force_User__c, NSP_FF_User_Count__c
            FROM User
            WHERE NSP_Employee_Per_ID__c = :USER_EMPLOYEE_NUMBER
            LIMIT 1
        ];
        Assert.isTrue(usersQ.size() == 1, 'Expected one User to exist for Per Id');
        List<Contact> contactsQ = [
            SELECT Id, NSP_Per_ID__c, pse__Salesforce_User__c, pse__Is_Resource_Active__c, pse__Is_Resource__c
            FROM Contact
            WHERE NSP_Per_ID__c = :USER_EMPLOYEE_NUMBER
            LIMIT 1
        ];
        Assert.isTrue(contactsQ.size() == 1, 'Expected one Contact to exist for Per Id');
        Contact testContact = contactsQ[0];
        Assert.areEqual(null, testContact.pse__Salesforce_User__c, 'Precondition: Contact should not be linked to a User');

        // Act: run full batch lifecycle within governor reset block
        System.runAs(usersQ[0]){

            Test.StartTest();

            NSP_FFUserContactBatch ffUserContactBatch = new NSP_FFUserContactBatch();
            Database.QueryLocator queryLocator = ffUserContactBatch.start(null);
            ffUserContactBatch.execute(null, new List<User>{ usersQ[0] });
            ffUserContactBatch.finish(null);

            Test.StopTest();
        }
        
        // Assert
        List<Contact> contactPost = [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE Id = :testContact.Id];
        Assert.isTrue(contactPost.size() == 1, 'Expected one Contact after batch');
        List<User> userPost = [SELECT Id, EmployeeNumber, NSP_Employee_Per_ID__c, NSP_FF_User_Count__c FROM User WHERE Id = :usersQ[0].Id];
        Assert.isTrue(userPost.size() == 1, 'Expected one User after batch');
        Assert.areEqual(USER_EMPLOYEE_NUMBER, userPost[0].NSP_Employee_Per_ID__c, 'Per Id should remain unchanged');
        Assert.areNotEqual(null, userPost[0].NSP_FF_User_Count__c, 'FF User Count should be set after batch');
    }
    
    /***********************************************************************************************
    * MethodName: updateContactUserException
    * Description : Negative Unit Test 
    * ********************************************************************************************/
    @IsTest
    private static void updateContactUserException(){
        // Arrange: choose a BPA user that should not match the seeded Contact Per Id
        List<pse__Region__c> regions2 = [
            SELECT Id, Name
            FROM pse__Region__c
            WHERE Name = 'United States'
            LIMIT 1
        ];
        Assert.isTrue(regions2.size() == 1, 'Expected one Region to exist');
        List<User> users2 = [
            SELECT Id, NSP_IS_FF_User__c, EmployeeNumber, NSP_Employee_Per_ID__c,
                   NSP_Financial_Force_User__c, NSP_FF_User_Count__c, Email
            FROM User
            WHERE Email = 'jsmithyUserBPA@insperity.com'
            LIMIT 1
        ];
        Assert.isTrue(users2.size() == 1, 'Expected one BPA User to exist');
        List<Contact> contacts2 = [
            SELECT Id, NSP_Per_ID__c, pse__Salesforce_User__c, pse__Is_Resource_Active__c, pse__Is_Resource__c
            FROM Contact
            WHERE NSP_Per_ID__c = :USER_EMPLOYEE_NUMBER
            LIMIT 1
        ];
        Assert.isTrue(contacts2.size() == 1, 'Expected one Contact to exist for Per Id');
        Contact testContact = contacts2[0];
        Assert.areEqual(null, testContact.pse__Salesforce_User__c, 'Precondition: Contact should be unlinked');
        
        // Act
        Test.StartTest(); 

        NSP_FFUserContactBatch ffUserContactBatch = new NSP_FFUserContactBatch();
        Database.QueryLocator queryLocator = ffUserContactBatch.start(null);
        ffUserContactBatch.execute(null, new List<User>{ users2[0] });
        ffUserContactBatch.finish(null);

        Test.StopTest();

        // Assert: Contact should remain unlinked since selection criteria do not match
        List<Contact> contactPost2 = [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE Id = :testContact.Id];
        Assert.isTrue(contactPost2.size() == 1, 'Expected one Contact after negative path');
        Assert.areEqual(null, contactPost2[0].pse__Salesforce_User__c, 'Contact should remain unlinked for negative path');
    }
    
    /***********************************************************************************************
    * MethodName: createPermissionControl
    * Description : Coverage for createPermissionControl
    * ********************************************************************************************/
    @IsTest
    private static void createPermissionControlTest(){
        // Arrange
        List<pse__Region__c> regions3 = [
            SELECT Id, Name
            FROM pse__Region__c
            WHERE Name = 'United States'
            LIMIT 1
        ];
        Assert.isTrue(regions3.size() == 1, 'Expected one Region to exist');
        List<User> users3 = [
            SELECT Id, NSP_IS_FF_User__c, EmployeeNumber, NSP_Employee_Per_ID__c,
                   NSP_Financial_Force_User__c, NSP_FF_User_Count__c
            FROM User
            WHERE NSP_Employee_Per_ID__c = :USER_EMPLOYEE_NUMBER
            LIMIT 1
        ];
        Assert.isTrue(users3.size() == 1, 'Expected one User to exist for Per Id');
        
        // Act
        Test.startTest();

        NSP_FFUserContactBatch.createPermissionControl(users3[0].id, regions3[0].Id);

        Test.stopTest();

        // Assert (basic invariant): Employee Per Id remains the same
        List<User> userAfterPerm = [SELECT Id, NSP_Employee_Per_ID__c FROM User WHERE Id = :users3[0].Id];
        Assert.isTrue(userAfterPerm.size() == 1, 'Expected one User after permission control');
        Assert.areEqual(USER_EMPLOYEE_NUMBER, userAfterPerm[0].NSP_Employee_Per_ID__c, 'Employee Per Id should remain unchanged after permission control');
    }
    
    /**
     * Method Name: testBatchScheduler_SchedulesAndRuns
     * Description : Coverage for testBatchScheduler_SchedulesAndRuns
     * @param 
     * @return
     */
    @IsTest
    private static void testBatchScheduler_SchedulesAndRuns() {
        // Arrange
        String cronExp = '0 0 0 * * ?'; // runs every day
        String jobName = 'NSP_FFUserContactBatchTest';
        
        // Act: schedule within Test.startTest/stopTest so async fires at stopTest
        Test.startTest();

        System.schedule(jobName, cronExp, new NSP_FFUserContactBatch());
        
        Test.stopTest();
        
        // Assert - verify a scheduled job created for the batch class
        List<CronTrigger> triggers = [
            SELECT Id, State, NextFireTime, TimesTriggered, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = :jobName
            LIMIT 1
        ];
        Assert.isTrue(triggers.size() == 1, 'Expected one scheduled job for batch');
        Assert.areNotEqual(null, triggers[0].NextFireTime, 'Next fire time should be set');
    }

}
//
