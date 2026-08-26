/**
Apex Class Name      : NSP_TaskTriggerHelperTest
Version              :  1.0
Created Date         :  5/2/2022
Function             :  Test Class to cover Task Trigger Handler and Helper classes
Story                :
Modification Log     :
*--------------------------------------------------------------------------------------------------
* Developer                   Date                   Description
* -------------------------------------------------------------------------------------------------
* Jatin                      6/9/2022            First Iteration
*/


/***********************************************************************************************
* MethodName: testData
* Description : Test Data Method
* Author :      Nischay Jindal
* ********************************************************************************************/
@isTest(SeeAllData=false)
public class NSP_TaskTriggerHelperTest {

    @testSetup
    static void testData() {
        Profile profileobj = NSP_sObjectSelector.selectProfileByName('PEO Service');
        UserRole userRole = NSP_sObjectSelector.selectUserRoleByName('Business Performance Advisor');

        User user = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        user.ProfileId = profileobj.Id;
        user.Email ='jsmith@insperity.com';
        user.UserName =  'insperityadminuser@insperity.com.testUs';
        user.userroleid = userRole.Id;
        insert user;
        System.runAs (user) {
            Account accoutObject1 = new Account();
            accoutObject1.Name = 'Test Account1';
            //inserting account object
            insert accoutObject1;
            Opportunity opportuniytObject = new Opportunity();
            opportuniytObject.Name = 'Test Oppty';
            opportuniytObject.stagename = 'Prospecting';
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
            leadObject.DNB_connect_DUNS_Number__c = '123';
            insert leadObject;
        }

    }

    /***********************************************************************************************
    * MethodName: testTaskInsert
    * Description :  unit test for testTaskInsert
    * ********************************************************************************************/
    @isTest
    static void testTaskInsert() {
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        List<Opportunity> opportunityList = [SELECT ID,NSP_PrimaryProduct__c,stagename FROM OPPORTUNITY WHERE stagename = 'Prospecting'];
        Lead getLead = [SELECT Id, Name,LastActivityDate,DNB_connect_DUNS_Number__c FROM Lead WHERE firstname = 'Test' LIMIT 1];
        getLead.NumberOfEmployees = 123;
        //updating list
        update getLead;
        Task taskRec;
        Task taskRec1;
        //creating list which stores task records
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
        //adding task records to task list
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
        taskRec1.Status = 'Completed';
        update taskRec1;
        Test.stopTest();
        system.assertNotEquals(taskRec, null);
    }

    /***********************************************************************************************
    * MethodName: salesOfficeDetails
    * Description :  unit test for salesOfficeDetails
    * ********************************************************************************************/
    @isTest
     static void salesOfficeDetails() {
         User currentUser = [SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user WHERE Id =:UserInfo.getUserId()];
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
        System.assert(taskList[0].NSP_Status__c == 'Open');

     }

    /***********************************************************************************************
    * MethodName: testTaskTriggerOperation
    * Description :  unit test for testTaskTriggerOperation
    * ********************************************************************************************/
    @isTest
    private static void testTaskTriggerOperation(){
    Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
    newAccount.Name = 'Test Account';
    //inserting new account
    insert newAccount;
    Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
    newContact.Account = newAccount;
    //inserting new contact
    insert newContact;
    Id recordTypePEOID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
    Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
    newCase.RecordTypeId = recordTypePEOID;
    //inserting new case
    insert newCase;
    Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
    newTask.WhatId = newCase.Id;
    newTask.NSP_Minutes_spent_on_task__c=30 ;
    //inserting new task
    insert newTask;

    Case queryCase = [SELECT Id,NSP_Actual_Minutes_Spent_To_Resolve_Case__c FROM Case WHERE Id=: newCase.Id];
    System.assertEquals(30, queryCase.NSP_Actual_Minutes_Spent_To_Resolve_Case__c);
    }

    /***********************************************************************************************
    * MethodName: testReferralTaskOperation
    * Description :  unit test for testReferralTaskOperation
    * ********************************************************************************************/
    @isTest
    private static void testReferralTaskOperation(){
        Id referralRecordTypeId =  Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.REFERRAL_RECORDTYPE)?.getRecordTypeId();
        Account account = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        //GIVEN
        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = account.Id;
        newTask.RecordTypeId = referralRecordTypeId;
        //WHEN
        newTask.Upsell_Product_of_Interest__c = NSP_ServiceConstants.EXPENSE_MANAGEMENT;
        insert newTask;
        newTask.Upsell_Product_of_Interest__c = NSP_ServiceConstants.PAYROLL_HR_MANAGEMENT_WA;
        update newTask;
        //THEN
        System.assertEquals(newTask.Upsell_Product_of_Interest__c,NSP_ServiceConstants.PAYROLL_HR_MANAGEMENT_WA);
        NSP_TaskTriggerHelper.testHandleException( null , null ); // for increased code coverage...
    }

    /***********************************************************************************************
    * MethodName: updateTaskSubjectTest
    * Description :  unit test for Task Status update
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    @isTest
    private static void updateTaskSubjectTest(){
        Id peoTaskRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.Task,NSP_ServiceConstants.peoTask);
        Account account = [SELECT Id FROM Account WHERE Name != null LIMIT 1];
        //GIVEN
        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = account.Id;
        newTask.RecordTypeId = peoTaskRecordType;
        // updating task status
        newTask.Subject = 'Test Subject';
        Test.startTest();
        	insert newTask;
        Test.stopTest();
        Task tsk = [Select Id,Subject, NSP_What_needs_to_get_done__c FROM Task WHERE Subject ='Test Subject' AND Id =:newTask.Id ];
        System.assertEquals(tsk.Subject,tsk.NSP_What_needs_to_get_done__c);
    }

    /***********************************************************************************************
    * MethodName: updateTaskSubjectTestFail
    * Description : negative unit test for Task Status update
    * Author :      Nischay Jindal
    * ********************************************************************************************/
   	@isTest
    private static void updateTaskSubjectTestFail(){
        Id peoTaskRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.Task,NSP_ServiceConstants.peoTask);
        Account account = [SELECT Id FROM Account WHERE Name != null LIMIT 1];

        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = account.Id;
        newTask.RecordTypeId = peoTaskRecordType;
        Test.startTest();
        	insert newTask;
        Test.stopTest();
        Task tsk = [Select Id,Subject, NSP_What_needs_to_get_done__c FROM Task WHERE Id =:newTask.Id ];
        System.assertNotEquals(null,tsk.NSP_What_needs_to_get_done__c);
    }

    /***********************************************************************************************
    * MethodName: restrictServiceTaskDeletion
    * Description : unit test for restrictServiceTaskDeletion
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    @isTest
    private static void restrictServiceTaskDeletion(){
        Id peoTaskRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.Task,NSP_ServiceConstants.peoTask);
        Account account = [SELECT Id FROM Account WHERE Name != null LIMIT 1];
        //GIVEN
        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = account.Id;
        newTask.RecordTypeId = peoTaskRecordType;
        insert newTask;
        Test.startTest();
        	delete newTask;
        Test.stopTest();
        List<Task> tskList = [Select Id FROM Task WHERE Id =:newTask.Id ];
        system.assertEquals(0,tskList.size() );
    }

    /***********************************************************************************************
    * MethodName: restrictServiceTaskDeletionException
    * Description : unit test for restrictServiceTaskDeletionFail
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    @isTest
    private static void restrictServiceTaskDeletionException(){
        Id peoTaskRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.Task,NSP_ServiceConstants.peoTask);
        Account account = [SELECT Id FROM Account WHERE Name != null LIMIT 1];
        User usr =[Select Id FROM User WHERE email='jsmith@insperity.com'];
        //GIVEN
        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = account.Id;
        newTask.RecordTypeId = peoTaskRecordType;
        insert newTask;
        System.runAs(usr){
            try{
                Test.startTest();
                	delete newTask;
                Test.stopTest();
            }catch(Exception ex){
                Boolean isExpectedExceptionThrown =  ex.getMessage().contains(label.NSP_CRMTaskError) ? true : false;
                System.assertEquals(isExpectedExceptionThrown, true);
            }

        }

    }

    /**
    * @Description: This test method is used to test showMessageWhenTaskIsUpdated method
    * @Created date: 7/21/2023.
    * @return void
    ***********************************/
    @isTest
    private static void showMessageWhenTaskIsUpdatedTest(){
        Onboarding_Meeting_Detail_Settings__c customSetting = new Onboarding_Meeting_Detail_Settings__c();
        customSetting.Restrict_Users_Edit_Orientation_Task__c = true;
        insert customSetting;

        List<String> userFields = new List<String>{'Id', 'email'};
        List<String> ACCOUNT_FIELDS = new List<String>{'Id','Name'};
        Id orientationMeetingReqRecTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.Task,NSP_ServiceConstants.ORIENTATION_MEETING_REQUEST);

        String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
            .addFilter('Name', 'Test Account1').addLimit(1).build();
        Account accountRec = Database.query(queryAcc);

        String queryUser = new NSP_QueryBuilder('User', userFields)
            .addFilter('email', 'jsmith@insperity.com').addLimit(1).setSecurityEnforce(false).build();
        User getUser = Database.query(queryUser);

        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = accountRec.Id;
        newTask.RecordTypeId = orientationMeetingReqRecTypeId;
        newTask.NSP_What_needs_to_get_done__c = 'Test';
        newTask.Notes__c = 'Test Notes';
        insert newTask;

        System.runAs(getUser){
            try{
                Test.startTest();
                update newTask;
                Test.stopTest();
            }catch(Exception ex){
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.NSP_PreventOreintationMeetingTaskUpdate) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }

        }
    }

    /***********************************************************************************************
    * MethodName: strategicSalesUpsellQueueRoutingTest
    * Description : unit test for routing HRScale / HR360 & HRScale transition upsell tasks to the Strategic Sales Upsell queue
    * ********************************************************************************************/
    @isTest
    private static void strategicSalesUpsellQueueRoutingTest(){
        Id referralRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.REFERRAL_RECORDTYPE)?.getRecordTypeId();
        List<Group> ssuQueueList = [SELECT Id FROM Group WHERE DeveloperName = 'Strategic_Sales_Upsell' AND Type = 'Queue' LIMIT 1];
        Id ssuQueueId = ssuQueueList.isEmpty() ? null : ssuQueueList[0].Id;
        List<Group> hrCoreQueueList = [SELECT Id FROM Group WHERE DeveloperName = 'HRCore_Transition' AND Type = 'Queue' LIMIT 1];
        Id hrCoreQueueId = hrCoreQueueList.isEmpty() ? null : hrCoreQueueList[0].Id;
        List<Account> accList = [SELECT Id FROM Account WHERE Name != null LIMIT 1];
        Account account = accList.isEmpty() ? null : accList[0];

        Task newTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        newTask.WhatId = account.Id;
        newTask.RecordTypeId = referralRecordTypeId;
        newTask.Upsell_Product_of_Interest__c = 'HRScale';
        Test.startTest();
        insert newTask;
        List<Task> afterInsert = [SELECT Id, OwnerId FROM Task WHERE Id = :newTask.Id];
        System.assertEquals(ssuQueueId, afterInsert[0].OwnerId, 'HRScale should route to the Strategic Sales Upsell queue');

        newTask.Upsell_Product_of_Interest__c = 'HR360 to HRScale Transition';
        update newTask;
        List<Task> afterUpdate = [SELECT Id, OwnerId FROM Task WHERE Id = :newTask.Id];
        System.assertEquals(ssuQueueId, afterUpdate[0].OwnerId, 'HR360 to HRScale Transition should route to the Strategic Sales Upsell queue');

        Task hrCoreTask = (Task)NSP_TestDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', false);
        hrCoreTask.WhatId = account.Id;
        hrCoreTask.RecordTypeId = referralRecordTypeId;
        hrCoreTask.Upsell_Product_of_Interest__c = 'HR360 to HRCore Transition';
        insert hrCoreTask;
        List<Task> afterHrCoreInsert = [SELECT Id, OwnerId FROM Task WHERE Id = :hrCoreTask.Id];
        System.assertEquals(hrCoreQueueId, afterHrCoreInsert[0].OwnerId, 'HR360 to HRCore Transition should route to the HRCore Transition queue');
        Test.stopTest();
    }

}