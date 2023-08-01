/**
Apex Class Name      :  NSP_AssignFSLUserPermissionsTest
Version              :  1.0                                                                          
Created Date         :  2/15/2023  
Author               :  Dhawal Saiya
Function             :  This is test class for NSP_AssignFSLUserPermissions   
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Dhawal Saiya               2/15/2023              First Iteration
*/

@isTest
public with sharing class NSP_AssignFSLUserPermissionsTest {
    @testSetup
    static void setupTestData(){
        User usr = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', true);
        User adminUser = (User)NSP_TestDataFactory.createSObject(new User(),'NSP_TestDataFactory.UserDefaults', false);
        adminUser.userName = 'someuniquemail@test.com';
        insert adminUser;
        
    }

    /**
    * @Description: This test method is used to cover processUserPermissions method
    * @Created date: 02/15/2023. 
    * @return void             
    */
    @isTest
    static void processUserPermissionsTest() {
        Test.startTest();
        User usr = [SELECT Id, NSP_Salesforce_Field_service__c, NSP_Service_Region__c  FROM User WHERE Id != null LIMIT 1];
        usr.NSP_Salesforce_Field_service__c = 'Resource';
        usr.NSP_Dispatch_Region__c = 'Central';
        System.enqueueJob(new NSP_AssignFSLUserPermissions(new List<User>{usr}, true));
        Test.stopTest();

        Set<String> setPermissionSetName = new Set<String>();
        for(PermissionSetAssignment psa : [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :usr.Id]){
            setPermissionSetName.add(psa.PermissionSet.Name);
        }
        
        system.assertNotEquals(setPermissionSetName, null);
        //system.assert(setPermissionSetName.contains('FSL_Resource_License'));
        

    }

    /**
    * @Description: This test method is used to cover negative scenario for processUserPermissions method
    * @Created date: 02/15/2023. 
    * @return void             
    */
    @isTest
    static void processUserPermissionsNegativeTest() {
        Test.startTest();
        User usr = [SELECT Id, NSP_Salesforce_Field_service__c FROM User WHERE username = 'someuniquemail@test.com' LIMIT 1];
        System.enqueueJob(new NSP_AssignFSLUserPermissions(new List<User>{usr}, true));
        Test.stopTest();

        Set<String> setPermissionSetName = new Set<String>();
        for(PermissionSetAssignment psa : [SELECT Id, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :usr.Id]){
            setPermissionSetName.add(psa.PermissionSet.Name);
        }
        
        system.assertNotEquals(setPermissionSetName, null);
        system.assert(!setPermissionSetName.contains('FSL_Resource_License'));
        system.assert(!setPermissionSetName.contains('EinsteinActivityCaptureIncluded'));
        system.assert(!setPermissionSetName.contains('FSL_Resource_Permissions_Read_Only'));

    }
}