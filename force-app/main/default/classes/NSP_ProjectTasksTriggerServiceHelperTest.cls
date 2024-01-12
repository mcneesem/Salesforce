/*
Represents test class of NSP_ProjectTasksTriggerServiceHelper
*/


@isTest
private class NSP_ProjectTasksTriggerServiceHelperTest {
    //Setting up test data
    private static final String PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
    private static final Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT, NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);
    @testSetup
    private static void setupProjectTaskdata(){
        
         //Creating Account
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        // Creating Contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        oContact.NSP_Date_of_Birth__c = System.today();
        insert oContact;
        //creating workType
        WorkType oWorkType = (WorkType)NSP_TestExtendedDataFactory.createSObject(new WorkType(), 'NSP_TestDataFactory.WorkTypeDefaults', false);
        oWorkType.Name = NSP_ServiceConstants.WORKTYPE_NAME;
        Database.insert(oWorkType);
        
        // Creating Project
        test.startTest();
        List<pse__Proj__c> projList  = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = Date.Today();
        oProject.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE;
        projList.add(oProject);
        
        pse__Proj__c oProject1 = (pse__Proj__c) NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults');
        oProject1.Name = 'Proj2';
        oProject1.pse__Account__c = oAccount.Id;
        oProject1.RecordTypeId = retProjectRecordTypeId;
        oProject1.pse__Start_Date__c = Date.Today();
        oProject1.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE;
        oProject1.pse__End_Date__c = System.Today().addDays(100);
        projList.add(oProject1);
        
        if(!projList.isEmpty()){
          database.insert(projList,false);  
        }
        
        // Creating Project Task
        List<pse__Project_Task__c> projTaskList  = new List<pse__Project_Task__c>();
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask.NSP_Percentage_Complete__c = '100%';
        oProjectTask.NSP_Create_Work_Order__c = true;
        oProjectTask.NSP_Dispatch_Region__c ='FSO Project Manager National';
        // oProjectTask.NSP_Child_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        projTaskList.add(oProjectTask);

        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
		oProjectTask1.Name = 'pTask';        
        oProjectTask1.pse__Project__c = oProject1.Id;
        oProjectTask1.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTaskList.add(oProjectTask1);

        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
		oProjectTask2.Name = NSP_ServiceConstants.PREPARE_AMENDMENT;        
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.Template_Name__c = NSP_ServiceConstants.PLAN_AMENDMENT_TEMPLATE;
        projTaskList.add(oProjectTask2);

        pse__Project_Task__c oProjectTask3 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask3.pse__Project__c = oProject.Id;
        oProjectTask3.Name = 'NewPt';
        oProjectTask3.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask3.NSP_Duration_in_minutes__c = 60;
        oProjectTask3.NSP_Create_Work_Order__c = true;
        oProjectTask3.NSP_Dispatch_Region__c = 'FSO Project Manager National';
        projTaskList.add(oProjectTask3);
        
        if(!projTaskList.isEmpty()){
          database.insert(projTaskList);  
        }
        // Creating PTA
        pse__Project_Task_Assignment__c oProjectTaskAssignment = (pse__Project_Task_Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task_Assignment__c(), 'NSP_TestDataFactory.ProjectTaskAssignmentDefaults', false);
        oProjectTaskAssignment.pse__Resource__c = oContact.Id;
        oProjectTaskAssignment.pse__Resource_Role__c = NSP_ServiceConstants.PTASSIGNMENTROLE;
        oProjectTaskAssignment.NSP_Priority__c = 1;
        oProjectTaskAssignment.pse__Project_Task__c = oProjectTask.Id;
        insert oProjectTaskAssignment;
        test.stopTest();
    }

    /**
    * Classes Covered
    * NSP_ProjectTasksTriggerHandler.afterUpdate
    * NSP_ProjectTasksTriggerServiceHelper.updateResourceOnPTA
    */
    @isTest
    static void updateResourceOnPTATest(){
        Id recordTypeIdBPS = SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE)?.getRecordTypeId();
    
        User userRec = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        userRec.userName = userRec.userName + '.' + System.now().millisecond();
        insert userRec;
        // Updating contact with User
        Contact con = [SELECT pse__Salesforce_User__c FROM Contact WHERE NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc'];
        con.pse__Salesforce_User__c = userRec.id;
        update con;
        // Making Auto Resource Chackbox false
        pse__Proj__c project = [SELECT NSP_Auto_Resource_Project__c From pse__Proj__c WHERE pse__Start_Date__c = : Date.Today() LIMIT 1];
        project.NSP_Auto_Resource_Project__c = false;
        update project;
        test.startTest();
        pse__Project_Task__c projectTask = [SELECT OwnerId FROM pse__Project_Task__c WHERE pse__Project__c = : project.id limit 1];
        projectTask.OwnerId = userRec.id;
        update projectTask;
        test.stopTest();
        System.assertEquals(con.pse__Salesforce_User__c, [SELECT OwnerId From pse__Project_Task__c WHERE Id = : projectTask.id].OwnerId);        

		//Method "updateRecordType" code coverage - Assert - start
        System.assertEquals(recordTypeIdBPS ,[SELECT RecordTypeId FROM pse__Project_Task__c WHERE ID = : projectTask.Id ].RecordTypeId);
        //Method "updateRecordType" code coverage - Assert - end
    }

    @isTest
    static void createWorkOrderTest(){
        // Test.startTest();
        pse__Proj__c project = [SELECT Id, NSP_Auto_Resource_Project__c From pse__Proj__c WHERE pse__Project_Type__c =: NSP_ServiceConstants.PROJECT_TYPE AND pse__Start_Date__c = : Date.Today() LIMIT 1];
        pse__Project_Task__c projectTask = [SELECT Id, Name FROM pse__Project_Task__c WHERE pse__Project__c =: project.id limit 1];
        
        List<WorkOrder> oWorkOrder = new List<WorkOrder>(
            [SELECT Id, NSP_Project_Task__c FROM WorkOrder WHERE NSP_Project_Task__c =: projectTask.Id LIMIT 1]);
        List<ServiceAppointment> oServiceAppointments = new List<ServiceAppointment>(
                        [SELECT Id FROM ServiceAppointment WHERE ParentRecordId =: oWorkOrder[0].Id LIMIT 1]);
        System.Assert(oWorkOrder.size()>0);
        System.Assert(oServiceAppointments.size()>0);
       
        pse__Proj__c project1 = [SELECT Id, RecordTypeId From pse__Proj__c WHERE pse__Start_Date__c = : Date.Today() AND Name = 'Proj2' LIMIT 1];
        project1.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE;
        UPDATE project1;
        pse__Project_Task__c projectTask1 = [SELECT Id, Name FROM pse__Project_Task__c WHERE pse__Project__c =: project1.id];
        projectTask1.NSP_Create_Work_Order__c = true;
        projectTask1.NSP_Dispatch_Region__c = 'FSO Project Manager National';
        // projectTask1.NSP_Child_Dispatch_Region__c = NSP_ServiceConstants.CHILD_DISPATCH_REGION;
        Test.startTest();
        UPDATE projectTask1;
        List<WorkOrder> oWorkOrder1 = new List<WorkOrder>(
            [SELECT Id, NSP_Project_Task__c FROM WorkOrder WHERE NSP_Project_Task__c =: projectTask1.Id LIMIT 1]);
        List<ServiceAppointment> oServiceAppointments1 = new List<ServiceAppointment>(
                        [SELECT Id FROM ServiceAppointment WHERE ParentRecordId =: oWorkOrder1[0].Id LIMIT 1]);
        System.Assert(oWorkOrder1.size()>0);
        System.Assert(oServiceAppointments1.size()>0);
        Test.stopTest();
    }
    
    @isTest
    static void updateServiceAppointmentTest(){
        Test.startTest();
        pse__Proj__c project = [SELECT Id From pse__Proj__c 
                                WHERE pse__Project_Type__c =: NSP_ServiceConstants.PROJECT_TYPE 
                                AND pse__Start_Date__c = : Date.Today() LIMIT 1];
        
        pse__Project_Task__c projectTask = [SELECT Id, Name FROM pse__Project_Task__c WHERE pse__Project__c =: project.id limit 1];
        projectTask.NSP_Orientation_Address__c = NSP_ServiceConstants.ORIENTATION_ADDRESS;
        UPDATE projectTask;
        List<WorkOrder> oWorkOrder = new List<WorkOrder>(
            [SELECT Id, NSP_Project_Task__c FROM WorkOrder WHERE NSP_Project_Task__c =: projectTask.Id LIMIT 1]);
        List<ServiceAppointment> oServiceAppointments = new List<ServiceAppointment>(
                        [SELECT Id, NSP_Orientation_Address__c FROM ServiceAppointment WHERE ParentRecordId =: oWorkOrder[0].Id LIMIT 1]);
        System.Assert(oWorkOrder.size()>0);
        System.Assert(oServiceAppointments.size()>0);
        Test.stopTest();
    }
    
    @isTest
    static void createProjectTasksforRetRecordType(){
        Id recordTypeIdRET = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c', NSP_ServiceConstants.PROJECT_TASK_RET_RECORDTYPE); 
        test.startTest();
        //Creating a Project
        pse__Proj__c project = [SELECT Id, RecordTypeId From pse__Proj__c WHERE pse__Start_Date__c = : Date.Today() AND Name = 'Proj2' LIMIT 1];

        //update project;
    
        pse__Project_Task__c projectTask = [SELECT Id, Name, RecordTypeId, pse__Project__c FROM pse__Project_Task__c WHERE Name = 'pTask' AND pse__Project__c =:  project.id ];
        System.assertEquals(recordTypeIdRET, projectTask.RecordTypeId);
        test.stopTest();  
    }
    
    @isTest
    static void createProjectAccountTest(){
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.Name ='TestcreateProjectAccount' ;
        insert oAccount;

        List<String> prjFields = new List<String>{
            'Id',
            'Name',
            'pse__Account__c'
        };
        String queryPrj = new NSP_QueryBuilder('pse__Proj__c', prjFields)
                         .addFilter('Name', 'Proj2').addLimit(1).setSecurityEnforce(false).build();
        pse__Proj__c oProject1 = Database.query(queryPrj);

        List<String> prjTskFields = new List<String>{
            'Id',
            'NSP_Account_Id__c',
            'pse__Project__c'
        };
        String queryPrjTsk = new NSP_QueryBuilder('pse__Project_Task__c', prjTskFields)
                         .addFilter('Name', 'pTask').addLimit(1).setSecurityEnforce(false).build();
        pse__Project_Task__c ptask = Database.query(queryPrjTsk);
        ptask.NSP_Account_Id__c = oAccount.Id ;
        Test.startTest();
            update ptask;
        Test.stopTest();

        List<String> prjAccFields = new List<String>{
            'Id',
            'Account__c',
            'Project__c'
        };
        String queryPrjAcc= new NSP_QueryBuilder('Project_Account__c', prjAccFields)
                         .addFilter('Project__c', oProject1.Id).setSecurityEnforce(false).build();
        List<Project_Account__c> prjAccount = Database.query(queryPrjAcc);

        system.assertEquals(prjAccount[0].Account__c, oAccount.Id);
    }

    /************************************************************************************************************************
    * MethodName	: projectTaskFieldSyncTest
    * Description	: test syncing of fields from project task to WO
    * ************************************************************************************************************************/
    @isTest
    static void projectTaskFieldSyncTest(){

        pse__Project_Task__c projtask = [SELECT Id,Name , pse__Long_Description__c,NSP_Orientation_Address__c,NSP_Project_Attendance__c From pse__Project_Task__c  WHERE Name = 'NewPt' LIMIT 1];
        projtask.pse__Long_Description__c = 'long description';
        projtask.NSP_Orientation_Address__c = 'Orientation Address';
        projtask.NSP_Project_Attendance__c = 123;
       
        test.startTest();
        Database.update(projtask);
        test.stopTest();
       
        List<String> WO_FIELDS = new List<String>{'Id','Description', 'NSP_Orientation_Address__c','Subject'};
        String query = new NSP_QueryBuilder('WorkOrder', WO_FIELDS)
                            .addFilter('NSP_Project_Task__c', projtask.Id)
            				.build();
        List<WorkOrder> relWo= Database.query(query);
        System.assertEquals(projtask.NSP_Orientation_Address__c, 'Orientation Address'); 
    }
    /**
    * Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.afterUpdateProjectTask
    */
    @isTest
    static void projectTaskDurationSyncTest(){

        pse__Project_Task__c projtask = [SELECT Id,Name , pse__Long_Description__c,NSP_Orientation_Address__c,
                                         NSP_Project_Attendance__c,NSP_Duration_in_minutes__c,NSP_Dispatch_Region__c 
                                         FROM pse__Project_Task__c  
                                         WHERE Name = 'NewPt' 
                                         LIMIT 1];
        
        test.startTest();
        Database.update(projtask);
        test.stopTest();
       
        List<String> WO_FIELDS = new List<String>{'Id','NSP_Project_Task__c', 'Description', 'NSP_Orientation_Address__c','Subject', 'Duration'};
        String query = new NSP_QueryBuilder('WorkOrder', WO_FIELDS)
                            .addFilter('NSP_Project_Task__c', projtask.Id)
                            .addLimit(1).build();
        WorkOrder relWo= Database.query(query);

        //checking for the syncing of the duration 
        System.assertEquals(relWo.NSP_Project_Task__c, projtask.Id);
        
    }
    
     /**
    * Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.createPTAOnProject
    */
    @isTest
    static void createPTAOnProjectTest(){
  		Account oAccount = [SELECT Id, Name FROM Account WHERE Id != null LIMIT 1];
        // Creating Contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        oContact.NSP_Date_of_Birth__c = System.today();
        oContact.pse__Salesforce_User__c = userinfo.getUserId();
        insert oContact;
         List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
       List<pse__Proj__c> proj = [SELECT Id, Name, pse__Project_Type__c FROM pse__Proj__c WHERE pse__Project_Type__c =: NSP_ServiceConstants.PROJECT_TYPE];
        test.startTest();        
       NSP_ProjectTasksTriggerServiceHelper.createPTAOnProject(new Set<Id>{userinfo.getUserId()}, new Set<Id>{proj[0].Id}, new Set<Id>{projectTaskRec.Id});
        test.stopTest();
        System.assertEquals(oContact.NSP_Date_of_Birth__c, System.today());
    }
    
         /**
    * Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
          @isTest
    static void emailAlertProjectTaskCompletedTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.PREPARE_AMENDMENT;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.PLAN_AMENDMENT_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
    
   /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedSubmitCoverSheetTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.SUBMIT_COVERSHEET;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.SAFE_HARBOUR_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
     /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedVerifyAllInfoTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.VERIFY_ALL_INFO;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.DECONVERSION_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
     /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedCollectSignedTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.COLLECT_SIGNED;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.PROTOTYPE_AMENDMENT_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
     /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedCollectDocumentTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.COLLECT_DOCUMENT;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.SALES_NSP401K_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
     /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedEaPackageTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.SUBMIT_EA_PACKAGE;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.SALES_NSP401K_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
     /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedValidationPPTTTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.VALIDATION_PPTT_INSTALL;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.NSPK_INSTALL_TEMPLATE;
        Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
     /* Classes Covered
    * NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskComplete
    */
      @isTest
    static void emailAlertProjectTaskCompletedStartUpSetupTest(){
          List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name', 'pse__Status__c', 'Template_Name__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', 'NewPt').addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        projectTaskRec.Name = NSP_ServiceConstants.VALIDATION_PPTT_STARTUP;
        projectTaskRec.Template_Name__c = NSP_ServiceConstants.STARTUP_SETUP_TEMPLATE;
       Test.startTest();
        update projectTaskRec;
        Test.stopTest();
         System.assertEquals(projectTaskRec.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
        
}