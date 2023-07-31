/**
* @description  :   Test class for NSP_ImplementaionProfileTriggerHelper .
* @date 08/3/2022
* Author : Nischay Jindal
* Name : NSP_ImplProfileTriggerHelperTest
*/
@isTest
public class NSP_ImplProfileTriggerHelperTest {
    /***********************************************************************************************
    * MethodName: setUpData
    * Description : Test Setup Method 
    * ********************************************************************************************/
	@testSetup
    public static void setUpData(){
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        
        //create acc
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
		insert acc;
        
        //create contact
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.lastName= 'Test';
        con.pse__Salesforce_User__c = UserInfo.getUserId();
        con.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert con;
        
        //create project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
		oProject.pse__Account__c = acc.Id;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = peoProjectRecordTypeId;
        insert oProject;
    }
    
     /***********************************************************************************************
    * MethodName: updateProjectTeamRolesTest
    * Description : Unit test for update roles on Project team 
    * ********************************************************************************************/
    @isTest
    public static void updateProjectTeamRolesTest(){
        Id MMRecordIPRecordTypeId = Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get('Middle_Market').getRecordTypeId();
		Account acc=[Select Id from Account WHERE Id != null];
        Contact contact =[Select Id,pse__Salesforce_User__c,AccountId From Contact WHERE Id !=null Limit 1];
        pse__Proj__c project = [Select Id ,pse__Account__c,pse__Project_Type__c,TemplateName__c, RecordTypeId From pse__Proj__c WHERE TemplateName__c =: label.Middle_Market_Implementation_Project ];
		project.pse__Account__c =acc.Id;
        update project;
        Implementation_Profile__c impProfile= new Implementation_Profile__c();
        impProfile.NSP_Project__c = project.Id;
        impProfile.RecordTypeId = MMRecordIPRecordTypeId;
        impProfile.Account__c= acc.Id;
        insert impProfile;
        impProfile.NSP_Transition_Specialist__c =contact.Id;
        Test.startTest();
        	update impProfile;
        Test.stopTest();
        NSP_Project_Team__c projectTeam = [Select Id , NSP_Role__c, NSP_Assignee__c FROM NSP_Project_Team__c 
                                           WHERE  NSP_Project__c=: project.Id AND NSP_Role__c ='Transition Specialist'  ];
        system.assertEquals(projectTeam.NSP_Assignee__c, contact.Id);
    }
}