/* Description : Test class for ProjectTaskAssignmentTrigger
    Date        : 01/12/2021 */
    @isTest
    public class NSP_ProjectTaskAssignmentTriggerHelpTest {
        @testSetup
        static void setupTestData(){
            //get RET Project Type Record Type
            Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'RET_Deconversion_2020_Form');
            // PEO project Task
        	Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c',NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
            //Creating Account
            Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
             // Creating Contact
            Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            oContact.AccountId = oAccount.Id;
            oContact.pse__Salesforce_User__c = userInfo.getUserId();
            oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
            oContact.NSP_Date_of_Birth__c = System.today();
            oContact.pse__Is_Resource__c = True;
            oContact.pse__Is_Resource_Active__c = True;
            insert oContact;
            
            //Creating Admin User
            String orgId = UserInfo.getOrganizationId();
        	User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
            testUser.userName = 'testemail@domain'+ orgId +'.com.test';
            insert testUser;
            // Creating Contact
            Contact conRec = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            conRec.AccountId = oAccount.Id;
            conRec.FirstName = 'ResourceFN2';
            conRec.LastName = 'ResourceLN2';
            conRec.pse__Salesforce_User__c = testUser.Id;
            conRec.NSP_Work_email__c = 'testnewresourc@test.com';
            conRec.NSP_Date_of_Birth__c = System.today();
            INSERT conRec;
            
            Test.startTest();
            NSP_Account_Team__c newAccTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
            newAccTeam.NSP_Role__c = NSP_ServiceConstants.PAYROLL_SPECIALIST;
            insert newAccTeam;
            
            List<pse__Proj__c> listofProject = new List<pse__Proj__c>();
            pse__Proj__c newProj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            newProj.pse__Is_Template__c = false;
            newProj.NSP_Auto_Resource_Project__c = true;
            listofProject.add(newProj);
            
            pse__Proj__c newProj1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            newProj1.pse__Is_Template__c = false;
            newProj1.RecordTypeId = retProjectRecordTypeId;
            listofProject.add(newProj1);
            
            insert listofProject;
            
            List<pse__Project_Task__c> listofProjectTask = new List<pse__Project_Task__c>();
            pse__Project_Task__c newProjTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            newProjTask.Name = 'Test ProjectTask';
            newProjTask.pse__Project__c = listofProject[0].id;
            newProjTask.RecordTypeId = peoRecordTypeId;
            listofProjectTask.add(newProjTask);
            
            pse__Project_Task__c newProjTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            newProjTask1.pse__Project__c = listofProject[0].id;
            newProjTask.RecordTypeId = peoRecordTypeId;
            listofProjectTask.add(newProjTask1);
            insert listofProjectTask;
            
            List<pse__Project_Task_Assignment__c> projTaskAssignmentList = new List<pse__Project_Task_Assignment__c>();
            
            pse__Project_Task_Assignment__c newProjTaskAssignment = (pse__Project_Task_Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task_Assignment__c(), 'NSP_TestDataFactory.ProjectTaskAssignmentDefaults', false);
            newProjTaskAssignment.pse__Project_Task__c = listofProjectTask[0].Id;
            newProjTaskAssignment.pse__Resource__c = oContact.Id;
            newProjTaskAssignment.Resource_Type__c = 'Primary';
            newProjTaskAssignment.pse__Resource_Role__c = NSP_ServiceConstants.PAYROLL_SPECIALIST;
            projTaskAssignmentList.add(newProjTaskAssignment);
            //INSERT newProjTaskAssignment;
            
            pse__Project_Task_Assignment__c projTaskAssignment = (pse__Project_Task_Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task_Assignment__c(), 'NSP_TestDataFactory.ProjectTaskAssignmentDefaults', false);
            projTaskAssignment.pse__Project_Task__c = listofProjectTask[1].Id;
            projTaskAssignment.pse__External_Resource__c = 'Test Resource';
            projTaskAssignment.Resource_Type__c = 'Secondary';
            //INSERT projTaskAssignment;
            projTaskAssignmentList.add(projTaskAssignment);
            INSERT projTaskAssignmentList;
            Test.stopTest();
        }
        
        /**
        * Classes Covered
        * NSP_ProjectTaskAssignmentTriggerHandler.afterInsert
        * NSP_ProjectTaskAssignmentTriggerHelper.updateResourceOnInsert
        */
        @isTest
        static void updateresourceAfterInsert() {

            Contact conObj = [SELECT id from Contact WHERE id!=NULL LIMIT 1];
            pse__Project_Task_Assignment__c ptaObj = [SELECT id,pse__Resource__c from pse__Project_Task_Assignment__c WHERE id!=NULL LIMIT 1];
              
            Test.StartTest();
            System.assertEquals(conObj.id,ptaObj.pse__Resource__c);
            Test.StopTest();
        }
        
        /**
        * Classes Covered
        * NSP_ProjectTaskAssignmentTriggerHandler.beforeUpdate
        * NSP_ProjectTaskAssignmentTriggerHelper.updateProjectTaskOwnerWhenResourceChangedOnPrimary
        */
        @IsTest
        static void testUpdateProjectTaskOwnerWhenResourceChangedOnPrimary() {
            List<String> contactFields = new List<String>{'Id','pse__Salesforce_User__c'};
            String contactQuery = new NSP_QueryBuilder('Contact', contactFields)
                				.addFilter('NSP_Work_email__c', 'abctestexamplyxyz@test.com.abc').addLimit(1).build();
            Contact contactRec = Database.query(contactQuery);
            String projTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', new List<String>{'Id', 'OwnerId', 'pse__Number_of_Assignments__c', 'pse__Project__c', 'pse__Project__r.pse__Account__c'})
                                    .addFilter('Name' ,'Test ProjectTask')
                                    .setSecurityEnforce(false)
                                    .build();
            pse__Project_Task__c prjTask =  Database.query(projTaskQuery);
            String accTeamQuery = new NSP_QueryBuilder('NSP_Account_Team__c', new List<String>{'NSP_Account__c','NSP_Role__c','NSP_User__c','NSP_Primary__c','NSP_First_Name__c'})
                                    .addFilter('NSP_Account__c', prjTask.pse__Project__r.pse__Account__c)
                                    .setSecurityEnforce(false)
                                    .build() +' Order by NSP_Primary__c DESC, NSP_First_Name__c ASC';
            
            NSP_Account_Team__c acTeam = Database.query(accTeamQuery);
            
            List<String> ptaFields = new List<String>{'Id','pse__Resource__c','pse__Project_Task__c'};
            String ptaQuery = new NSP_QueryBuilder('pse__Project_Task_Assignment__c', ptaFields)
                				.addFilter('pse__Resource__c', contactRec.Id).addLimit(1).build();
            pse__Project_Task_Assignment__c ptaRec = Database.query(ptaQuery);
            

            Test.StartTest();
            List<String> newConFields = new List<String>{'Id'};
            String conQuery = new NSP_QueryBuilder('Contact', newConFields)
                				.addFilter('NSP_Work_email__c', 'testnewresourc@test.com').addLimit(1).build();
            Contact newContactRec = Database.query(conQuery);
            
            ptaRec.pse__Resource__c = newContactRec.Id;
            UPDATE ptaRec;
            System.assertEquals(newContactRec.Id,ptaRec.pse__Resource__c);
            Test.StopTest();
            pse__Project_Task__c prjTaskupdate =  Database.query(projTaskQuery);
            System.assertEquals(prjTaskupdate.OwnerId,acTeam.NSP_User__c);
        }
    
        /**
        * Classes Covered
        * NSP_ProjectTaskAssignmentTriggerHandler.beforeUpdate
        * NSP_ProjectTaskAssignmentTriggerHelper.updateResourceOnUpdateWhenResourceTypeIsChanged
        */
        @IsTest
        static void testUpdateResourceOnUpdateWhenResourceTypeIsChanged() {
            Test.StartTest();
            List<String> ptaFields = new List<String>{'Id','pse__Resource__c','Resource_Type__c','pse__Project_Task__c'};
            String ptaQuery = new NSP_QueryBuilder('pse__Project_Task_Assignment__c', ptaFields)
                				.addFilter('pse__External_Resource__c', 'Test Resource').addLimit(1).build();
            pse__Project_Task_Assignment__c ptaRec = Database.query(ptaQuery);

            ptaRec.Resource_Type__c = 'Primary';
            UPDATE ptaRec;
            System.assertEquals('Primary',ptaRec.Resource_Type__c);
            Test.StopTest();
        }
        
        /**
        * Classes Covered
        * NSP_ProjectTaskAssignmentTriggerHandler.afterInsert
        * NSP_ProjectTaskAssignmentTriggerHelper.updateResourceOnInsert
        */
        @isTest
        static void updateresourceAfterInsertTest() {

            Contact conObj = [SELECT id from Contact WHERE FirstName = 'ResourceFN2' LIMIT 1];
            pse__Project_Task_Assignment__c ptaObj = [SELECT id,pse__Resource__c from pse__Project_Task_Assignment__c WHERE id!=NULL LIMIT 1];
             ptaObj.pse__Resource__c = conObj.Id;
            Test.StartTest();
            Update ptaObj;
            System.assertEquals(conObj.id,ptaObj.pse__Resource__c);
            Test.StopTest();
        }
    }