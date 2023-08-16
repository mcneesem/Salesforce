/**
* @description  :   Test class for NSP_assignTaskOwners .
* @date 06/26/2022
* Author : Nischay Jindal
* Name : NSP_assignTaskOwnersTest
*/

@isTest
public class NSP_assignTaskOwnersTest {
    /**
    * @description  :   Test Setup Method for NSP_assignTaskOwnersTest .
    * Author : Nischay Jindal
    * Name : setupProjectTaskdata
    */
    
    @testSetup
    public static void setUpData(){
     String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert oContact;

        Test.startTest();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = System.Today();
        oProject.pse__Account__c= oAccount.Id;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.RecordTypeId = PEORecordTypeId;
        insert oProject;
        
        
        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask1.Name = 'pTask1';
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        Insert oProjectTask1;
        
        pse__Project_Task_Assignment__c oProjectTaskAssignment1 = (pse__Project_Task_Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task_Assignment__c(), 'NSP_TestDataFactory.ProjectTaskAssignmentDefaults', false);
        oProjectTaskAssignment1.pse__Project_Task__c = oProjectTask1.Id;
        oProjectTaskAssignment1.pse__Resource_Role__c = NSP_ServiceConstants.PayrollSpecialist;
        oProjectTaskAssignment1.NSP_Priority__c = 1;
        insert oProjectTaskAssignment1;   
        Test.stopTest();

    }
   /**
    * @description  :   Unit test for Assign Task using Button  .
    * Author : Nischay Jindal
    * Name : projectTaskAssignmentTest
    */

    @isTest
    public static void projectTaskAssignmentTest(){
       Test.startTest();
       Account acc=[Select Id from Account WHERE Id != null];
       Contact contact =[Select Id,pse__Salesforce_User__c,AccountId From Contact WHERE Id !=null Limit 1]; 
       pse__Proj__c project = [Select Id ,pse__Account__c,pse__Project_Type__c,TemplateName__c, RecordTypeId From pse__Proj__c WHERE TemplateName__c =: label.Middle_Market_Implementation_Project ];
	   List<NSP_Project_Team__c> projectTeam = [Select Id , NSP_Role__c, NSP_Assignee__c FROM NSP_Project_Team__c WHERE  NSP_Project__c=: project.Id  ];
  		 for(NSP_Project_Team__c prjTeam: projectTeam){
             prjTeam.NSP_Assignee__c = contact.Id;
        }
        	update projectTeam;
        NSP_assignTaskOwners.projectTaskAssignment(project.Id);
        Test.stopTest();
        pse__Project_Task__c projectTask = [Select Id ,OwnerId from pse__Project_Task__c WHERE pse__Project__c =:project.Id ];
        System.assertEquals(projectTask.OwnerId, contact.pse__Salesforce_User__c);
    }
    
}