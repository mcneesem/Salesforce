@isTest
private class NSP_AccountContactServiceHelperTest {
    private static final String EN_US = 'en_US';

    @testSetup
    private static void testData() {
        Test.startTest();
        List<User> runners = new List<User>();
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole userRole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        User runner = new User(alias = 'jsmi', email='jsmith@insperity.com',
                             emailencodingkey='UTF-8', lastname='Smih',
                             languagelocalekey= EN_US,
                             localesidkey= EN_US, profileid = profileobj.Id, userroleid = userRole.Id,
                             timezonesidkey= 'America/Los_Angeles' ,
                             username='insperityadminuser@insperity.com.testUs');
        runners.add( runner );
        User BpaUser = new User(alias = 'jBPA', email='jsmithyUserBPA@insperity.com',
                                emailencodingkey='UTF-8', lastname='Smith',
                                languagelocalekey= EN_US,
                                localesidkey= EN_US, profileid = profileobj.Id,
                                timezonesidkey='America/Los_Angeles' ,
                                username='insperitytestadminuser@insperity.com.testBPA');
        runners.add( BpaUser );
        insert runners;
        System.runAs ( runner ) {
            //Insert Test Account record
            Account acc1 = NSP_TestHelper.createAccount(true);
            //NSP_TestHelper.createContact(acc1.id, true);
            Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            newContact.AccountId = acc1.Id;
            newContact.NSP_Work_email__c='test@pwc.com';
            insert newContact;
        }
        System.runAs ( runner ) {
            insert new pse__Region__c( Name='United States' );
        }
        Test.stopTest();
    }

    @isTest
    private static void testCodeCoverage1() {
        Map<Id,AccountContactRelation> newACRMap = new Map<Id,AccountContactRelation>(
            [
                SELECT Id , ContactId , NSP_Community_Access__c
                FROM AccountContactRelation
            ]
        );
        List<User> portalUsers = new List<User>();
        Map<Id,AccountContactRelation> oldACRMap = new Map<Id,AccountContactRelation>();
        for ( AccountContactRelation newACR : newACRMap.values() ) {
            newACR.NSP_Community_Access__c='PEO Projects';
            oldACRMap.put(
                newACR.Id ,
                new AccountContactRelation(
                    Id=newACR.Id ,
                    ContactId=newACR.ContactId ,
                    NSP_Community_Access__c=null
                )
            );
            portalUsers.add(
                new User(
                    UserName=UserInfo.getUsername() + '.portal' ,
                    FirstName='sharedFirstName' ,
                    LastName='sharedLastName' ,
                    Alias='alias' ,
                    CommunityNickname='communityNickname' ,
                    Email=UserInfo.getUserEmail() + '.portal' ,
                    ContactId=newACR.ContactId ,
                    ProfileId='00e4x0000013MV2AAM' , // Customer Community Plus User
                    EmailEncodingKey='UTF-8' ,
                    TimeZoneSidKey='America/Los_Angeles' ,
                    LocaleSidKey='en_US' ,
                    LanguageLocaleKey='en_US'
                )
            );
        }
        List<User> runners = [ SELECT Id FROM User WHERE ( Email = 'jsmith@insperity.com' ) LIMIT 1 ];
        User runner = runners[0];
        System.runAs ( runner ) {
            update newACRMap.values();
        }
        System.runAs ( runner ) {
            insert portalUsers;
        }
        //
        Test.startTest();
        NSP_AccountContactServiceHelper.createExternalUser( newACRMap , oldACRMap );
        Test.stopTest();
    }

    @isTest
    private static void testCodeCoverage2() {
        Map<Id,AccountContactRelation> newACRMap = new Map<Id,AccountContactRelation>(
            [
                SELECT Id , ContactId , NSP_Community_Access__c
                FROM AccountContactRelation
            ]
        );
        List<User> portalUsers = new List<User>();
        Map<Id,AccountContactRelation> oldACRMap = new Map<Id,AccountContactRelation>();
        for ( AccountContactRelation newACR : newACRMap.values() ) {
            newACR.NSP_Community_Access__c=null;
            oldACRMap.put(
                newACR.Id ,
                new AccountContactRelation(
                    Id=newACR.Id ,
                    ContactId=newACR.ContactId ,
                    NSP_Community_Access__c='PEO Projects'
                )
            );
            portalUsers.add(
                new User(
                    UserName=UserInfo.getUsername() + '.portal' ,
                    FirstName='sharedFirstName' ,
                    LastName='sharedLastName' ,
                    Alias='alias' ,
                    CommunityNickname='communityNickname' ,
                    Email=UserInfo.getUserEmail() + '.portal' ,
                    ContactId=newACR.ContactId ,
                    ProfileId='00e4x0000013MV2AAM' , // Customer Community Plus User
                    EmailEncodingKey='UTF-8' ,
                    TimeZoneSidKey='America/Los_Angeles' ,
                    LocaleSidKey='en_US' ,
                    LanguageLocaleKey='en_US'
                )
            );
        }
        List<User> runners = [ SELECT Id FROM User WHERE ( Email = 'jsmith@insperity.com' ) LIMIT 1 ];
        User runner = runners[0];
        System.runAs ( runner ) {
            update newACRMap.values();
        }
        System.runAs ( runner ) {
            insert portalUsers;
        }
        Test.startTest();
        NSP_AccountContactServiceHelper.createExternalUser( newACRMap , oldACRMap );
        Test.stopTest();
    }

    @isTest
    private static void testCodeCoverage3() {
        Map<Id,AccountContactRelation> newACRMap = new Map<Id,AccountContactRelation>(
            [
                SELECT Id , ContactId , NSP_Community_Access__c
                FROM AccountContactRelation
            ]
        );
        List<User> portalUsers = new List<User>();
        Map<Id,AccountContactRelation> oldACRMap = new Map<Id,AccountContactRelation>();
        for ( AccountContactRelation newACR : newACRMap.values() ) {
            newACR.NSP_Community_Access__c='PEO Projects';
            oldACRMap.put(
                newACR.Id ,
                new AccountContactRelation(
                    Id=newACR.Id ,
                    ContactId=newACR.ContactId ,
                    NSP_Community_Access__c=null
                )
            );
        }
        List<User> runners = [ SELECT Id FROM User WHERE ( Email = 'jsmith@insperity.com' ) LIMIT 1 ];
        User runner = runners[0];
        System.runAs ( runner ) {
            update newACRMap.values();
        }
        //
        Test.startTest();
        NSP_AccountContactServiceHelper.createExternalUser( newACRMap , oldACRMap );
        Test.stopTest();
    }

    @isTest
    private static void testCodeCoverage4() {
        Map<Id,AccountContactRelation> newACRMap = new Map<Id,AccountContactRelation>(
            [
                SELECT Id , ContactId , NSP_Community_Access__c
                FROM AccountContactRelation
            ]
        );
        List<User> portalUsers = new List<User>();
        Map<Id,AccountContactRelation> oldACRMap = new Map<Id,AccountContactRelation>();
        for ( AccountContactRelation newACR : newACRMap.values() ) {
            newACR.NSP_Community_Access__c=null;
            oldACRMap.put(
                newACR.Id ,
                new AccountContactRelation(
                    Id=newACR.Id ,
                    ContactId=newACR.ContactId ,
                    NSP_Community_Access__c='PEO Projects'
                )
            );
        }
        List<User> runners = [ SELECT Id FROM User WHERE ( Email = 'jsmith@insperity.com' ) LIMIT 1 ];
        User runner = runners[0];
        System.runAs ( runner ) {
            update newACRMap.values();
        }
        //
        Test.startTest();
        NSP_AccountContactServiceHelper.createExternalUser( newACRMap , oldACRMap );
        Test.stopTest();
    }

    @isTest
    private static void createExternalUserTest() {
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
    }

    @isTest
    private static void removeExternalUserPermTest() {
        Set<String> permissionSetNameSet = new Set<String>();
        Set<Id> permissionIdSet = new Set<Id>();
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        User portalUser = new User ();
        // fetching all the permission set from the metadata
        Map<String, NSP_Assign_permission_set_to_Community__mdt> assignPermSetMap = NSP_Assign_permission_set_to_Community__mdt.getAll();
        for(NSP_Assign_permission_set_to_Community__mdt permSet:assignPermSetMap.values() ){
            if(permSet.NSP_Permission_Set_Name__c!=null){
                permissionSetNameSet.add(permSet.NSP_Permission_Set_Name__c);
            }
        }
        // creating set of Permission Set Id required to be assigned to Comm User
        for(PermissionSet permSet:[SELECT Id FROM PermissionSet WHERE Name IN:permissionSetNameSet ] ){
            permissionIdSet.add(permSet.Id);
        }
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
            test.startTest();
            update acrObj;
            NSP_AccountContactServiceHelper.removeUserPermissions(new Set<Id>{portalUser.Id},permissionIdSet);
            test.stopTest();
        }
        for(PermissionSetAssignment psa:[SELECT Id ,AssigneeId ,PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =:portalUser.Id]){
            if(permissionIdSet.contains(psa.PermissionSetId)){
                psaList.add(psa);
            }
        }
        System.assertEquals(psaList.size(), 0 );
    }

    @isTest
    private static void deactivateExternalUserPermTest() {
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
    }

    @isTest
    private static void createExternalUserTestException() {
        List<User> portalUser = new  List<User>();
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
        try{
            System.runAs (user) {
                Test.startTest();
                update acrObj;
                Test.stopTest();
            }
            portalUser = [SELECT Id , ContactId FROM User WHERE ContactId = :acrObj.ContactId];
            System.assertEquals(portalUser.size(), 0 );
        }catch(Exception ex){
            Boolean isExpectedExceptionThrown =  ex.getMessage().contains('System.DmlException: Insert failed') ? true : false;
            System.assertEquals(isExpectedExceptionThrown, true);
        }
    }

}
//