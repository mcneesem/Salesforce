/**
* Author: Harsha Khiroya
* Represents test class for task trigger helper
* Test Class to cover Task Trigger Handler and Helper classes 
* Modified Date: 11 March 2022
*/
@isTest(SeeAllData=false)
public class NSP_TaskTriggerHelperTest {
    
    @testSetup
    static void testData() {
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        //inserting account object
        insert accoutObject1;
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.stagename = 'Discovery';
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.accountId = accoutObject1.Id;
        
        //Inserting Opportunity Object
        insert opportuniytObject;
        Lead leadObject = new Lead();
        leadObject.firstname='Test';
        leadObject.lastname='Lead';
        leadObject.Company = 'TestClass';
        leadObject.NSP_Product_Interest__c = 'Full Service HR (Workforce Optimization)';
        leadObject.NumberOfEmployees =150;
        leadObject.Email = 'testlead1@testlead1.com';
        leadObject.PostalCode = '10001';
        leadObject.NSP_Lead_Stage__c  =null; 
        leadObject.DNBoptimizer__DNB_D_U_N_S_Number__c = '123';
        
        insert leadObject;
    }
    
    @isTest
    static void testTaskInsert() {
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE stagename = 'Discovery'];
        Lead getLead = [SELECT Id, Name,LastActivityDate,DNBoptimizer__DNB_D_U_N_S_Number__c FROM Lead WHERE firstname = 'Test' LIMIT 1];
        getLead.NumberOfEmployees = 123;
        update getLead;
        Task taskRec;
        Task taskRec1;
        List<Task> taskList = new List<Task>();
        Test.startTest();
        taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = opportunityList[0].Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Open'
        );
        taskList.add(taskRec);
        taskRec1 = new Task(
            Subject = 'Discovery Call',
            whoId = getLead.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Open'
        );
        taskList.add(taskRec1);
        insert taskList;
        taskRec.NSP_Status__c = 'Completed';
        update taskRec;
        taskRec1.NSP_Status__c = 'Completed';
        update taskRec1;
        Test.stopTest();
        system.assertNotEquals(taskRec, null);
    }

    @isTest
    static void salesOfficeDetails() {
        User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id =:UserInfo.getUserId()];
        currentUser.NSP_Sales_Office__c = '301';
        currentUser.NSP_SalesRegion__c = 'Central 1';
        currentUser.NSP_SalesDivision__c = 'Central';
        update currentUser;
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
       
        Test.startTest();
         List<Task> taskList = new List<Task>();
       
       Task taskRec = new Task(
           Subject = 'Discovery Call',
           OwnerId = UserInfo.getUserId(),
           NSP_Task_Type__c = 'BPS',
           RecordTypeId = taskRecTypeId,
           NSP_Task_Subtype__c = 'Client Meeting',
           NSP_Status__c='Open'
       );
       taskList.add(taskRec);
       
       insert taskList;
        Test.stopTest();
        
    }
}