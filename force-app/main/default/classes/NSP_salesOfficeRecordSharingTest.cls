@isTest
private class NSP_salesOfficeRecordSharingTest {

    private static final String emailencodingkey = 'UTF-8';
    private static final String languagekey = 'en_US';
    private static final String timezonesidkey = 'America/Los_Angeles';
    private static LeadConversionSettings__c settings = LeadConversionSettings__c.getOrgDefaults();

    @testSetup
    private static void testData() {
        List<User> users = new List<User>();
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole BPArole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        UserRole SalesLeaderRole = [SELECT Id FROM UserRole WHERE Name='Sales Leader'];
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        System.runAs(thisUser){
            settings = settings == null ? LeadConversionSettings__c.getOrgDefaults() : settings;
            settings.Is_Enabled_SOQL_Fix__c = true;
            upsert settings;
        }
        // Adding BPA User
        User BpaUser = new User(alias = 'jsmit', email='BPAUSER@insperity.com',
                                emailencodingkey=emailencodingkey, lastname='Smith',
                                languagelocalekey=languagekey,
                                localesidkey=languagekey, profileid = profileobj.Id, userroleid = BPArole.Id,
                                timezonesidkey=timezonesidkey, NSP_Sales_Office_Membership__c='302' ,
                                username='insperitytestadminuser@insperity.com.testUsr');
        users.add(BpaUser);
        // Adding second BPA User
        User BpaUser2 = new User(alias = 'jBPA', email='BPAUSER2@insperity.com',
                                 emailencodingkey=emailencodingkey, lastname='Smith',
                                 languagelocalekey=languagekey,
                                 localesidkey=languagekey, profileid = profileobj.Id, userroleid = BPArole.Id,
                                 timezonesidkey=timezonesidkey, NSP_Sales_Office_Membership__c='601' ,
                                 username='insperitytestadminuser@insperity.com.testBPA');
        users.add(BpaUser2);
        // Adding Account Team User
        User accountTeamUser = new User(alias = 'jhnATM', email='AccounTeaMUser@insperity.com',
                                        emailencodingkey=emailencodingkey, lastname='Smit',
                                        languagelocalekey=languagekey,
                                        localesidkey=languagekey, profileid = profileobj.Id, userroleid = SalesLeaderRole.Id,
                                        timezonesidkey=timezonesidkey,  NSP_Sales_Office_Membership__c='701',
                                        username='insperitytestadminuser@insperity.com.ATM');

        users.add(accountTeamUser);

        // Inserting Users
        insert users;

        // Creating Groups
        Group gp1= new Group();
        gp1.Name='0302 Phoenix 2';
        Group gp2= new Group();
        gp2.Name='0601 Denver 1';
        Group gp3= new Group();
        gp3.Name='0701 Stamford 1';
        // Inserting groups
        List<Group> groups= new List<Group>{gp1, gp2, gp3};
        Insert groups;
        // adding Users to groups
        GroupMember bpagm = new GroupMember (UserOrGroupId = BpaUser.Id, GroupId = gp1.Id);
        GroupMember bpaUsergm = new GroupMember (UserOrGroupId = BpaUser2.Id, GroupId = gp2.Id);
        GroupMember AccoutTeamgm= new GroupMember (UserOrGroupId = accountTeamUser.Id, GroupId = gp3.Id);
        List<GroupMember> groupMemberList= new List<GroupMember>{bpagm,bpaUsergm,AccoutTeamgm};
        // Inserting Group Members
        Insert groupMemberList;
        // Inserting account ,opportunity and lead records
        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) { // prevent System.DmlException MIXED_DML_OPERATION
            Test.startTest();
            Lead ld=NSP_TestHelper.createLeadRecord(true);
            Account acc1 = NSP_TestHelper.createAccount(true);
            Opportunity opp= NSP_TestHelper.createOpenOpportunity(acc1.Id,'New Product',true);
            NSP_Account_Team__c acTeam=new NSP_Account_Team__c();
            acTeam.NSP_Role__c=System.Label.NSP_AccountTeamMemberRole;
            acTeam.NSP_User__c=accountTeamUser.Id;
            acTeam.NSP_Account__c=acc1.Id;
            insert acTeam;
            Test.StopTest();
        }
    }

    @isTest
    private static void recordShareNonBPAUser() {
        // quering BPA user
        User BpaUser=[Select Id , Name ,UserRole.Name, Email , toLabel(NSP_Sales_Office_Membership__c) from User WHERE Email = 'BPAUSER@insperity.com' Limit 1];
        // quering another BPA user for update the record owner
        User BpaUser2=[Select Id , Name ,UserRole.Name, Email , toLabel(NSP_Sales_Office_Membership__c)  from User WHERE Email = 'BPAUSER2@insperity.com' Limit 1];
        // quering Account team user user for account team sharing
        User ATMuser=[Select Id , Name , UserRole.Name,Email , NSP_Sales_Office_Membership__c  from User WHERE Email = 'AccounTeaMUser@insperity.com' Limit 1];
        Account acc1 = [Select Id , Name ,OwnerId,Owner.UserRole.Name,toLabel(Owner.NSP_Sales_Office_Membership__c) FROM Account WHERE Name ='ABCTest Co' ];
        // querying Lead record
        Lead ld=[Select Id , FirstName, OwnerId from Lead WHERE FirstName = 'Insperity' LIMIT 1];
        // querying Opportunity record
        Opportunity opp=[Select Id ,Name, StageName,AccountId, OwnerId,Owner.UserRole.Name,toLabel(Owner.NSP_Sales_Office_Membership__c) from Opportunity WHERE AccountId =: acc1.Id LIMIT 1];
        Test.startTest();
        acc1.OwnerId=BpaUser2.Id;
        update acc1;
        ld.OwnerId=  BpaUser2.Id;
        update ld;
        opp.OwnerId=BpaUser2.Id;
        update opp;
        Test.stopTest();
        System.assertEquals( opp.OwnerId,BpaUser2.Id);
    }


    @isTest
    private static void removingATMSharing() {
        // quering account record
        Account acc1 = [Select Id , Name,toLabel(Owner.NSP_Sales_Office_Membership__c), OwnerId from Account WHERE Name = 'ABCTest Co' LIMIT 1];
            NSP_Account_Team__c ATM =[Select Id ,NSP_Account__c,NSP_User__c,toLabel(NSP_User__r.NSP_Sales_Office_Membership__c)
                                    from NSP_Account_Team__c WHERE  NSP_Account__c =:acc1.Id LIMIT 1 ];
        Test.startTest();
        delete ATM;
        Test.stopTest();
        List<NSP_Account_Team__c> ATMUserList =[Select Id ,NSP_Account__c from NSP_Account_Team__c WHERE  NSP_Account__c =:acc1.Id ];
        System.assertEquals(0, ATMUserList.size());
    }

    @isTest
    private static void userSalesOfficeUpdateOld() {
        User thisUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        System.runAs( thisUser ) {
            settings.Is_Enabled_SOQL_Fix__c = false;
            upsert settings;
        }
        // quering BPA user
        User bpaUser = [
            SELECT Id , Name , UserRole.Name , Email , NSP_Sales_Office_Membership__c
            FROM User
            WHERE Email = 'BPAUSER@insperity.com'
            LIMIT 1
        ];
        bpaUser.NSP_Sales_Office_Membership__c = '503';
        Test.startTest();
        update bpaUser;
        Test.stopTest();
        System.assertEquals( '503' , bpaUser.NSP_Sales_Office_Membership__c );
    }

    @isTest
    private static void userSalesOfficeUpdateNew() {
        // quering BPA user
        User BpaUser=[Select Id , Name ,UserRole.Name, Email , NSP_Sales_Office_Membership__c from User WHERE Email = 'BPAUSER@insperity.com' Limit 1];
        BpaUser.NSP_Sales_Office_Membership__c='503';
        Test.startTest();
        update BpaUser;
        Test.stopTest();
        System.assertEquals('503',BpaUser.NSP_Sales_Office_Membership__c );
    }

    @isTest
    private static void opportunityOwnerUpdate() {
        User BpaUser=[Select Id , Name ,UserRole.Name, Email , NSP_Sales_Office_Membership__c from User WHERE Email = 'BPAUSER@insperity.com' Limit 1];
        Account acc1 = [Select Id , Name ,OwnerId,Owner.UserRole.Name,toLabel(Owner.NSP_Sales_Office_Membership__c) FROM Account WHERE Name ='ABCTest Co' ];
        Opportunity opp=[Select Id ,Name, StageName,AccountId, OwnerId,Owner.UserRole.Name,toLabel(Owner.NSP_Sales_Office_Membership__c) from Opportunity WHERE AccountId =: acc1.Id LIMIT 1];
        Map<String,Set<String>> mapNewSalesOfficeSetUserId = new Map<String,Set<String>>();
        Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
        Set<Id> ownerIdSet = new Set<Id>();
        ownerIdSet.add(BpaUser.Id);
        mapNewSalesOfficeSetUserId.put('0601 Denver 1', new Set<String>());
        mapNewSalesOfficeSetUserId.get('0601 Denver 1').add(BpaUser.Id);
        mapUserIdSetOldSalesOffice.put(BpaUser.Id, new Set<String>());
        mapUserIdSetOldSalesOffice.get(BpaUser.Id).add('0302 Phoenix 2');
        Group salesOfficeGroups= [SELECT Id, Name FROM Group WHERE Name IN:mapNewSalesOfficeSetUserId.Keyset() Limit 1];
        Test.startTest();
        System.enqueueJob( new NSP_userOpportunitySalesOfficeSharing( mapNewSalesOfficeSetUserId,mapUserIdSetOldSalesOffice,ownerIdSet ) );
        Test.stopTest();
    }

    @isTest
    private static void leadOwnerUpdate() {
        User BpaUser=[Select Id , Name ,UserRole.Name, Email , NSP_Sales_Office_Membership__c from User WHERE Email = 'BPAUSER@insperity.com' Limit 1];
        Lead ld=[Select Id , FirstName, OwnerId from Lead WHERE FirstName = 'Insperity' LIMIT 1];
        Map<String,Set<String>> mapNewSalesOfficeSetUserId = new Map<String,Set<String>>();
        Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
        Set<Id> ownerIdSet = new Set<Id>();
        ownerIdSet.add(BpaUser.Id);
        mapNewSalesOfficeSetUserId.put('0601 Denver 1', new Set<String>());
        mapNewSalesOfficeSetUserId.get('0601 Denver 1').add(BpaUser.Id);
        mapUserIdSetOldSalesOffice.put(BpaUser.Id, new Set<String>());
        mapUserIdSetOldSalesOffice.get(BpaUser.Id).add('0302 Phoenix 2');
        Group salesOfficeGroups= [SELECT Id, Name FROM Group WHERE Name IN:mapNewSalesOfficeSetUserId.Keyset() Limit 1];
        Test.startTest();
        System.enqueueJob( new NSP_userLeadSalesOfficeSharing( mapNewSalesOfficeSetUserId,mapUserIdSetOldSalesOffice,ownerIdSet ) );
        Test.stopTest();
    }

    @isTest
    private static void atmOwnerUpdate() {
        User ATMUser=[Select Id , Name ,UserRole.Name, Email , NSP_Sales_Office_Membership__c from User WHERE Email = 'AccounTeaMUser@insperity.com' Limit 1];
        Account acc1 = [Select Id , Name,toLabel(Owner.NSP_Sales_Office_Membership__c), OwnerId from Account WHERE Name = 'ABCTest Co' LIMIT 1];
        NSP_Account_Team__c ATM =[Select Id ,NSP_Role__c,NSP_Account__c,NSP_User__c,toLabel(NSP_User__r.NSP_Sales_Office_Membership__c)
                                      from NSP_Account_Team__c WHERE  NSP_Account__c =:acc1.Id LIMIT 1 ];

        Map<String,Set<String>> mapNewSalesOfficeSetUserId = new Map<String,Set<String>>();
        Map<String,Set<String>> mapUserIdSetOldSalesOffice = new Map<String,Set<String>>();
        Set<Id> ownerIdSet = new Set<Id>();
        ownerIdSet.add(ATMUser.Id);
        mapNewSalesOfficeSetUserId.put('0601 Denver 1', new Set<String>());
        mapNewSalesOfficeSetUserId.get('0601 Denver 1').add(ATMUser.Id);
        mapUserIdSetOldSalesOffice.put(ATMUser.Id, new Set<String>());
        mapUserIdSetOldSalesOffice.get(ATMUser.Id).add('0302 Phoenix 2');
        Group salesOfficeGroups= [SELECT Id, Name FROM Group WHERE Name IN:mapNewSalesOfficeSetUserId.Keyset() Limit 1];
        Test.startTest();
        System.enqueueJob( new NSP_userAccountTeamSalesOfficeSharing( mapNewSalesOfficeSetUserId,mapUserIdSetOldSalesOffice,ownerIdSet ) );
        Test.stopTest();
        System.assertEquals(ATMUser.Id,ATM.NSP_User__c);
        NSP_userAccountTeamSalesOfficeSharing.testHandleException( null , null );
    }

}
//
