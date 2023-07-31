/**
Apex Class Name      :  NSP_AssignFSLPermissionsBatchTest
Version              :  1.0                                                                          
Created Date         :  2/15/2023  
Author               :  Dhawal Saiya
Function             :  This is test class for NSP_AssignFSLPermissionsBatchTest
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Dhawal Saiya               2/15/2023              First Iteration
*/
@isTest
public with sharing class NSP_AssignFSLPermissionsBatchTest {
    @TestSetup
    static void makeData(){
        String orgId = UserInfo.getOrganizationId();
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id;
        User usr = (User) NSP_TestDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        User usr1 = (User) NSP_TestDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        usr1.userName = 'testemail@domain'+ orgId +'.com.test';
        INSERT usr1;
        System.runAs (usr1) {
            usr.ProfileId = profileId;
            usr.NSP_IsFSLPermissionAssigned__c = false;
            usr.NSP_Salesforce_Field_Service__c = 'Dispatcher';
            UPDATE usr;
        }
    }

    /**
    * @Description: This test method is used to cover batch execute method
    * @Created date: 02/15/2023. 
    * @return void             
    */
    @isTest
    static void processUserPermissionsTest() {
        User getUser = [SELECT Id, NSP_IsFSLPermissionAssigned__c, Name FROM User WHERE Id != null LIMIT 1];
        Boolean isFlase = false;
        Test.startTest();
        Database.executeBatch(new NSP_AssignFSLPermissionsBatch());
        Test.stopTest();
        system.assertEquals(isFlase, getUser.NSP_IsFSLPermissionAssigned__c);
    }

}