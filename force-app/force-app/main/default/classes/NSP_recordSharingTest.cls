/**
* @description  :   Test class for NSP_recordSharing .
* @date 02/14/2022
* Author : Nischay Jindal
* Name : NSP_recordSharingTest
*/
@istest
public class NSP_recordSharingTest {
    
    /***********************************************************************************************
    * Variables
    * ********************************************************************************************/
	private static final String emailencodingkey = 'UTF-8';
	private static final String languagekey = 'en_US'; 
	private static final String timezonesidkey = 'America/Los_Angeles';   
    /***********************************************************************************************
    * MethodName: testData
    * Description : Creating test data for NSP_recordSharing
    * ********************************************************************************************/
    @testSetup
    static void testData(){
        List<User> users = new List<User>();
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole BPArole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        UserRole SalesLeaderRole = [SELECT Id FROM UserRole WHERE Name='Sales Leader'];
        User BpaUser = new User(alias = 'jsmit', email='jsmith@acmetestusr.com', 
                                emailencodingkey='UTF-8', lastname='Smith', 
                                languagelocalekey='en_US', 
                                localesidkey='en_US', profileid = profileobj.Id, userroleid = BPArole.Id,
                                timezonesidkey='America/Los_Angeles', NSP_Sales_Office__c='0302 Phoenix 2' ,
                                username='insperitytestadminuser@insperity.com.testUsr');
        users.add(BpaUser);
        User BpaUser2 = new User(alias = 'jBPA', email='jsmithyBPA@acmetest.com', 
                                 emailencodingkey='UTF-8', lastname='Smith', 
                                 languagelocalekey='en_US', 
                                 localesidkey='en_US', profileid = profileobj.Id, userroleid = BPArole.Id,
                                 timezonesidkey='America/Los_Angeles', NSP_Sales_Office__c='0601 Denver 1' ,
                                 username='insperitytestadminuser@insperity.com.testBPA');
        users.add(BpaUser2);
        User SalesLeader = new User(alias = 'johnth', email='johnsmith@acme.com', 
                                    emailencodingkey='UTF-8', lastname='Smith', 
                                    languagelocalekey='en_US', 
                                    localesidkey='en_US', profileid = profileobj.Id, userroleid = SalesLeaderRole.Id,
                                    timezonesidkey='America/Los_Angeles', 
                                    username='insperitytestadminuser@insperity.com.test2');
        
        users.add(SalesLeader);
        User SalesLeader2 = new User(alias = 'jonth', email='johnsmith@acme.com', 
                                     emailencodingkey='UTF-8', lastname='Smit', 
                                     languagelocalekey='en_US', 
                                     localesidkey='en_US', profileid = profileobj.Id, userroleid = SalesLeaderRole.Id,
                                     timezonesidkey='America/Los_Angeles', 
                                     username='insperitytestadminuser@insperity.com.SLeaderTest');
        users.add(SalesLeader2);
        
        User accountTeamUser = new User(alias = 'jhnATM', email='johnsmith@aTM.com', 
                                        emailencodingkey='UTF-8', lastname='Smit', 
                                        languagelocalekey='en_US', 
                                        localesidkey='en_US', profileid = profileobj.Id, userroleid = SalesLeaderRole.Id,
                                        timezonesidkey='America/Los_Angeles',  NSP_Sales_Office__c='0701 Stamford 1',
                                        username='insperitytestadminuser@insperity.com.ATM');
        
        users.add(accountTeamUser);
        User accountTeamGroupUser = new User(alias = 'jhAUser', email='johnsmith@aTMUser.com', 
                                             emailencodingkey='UTF-8', lastname='Smit', 
                                             languagelocalekey='en_US', 
                                             localesidkey='en_US', profileid = profileobj.Id, userroleid = SalesLeaderRole.Id,
                                             timezonesidkey='America/Los_Angeles', 
                                             username='insperitytestadminuser@insperity.com.ATMUser');
        
        users.add(accountTeamGroupUser);
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
        GroupMember nonBpagm = new GroupMember (UserOrGroupId = SalesLeader.Id, GroupId = gp1.Id);
        GroupMember bpaUsergm = new GroupMember (UserOrGroupId = BpaUser2.Id, GroupId = gp2.Id);
        GroupMember Salesleadergm= new GroupMember (UserOrGroupId = SalesLeader2.Id, GroupId = gp2.Id);
        GroupMember AccoutTeamgm= new GroupMember (UserOrGroupId = accountTeamGroupUser.Id, GroupId = gp3.Id);
        List<GroupMember> groupMemberList= new List<GroupMember>{bpagm,nonBpagm,bpaUsergm,Salesleadergm,AccoutTeamgm};
        // Inserting Group Members
        Insert groupMemberList;
        // Inserting account ,opportunity and lead records
        System.runAs (BpaUser) {
            Test.startTest();
            NSP_TestHelper.createLeadRecord(true); 
            Account acc1 = NSP_TestHelper.createAccount(true);
            NSP_TestHelper.createOpenOpportunity(acc1.Id,'New Product',true);
            Test.StopTest();
        }
        
    }
    
    /***********************************************************************************************
    * MethodName: recordShareNonBPAUser
    * Description : Sharing Sales records with non BPA role Users
    * ********************************************************************************************/
    @isTest
    static void recordShareNonBPAUser(){
        try{
            // quering BPA user 
            User BpaUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'jsmith@acmetestusr.com' Limit 1];
            // quering another BPA user for update the record owner 
            User BpaUser2=[Select Id , Name , Email , NSP_Sales_Office__c  from User WHERE Email = 'jsmithyBPA@acmetest.com' Limit 1];
            // quering Account team user user for account team sharing
            User ATMuser=[Select Id , Name , Email , NSP_Sales_Office__c  from User WHERE Email = 'johnsmith@aTM.com' Limit 1];     
            // querying Lead record
            Lead ld=[Select Id , FirstName, OwnerId from Lead WHERE FirstName = 'Insperity' LIMIT 1];
            // querying Account record
            Account acc1 =[Select Id , Name, OwnerId from Account WHERE Name = 'ABCTest Co' LIMIT 1];
            // Inserting Account Team User
            NSP_Account_Team__c acTeam=new NSP_Account_Team__c();
            acTeam.NSP_Role__c=System.Label.NSP_AccountTeamMemberRole;
            acTeam.NSP_User__c=ATMuser.Id;
            acTeam.NSP_Account__c=acc1.Id;
            Insert acTeam;
            // querying opportunity record
            Opportunity opp=[Select Id ,Name, AccountId, OwnerId from Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
            // Updating Owners 
            System.runAs (BpaUser) {
                Test.startTest();
                ld.OwnerId=BpaUser2.Id;
                acc1.OwnerId=BpaUser2.Id;
                opp.OwnerId=BpaUser2.Id;
                update ld;
                update acc1;
                update opp;
                Test.stopTest();
            }
            system.assertEquals(BpaUser2.Id, opp.OwnerId);
        }
        catch(Exception ex){
            ex.getStackTraceString();
        }
    }
    
    /***********************************************************************************************
    * MethodName: updateATMSharing
    * Description : Sharing records with Account Team Users Sales Office Group Users on Update 
    * ********************************************************************************************/
    @isTest
    static void updateATMSharing(){
        try{
            // quering BPA user
            User BpaUser=[Select Id , Name , Email , NSP_Sales_Office__c from User WHERE Email = 'jsmith@acmetestusr.com' Limit 1];
            // quering another BPA user
            User BpaUser2=[Select Id , Name , Email , NSP_Sales_Office__c  from User WHERE Email = 'jsmithyBPA@acmetest.com' Limit 1];
            // quering account team user 
            User ATMuser=[Select Id , Name , Email , NSP_Sales_Office__c  from User WHERE Email = 'johnsmith@aTM.com' Limit 1];     
            
            // quering account record
            Account acc1 = [Select Id , Name, OwnerId from Account WHERE Name = 'ABCTest Co' LIMIT 1];
            // creating account team record
            NSP_Account_Team__c acTeam=new NSP_Account_Team__c();
            acTeam.NSP_Role__c=System.Label.NSP_AccountTeamMemberRole;
            acTeam.NSP_User__c=ATMuser.Id;
            acTeam.NSP_Account__c=acc1.Id;
            insert acTeam;
            // Updating Account Team record 
            System.runAs (BpaUser) {
                Test.startTest();
                acTeam.NSP_User__c=BpaUser2.Id;
                update acTeam;
                Test.stopTest();
            }
            system.assertEquals(BpaUser2.Id, acTeam.NSP_User__c);
        } 
        catch(Exception ex){
            ex.getStackTraceString();
        }
    }
}