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
       NSP_TestHelper.createUser(true);
  }    

  static testMethod void updatePhoneNumberTest(){
    Test.startTest();
    User users = [Select Id, Name,Phone from User WHERE Username =: NSP_TestHelper.DEFAULT_USERNAME LIMIT 1]; //Added WHERE Condition as part of code fix
    users.Phone = '(312)6475261 ext415';
    update users;
    Test.stopTest();
    System.assertEquals(users.Phone, '(312)6475261 ext415');
}

}