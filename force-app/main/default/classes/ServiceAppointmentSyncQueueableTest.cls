@isTest
private class ServiceAppointmentSyncQueueableTest {
    private static final String DESCRIPTION = 'Updated from test clas';

    @testSetup
    private static void setupProjectTaskdata() {
        Service_Appointment_Settings__c settings = Service_Appointment_Settings__c.getOrgDefaults();
        settings.IsEnabledQueueableSync__c = true;
        //settings.IsEnabledFutureSync__c = true;
        upsert settings;
        ServiceAppointmentSyncQueueable.testHandleException( null , null );

        String pEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);
        Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'PEO_Project');


        User newUser = [select Id,NSP_Salesforce_Field_Service__c FROM User WHERE ID =: userInfo.getUserId()];
        newUser.NSP_Salesforce_Field_Service__c = 'Dispatcher';
        Update newUser;

        //Creating Account
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);

        // Creating Contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert oContact;

        test.startTest();
        // Creating Project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.Name = 'Proj1';
        oProject.RecordTypeId = peoProjectRecordTypeId;
        oProject.Templates_Used__c = 'Temp Used';
        oProject.pse__Start_Date__c = Date.newInstance(2023, 1, 1);
        oProject.pse__Project_Type__c = 'Implementation';
        insert oProject;

        pse__Proj__c oProject1 = (pse__Proj__c) NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults');
        oProject1.Name = 'Proj2';
        oProject1.RecordTypeId = retProjectRecordTypeId;
        oProject1.pse__Start_Date__c = Date.Today();
        oProject1.pse__End_Date__c = System.Today().addDays(100);
        insert oProject1;

        WorkType oWorkType = (WorkType)NSP_TestExtendedDataFactory.createSObject(new WorkType(), 'NSP_TestDataFactory.WorkTypeDefaults', false);
        oWorkType.Name = 'Generic';
        Database.insert(oWorkType);

        // Creating Project Task
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.Name = 'Test rec';
        oProjectTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask.NSP_Percentage_Complete__c = '100%';
        oProjectTask.pse__Start_Date_Time__c = system.now();
        oProjectTask.pse__End_Date_Time__c = system.now().addMinutes(60);
        oProjectTask.NSP_Create_Work_Order__c = true;
        oProjectTask.OwnerId = newUser.Id;
        oProjectTask.NSP_Dispatch_Region__c = 'Central';
        insert oProjectTask;

        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.Name = 'Test rec 2';
        oProjectTask2.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask.OwnerId = newUser.Id;
        insert oProjectTask2;

        test.stopTest();

        WorkOrder relWo = new WorkOrder();
        relWo.Status = 'Unscheduled';
        relWo.NSP_Project_Task__c = oProjectTask.Id;
        insert relWo;

        ServiceAppointment saRec = new ServiceAppointment();
        saRec.Subject = 'Subject Abc';
        saRec.Status = 'None';
        saRec.EarliestStartTime = Date.newInstance(2016, 12, 9);
        saRec.DueDate = Date.newInstance(2024, 12, 9);
        saRec.ParentRecordId = relWo.Id;
        insert saRec;

        ServiceResource  srv = new ServiceResource();
        srv.IsActive= true;
        srv.ResourceType= 'T';
        srv.Name = 'Test01';
        srv.RelatedRecordId = userInfo.getUserId();
        insert srv;
    }

    @isTest
    private static void syncProjTaskOwnerSATest() {
        Test.startTest();
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        pse__Proj__c oproj = [SELECT Id, Name, Templates_Used__c FROM pse__Proj__c WHERE Templates_Used__c = 'Temp Used'];
        List<pse__Project_Task__c> oprojTask = [SELECT Id, Name, OwnerId FROM pse__Project_Task__c WHERE pse__Project__c =: oProj.Id];
        List<WorkOrder> workOrder1 = [SELECT Id, NSP_Project_Task__c, StartDate, Description, OwnerId FROM WorkOrder WHERE NSP_Project_Task__c =: oprojTask[0].Id];

        ServiceAppointment sappointment = [SELECT Id, NSP_IsDispatched__c,Status,SchedEndTime, SchedStartTime,Description, OwnerId FROM ServiceAppointment WHERE ParentRecordId =: workOrder1[0].Id LIMIT 1];
        sappointment.Description = DESCRIPTION;
        sappointment.SchedEndTime = system.today().addDays(10);
        sappointment.SchedStartTime =system.today().addDays(1);
        Database.update(sappointment);

        ServiceResource srv = [select Id,Name, RelatedRecordId
                              FROM ServiceResource
                              WHERE Name = 'Test01'
                              LIMIT 1];

        OperatingHours opHrs = new OperatingHours();
        opHrs.Name ='EST Operating Hours';
        insert opHRS;

        ServiceTerritory serTer = new ServiceTerritory();
        serTer.IsActive = true;
        serTer.Name = 'Test';
        serTer.OperatingHoursId = opHrs.Id;
        insert serTer;

        ServiceTerritoryMember stm = new ServiceTerritoryMember();
        stm.ServiceResourceId = srv.Id;
        stm.ServiceTerritoryId = serTer.Id;
        stm.EffectiveStartDate = system.today();
        insert stm;

        AssignedResource assRes = new AssignedResource();
        assRes.ServiceAppointmentId = sappointment.Id;
        assRes.ServiceResourceId = srv.Id;
        insert assRes;

        //checking whether the owner Id is updated after insertion of service resource coverage of syncProjTaskOwnerSA method
        System.Assert(sappointment.OwnerId == srv.RelatedRecordId);
        System.Assert(workOrder1[0].OwnerId == srv.RelatedRecordId);
        System.Assert(oprojTask[0].OwnerId == srv.RelatedRecordId);
    }

}
//