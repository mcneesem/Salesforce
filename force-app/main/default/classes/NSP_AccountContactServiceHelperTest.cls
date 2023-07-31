/**
* @description  : Test Class for NSP_AccountContactServiceHelper .
* @date 11/11/2022
* Author : Nischay Jindal
* Name : NSP_AccountContactServiceHelperTest
*/
@isTest
private class NSP_AccountContactServiceHelperTest {
    /***********************************************************************************************
    * MethodName: testData
    * Description : Test Data Method
    * Author :      Nischay Jindal
    * ********************************************************************************************/   
    private static final String EN_US = 'en_US';
    @testsetup 
     private static void testData() {
        Test.startTest();
        List<User> users = new List<User>();
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole userRole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        User user = new User(alias = 'jsmi', email='jsmith@insperity.com', 
                             emailencodingkey='UTF-8', lastname='Smih', 
                             languagelocalekey= EN_US, 
                             localesidkey= EN_US, profileid = profileobj.Id, userroleid = userRole.Id,
                             timezonesidkey= 'America/Los_Angeles' ,
                             username='insperityadminuser@insperity.com.testUs');
        users.add(user);
        User BpaUser = new User(alias = 'jBPA', email='jsmithyUserBPA@insperity.com', 
                                emailencodingkey='UTF-8', lastname='Smith', 
                                languagelocalekey= EN_US, 
                                localesidkey= EN_US, profileid = profileobj.Id,
                                timezonesidkey='America/Los_Angeles' ,
                                username='insperitytestadminuser@insperity.com.testBPA');
        users.add(BpaUser);
        insert users;
        System.runAs (user) {
            //Insert Test Account record
            Account acc1 = NSP_TestHelper.createAccount(true);
            //NSP_TestHelper.createContact(acc1.id, true); 
            Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            newContact.AccountId = acc1.Id;
            newContact.NSP_Work_email__c='test@pwc.com';
            insert newContact;
        }
        Test.stopTest();
    }

    /***********************************************************************************************
    * MethodName: createExternalUserTest
    * Description : unit test for creating External User
    * Author :      Nischay Jindal
    * ********************************************************************************************/ 
    @isTest
    static void createExternalUserTest() {
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        User user=[Select Id , Name , Email  from User WHERE Email = 'jsmith@insperity.com' Limit 1];
        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM 
                                          AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
        
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        // Start Test
        System.runAs (user) {
            Test.startTest();
            update acrObj; 
            Test.stopTest();
        }
        User portalUser = [SELECT Id , ContactId FROM User WHERE ContactId = :acrObj.ContactId ];
        System.assertEquals(portalUser.ContactId, acrObj.ContactId );  
    }

    /***********************************************************************************************
    * MethodName: removeExternalUserPermTest
    * Description : unit test for removing perm from External User
    * Author :      Nischay Jindal
    * ********************************************************************************************/     
    @isTest
    static void removeExternalUserPermTest() {
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        User user=[Select Id , Name , Email  from User WHERE Email = 'jsmith@insperity.com' Limit 1];
        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM 
                                          AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
        
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        update acrObj;
        
        acrObj.NSP_Community_Access__c =null;
        // Start Test
        System.runAs (user) {
            Test.startTest(); 
            update acrObj;
            Test.stopTest();
        }
        
        User portalUser = [SELECT Id , ContactId FROM User WHERE ContactId = :acrObj.ContactId ];
        List<PermissionSetAssignment> psa = [SELECT Id ,AssigneeId ,PermissionSetId FROM PermissionSetAssignment 
                                             WHERE AssigneeId =:portalUser.Id AND PermissionSet.Name =:NSP_ServiceConstants.projectCommunityPerm ];
        System.assertEquals(psa.size(), 0 );  
    }

    /***********************************************************************************************
    * MethodName: deactivateExternalUserPermTest
    * Description : unit test for deactivating External User
    * Author :      Nischay Jindal
    * ********************************************************************************************/        
    @isTest
    static void deactivateExternalUserPermTest() {
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        User user=[Select Id , Name , Email  from User WHERE Email = 'jsmith@insperity.com' Limit 1];
        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM 
                                          AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
        
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        update acrObj;
        
        acrObj.NSP_Community_Access__c = null;
        // Start Test
        System.runAs (user) {
            Test.startTest(); 
            update acrObj;
            Test.stopTest();
        }
        
        User portalUser = [SELECT Id , ContactId, IsActive FROM User WHERE ContactId = :acrObj.ContactId ];
        System.assertEquals(portalUser.IsActive, False );  
    }
    
    /***********************************************************************************************
    * MethodName: createExternalUserTestException
    * Description : negative unit test for creating External User
    * Author :      Nischay Jindal
    * ********************************************************************************************/      
    @isTest
    static void createExternalUserTestException() {
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        User user=[Select Id , Name , Email from User WHERE Email = 'jsmithyUserBPA@insperity.com' Limit 1];
        Account acc = [Select Id , OwnerId From Account WHERE Name != null LIMIT 1];
        acc.ownerId = user.Id;
        update acc;
        
        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM 
                                          AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        // Start Test
        System.runAs (user) {
            Test.startTest();
            update acrObj; 
            Test.stopTest();
        }
        List<User> portalUser = [SELECT Id , ContactId FROM User WHERE ContactId = :acrObj.ContactId ];
        System.assertEquals(portalUser.size(), 0 );
    }
    
}