/**
Apex Class Name      :  NSP_ProjectDeleteControllerTest
Function             :  This class is used as a test class for  NSP_ProjectDeleteControllerTest
*/
@isTest(SeeAllData=false)
public class NSP_ProjectDeleteControllerTest {
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void setupTestData(){
        Id PEORecordTypeId  = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        
        //Creating Account
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        
        // Creating Contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        oContact.NSP_Date_of_Birth__c = System.today();
        oContact.NSP_Work_email__c = 'abcworkemail@test.com';
        insert oContact;
        
        //project creation
        pse__Proj__c projectObj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        projectObj.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        projectObj.TemplateName__c = label.Middle_Market_Implementation_Project;
        projectObj.RecordTypeId = PEORecordTypeId;
        projectObj.pse__Account__c = oAccount.Id;
        insert projectObj;
        
        //Creating Admin User
        String orgId = UserInfo.getOrganizationId();
        User adminUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        adminUser.userName = 'testemail@domain'+ orgId +'.com.test';
        INSERT adminUser;
        //Creating Permission Control for Project
		pse__Permission_Control__c prmControlProject = new pse__Permission_Control__c();
        prmControlProject.pse__User__c = adminUser.Id;
        prmControlProject.pse__Staffing__c = true;
        prmControlProject.pse__Project__c = projectObj.Id;
        INSERT prmControlProject;
        
        //Creating Permission Control for Resource
        pse__Permission_Control__c prmControlResource = new pse__Permission_Control__c();
        prmControlResource.pse__User__c = adminUser.Id;
        prmControlResource.pse__Staffing__c = true;
        prmControlResource.pse__Resource__c = oContact.Id;
        INSERT prmControlResource;

        //milstone creation
        pse__Milestone__c milestoneObj = new pse__Milestone__c();
        milestoneObj.Name = 'Test milestone delete 1';
        milestoneObj.pse__Target_Date__c = system.today();
        milestoneObj.pse__Project__c = projectObj.id;
        insert milestoneObj;
        //Project Task Creation
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
		oProjectTask.Name = 'pTask';        
        oProjectTask.pse__Project__c = projectObj.Id;
        oProjectTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        INSERT oProjectTask;
        System.runAs(adminUser){
        //Schedule Creation
        pse__Schedule__c schedule = (pse__Schedule__c)NSP_TestExtendedDataFactory.createSObject(new pse__Schedule__c(), 'NSP_TestDataFactory.ScheduleDefaults', false);
        schedule.pse__Start_Date__c = System.today();
        schedule.pse__End_Date__c = System.today().addDays(7);
        schedule.pse__Monday_Hours__c = 8.0;
        schedule.pse__Tuesday_Hours__c = 8.0;
        schedule.pse__Wednesday_Hours__c = 8.0;
        schedule.pse__Thursday_Hours__c = 8.0;
        schedule.pse__Friday_Hours__c = 8.0;
        schedule.pse__Saturday_Hours__c = 8.0;
        schedule.pse__Sunday_Hours__c = 8.0;
        INSERT schedule;
        //Assignment Creation
        pse__Assignment__c assignment = (pse__Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Assignment__c(), 'NSP_TestDataFactory.AssignmentDefaults', false);
        assignment.Name = 'Test Assignment';
        assignment.pse__Resource__c = oContact.Id;
        assignment.pse__Project__c = projectObj.Id;
        assignment.pse__Schedule__c = schedule.Id;
		assignment.pse__Bill_Rate__c = 0.0;
        assignment.pse__Cost_Rate_Amount__c = 0.0;
        INSERT assignment;
        }
    }
    /* Checks the deep delete method
* @param N/A. 
* @return void                          
*/
    @isTest
    static void testdeepDelete(){  
        test.startTest();
        List<pse__Proj__c> projectList = [SELECT ID FROM pse__Proj__c WHERE ID!=null LIMIT 1 ];
        system.assertEquals(projectList.size()>0, true);
        NSP_ProjectDeleteController.deepDeleteRecords(projectList[0].Id);
        test.stopTest();
    }
    /* Checks if user is system admin
* @param N/A. 
* @return void                          
*/ 
    @isTest
    static void testisSystemAdmin(){  
        test.startTest();
        Boolean issystemAdmin =false;
        Profile adminProfile = [SELECT id, Name FROM Profile WHERE name = 'System Administrator' ].get(0);  
        User userObj = new User(firstname= 'test admin',
                                lastname='XXXX',
                                Alias='test',
                                email = 'testadmin@insperity.com',
                                username= 'testadmin@fake.com', 
                                profileId= adminProfile.id, 
                                emailencodingkey='UTF-8',
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles');
        insert userObj;
        System.runAs(userObj) {
            issystemAdmin = NSP_ProjectDeleteController.getIsUserSystemAdmin();
        }
        system.assertEquals(issystemAdmin, true);
        test.stopTest();
    }
}