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
        User PEOUSER = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert PEOUSER;      
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
    
    /**
    * @Description: This test method is used to provide permission set to user when clicks upsell button and remove the permission set when creates a records or cancel it
    * @Method Cover : NSP_CreateReferralLead.taskReferralRecord, NSP_CreateReferralLead.deletePermissionSet and NSP_TaskTriggerHelper.removePermissionSet
    * @Created date: 1/23/2023. 
    * @ DF-02737
    * @return void             
    */

    @isTest
    private static void taskReferralRecordTest(){
        
        Id REFERRAL_RECORDTYPE_ID = NSP_GenericRecordType.getRecordTypeId('Task', NSP_ServiceConstants.REFERRAL_RECORDTYPE);
        //query to permission set of Name Task-Referral Task
        List<String> permSetFields = new List<String>{'Id', 'Name', 'Label'};
            String query = new NSP_QueryBuilder('PermissionSet', permSetFields)
            .addFilter('Name', 'NSP_Task_Referral_Task')
            .addLimit(1).build();
        PermissionSet permSet = Database.query(query);

        Test.startTest();
        // A user who does not have the Task-Referral Task permission set
        User getPeoUser = [SELECT Id FROM User WHERE Email='testuser@insperity.com' LIMIT 1];
        //assigning the Task-Referral Task permission set to the user 

        System.runAs(getPeoUser){
            NSP_CreateReferralLead.taskReferralRecord(REFERRAL_RECORDTYPE_ID);
            List<PermissionSetAssignment> assertPermSetAssignment = [SELECT Id, AssigneeId ,PermissionSetId FROM PermissionSetAssignment  WHERE PermissionSetId =: permSet.Id];
            //system.assertEquals(assertPermSetAssignment[0].AssigneeId, Userinfo.getUserId());
        }
        Test.stopTest();

        //removal of the Task-Referral Task permission set to the user
        NSP_CreateReferralLead.deletePermissionSet();
        
        Task newRefTask = (Task)NSP_TestExtendedDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newRefTask.NSP_Is_Referral_Task__c = true;
        insert newRefTask;
        
        List<PermissionSetAssignment> assertPermSetAssignmentRemoved = [SELECT Id, AssigneeId ,PermissionSetId FROM PermissionSetAssignment  WHERE PermissionSetId =: permSet.Id];
        system.assertNotEquals(assertPermSetAssignmentRemoved[0].AssigneeId, Userinfo.getUserId()); 
        
    }
}