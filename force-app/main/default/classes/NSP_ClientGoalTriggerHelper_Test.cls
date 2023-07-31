/**
Apex Class Name      :  NSP_ClientGoalTriggerHelper_Test 
Version              :  1.0                                                                          
Created Date         :  6/9/2022   
Function             :  NSP_ClientGoalTriggerHelper_Test for NSP_ClientGoalTriggerHelper
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Nischay                    6/28/2022                 First Iteration
*/
@isTest(SeeAllData=false)
public class NSP_ClientGoalTriggerHelper_Test {
 /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void setupTestData(){
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
       //Account creation
        Account accRecord = NSP_TestHelper.createAccount(true);
        //project creation
        pse__Proj__c projectObj = new pse__Proj__c();
        projectObj.Name = 'Test Proj 1';
        projectObj.pse__Is_Active__c = true;
        projectObj.pse__Project_Status__c = 'Active';
        projectObj.pse__Account__c = accRecord.Id;
        projectObj.recordTypeId = peoProjectRecordTypeId;
        insert projectObj;
        //RSAP creation
        NSP_Relationship_Strategy_Action_Plan__c rsap = new NSP_Relationship_Strategy_Action_Plan__c();
        rsap.Name = 'RSAP1';
        rsap.NSP_Account__c = accRecord.Id;
        rsap.NSP_Status__c='Active';
        insert rsap;
        
       //Account creation
        Account accRecord1 = NSP_TestHelper.createAccount(true);
        // Client Goal creation
        NSP_ClientGoal__c clientGoal1 = new NSP_ClientGoal__c();
        clientGoal1.NSP_Goal_Type__c = 'Business Goal';
        clientGoal1.NSP_Goal_Details__c = 'Test details_Test Class';
        clientGoal1.NSP_Goal_Date__c = system.today();
        clientGoal1.NSP_Account__c = accRecord1.Id;
        clientGoal1.NSP_Status__c = NSP_ServiceConstants.ActiveClientGoal;
        insert clientGoal1;
        //project creation
        pse__Proj__c projectObj1 = new pse__Proj__c();
        projectObj1.Name = 'Test Proj 1';
        projectObj1.pse__Is_Active__c = true;
        projectObj1.pse__Project_Status__c = 'Active';
        projectObj1.pse__Account__c = accRecord1.Id;
        projectObj1.recordTypeId = peoProjectRecordTypeId;
        insert projectObj1; 
        //project goal creation
        NSP_ProjectGoal__c projectGoal1 = new NSP_ProjectGoal__c();
        projectGoal1.NSP_GoalType__c = 'Business Goal';
        projectGoal1.NSP_PG_Date__c = system.today();
        projectGoal1.NSP_PG_Status__c = NSP_ServiceConstants.ActiveClientGoal;
        projectGoal1.Client_Goals_Name__c = clientGoal1.Name;
        projectGoal1.NSP_Project__c = projectObj1.Id;
        insert projectGoal1;
    }
    
    @isTest
    static void inActiveRSAPClientGoalTest(){
        Account acc = [Select id from Account WHERE Name != '' limit 1];
        List<NSP_ClientGoal__c> clientGoalList = new List<NSP_ClientGoal__c> ();
        NSP_ClientGoal__c clientGoal = new NSP_ClientGoal__c();
        clientGoal.NSP_Goal_Type__c = 'Business Goal';
        clientGoal.NSP_Goal_Details__c = 'details';
        clientGoal.NSP_Goal_Date__c = system.today();
        clientGoal.NSP_Account__c = acc.Id;
        clientGoal.NSP_Status__c = NSP_ServiceConstants.ActiveClientGoal;
        clientGoalList.add(clientGoal);
        NSP_Relationship_Strategy_Action_Plan__c rsap = new NSP_Relationship_Strategy_Action_Plan__c();
        rsap.Name = 'RSAP1';
        rsap.NSP_Account__c = acc.Id;
        test.startTest();
          insert clientGoalList;
            insert rsap;
            List<NSP_ClientGoal__c> RSAPclientGoalList = NSP_ClientGoalsController.getClientGoalsList(rsap.Id);
        test.stopTest();  
        system.assertEquals(RSAPclientGoalList.Size(), clientGoalList.Size());
    }
       @isTest
    static void activeRSAPClientGoalTest(){
        Set<Id> accountIds = new Set<Id>();
        Account acc = [Select id from Account WHERE Name != '' limit 1];
        accountIds.add(acc.Id);
        List<NSP_ClientGoal__c> clientGoalList = new List<NSP_ClientGoal__c> ();
        NSP_ClientGoal__c clientGoal = new NSP_ClientGoal__c();
        clientGoal.NSP_Goal_Type__c = 'Business Goal';
        clientGoal.NSP_Goal_Details__c = 'details';
        clientGoal.NSP_Goal_Date__c = system.today();
        clientGoal.NSP_Account__c = acc.Id;
        clientGoal.NSP_Status__c = NSP_ServiceConstants.ActiveClientGoal;
        clientGoalList.add(clientGoal);
        NSP_ClientGoalTriggerHelper.getRSAPDetails(accountIds);
        NSP_Relationship_Strategy_Action_Plan__c rsap = new NSP_Relationship_Strategy_Action_Plan__c();
        rsap.Name = 'RSAP1';
        rsap.NSP_Account__c = acc.Id;
        insert clientGoalList;
        insert rsap;
        rsap.NSP_Status__c ='Completed';
        test.startTest();
          update rsap;           
        List<NSP_ClientGoal__c> RSAPclientGoalList = NSP_ClientGoalsController.getClientGoalsList(rsap.Id);
        test.stopTest();
        system.assertEquals(RSAPclientGoalList.Size(), 1);
    }
    
    @IsTest
    static void updateClientGoalToProjectGoalTest(){

        List<NSP_ClientGoal__c> clientGoalList = [SELECT ID, NSP_Goal_Type__c, NSP_Goal_Details__c, NSP_Goal_Date__c, NSP_Account__c, NSP_Status__c  from NSP_ClientGoal__c 
                                                WHERE NSP_Goal_Type__c = 'Business Goal' LIMIT 1];
        clientGoalList[0].NSP_Goal_Details__c = 'Test Class';
        test.startTest();
        update clientGoalList;
        test.stopTest();
        system.assertEquals(clientGoalList[0].NSP_Goal_Type__c, 'Business Goal');
    }
    @IsTest
    static void beforeUpdate() {
        new NSP_ClientGoalTriggerHandler().beforeUpdate(null, null);
        System.assert(new NSP_ClientGoalTriggerHandler().beforeUpdate(null, null) == null);
    }
   // @IsTest
    //static void afterUpdate() {
      //  new NSP_ClientGoalTriggerHandler().afterUpdate(null, null);
    //}
    @IsTest
    static void beforeDelete() {
        new NSP_ClientGoalTriggerHandler().beforeDelete(null, null);
        System.assert(new NSP_ClientGoalTriggerHandler().beforeDelete(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_ClientGoalTriggerHandler().afterDelete(null, null);
        System.assert(new NSP_ClientGoalTriggerHandler().afterDelete(null, null) == null);
    }
}