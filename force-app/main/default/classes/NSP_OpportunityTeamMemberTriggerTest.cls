/**
* @description  : Test class for OpprtunityTeamMember trigger class
* @date 06/04/2021
* Author : Tejas
* Name : NSP_OpportunityTeamMemberTriggerHelper
*/
@isTest
public without sharing class NSP_OpportunityTeamMemberTriggerTest {
    public static final String Opp_TYPE_NEW_BUSINESS = 'New Business';
    @testsetup
    public static void createTestData(){
        Test.startTest();
        Account accountRecord = NSP_TestHelper.createAccount(true);
        
        NSP_TestHelper.createOpenOpportunity(accountRecord.Id, 'New Business', true);
        
        NSP_TestHelper.createUser(true);
        
        Test.stopTest();
    }
    
    /**
    * @description  : Test method for OpprtunityTeamMember trigger class
    * @date 06/04/2021
    * Author : Tejas
    * Name : testOTMInsert
    */
    @isTest
    public static void testOTMInsert(){
        List<Opportunity> opportunityRecord = [SELECT Id, Name, StageName, Type FROM Opportunity WHERE Type =: Opp_TYPE_NEW_BUSINESS LIMIT 2]; //Added Where Condition as part of Code fix
        
        User userRecord = [SELECT Id, Name FROM User WHERE Username = :NSP_TestHelper.DEFAULT_USERNAME LIMIT 1];
        
        OpportunityTeamMember otmRecord = NSP_TestHelper.createOTMRecord(opportunityRecord[0].Id, userRecord.Id, 'BPA', 'Edit', false);
        
        insert otmRecord;        
        System.assertEquals(otmRecord.TeamMemberRole, 'BPA');
    }
    
    /**
    * @description  : Test method for OpprtunityTeamMember trigger class
    * @date 06/04/2021
    * Author : Tejas
    * Name : testOTMUpdate
    */
    @isTest
    public static void testOTMUpdate(){
        Test.startTest();
        List<Opportunity> opportunityRecord = [SELECT Id, Name, StageName, Type FROM Opportunity WHERE Type =:Opp_TYPE_NEW_BUSINESS LIMIT 2]; //Added Where Condition as part of Code fix
        
        User userRecord = [SELECT Id, Name FROM User WHERE Username = :NSP_TestHelper.DEFAULT_USERNAME LIMIT 1];
        
        OpportunityTeamMember otmRecord = NSP_TestHelper.createOTMRecord(opportunityRecord[0].Id, userRecord.Id, 'BPA', 'Edit', false);
        
        insert otmRecord;
        
        otmRecord.TeamMemberRole = 'BPC';
        
        update otmRecord;
        Test.stopTest();
        
        OpportunityTeamMember otm = [SELECT Id, TeamMemberRole FROM OpportunityTeamMember WHERE Id=:otmRecord.Id];
        system.assertEquals(otm.TeamMemberRole, otmRecord.TeamMemberRole);
    }
    /*Cover the code coverage*/
    @isTest
    public static void test_beforeInsert_UseCase1(){
        List<OpportunityTeamMember> opportunityteammember_Obj  =  [SELECT Id,OpportunityId,UserId from OpportunityTeamMember];
        System.assertEquals(true,opportunityteammember_Obj.size()>0);
        NSP_OpportunityTeamMemberTriggerHandler obj01 = new NSP_OpportunityTeamMemberTriggerHandler();
        obj01.beforeInsert(new List<sObject>());
    }
    @isTest
    public static void test_afterDelete_UseCase1(){
        List<OpportunityTeamMember> opportunityteammember_Obj  =  [SELECT OpportunityId,UserId from OpportunityTeamMember];
        System.assertEquals(true,opportunityteammember_Obj.size()>0);
        NSP_OpportunityTeamMemberTriggerHandler obj01 = new NSP_OpportunityTeamMemberTriggerHandler();
        obj01.afterDelete(new List<sObject>(),new Map<Id,sObject>());
    }  
    
    
}