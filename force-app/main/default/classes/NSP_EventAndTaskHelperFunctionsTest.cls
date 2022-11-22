/**
* Author: Sales Team
* Represents test class for lead opportunity helper
* Test Class to cover NSP_EventAndTaskHelperFunctions class
* Modified Date: 3/3/2022
*/
@isTest(SeeAllData=false)
public class NSP_EventAndTaskHelperFunctionsTest {

    public static final String ACCOUNT_NAME = 'Test Account1';  
    public static final String OPP_TYPE = 'CAMS';
      /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        
        Account accoutObject1 = new Account();
        accoutObject1.Name = ACCOUNT_NAME;
        insert accoutObject1;       
        
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            Opportunity opp = new Opportunity();
            opp = NSP_TestHelper.createOpenOpportunity(accoutObject1.Id, OPP_TYPE, false);
            opp.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
            opp.NSP_PrimaryProduct__c = NSP_SalesConstants.WX;
            opp.NSP_Client_For_Life__c = NSP_SalesConstants.WX;
            opp.NSP_Number_of_Employees__c = 100;
            insert opp;
        }  
    }
    
      /**
* @Description: This test method is used to cover createTaskForPrimaryQuote method 
* @Created date: 03/03/2022.
* @return void 
*  Modification History:
* -------------------------------------------------------------------------------------
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* RAHUL SINGH       11-11-2022          modified this method as part of userstory 128436          
* 
*                
*/
      @isTest
    static void createTaskForPrimaryQuoteTest(){
     List<Opportunity> opportunityList = [SELECT Id, 
                                          		AccountId, 
                                                Name, 
                                          		Type,
                                          		CloseDate,
                                                NSP_PrimaryProduct__c,
                                          		NSP_Client_For_Life__c,
                                             	OwnerId FROM Opportunity 
                                             	WHERE StageName =: NSP_SalesConstants.ANALYSIS_STAGE LIMIT 1];
        Test.startTest();
        NSP_EventAndTaskHelperFunctions.createTaskForPrimaryQuote(opportunityList);
        Test.stopTest();
        List<Task> taskList = [SELECT Id, WhatId FROM Task WHERE WhatId =: opportunityList[0].Id];
        System.assert(taskList.size() > 0);
    }
    
     /**
* @Description: This test method is used to cover createTaskRecordsForNCSQueue method 
* @Created date: 03/03/2022.
* @return void             
*                
*/
      @isTest
    static void createTaskRecordsForNCSQueueTest(){
        Map < Id, Opportunity > opportunityOldMap = new Map < Id, Opportunity > ();
     List<Opportunity> opportunityList = [SELECT Id,
                                          		AccountId, 
                                          		Name,
                                          		Type,
                                          		CloseDate,
                                             	OwnerId FROM Opportunity 
                                             	WHERE StageName =: NSP_SalesConstants.ANALYSIS_STAGE LIMIT 1];
        opportunityOldMap.put(opportunityList[0].Id, opportunityList[0]);
        Test.startTest();
        NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue(opportunityList, opportunityOldMap);
        Test.stopTest();
        List<Task> taskList = [SELECT Id, WhatId FROM Task WHERE WhatId =: opportunityList[0].Id];
    }
}