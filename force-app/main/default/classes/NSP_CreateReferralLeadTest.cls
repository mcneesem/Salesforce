/**************************************************************************************************   
Class Name :  NSP_CreateReferralLeadTest
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used as test class for NSP_CreateReferralLead
Test class           :  NSP_CreateReferralLeadTest
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	Tejas           October 10, 2021          First Iteration
***************************************************************************************************/
@isTest
public without sharing class NSP_CreateReferralLeadTest {

    @testSetup
    public static void createTestData(){
        Account accountRecord = NSP_TestHelper.createAccount(false);
        accountRecord.Name='AccountOwner';
        
        Test.startTest();
        insert accountRecord;
        Test.stopTest();        
    }
    
    @isTest
    public static void returnAllPickListValuesTest(){
        NSP_CreateReferralLead.picklistValueClass piclistValueWrapper = NSP_CreateReferralLead.returnAllPickListValues();  
        system.assertNotEquals(null, piclistValueWrapper);
    }
    
    @isTest
    public static void getDependentMapTest(){
        Lead leadRecord = new Lead();
        Map<String, List<String>> picklistDependencyMap = NSP_CreateReferralLead.getDependentMap(leadRecord, 'CountryCode', 'StateCode');
    	system.assertNotEquals(null, picklistDependencyMap);
    }
    
    @isTest
    public static void getAccountOwnerTest(){
        Account accountRecord = [SELECT Id, Name FROM Account WHERE Name='AccountOwner' LIMIT 1];
        NSP_CreateReferralLead.taskClass taskClassInstance = NSP_CreateReferralLead.getAccountOwner(accountRecord.Id);
        system.assertNotEquals(null, taskClassInstance);
    }
    
    @isTest
    public static void createReferralLeadTest(){
        Lead leadRecord = NSP_TestHelper.createLeadRecord(false);
        leadRecord.FirstName='Referral';
        leadRecord.LastName='LeadInsperity';
        
        String leadStringified = JSON.Serialize(leadRecord);
        Test.startTest();
        NSP_CreateReferralLead.createReferralLead(leadStringified);
        Test.stopTest();
        
        Lead leadVerify = [SELECT Id, FirstName,RecordType.Name, LastName FROM Lead WHERE LastName='LeadInsperity' LIMIT 1];
        
        System.assertEquals(leadVerify.RecordType.Name, 'Referral');
        
    }
}