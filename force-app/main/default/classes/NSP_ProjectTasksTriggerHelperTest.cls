@isTest
public class NSP_ProjectTasksTriggerHelperTest {
     
    public static final String pEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        public static final String bPS_ProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE).getRecordTypeId();
		public static final Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        public static final String ClientRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Client_Reinstatement).getRecordTypeId();
    
    @testSetup
    public static void setupProjectTaskdata(){
        //Test Setup

        List<Account> accList = new List<Account>();
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        oAccount.NSP_AIMS_Client__c = '8900';
        accList.add(oAccount);
        
        Account acc2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc2.Name = 'Test Account 2';
        accList.add(acc2);
        INSERT accList;
        
        Group terminationQueueEmailAddress = [SELECT Id, Email from Group WHERE Type = 'Queue' and DeveloperNAME = 'Termination_Team'];
		
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Account__c = accList[0].Id;
        accTeam.NSP_Role__c = NSP_ServiceConstants.HRSpecialist;
        accTeam.NSP_User__c = UserInfo.getUserId();
        Insert accTeam;
            
        Asset oAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', true);
        NSP_Sub_Client__c oSubClient = (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', true);
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert oContact;

        Case oCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', true);
        
        
        List<pse__Proj__c> nProjectList = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = Date.Today();
        oPRoject.Case__c = oCase.Id;
        oProject.pse__End_Date__c = System.Today().addDays(100);
        oProject.pse__Account__c= oAccount.Id;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.pse__Project_Type__c=NSP_ServiceConstants.ImplementationProjectType;
        oProject.NSP_Asset_Implementation_Project__c =True;
        nProjectList.add(oProject);
        
        pse__Proj__c oProject1 = (pse__Proj__c) NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults');
        oProject1.Name = 'Proj2';
        oProject1.pse__Start_Date__c = Date.Today();
        oProject1.Case__c = oCase.Id;
        oProject1.pse__End_Date__c = System.Today().addDays(100);
        oProject1.pse__Account__c= acc2.Id;
        nProjectList.add(oProject1);
        
         pse__Proj__c oPeoProject = (pse__Proj__c) NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults');
        oPeoProject.Name = 'PeoProject';
        oPeoProject.pse__Start_Date__c = Date.Today();
        oPeoProject.Case__c = oCase.Id;
        oPeoProject.pse__End_Date__c = System.Today().addDays(100);
        oPeoProject.pse__Account__c= acc2.Id;
        nProjectList.add(oPeoProject);
        
        pse__Proj__c hcmProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        hcmProject.Name = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.pse__Start_Date__c = Date.Today();
        hcmProject.pse__Account__c= oAccount.Id;
        hcmProject.TemplateName__c = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProject.Project_Implementer__c = UserInfo.getUserId();        
        nProjectList.add(hcmProject);
        test.startTest();
        insert nProjectList;
        
        List<pse__Project_Task__c> nProjectTaskList = new List<pse__Project_Task__c>();
        pse__Project_Task__c discoveryProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c());
        discoveryProjectTask.Name = NSP_ServiceConstants.PROJECT_TASK_DISCOVERY;
        discoveryProjectTask.pse__Project__c = hcmProject.Id;
        discoveryProjectTask.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        discoveryProjectTask.NSP_Template_Generated__c = true;
        discoveryProjectTask.RecordTypeId = bPS_ProjectTaskRecordTypeId;
        nProjectTaskList.add(discoveryProjectTask);
        
        pse__Project_Task__c configProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c());
        configProjectTask.Name = NSP_ServiceConstants.CONFIGURATION_TASK;
        configProjectTask.pse__Project__c = hcmProject.Id;
        configProjectTask.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        configProjectTask.NSP_Template_Generated__c = true;
        configProjectTask.RecordTypeId = bPS_ProjectTaskRecordTypeId;
 		nProjectTaskList.add(configProjectTask);
        
        pse__Project_Task__c goLiveProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c());
        goLiveProjectTask.Name = NSP_ServiceConstants.GO_LIVE;
        goLiveProjectTask.pse__Project__c = hcmProject.Id;
        goLiveProjectTask.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        goLiveProjectTask.NSP_Template_Generated__c = true;
        goLiveProjectTask.RecordTypeId = bPS_ProjectTaskRecordTypeId;
 		nProjectTaskList.add(goLiveProjectTask);
        
        pse__Project_Task__c letterReceived = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c());
        letterReceived.Name = 'Letter Received (Termination Letter)';
        letterReceived.pse__Project__c = hcmProject.Id;
        letterReceived.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        letterReceived.NSP_Template_Generated__c = true;
        letterReceived.RecordTypeId = bPS_ProjectTaskRecordTypeId;
 		nProjectTaskList.add(letterReceived);
		
         pse__Project_Task__c itaTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c());
        itaTask.Name = 'Notify ITA if term date is today';
        itaTask.pse__Project__c = hcmProject.Id;
        itaTask.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        itaTask.NSP_Template_Generated__c = true;
        itaTask.RecordTypeId = bPS_ProjectTaskRecordTypeId;
 		nProjectTaskList.add(itaTask);

        insert nProjectTaskList;
        
        pse__Milestone__c milestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestone.pse__Project__c = oProject.id;
        insert milestone;

        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask1.Name = 'pTask1';
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.pse__Milestone__c = milestone.id;
        oProjectTask1.NSP_Account_Id__c = oAccount.Id;
        oProjectTask1.NSP_Template_Generated__c = true;
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.RecordTypeId = pEOProjectTaskRecordTypeId;

        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask2.Name = 'pTask2';
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.NSP_of_Days_Offset__c = 10;
        oProjectTask2.NSP_Offset_Date__c = 'Asset Renewal Date';
        oProjectTask2.pse__Milestone__c = milestone.id;
        oProjectTask2.NSP_Template_Generated__c = true;
        oProjectTask2.NSP_Account_Id__c = oAccount.Id;
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.pse__Parent_Task__c = ItaTask.Id;
        oProjectTask2.RecordTypeId = pEOProjectTaskRecordTypeId;
        
        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.Name = 'Preceding Task';
        oProjectTask.Responsible_Party__c = NSP_ServiceConstants.PROJECTTASKRETCOMPLIANCE;
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.NSP_Template_Generated__c = true;
        oProjectTask.RecordTypeId = pEOProjectTaskRecordTypeId;

        pse__Project_Task__c oBPSProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oBPSProjectTask.Name = 'BPS Preceding Task';
        oBPSProjectTask.Responsible_Party__c = NSP_ServiceConstants.PROJECTTASKRETCOMPLIANCE;
        oBPSProjectTask.pse__Project__c = oProject.Id;
        oBPSProjectTask.NSP_Template_Generated__c = true;
        oBPSProjectTask.RecordTypeId = bPS_ProjectTaskRecordTypeId;
        
        pse__Project_Task__c oPEOProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oPEOProjectTask.Name = 'PEO Preceding Task';
        oPEOProjectTask.pse__Project__c = oPeoProject.Id;
        oPEOProjectTask.NSP_Template_Generated__c = true;
        oPEOProjectTask.RecordTypeId = pEOProjectTaskRecordTypeId;
        
        pse__Project_Task__c oPEODependingTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oPEODependingTask.Name = 'PEO Depending Task';
        oPEODependingTask.NSP_Template_Generated__c = true;
        oPEODependingTask.pse__Project__c = oPeoProject.Id;
        oPEODependingTask.RecordTypeId = pEOProjectTaskRecordTypeId;
    
            
        pse__Project_Task__c oDependingTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oDependingTask.Name = 'Depending Task';
        oDependingTask.Responsible_Party__c = NSP_ServiceConstants.PROJECTTASKRETEXECUTIVE;
        oDependingTask.NSP_Template_Generated__c = true;
        oDependingTask.pse__Project__c = oProject.Id;

        pse__Project_Task__c oBPSDependingTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oBPSDependingTask.Name = 'BPS Depending Task';
        oBPSDependingTask.Responsible_Party__c = NSP_ServiceConstants.PROJECTTASKRETEXECUTIVE;
        oBPSDependingTask.pse__Project__c = oProject.Id;
        oBPSDependingTask.NSP_Template_Generated__c = true;
        oBPSDependingTask.RecordTypeId = BPS_ProjectTaskRecordTypeId;
        
        pse__Project_Task__c oProjectTask9 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask9.Name = NSP_ServiceConstants.PayCodeEmpTask;
        oProjectTask9.pse__Project__c = oProject.Id;
        oProjectTask9.pse__Milestone__c = milestone.id;
        oProjectTask9.NSP_Template_Generated__c = true;
        oProjectTask9.RecordTypeId = pEOProjectTaskRecordTypeId;
        
        pse__Project_Task__c oProjectTask10 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask10.Name = NSP_ServiceConstants.ClientOptumTask;
        oProjectTask10.pse__Project__c = oProject.Id;
        oProjectTask10.pse__Milestone__c = milestone.id;
        oProjectTask10.NSP_Template_Generated__c = true;
        oProjectTask10.RecordTypeId = pEOProjectTaskRecordTypeId;
        
        pse__Project_Task__c oProjectTask11 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask11.Name = NSP_ServiceConstants.PTOTask;
        oProjectTask11.pse__Project__c = oProject.Id;
        oProjectTask11.pse__Milestone__c = milestone.id;
        oProjectTask11.NSP_Template_Generated__c = true;
        oProjectTask11.RecordTypeId = pEOProjectTaskRecordTypeId;
        
        pse__Project_Task__c oProjectTask12 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask12.Name = 'projTask1';
        oProjectTask12.pse__Project__c = oProject1.Id;
        oProjectTask12.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask12.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        oProjectTask12.NSP_Percentage_Complete__c = '50%';
        
        pse__Project_Task__c oProjectTask13 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask13.Name = 'projTask2';
        oProjectTask13.pse__Project__c = oProject1.Id;
        oProjectTask13.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask13.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        oProjectTask13.NSP_Percentage_Complete__c = '75%';
        
        pse__Project_Task__c oProjectTask14 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask14.Name = 'projTask3';
        oProjectTask14.pse__Project__c = oProject1.Id;
        oProjectTask14.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask14.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        oProjectTask14.NSP_Percentage_Complete__c = '25%';

        pse__Project_Task__c oProjectTask15 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask15.pse__Project__c = oProject.Id;
        oProjectTask15.Name = 'NewPt';
        oProjectTask15.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask15.NSP_Create_Work_Order__c = true;
        oProjectTask15.NSP_Dispatch_Region__c = 'FSO Project Manager National';

        pse__Project_Task__c oProjectTask16 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask16.pse__Project__c = oProject.Id;
        oProjectTask16.Name = 'DurationPt';
        oProjectTask16.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask16.NSP_Create_Work_Order__c = true;
        oProjectTask16.NSP_Dispatch_Region__c = 'FSO Project Manager National';
        oProjectTask16.NSP_Duration_in_minutes__c = 60;
        oProjectTask16.pse__Start_Date_Time__c = DateTime.now();
        oProjectTask16.pse__End_Date_Time__c = DateTime.now().addMinutes(60);
        
        pse__Project_Task__c oProjectTask17 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask17.pse__Project__c = oProject.Id;
        oProjectTask17.Name = 'Schedule deconversion date';
        oProjectTask17.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask17.pse__Start_Date_Time__c = DateTime.now();
		oProjectTask17.pse__End_Date_Time__c = DateTime.now().addMinutes(60);
        insert new List<pse__Project_Task__c> {oProjectTask1, oProjectTask2, oProjectTask, oBPSProjectTask, oDependingTask, oBPSDependingTask,oProjectTask9,oProjectTask10,oProjectTask11, oProjectTask12, oProjectTask13, oProjectTask14,oProjectTask15,oProjectTask16,oProjectTask17,oPEOProjectTask,oPEODependingTask};
        List<NSP_Termination_Form__c> terminationList = new List<NSP_Termination_Form__c>();
        NSP_Termination_Form__c oTerminationForm = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm.NSP_Project_Task__c = oDependingTask.Id;
        oTerminationForm.NSP_Client_Term_Date__c = System.today();
        terminationList.add(oTerminationForm);
        
        NSP_Termination_Form__c oTerminationForm1 = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm1.NSP_Project_Task__c = letterReceived.Id;
        oTerminationForm1.NSP_Client_Term_Date__c = System.today();
        oTerminationForm1.NSP_Notes_Comments__c = 'Test Comments';
        terminationList.add(oTerminationForm1);
        
        NSP_Termination_Form__c oTerminationForm2 = (NSP_Termination_Form__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults', false);
        oTerminationForm2.NSP_Project_Task__c = oPEOProjectTask.Id;
        oTerminationForm2.NSP_Client_Term_Date__c = System.today();
        oTerminationForm2.RecordTypeId = ClientRecordTypeId;
        terminationList.add(oTerminationForm2);
        
        insert terminationList;
        
        List<pse__Project_Task__c> nProjectTaskListToUpdate = new List<pse__Project_Task__c>();
        letterReceived.pse__Status__c = 'Complete';
        
        itaTask.pse__Status__c = 'Complete';
        nProjectTaskListToUpdate.add(itaTask);
        
		Test.stopTest();
        
        pse__Project_Task_Assignment__c oProjectTaskAssignment = (pse__Project_Task_Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task_Assignment__c(), 'NSP_TestDataFactory.ProjectTaskAssignmentDefaults', false);
        oProjectTaskAssignment.pse__Resource__c = oContact.Id;
        oProjectTaskAssignment.pse__Resource_Role__c = NSP_ServiceConstants.PTASSIGNMENTROLE;
        oProjectTaskAssignment.NSP_Priority__c = 2;
        oProjectTaskAssignment.pse__Project_Task__c = oDependingTask.Id;
        insert oProjectTaskAssignment;
       
        pse__Project_Task_Assignment__c oBPSProjectTaskAssignment = (pse__Project_Task_Assignment__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task_Assignment__c(), 'NSP_TestDataFactory.ProjectTaskAssignmentDefaults', false);
        oBPSProjectTaskAssignment.pse__Resource__c = oContact.Id;
        oBPSProjectTaskAssignment.pse__Resource_Role__c = NSP_ServiceConstants.PTASSIGNMENTROLE;
        oBPSProjectTaskAssignment.NSP_Priority__c = 2;
        oBPSProjectTaskAssignment.pse__Project_Task__c = oBPSDependingTask.Id;
        insert oBPSProjectTaskAssignment;
             
        pse__Project_Task_Dependency__c oProjectDependency  = new pse__Project_Task_Dependency__c();
        oProjectDependency.pse__Dependent_Task__c = oDependingTask.Id;
        oProjectDependency.pse__Preceding_Task__c = oProjectTask.Id;

        pse__Project_Task_Dependency__c oBPSProjectDependency  = new pse__Project_Task_Dependency__c();
        oBPSProjectDependency.pse__Dependent_Task__c = oBPSDependingTask.Id;
        oBPSProjectDependency.pse__Preceding_Task__c = oBPSProjectTask.Id;
        
		pse__Project_Task_Dependency__c oPeoProjectDependency  = new pse__Project_Task_Dependency__c();
        oPeoProjectDependency.pse__Dependent_Task__c = oPEODependingTask.Id;
        oPeoProjectDependency.pse__Preceding_Task__c = oPEOProjectTask.Id;
        
        insert new List<pse__Project_Task_Dependency__c>{oProjectDependency, oBPSProjectDependency, oPeoProjectDependency};
        
        ServiceResource sr = new ServiceResource();
        sr.Name = 'Test';
        sr.RelatedRecordId = UserInfo.getUserId();
        INSERT sr;
        
    }
    /**
    * Classes Covered
    * NSP_ProjectTasksTriggerHandler.afterUpdate
    * NSP_ProjectTasksTriggerHelper.notifyDependentTaskResources
    * NSP_ProjectTasksTriggerHelper.sendNotificationToDependentResource
    */
    @isTest
    public static void handleMilestoneCompletion(){
        List<pse__Project_Task__c> lPrecedingTasks = new List<pse__Project_Task__c>([SELECT Id,pse__Status__c FROM pse__Project_Task__c WHERE Name = 'Preceding Task']);
        Test.startTest();
        lPrecedingTasks[0].pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        update lPrecedingTasks;
        lPrecedingTasks = new List<pse__Project_Task__c>([SELECT Id,pse__Status__c FROM pse__Project_Task__c WHERE NAME = 'BPS Preceding Task']);
        lPrecedingTasks[0].pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        update lPrecedingTasks;

        Test.stopTest();

        //System.assertEquals(2,Limits.getFutureCalls());
    }
    
    /**
    * Classes Covered
    * NSP_ProjectTasksTriggerHandler.afterUpdate
    * NSP_ProjectTasksTriggerHelper.bellNotification
    * 
    */
    @isTest
    public static void testBellNotification(){
        String PEOProjectTaskRecordTypeIds = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        
        Test.startTest();
        List<pse__Project_Task__c> peoPrecedingTasks = new List<pse__Project_Task__c>([SELECT Id,pse__Status__c,Recordtypeid  FROM pse__Project_Task__c WHERE Name = 'PEO Preceding Task' Limit 1]);
        ID termProjectId = peoPrecedingTasks[0].Id;
        List<NSP_Termination_Form__c> peoTermFormList = new List<NSP_Termination_Form__c>([SELECT Id,NSP_Project_Task__c,ownerId FROM NSP_Termination_Form__c WHERE NSP_Project_Task__c =: termProjectId ]);
        peoTermFormList[0].NSP_Status__c = 'Term Team Approved';
        update peoTermFormList;
        peoPrecedingTasks[0].recordTypeId =PEOProjectTaskRecordTypeIds;
        peoPrecedingTasks[0].pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        update peoPrecedingTasks;
        Test.stopTest();
        system.assertEquals(peoPrecedingTasks[0].pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);

       
    }

    /**
    * Classes Covered
    * NSP_ProjectTasksTriggerHelper.checkRelatedTerminationsFormStatus
    */
    @isTest
    public static void testcheckRelatedTerminationsFormStatus(){
        List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT Id FROM pse__Project_Task__c WHERE Name = 'Depending Task']);
        Test.startTest();
       try{
            update new pse__Project_Task__c(Id = lProjectTasks[0].Id, pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE);
        }catch(Exception ex){
            System.assertNotEquals(NSP_ServiceConstants.TASKCOMPLETE, [SELECT Id,pse__Status__c FROM pse__Project_Task__c WHERE Name = 'Depending Task']?.pse__Status__c);
        }
        List<NSP_Termination_Form__c> lTerminationFroms = new List<NSP_Termination_Form__c>([SELECT Id FROM NSP_Termination_Form__c WHERE Id != NULL LIMIT 1]);
        lTerminationFroms[0].NSP_Status__c = NSP_ServiceConstants.TERMINATION_FORM_APPROVED_STATUS;
        update lTerminationFroms;
        System.assertEquals(lTerminationFroms[0].NSP_Status__c, NSP_ServiceConstants.TERMINATION_FORM_APPROVED_STATUS);
        Test.stopTest();
    }

    /**
    * Classes Covered
    * NSP_ProjectTasksTriggerHandler.afterUpdate
    * NSP_ProjectTasksTriggerHelper.calculateNumberOfCompletedAndCancelledProjectTask
    */
    @isTest
    public static void populateNumberOfCompletedProjectTask(){
         String PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_TASK_SOBJECT_TYPE,NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        List<pse__Project_Task__c> projectTasks = [SELECT Id, pse__Status__c FROM pse__Project_Task__c WHERE pse__Milestone__r.Name = 'PMilestone1' AND Name IN ('pTask1', 'pTask2')];
        Test.startTest();
        for(pse__Project_Task__c pTask : projectTasks){
            pTask.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
            pTask.pse__Synchronize_Milestone_And_Task__c = false;
            pTask.recordTypeId = PEOProjectTaskRecordTypeId;
            pTask.Name = NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK;
        }
        update projectTasks;
        pse__Milestone__c milestone = [SELECT NSP_NumberOfCompletedProjectTask__c FROM pse__Milestone__c  WHERE Name ='PMilestone1' LIMIT 1];
        System.assertEquals(1, projectTasks.size());
        Test.stopTest();
    }

    @isTest
    public static void markParentProjectCancelled(){
        test.startTest();
        pse__Proj__c project1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project1.pse__Start_Date__c = Date.Today();
        insert project1;

        pse__Proj__c project2 = [SELECT id, pse__Parent_Project__c FROM pse__Proj__c WHERE Id != null LIMIT 1];
        project2.pse__Parent_Project__c = project1.id;
        update project2;
        
        pse__Project_Task__c projectTasks = [SELECT Id,pse__Status__c FROM pse__Project_Task__c WHERE Name = : 'pTask2'];
        projectTasks.pse__Project__c = project2.id;
        projectTasks.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSCOMPLETED;
        projectTasks.Name = NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK;
       system.assertEquals(projectTasks.pse__Status__c, NSP_ServiceConstants.PROJECTSTATUSCOMPLETED);
        test.stopTest();
    }

    @isTest
    public static void calculatePercentageCompleteTest(){
        test.startTest();
        List<pse__Project_Task__c> projectTasks = [SELECT NSP_PercentageCompleteFormula__c,pse__Status__c FROM pse__Project_Task__c WHERE Name = 'pTask2'];
        for(pse__Project_Task__c pTask : projectTasks){
            pTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
            pTask.NSP_Percentage_Complete__c = '25%';
            pTask.pse__Synchronize_Milestone_And_Task__c = false;
        }
        update projectTasks;
        test.stopTest();

        pse__Project_Task__c updatedProjectTasks = [SELECT NSP_PercentageCompleteFormula__c,pse__Milestone__r.NSP_Milestone_Complete__c from pse__Project_Task__c WHERE Id = : projectTasks[0].id];
        System.assertEquals(25, updatedProjectTasks.NSP_PercentageCompleteFormula__c);
  }
 /***********************************************************************************************
    * MethodName: calculateProjectPercentageCompleteTest
    * Description : This Method calculate Project Percentage complete on project
 *********************************************************************************************/
     @isTest
    public static void caluclateProjectPercentageCompleteTestonUpdatingProjectTask(){
        test.startTest();
        pse__Project_Task__c updatingValuesProjectTasks = [SELECT Name, NSP_PercentageCompleteFormula__c, pse__Status__c,pse__Project__c, pse__Project__r.NSP_Project_Complete__c FROM pse__Project_Task__c WHERE Name = 'projTask1' LIMIT 1];
        //updating percentage complete to different value
        updatingValuesProjectTasks.NSP_Percentage_Complete__c = '75%';
        update updatingValuesProjectTasks;
        test.stopTest();
 
        pse__Proj__c proj =[SELECT Id, Name, NSP_Project_Complete__c FROM pse__Proj__c WHERE pse__Account__r.Name = 'Test Account 2' LIMIT 1];
     	
        //Checking the aggregate value
        System.assertEquals(58.3, proj.NSP_Project_Complete__c.setScale(1));
    }
    
    @isTest
    public static void calculateProjectPercentageCompleteTestOnDeleteProjectTask(){
        test.startTest();
        pse__Project_Task__c deletingProjectTasks = [SELECT Name, NSP_PercentageCompleteFormula__c, pse__Status__c FROM pse__Project_Task__c WHERE Name IN ('projTask1')];
        //deleting a project tasks record
        delete deletingProjectTasks;
        test.stopTest();
        
        //Query the Project 
        pse__Proj__c proj =[SELECT Id, Name, NSP_Project_Complete__c FROM pse__Proj__c WHERE pse__Account__r.Name = 'Test Account 2' LIMIT 1];
        
        //Checking the aggregate value
        System.assertEquals(50.0, proj.NSP_Project_Complete__c.setScale(1)); 
    }
     @isTest
    public static void updatingProjectStatusToCancelled(){
        //negative scenerio
        test.startTest();
        pse__Project_Task__c updatingStatusProjectTasks = [SELECT Name, NSP_PercentageCompleteFormula__c, pse__Status__c FROM pse__Project_Task__c WHERE Name= 'projTask2'];
        //changing the status to cancelled
        updatingStatusProjectTasks.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_CANCELLED;
        update updatingStatusProjectTasks;
        test.stopTest();
        
        //Query the Project 
        pse__Proj__c proj =[SELECT Id, Name, NSP_Project_Complete__c FROM pse__Proj__c WHERE pse__Account__r.Name = 'Test Account 2' LIMIT 1];
     	//Checking the aggregate value
        System.assertNotEquals(25.0, proj.NSP_Project_Complete__c.setScale(1));
    }

    /***********************************************************************************************
    * MethodName: startDateEndDateUpdateTest
    * Description : This Method will update start and end Date on Projects Tasks 
    * ********************************************************************************************/
   	@isTest
    public static void startDateEndDateUpdateTest(){
       Test.startTest();    
        pse__Project_Task__c pTasks= [Select Id , pse__Start_Date_Time__c, NSP_Account_Id__c ,pse__End_Date_Time__c, NSP_of_Days_Offset__c ,pse__Project__c From pse__Project_Task__c
                                    WHERE  Name ='pTask2' limit 1];
        List<NSP_Sub_Client__c> lSubClients = new List<NSP_Sub_Client__c>([SELECT Id, NSP_Sub_Client__c, NSP_Renewal_Date__c FROM NSP_Sub_Client__c WHERE NSP_Account__c =:pTasks.NSP_Account_Id__c  LIMIT 1]);
       Test.stopTest();
       system.assertEquals(true,pTasks.pse__Start_Date_Time__c!=null);
       
   }
    
    /***********************************************************************************************
    * MethodName: testCreateHCMCaseOnProjectTaskUpdate
    * Description : This Method will test positive scenario which will create HCM Case  
    * ********************************************************************************************/
    @IsTest
    private static void testCreateHCMCaseOnProjectTaskUpdate(){        
         Test.startTest();
        StaticResource srObject = [SELECT Id, Name, Body FROM StaticResource WHERE Name =:NSP_ServiceConstants.HCM_CASE_DATA_TEMPLATE LIMIT 1];
        pse__Proj__c getProject = [SELECT Id, Name,Project_Implementer__c, TemplateName__c FROM pse__Proj__c WHERE TemplateName__c =: NSP_ServiceConstants.HCM_PROJECT_NAME];
       pse__Project_Task__c discoveryTask = [SELECT Id, Name, pse__Status__c  FROM pse__Project_Task__c WHERE Name =: NSP_ServiceConstants.PROJECT_TASK_DISCOVERY];
        discoveryTask.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
         UPDATE discoveryTask;
       
        NSP_ProjectTasksTriggerHelper.createHCMCaseOnProjectTaskUpdate(new Set<Id>{discoveryTask.Id});
        Test.stopTest();
        System.assertEquals(discoveryTask.pse__Status__c, NSP_ServiceConstants.TASKCOMPLETE);
    }
    
     /***********************************************************************************************
    * MethodName: testCreateNoHCMCaseOnProjectTaskUpdate
    * Description : This Method will test negative scenario 
    * ********************************************************************************************/
    @IsTest
    private static void testCreateNoHCMCaseOnProjectTaskUpdate(){
        Test.startTest();
        pse__Project_Task__c discoveryTask = [SELECT Id, Name, pse__Status__c  FROM pse__Project_Task__c WHERE Name =:NSP_ServiceConstants.PROJECT_TASK_DISCOVERY];
        discoveryTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        UPDATE discoveryTask;
        Test.stopTest();
        System.assertEquals(0, [SELECT count() FROM Case WHERE Subject =:NSP_ServiceConstants.HCM_TEST_CASE_SUBJECT]);
    }
    
    /***********************************************************************************************
    * MethodName	: testWXWADataMigrationAndNewTaxImplProjectCreation
    * Description	: This Method will test positive scenario which will create 
    *                 New Tax IMPL and WX/WA Data Migration sub project when 
    * 				  Configuration Task of iSolved HCM project is marked as complete 
    * ********************************************************************************************/
    @IsTest
    private static void testWXWADataMigrationAndNewTaxImplProjectCreation(){
        Test.startTest();
        pse__Proj__c newTaxImplTemplate = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        newTaxImplTemplate.Name = NSP_ServiceConstants.NEW_TAX_IMPL_PROJECT;
        newTaxImplTemplate.pse__Start_Date__c = Date.Today();
        newTaxImplTemplate.pse__Is_Template__c = true;
		INSERT newTaxImplTemplate;
        
        pse__Proj__c wxwaDMTemplate = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        wxwaDMTemplate.Name = NSP_ServiceConstants.WX_WA_DATA_MIGRATION_PROJECT;
        wxwaDMTemplate.pse__Start_Date__c = Date.Today();
        wxwaDMTemplate.pse__Is_Template__c = true;
		INSERT wxwaDMTemplate;
        
        List<String> projTaskFields = new List<String>{'Id'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', NSP_ServiceConstants.CONFIGURATION_TASK).addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        update projectTaskRec;
        
        NSP_ProjectTasksTriggerHelper.createNewTaxIMPLSubProject(new Set<Id>{projectTaskRec.Id});
        System.assertEquals(1, [SELECT count() FROM pse__Proj__c WHERE Name =:NSP_ServiceConstants.NEW_TAX_IMPL_PROJECT]);
        System.assertEquals(1, [SELECT count() FROM pse__Proj__c WHERE Name =:NSP_ServiceConstants.WX_WA_DATA_MIGRATION_PROJECT]);
        Test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName	: testWXWADataMigrationAndNewTaxImplProjectNoCreation
    * Description	: This Method will test negative scenario which should not create 
    * 				  New Tax IMPL and WX/WA Data Migration sub project 
    * 				  when Configuration Task of iSolved HCM project is In Progress 
    * ********************************************************************************************/
    @IsTest
    private static void testWXWADataMigrationAndNewTaxImplProjectNoCreation(){
        Test.startTest();
        List<String> projTaskFields = new List<String>{'Id'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', NSP_ServiceConstants.CONFIGURATION_TASK).addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        Database.update(projectTaskRec);
        System.assertEquals(0, [SELECT count() FROM pse__Proj__c WHERE Name =:NSP_ServiceConstants.NEW_TAX_IMPL_PROJECT]);
        System.assertEquals(0, [SELECT count() FROM pse__Proj__c WHERE Name =:NSP_ServiceConstants.WX_WA_DATA_MIGRATION_PROJECT]);
        Test.stopTest();
    }

    /************************************************************************************************************************
    * MethodName	: schedulePtWithNonServiceResOwnerTest
    * Description	: Schedule PT with Owner not having Service Resource Rec
    * ************************************************************************************************************************/
    @isTest
    private static void schedulePtWithNonServiceResOwnerTest(){
        try{
        List<String> projTaskFields = new List<String>{'Id','Name', 'pse__Status__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                            .addFilter('Name', 'Schedule deconversion date')
                            .addFilter('pse__Status__c', NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED).addLimit(1).build();
        pse__Project_Task__c  projectTaskRec = Database.query(query);
        Test.startTest();
        projectTaskRec.pse__Status__c = 'Scheduled';
        Database.update(projectTaskRec);
        Test.stopTest();
        }catch ( DmlException ex ){
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION',ex.getDmlStatusCode(0),'Owner is not a dispatcher erro');
        }
    }
    /************************************************************************************************************************
    * MethodName	: schedulePtWithoutStartDateTest
    * Description	: Schedule PT with Start date null
    * ************************************************************************************************************************/
    @isTest
    private static void schedulePtWithoutStartDateTest(){
        try{
        Test.startTest();
        List<String> projTaskFields = new List<String>{'Id','Name', 'pse__Status__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                            .addFilter('Name', 'Schedule deconversion date')
                            .addFilter('pse__Status__c', NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED).addLimit(1).build();
        pse__Project_Task__c  projectTaskRec = Database.query(query);
        ServiceResource serRes = [SELECT Id,RelatedRecordId FROM ServiceResource WHERE Name = 'Test' LIMIT 1];
        projectTaskRec.OwnerId = serRes.RelatedRecordId;
        projectTaskRec.pse__Start_Date_Time__c = null;
        projectTaskRec.pse__Status__c = 'Scheduled';
        Database.update(projectTaskRec);
        Test.stopTest();
        }catch ( DmlException ex ){
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION',ex.getDmlStatusCode(0) ,'Start Date cannot be null error');
        }
    }

   

    /************************************************************************************************************************
    * MethodName	: serviceAppointmentSchedulingTest
    * Description	: test SA scheduling FROM project Task
    * ************************************************************************************************************************/
    @isTest
    private static void serviceAppointmentSchedulingTest(){
        Test.startTest();
        List<String> projTaskFields = new List<String>{'Id','Name', 'pse__Status__c'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                            .addFilter('Name', 'NewPt')
                            .addLimit(1).build();
        pse__Project_Task__c  projectTaskRec = Database.query(query);
        ServiceResource serRes = [SELECT Id,RelatedRecordId FROM ServiceResource WHERE Name = 'Test' LIMIT 1];
        projectTaskRec.OwnerId = serRes.RelatedRecordId;
        projectTaskRec.pse__Start_Date_Time__c =System.today();
        projectTaskRec.pse__End_Date_Time__c = System.today().addDays(2);

        WorkOrder newWo = new WorkOrder();
        newWo.NSP_Project_Task__c = projectTaskRec.Id;
        insert newWo;

        ServiceAppointment newSa = new ServiceAppointment();
        newSa.ParentRecordId = newWo.Id;
        insert newSa;
        
        projectTaskRec.pse__Status__c = 'Scheduled';
        projectTaskRec.NSP_Dispatch_Region__c = '';
        Database.update(projectTaskRec);
        Test.stopTest();
        WorkOrder updatedWo = [SELECT Id, Status FROM WorkOrder WHERE Id =: newWo.Id];
        System.assertEquals(updatedWo.Status, 'New');
        
    }

    /************************************************************************************************************************
    * MethodName	: durationStartEndDateTest
    * Description	: checking for the updation of duration, start date and end date
    * ************************************************************************************************************************/
    @isTest
    private static void durationStartEndDateTest(){
        Test.startTest();
        List<String> projTaskFields = new List<String>{'Id','Name', 'NSP_Duration_in_minutes__c','pse__Start_Date_Time__c','pse__End_Date_Time__c'};
        List<String> workOrderFields = new List<String>{'Id','NSP_Project_Task__c', 'Duration','StartDate','EndDate'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                            .addFilter('Name', 'DurationPt').addLimit(1).build();

        pse__Project_Task__c  projectTaskRec = Database.query(query);

        WorkOrder newWo = new WorkOrder();
        newWo.NSP_Project_Task__c = projectTaskRec.Id;
        insert newWo;
        projectTaskRec.NSP_Duration_in_minutes__c = 120;
        Database.update(projectTaskRec);

        String query1 = new NSP_QueryBuilder('WorkOrder', workOrderFields)
                        .addFilter('Id', newWo.Id).addLimit(1).build();


        WorkOrder  workOrderRec = Database.query(query1);
        System.assertEquals(projectTaskRec.NSP_Duration_in_minutes__c, 120, 'Both are equal');
        Test.stopTest();
    }
    
     /***********************************************************************************************
    * MethodName: testCreateCasesOnProjectTasksUpdate
    * Description : Test creation of First Live Payroll Case when Go Live Project Task 
    * 				status is Complete on iSolved HCM Implementation project
    * ********************************************************************************************/ 
    @isTest
    private static void testCreateCasesOnProjectTasksUpdate(){
    	Test.startTest();
        Group wxImplqueue = (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
        wxImplqueue.Name = NSP_ServiceConstants.CASE_ASIGNED_QUEUE_WX_IMPL_SUPPORT;
        wxImplqueue.Type = 'Queue';
        INSERT wxImplqueue;    
        Set<Id> prjctTaskId = new Set<Id>();
        List<String> projTaskFields = new List<String>{'Id','pse__Project__r.Name'};
        String query = new NSP_QueryBuilder('pse__Project_Task__c', projTaskFields)
                          .addFilter('Name', NSP_ServiceConstants.GO_LIVE).addLimit(1).build();
        pse__Project_Task__c projectTaskRec = Database.query(query);
        projectTaskRec.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        Database.update(projectTaskRec);
        prjctTaskId.add(projectTaskRec.Id);
        NSP_ProjectTasksTriggerHelper.createPTAIfOwnerIsChanged(prjctTaskId);
        System.assertEquals(1, [SELECT count() FROM Case WHERE NSP_Category__c =: NSP_ServiceConstants.CASE_CATEGORY_WX_WA]);
        Test.stopTest();
    }   
    //Method Name:sendEmailToAccountTeamMembersIfTaskIsLetterReceived -STY-04147
     @IsTest
    private static void testsendEmailToAccountTeamMembersIfTaskIsLetterReceived(){
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WO').getRecordTypeId();
        Test.startTest();
        pse__Project_Task__c letterrcvdTask = [SELECT Id, Name, pse__Status__c,NSP_AccountId__c  FROM pse__Project_Task__c WHERE Name ='Letter Received (Termination Letter)' Limit 1];
       
        
         NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Account__c = letterrcvdTask.NSP_AccountId__c;
        accTeam.NSP_Role__c ='Payroll Specialist';
        Insert accTeam;
         
         
        Asset asseObj = [SELECT Id, AccountId,NSP_Reason_for_Term__c,NSP_Anticipated_Date_Of_Termination__c  FROM Asset Limit 1];
        asseObj.AccountId = letterrcvdTask.NSP_AccountId__c;
        asseObj.RecordTypeId =new_Asset_RT_ID;
        asseObj.Status = 'Active';
            UPDATE asseObj;
        
        NSP_Termination_Form__c TermrrcvdTask = [SELECT Id FROM NSP_Termination_Form__c WHERE NSP_Project_Task__c =: letterrcvdTask.Id LIMIT 1];
        TermrrcvdTask.NSP_Status__c = 'Term Team Approved';
        update TermrrcvdTask;
        
        letterrcvdTask.pse__Status__c = 'Complete';
        UPDATE letterrcvdTask;
        
        Test.stopTest();
    }
    
     @IsTest
    private static void testnotifysendEmailToAccountTeamMembersIfTaskIsLetterReceived(){
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WO').getRecordTypeId();
        Test.startTest();
        pse__Project_Task__c letterrcvdTask = [SELECT Id, Name, pse__Status__c,NSP_AccountId__c,pse__Started__c,pse__Completed__c  FROM pse__Project_Task__c WHERE Name ='Notify ITA if term date is today' Limit 1];
       	letterrcvdTask.pse__Status__c= 'In Progress';
        letterrcvdTask.pse__Started__c = True;
        letterrcvdTask.pse__Completed__c = False;
        update letterrcvdTask;
         NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', false);
        accTeam.NSP_Account__c = letterrcvdTask.NSP_AccountId__c;
        accTeam.NSP_Role__c ='Payroll Specialist';
        Insert accTeam;
         
         
        Asset asseObj = [SELECT Id, AccountId,NSP_Reason_for_Term__c,NSP_Anticipated_Date_Of_Termination__c  FROM Asset Limit 1];
        asseObj.AccountId = letterrcvdTask.NSP_AccountId__c;
        asseObj.RecordTypeId =new_Asset_RT_ID;
        asseObj.Status = 'Active';
            UPDATE asseObj;
               
        letterrcvdTask.pse__Status__c = 'Complete';
        UPDATE letterrcvdTask;
        
        Test.stopTest();
    }  
}