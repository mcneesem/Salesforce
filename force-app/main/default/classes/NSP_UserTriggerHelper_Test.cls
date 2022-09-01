//***Test Class for NSP_QuoteTriggerHelper Class***
/**
* @description  : Test Class for NSP_UserTriggerHelper Class
* @author Raksha
* @date 22/02/2022
* Name : NSP_UserTriggerHelper_Test
*/
@IsTest
public with sharing class NSP_UserTriggerHelper_Test {
    public static final String ACCOUNTTEST1 = 'AccountTest';
    
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
        tUser.Username = 'updatePTest39@user.com';
        tUser.Email = 'updatePTest39@user.com';
        tUser.Phone = '(312)6475261 ext415';
        insert tUser;
        Test.stopTest();
        system.assertEquals(tUser.Phone, '(312)6475261 ext415');
    }
    
    /**
* @Description: This test method is used to cover setSalesOfficeDetails method
* @Created date: 08/20/2022.
* @return void
    */
    @isTest
   static void salesOfficeTest()
   {
       NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
        officeMapping.NSP_Sales_Office__c = '1081';
        officeMapping.NSP_Sales_Division__c = 'Central';
        officeMapping.NSP_Sales_Region__c = 'Central 1';
        officeMapping.NSP_Start_Date__c = system.today()-1;
        officeMapping.NSP_End_Date__c = system.today()+100;
        insert officeMapping;
       
       NSP_Sales_Office_Mapping__c office1Mapping = new NSP_Sales_Office_Mapping__c();
        office1Mapping.NSP_Sales_Office__c = '301';
        office1Mapping.NSP_Sales_Division__c = 'Central';
        office1Mapping.NSP_Sales_Region__c = 'Central 1';
        office1Mapping.NSP_Start_Date__c = system.today()-1;
        office1Mapping.NSP_End_Date__c = system.today()+200;
        insert office1Mapping;
       
        Test.startTest();
        User tUser =  NSP_TestHelper.createUser(false);
        tUser.Username = 'Testsalesoffic@user.com';
        tUser.Email = 'Test1239@user.com';
        tUser.Phone = '(313)6475261 ext415';
        tUser.NSP_Sales_Office__c = '301';
        insert tUser;
        
        Account accoutObject = new Account();
            Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
            accoutObject.Name = ACCOUNTTEST1;
            accoutObject.recordTypeId=partnerRecordTypeId;
            accoutObject.DNBoptimizer__DNB_D_U_N_S_Number__c = '876543987';
            accoutObject.OwnerId = tUser.Id;
            insert accoutObject;
            
        tUser.NSP_Sales_Office__c = '1081';
        Update tUser;
        Test.stopTest();
   }
    
    
}