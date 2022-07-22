/**
* Represents test class for AccountTeam Trigger helper 
* Represents test class for AccountTeam Trigger Handler
* Created by : Hemali Patel
* Created Date : 8/11/2021
*/
@isTest(SeeAllData=false)
public without sharing class NSP_AccountTeamTriggerTest {
	
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void testData() {
        User userObj = NSP_TestHelper.createUser(false);
        userObj.NSP_Employee_Per_ID__c = 'EMP 1234';
        insert userObj;
        NSP_TestHelper.createAccount(true);
        
    }
    
 /**
* Checks the update insert logic of the trigger
* @param N/A. 
* @return void                          
*/    
    @isTest
    public static void testInsert(){
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];
        
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = 'EMP 1234';
        accTeam.NSP_Role__c = 'Recruiting';
        test.startTest();
        	insert accTeam;
        test.stopTest(); 
        User userObj = [SELECT Id from User WHERE NSP_Employee_Per_ID__c = 'EMP 1234'];
        NSP_Account_Team__c accTeamObj = [SELECT Id,NSP_User__c FROM NSP_Account_Team__c WHERE NSP_PER_ID__c = 'EMP 1234'];
        system.assertEquals(userObj.Id, accTeamObj.NSP_User__c);
    }
   
 /**
* Checks the update update logic of the trigger
* @param N/A. 
* @return void                          
*/     
    @isTest
    public static void testUpdate(){
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];
        
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = 'EMP 1234';
        accTeam.NSP_Role__c = 'Recruiting';
        insert accTeam;
        
        NSP_Account_Team__c accountTeamObj = [SELECT Id from NSP_Account_Team__c WHERE
                                              NSP_Account__c =: accountObj.Id limit 1];
        
        accountTeamObj.NSP_Role__c = 'HR Specialist';
        test.startTest();
        	update accountTeamObj;
        test.stopTest();  
        
        NSP_Account_Team__c accountTeam = [SELECT Id,NSP_Role__c from NSP_Account_Team__c 
                                              WHERE NSP_Account__c = :accountObj.Id];
        
        system.assertEquals('HR Specialist', accountTeam.NSP_Role__c);
    }
}