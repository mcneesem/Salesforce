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
    }
    
	@isTest
    static void testTaskInsert() {
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
          List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE stagename = 'Discovery'];
        Task taskRec;
        Test.startTest();
        taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = opportunityList[0].Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = NSP_SalesConstants.DISCOVERY_CALL_ACTIVITY,
            Status='Open'
        );
        insert taskRec;
        taskRec.Status = 'Completed';
        update taskRec;
        Test.stopTest();
        system.assertNotEquals(taskRec, null);
    }
}