//***Test Class for NSP_QuoteTriggerHelper Class***
/**
* @description  : Test Class for NSP_UserTriggerHelper Class
* @author Raksha
* @date 22/02/2022
* Name : NSP_UserTriggerHelper_Test
*/
@IsTest
public with sharing class NSP_UserTriggerHelper_Test {
    public NSP_UserTriggerHelper_Test() {
        
    }
    
    @testSetup
    static void setupTestData(){
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Phone = '(112)6475261 ext415';
        insert tUser;
    } 
    /**
* @Description: This test method is used to cover updatePhoneNumber method
* @Created date: 04/28/2022.
* @return void                           
*/ 
    static testMethod void updatePhoneNumberTest(){
        Test.startTest();
        User users = [Select Id, Name,Phone from User WHERE Username =: NSP_TestHelper.DEFAULT_USERNAME LIMIT 1]; //Added WHERE Condition as part of code fix
        users.Phone = '(112)6475261 ext415';
        update users;
        users.Phone = '(122)6475261 ext415';
        update users;
        users.Phone = '(122)6475261 x415';
        update users;
        Test.stopTest();
        system.assertEquals(users.Phone, '(122)6475261 x415');
    }
    /**
* @Description: This test method is used to cover updatePhoneNumber method
* @Created date: 04/28/2022.
* @return void                           
*/ 
    static testMethod void updatePhoneNumberTest1(){
        Test.startTest();
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Username = 'Test39@user.com';
        tUser.Phone = '(312)6475261 ext415';
        insert tUser;
        Test.stopTest();
        system.assertEquals(tUser.Phone, '(312)6475261 ext415');
    }
    
}