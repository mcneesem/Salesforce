/**
* @description  : Test Class for NSP_AssignedResourceTriggerHelper .
* @date 06/30/2023
* Name : NSP_AssignedResourceTriggerHelper_Test
*/
@isTest
private class NSP_AssignedResourceTriggerHelper_Test {
	private static final String DESCRIPTION = 'Updated from test class';
   
    
    /***********************************************************************************************
    * MethodName: testData
    * Description : Test Data Method
    * ********************************************************************************************/
    
    @testSetup
    static void setupProjectTaskdata(){
        String pEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c', NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        Id peoProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'PEO_Project');
        
        test.startTest();
         User newUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser2',
            Email = 'testuser22121@insperity.com',
            Username = 'testuser1=221@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            NSP_Salesforce_Field_Service__c = 'Dispatcher',
            NSP_Dispatch_Region__c = 'Central',
            LocaleSidKey = 'en_US'
            );
        insert newUser;
       
        //Creating Account
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        
        // Creating Contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.Email = 'abctestexamplyxyz@test.com.abc';
        insert oContact;
        
        // Creating Project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.Name = 'Proj1';
        oProject.RecordTypeId = peoProjectRecordTypeId;
        oProject.Templates_Used__c = 'Temp Used';
        oProject.pse__Start_Date__c = Date.newInstance(2023, 1, 1);
        oProject.pse__Project_Type__c = 'Implementation';
        insert oProject;
        
        // Creating Project Task
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.Name = 'Test rec';
        oProjectTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        oProjectTask.NSP_Percentage_Complete__c = '100%';
        oProjectTask.pse__Start_Date_Time__c = system.now();
        oProjectTask.pse__End_Date_Time__c = system.now().addMinutes(60);
        oProjectTask.NSP_Create_Work_Order__c = true;
        oProjectTask.OwnerId = userinfo.getUserId();
        oProjectTask.NSP_Dispatch_Region__c = 'Central';
        insert oProjectTask;
        
        WorkOrder relWo = new WorkOrder();
        relWo.Status = 'Unscheduled';
        relWo.NSP_Project_Task__c = oProjectTask.Id;
        insert relWo;

        ServiceAppointment saRec = new ServiceAppointment();
        saRec.Subject = 'Subject Abc';
        saRec.Status = 'Unscheduled';
        saRec.EarliestStartTime = Date.newInstance(2016, 12, 9);
        saRec.DueDate = Date.newInstance(2024, 12, 9);
        saRec.ParentRecordId = relWo.Id;
        insert saRec;
		
        List<ServiceResource> srvList = new List<ServiceResource>();
        ServiceResource  srv = new ServiceResource();
        srv.IsActive= true;
        srv.ResourceType= 'T';
        srv.Name = 'Test01';
        srv.RelatedRecordId = newUser.Id;
        srvList.add(srv);
        insert srvList;
       
        test.stopTest();
    }  
    
    @isTest
    static void syncProjTaskOwnerSATest(){
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
        test.stopTest();
        //Querying again to get latest data after future method calls
        ServiceAppointment sappointment1 = [SELECT Id, NSP_IsDispatched__c,Status,SchedEndTime, SchedStartTime,Description, OwnerId FROM ServiceAppointment WHERE ParentRecordId =: workOrder1[0].Id LIMIT 1];
        System.Assert(sappointment1.OwnerId == srv.RelatedRecordId);
    }
    
}