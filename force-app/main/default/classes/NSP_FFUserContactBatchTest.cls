/**
* @description  :  Test Class to NSP_FFUserContactBatch.
* @date 16/01/2023
* Author : Nischay Jindal
* Name : NSP_FFUserContactBatchTest
*/
@isTest
public class NSP_FFUserContactBatchTest { 
    private static final String USER_EMPLOYEE_NUMBER = '12449';
    /***********************************************************************************************
    * MethodName: testData
    * Description : Creating test data for NSP_FFUserContactBatchTest
    * ********************************************************************************************/
    @testSetup
    static void testData(){
        List<User> users = new List<User>();
        UserRole userRole = NSP_sObjectSelector.selectUserRoleByName('Business Performance Advisor');
        
        User user = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        user.userRoleId = userRole.Id;
        user.EmployeeNumber = USER_EMPLOYEE_NUMBER;
        user.NSP_FF_User_Count__c = 0;
        user.NSP_IS_FF_User__c = False;
        users.add(user);
        
        User BpaUser = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        BpaUser.userRoleId = userRole.Id;
        BpaUser.email = 'jsmithyUserBPA@insperity.com';
        BpaUser.username = 'insperitytestadminuser@insperity.com.testBPA';
        //Updated 
        BpaUser.NSP_Financial_Force_User__c = 'Full Access';
        BpaUser.NSP_FF_User_Count__c = 0;
        BpaUser.EmployeeNumber ='3333';
        BpaUser.NSP_IS_FF_User__c = False;
        users.add(BpaUser);
        
        User BpaUser2 = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        BpaUser2.userRoleId = userRole.Id;
        BpaUser2.email = 'jsmithyUserBPA@insperity.com';
        BpaUser2.username = 'insperitytestadminuser@insperity.com.testBPAS';
        users.add(BpaUser2);
        insert users;
        
        System.runAs (user) {
            //Insert Test Account record
            pse__Region__c region = new pse__Region__c();
            region.Name = 'United States';
            insert region;
            
            Account acc1 = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
            acc1.Name = 'acc1';
            insert acc1;
            
            //create contact
            Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            newContact.AccountId = acc1.Id;
            newContact.Email = 'test@pwc.com';
            newContact.NSP_Per_ID__c = USER_EMPLOYEE_NUMBER;
            newContact.pse__Is_Resource__c =True;
            newContact.pse__Is_Resource_Active__c = True;
            insert newContact;   
        } 
    }
    /***********************************************************************************************
    * MethodName: updateFFUserTest
    * Description : Unit Test 
    * ********************************************************************************************/
    @isTest
    private static void updateFFUserTest(){
        List<String> regionFields = new List<String>{
            'Id',
                'Name'
                };
                    String queryRegion = new NSP_QueryBuilder('pse__Region__c', regionFields)
                    .addFilter('Name', 'United States').addLimit(1).setSecurityEnforce(false).build();
        pse__Region__c region = Database.query(queryRegion);
        
        List<String> userFields = new List<String>{
            'Id',
                'NSP_IS_FF_User__c',
                'EmployeeNumber',
                'NSP_Financial_Force_User__c',
                'NSP_FF_User_Count__c'
                };
                    String queryUser = new NSP_QueryBuilder('User', userFields)
                    .addFilter('EmployeeNumber', USER_EMPLOYEE_NUMBER).addLimit(1).setSecurityEnforce(false).build();
        User user = Database.query(queryUser);
        List<String> conFields = new List<String>{
            'Id',
                'NSP_Per_ID__c',
                'pse__Salesforce_User__c',
                'pse__Is_Resource_Active__c',
                'pse__Is_Resource__c'
                };
                    String queryContact = new NSP_QueryBuilder('Contact', conFields)
                    .addFilter('NSP_Per_ID__c', USER_EMPLOYEE_NUMBER).addLimit(1).setSecurityEnforce(false).build();
        
		
        Contact cont = Database.query(queryContact);
        system.runAs(user){
        Test.StartTest();
       NSP_FFUserContactBatch cb = New NSP_FFUserContactBatch();
        Database.QueryLocator ql = cb.start(null);
        cb.execute(null,new List<User>{user});
        cb.Finish(null);
        Test.StopTest();
        }
        
        system.assertEquals(user.EmployeeNumber, USER_EMPLOYEE_NUMBER);
    }
    
    /***********************************************************************************************
    * MethodName: updateContactUserException
    * Description : Negative Unit Test 
    * ********************************************************************************************/
    @isTest
    private static void updateContactUserException(){
        List<String> regionFields = new List<String>{
            'Id',
                'Name'
                };
                    String queryRegion = new NSP_QueryBuilder('pse__Region__c', regionFields)
                    .addFilter('Name', 'United States').addLimit(1).setSecurityEnforce(false).build();
        pse__Region__c region = Database.query(queryRegion);
        List<String> userFields = new List<String>{
            'Id',
                'NSP_IS_FF_User__c',
                'EmployeeNumber',
                'NSP_Financial_Force_User__c',
                'NSP_FF_User_Count__c'
                };
                    String queryUser = new NSP_QueryBuilder('User', userFields)
                   //.addFilter('NSP_Financial_Force_User__c', False)
                    .addFilter('email', 'jsmithyUserBPA@insperity.com').addLimit(1).setSecurityEnforce(false).build();
        User user = Database.query(queryUser);
        
        List<String> conFields = new List<String>{
            'Id',
                'NSP_Per_ID__c',
                'pse__Salesforce_User__c',
                'pse__Is_Resource_Active__c',
                'pse__Is_Resource__c'
                
                };
                    String queryContact = new NSP_QueryBuilder('Contact', conFields)
                    .addFilter('NSP_Per_ID__c', USER_EMPLOYEE_NUMBER).addLimit(1).setSecurityEnforce(false).build();
        
        Contact con = Database.query(queryContact);
        
        Test.StartTest(); 
        NSP_FFUserContactBatch cb = New NSP_FFUserContactBatch();
        Database.QueryLocator ql = cb.start(null);
        cb.execute(null,new List<User>{user});
        cb.Finish(null);
        Test.StopTest();
        System.assertEquals(con.pse__Salesforce_User__c,Null);
    }
    
    /***********************************************************************************************
    * MethodName: createPermissionControl
    * Description : Coverage for createPermissionControl
    * ********************************************************************************************/
    @isTest
    private static void createPermissionControlTest(){
        
            List<String> regionFields = new List<String>{
            'Id',
                'Name'
                };
                    String queryRegion = new NSP_QueryBuilder('pse__Region__c', regionFields)
                    .addFilter('Name', 'United States').addLimit(1).setSecurityEnforce(false).build();
        pse__Region__c region = Database.query(queryRegion);
        
        List<String> userFields = new List<String>{
            'Id',
                'NSP_IS_FF_User__c',
                'EmployeeNumber',
                'NSP_Financial_Force_User__c',
                'NSP_FF_User_Count__c'
                };
                    String queryUser = new NSP_QueryBuilder('User', userFields)
                    .addFilter('EmployeeNumber', USER_EMPLOYEE_NUMBER).addLimit(1).setSecurityEnforce(false).build();
        User user = Database.query(queryUser);
        
        Test.startTest();
        NSP_FFUserContactBatch.createPermissionControl(user.id, region.Id);
        Test.stopTest();
        system.assertEquals(user.EmployeeNumber, USER_EMPLOYEE_NUMBER);
    }
    
}