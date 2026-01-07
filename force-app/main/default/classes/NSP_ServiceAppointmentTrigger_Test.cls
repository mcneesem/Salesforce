@isTest
private class NSP_ServiceAppointmentTrigger_Test {
    private static final String DESCRIPTION = 'Updated from test clas';
    private static final List<String> EVENT_FIELDS = new List<String>{
        'Id',
        'ShowAs',
        'Subject',
        'StartDateTime',
        'EndDateTime',
        'WhatId',
        'Location'
    };

    @testSetup
    private static void setupProjectTaskdata() {
        Service_Appointment_Settings__c settings = Service_Appointment_Settings__c.getOrgDefaults();
        settings.IsEnabledFutureSync__c = true;
        upsert settings;

        String pEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);
        Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'PEO_Project');


        User newUser = [select Id,NSP_Salesforce_Field_Service__c FROM User WHERE ID =: userInfo.getUserId()];
        newUser.NSP_Salesforce_Field_Service__c = 'Dispatcher';
        Update newUser;

        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

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
    private static void syncProjectTaskTest() {
        ServiceAppointment sappointment = [SELECT Id, EarliestStartTime, Description, NSP_Orientation_Address__c,Subject FROM ServiceAppointment WHERE Subject != NULL LIMIT 1];
        sappointment.EarliestStartTime = system.now().addHours(1);
        sappointment.Description = DESCRIPTION;
        sappointment.NSP_Orientation_Address__c = 'Orientation Address from SA';
        sappointment.Subject = 'Subject From SA';

        Test.startTest();
        Database.update(sappointment);
        Test.stopTest();

        WorkOrder workOrder = [SELECT Id, NSP_Project_Task__c, StartDate, Description,NSP_Orientation_Address__c FROM WorkOrder WHERE NSP_Project_Task__c != NULL  LIMIT 1 ];
        pse__Project_Task__c pTask = [SELECT Id, Name, pse__Long_Description__c, NSP_AccountId__c,NSP_Orientation_Address__c  FROM pse__Project_Task__c WHERE Id =: workOrder.NSP_Project_Task__c];

        System.assertEquals(DESCRIPTION, workOrder.Description,'Description Field Updated ');
        System.assertEquals('Orientation Address from SA', workOrder.NSP_Orientation_Address__c,'Orientation Address Field Updated ');
        System.assertEquals(DESCRIPTION, pTask.pse__Long_Description__c,'Description Field Updated ');
        System.assertEquals('Orientation Address from SA', pTask.NSP_Orientation_Address__c,'Description Field Updated ');
    }

    @isTest
    private static void syncProjectTaskScheduleTest() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        pse__Project_Task__c oProjectTask = [SELECT Id, Name, NSP_Percentage_Complete__c, pse__Start_Date_Time__c, pse__End_Date_Time__c, NSP_Create_Work_Order__c,NSP_Dispatch_Region__c,pse__Status__c
                                             FROM pse__Project_Task__c
                                             WHERE Name = 'Test rec 2'
                                             LIMIT 1];
        oProjectTask.pse__Start_Date_Time__c = System.Today().addDays(1);
        oProjectTask.pse__End_Date_Time__c = System.Today().addDays(2);
        oProjectTask.NSP_Create_Work_Order__c = true;
        oProjectTask.NSP_Dispatch_Region__c = 'Central';
        Update oProjectTask;

        WorkOrder Wo = [SELECT Id, NSP_Project_Task__c, StartDate, Description,NSP_Orientation_Address__c, Duration
                        FROM WorkOrder
                        WHERE NSP_Project_Task__c =:oProjectTask.Id LIMIT 1 ];

                        ServiceAppointment sappointment = [SELECT Id, Status,SchedEndTime, SchedStartTime,Description, OwnerId,ParentRecordId
                        FROM ServiceAppointment
                        WHERE ParentRecordId =:Wo.Id LIMIT 1];
        User curUser = [SELECT Id FROM User WHERE Id =: userInfo.getUserId() LIMIT 1];

        sappointment.Status = 'Scheduled';
        System.runAs(curUser){

            Test.startTest();
            Database.update(sappointment);
            Test.stopTest();

        }
        WorkOrder woUpdated = [SELECT Id, NSP_Project_Task__c, StartDate, Description,NSP_Orientation_Address__c, Duration ,Status
                        FROM WorkOrder
                        WHERE NSP_Project_Task__c =:oProjectTask.Id LIMIT 1 ];
                        pse__Project_Task__c oProjectTask1 = [SELECT Id, Name, NSP_Percentage_Complete__c, pse__Start_Date_Time__c, pse__End_Date_Time__c, NSP_Create_Work_Order__c,NSP_Dispatch_Region__c,pse__Status__c
                                             FROM pse__Project_Task__c
                                             WHERE Name = 'Test rec 2'
                                             LIMIT 1];
        System.assertEquals('Scheduled', woUpdated.Status,'Status Field Updated ');
        System.assertEquals('Scheduled', oProjectTask1.pse__Status__c,'Project Task Status Field Updated ');

    }

    @isTest
    private static void syncProjectTaskDuration() {
        ServiceAppointment sappointment = [SELECT Id, EarliestStartTime, Description, NSP_Orientation_Address__c,
                                           Subject, Duration
                                           FROM ServiceAppointment
                                           WHERE Id != null
                                           LIMIT 1];
            //updating Duration field
            sappointment.Duration = 60;

            Test.startTest();
            Database.update(sappointment);
            Test.stopTest();

            WorkOrder workOrder = [SELECT Id, NSP_Project_Task__c, StartDate, Description,NSP_Orientation_Address__c, Duration FROM WorkOrder WHERE Id != null LIMIT 1 ];
            pse__Project_Task__c pTask = [SELECT Id, Name, pse__Long_Description__c, NSP_AccountId__c,NSP_Orientation_Address__c, NSP_Duration_in_minutes__c  FROM pse__Project_Task__c WHERE Id =: workOrder.NSP_Project_Task__c];

            //checking for sync between Service Appointment & (work order and project task)
            System.assertEquals(sappointment.Duration, workOrder.Duration);
    }

    @isTest
    private static void syncProjectTaskTestNegative() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =: NSP_ServiceConstants.PEOSERVICE LIMIT 1];

        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newUser.ProfileId = profile.Id;
        newUser.UserName =  Integer.valueOf(math.rint(math.random() * 1000000))+ '@test' + UserInfo.getOrganizationId()+ '.org';

        ServiceAppointment sappointment = [SELECT Id, EarliestStartTime, Description FROM ServiceAppointment WHERE Id != null LIMIT 1];
        System.runAs(newUser) {
            Test.startTest();
            try {
                sappointment.EarliestStartTime = system.now().addHours(1);
                sappointment.Description = DESCRIPTION;
                Database.update(sappointment);
            }
            catch (DmlException ex) {
                System.assert(ex.getMessage().contains('INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY'));
            }
            Test.stopTest();
        }
        WorkOrder workOrder = [SELECT Id, NSP_Project_Task__c, StartDate, Description FROM WorkOrder WHERE Id != null LIMIT 1 ];
        pse__Project_Task__c pTask = [SELECT Id, Name, pse__Long_Description__c, NSP_AccountId__c  FROM pse__Project_Task__c WHERE Id =: workOrder.NSP_Project_Task__c];

        system.assertNotEquals(sappointment.Description, pTask.pse__Long_Description__c, 'Updated');
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

    @isTest
    private static void serviceAppointmentScheduledEventTest() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        //Given
        pse__Proj__c oproj = [SELECT Id, Name, Templates_Used__c FROM pse__Proj__c WHERE Templates_Used__c = 'Temp Used'];
        List<pse__Project_Task__c> oprojTask = [SELECT Id, Name, OwnerId FROM pse__Project_Task__c WHERE pse__Project__c =: oProj.Id];
        List<WorkOrder> workOrder2 = [SELECT Id, NSP_Project_Task__c, StartDate, Description, OwnerId FROM WorkOrder WHERE NSP_Project_Task__c =: oprojTask[0].Id];
        ServiceAppointment sappointment = [SELECT Id, NSP_IsDispatched__c,Status,SchedEndTime, SchedStartTime,Description, OwnerId FROM ServiceAppointment WHERE ParentRecordId =: workOrder2[0].Id LIMIT 1];
        sappointment.SchedStartTime = Date.today();
        sappointment.SchedEndTime = Date.today().addDays(1);
        sappointment.OwnerId = userInfo.getUserId();
        sappointment.Status = 'Scheduled';
        //When
        Test.startTest();
        update sappointment;
        Test.stopTest();
        //Then
        system.assertEquals( sappointment.Status, 'Scheduled');
    }

    @isTest
    private static void serviceAppointmentDispacthedEventTest() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        //Given
        pse__Proj__c oproj = [SELECT Id, Name, Templates_Used__c FROM pse__Proj__c WHERE Templates_Used__c = 'Temp Used'];
        List<pse__Project_Task__c> oprojTask = [SELECT Id, Name, OwnerId FROM pse__Project_Task__c WHERE pse__Project__c =: oProj.Id];
        List<WorkOrder> workOrder3 = [SELECT Id, NSP_Project_Task__c, StartDate, Description, OwnerId FROM WorkOrder WHERE NSP_Project_Task__c =: oprojTask[0].Id];
        ServiceAppointment sappointment = [SELECT Id, NSP_IsDispatched__c,Status,SchedEndTime, SchedStartTime,Description, OwnerId FROM ServiceAppointment WHERE ParentRecordId =: workOrder3[0].Id LIMIT 1];
        sappointment.SchedStartTime = Date.today();
        sappointment.SchedEndTime = Date.today().addDays(1);
        sappointment.Status = 'Scheduled';
        sappointment.OwnerId = userInfo.getUserId();
        update sappointment;
        FSL.GlobalAPIS.addStatusTransition('Scheduled','Dispatched');
        sappointment.Status = 'Dispatched';
        //When
        Test.startTest();
        update sappointment;
        Test.stopTest();
        //Then
      system.assertEquals( sappointment.Status, 'Dispatched');
    }

    @isTest
    private static void serviceAppointmentCancelledEventTest() {
        //Given
        ServiceAppointment sappointment = [SELECT Id, Status FROM ServiceAppointment WHERE Subject = 'Subject Abc' LIMIT 1];
        sappointment.Status = 'Canceled';
        //When
        Test.startTest();
        update sappointment;
        Test.stopTest();
        //Then
        system.assertEquals(0, [ SELECT COUNT() FROM Event WHERE WhatId =: sappointment.Id ],'No Event related to Cancelled SA');
    }

    @isTest
    private static void UpdateSaRelatedEventTest() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        List<String> EVENT_FIELD = new List<String>{'Id', 'Subject'};
        //Given
        pse__Proj__c oproj = [SELECT Id, Name, Templates_Used__c FROM pse__Proj__c WHERE Templates_Used__c = 'Temp Used' LIMIT 1];
        pse__Project_Task__c oprojTask = [SELECT Id, Name, OwnerId FROM pse__Project_Task__c WHERE pse__Project__c =: oProj.Id LIMIT 1];
        WorkOrder workOrder2 = [SELECT Id, NSP_Project_Task__c, StartDate, Description, OwnerId FROM WorkOrder WHERE NSP_Project_Task__c =: oprojTask.Id LIMIT 1];
        ServiceAppointment sappointment = [SELECT Id, NSP_IsDispatched__c,Subject,Status,SchedEndTime, SchedStartTime,Description,NSP_Orientation_Address__c, OwnerId FROM ServiceAppointment WHERE ParentRecordId =: workOrder2.Id LIMIT 1];
        sappointment.SchedStartTime = Date.today();
        sappointment.SchedEndTime = Date.today().addDays(1);
        sappointment.OwnerId = userInfo.getUserId();
        sappointment.Status = 'Scheduled';
        update sappointment;

        Event newEvent = new Event();
        newEvent.WhatId = sappointment.id;
        newEvent.ShowAs = 'Free';
        newEvent.Subject = sappointment.Subject;
        newEvent.Description = sappointment.Description;
        newEvent.Location = sappointment.NSP_Orientation_Address__c;
        newEvent.StartDateTime = sappointment.SchedStartTime;
        newEvent.EndDateTime = sappointment.SchedEndTime;
        insert newEvent;

        sappointment.Subject = 'Updated Subject';
        //When
        Test.startTest();
        update sappointment;
        Test.stopTest();
        //Then
        String query = new NSP_QueryBuilder('Event', EVENT_FIELD)
                            .addFilter('WhatId', sappointment.Id).addLimit(1).build();
        Event  relatedEvent = Database.query(query);
        system.assertEquals( relatedEvent.Subject, '[SF] Updated Subject');
    }

    @isTest
    private static void eventDeletionTest() {
        FSL.GlobalAPIS.addStatusTransition('Unscheduled', 'Scheduled');
        FSL.GlobalAPIS.addStatusTransition('Scheduled', 'Canceled');
        List<String> EVENT_FIELD = new List<String>{'Id', 'Subject'};
        //Given
        pse__Proj__c oproj = [SELECT Id, Name, Templates_Used__c FROM pse__Proj__c WHERE Templates_Used__c = 'Temp Used' LIMIT 1];
        pse__Project_Task__c oprojTask = [SELECT Id, Name, OwnerId FROM pse__Project_Task__c WHERE pse__Project__c =: oProj.Id LIMIT 1];
        WorkOrder workOrder2 = [SELECT Id, NSP_Project_Task__c, StartDate, Description, OwnerId FROM WorkOrder WHERE NSP_Project_Task__c =: oprojTask.Id LIMIT 1];
        ServiceAppointment sappointment = [SELECT Id, NSP_IsDispatched__c,Subject,Status,SchedEndTime, SchedStartTime,Description,NSP_Orientation_Address__c, OwnerId FROM ServiceAppointment WHERE ParentRecordId =: workOrder2.Id LIMIT 1];
        sappointment.SchedStartTime = Date.today();
        sappointment.SchedEndTime = Date.today().addDays(1);
        sappointment.OwnerId = userInfo.getUserId();
        sappointment.Status = 'Scheduled';
        update sappointment;

        Event newEvent = new Event();
        newEvent.WhatId = sappointment.id;
        newEvent.ShowAs = 'Free';
        newEvent.Subject = sappointment.Subject;
        newEvent.Description = sappointment.Description;
        newEvent.Location = sappointment.NSP_Orientation_Address__c;
        newEvent.StartDateTime = sappointment.SchedStartTime;
        newEvent.EndDateTime = sappointment.SchedEndTime;
        insert newEvent;

        sappointment.Status = 'Canceled';
        //When
        Test.startTest();
        update sappointment;
        Test.stopTest();
    }

}
//