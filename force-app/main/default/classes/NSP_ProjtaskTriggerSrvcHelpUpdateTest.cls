@isTest
private class NSP_ProjtaskTriggerSrvcHelpUpdateTest {
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    private static Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    public final static Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByName().get('PEO Project').getRecordTypeId();
    public final static String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
    private static final String PROJECT_TASK_DEFAULTS = 'nsp_testdatafactory.projecttaskdefaults';

    @testSetup
    static void setUpData(){
        List<pse__Proj__c> prjList = new List<pse__Proj__c>();
        List<pse__Project_Task__c> prjtaskList = new List<pse__Project_Task__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = 'Implementation';
        oProject.RecordTypeId = PEORecordTypeId;
        oProject.TemplateName__c=label.FSOImplementationProject;
        prjList.add(oProject);
        
        pse__Proj__c oProject2 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject2.pse__Project_Type__c = 'Implementation';
        oProject2.RecordTypeId = PEORecordTypeId;
        oProject2.TemplateName__c=label.Middle_Market_Implementation_Project;
        prjList.add(oProject2);
        
        database.insert(prjList);

		List<Implementation_Profile__c> ipRecords = new List<Implementation_Profile__c>();
        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.NSP_Project__c = oProject.Id;
        ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c=NSP_ServiceConstants.REQUESTED;
        ip.Gave_copy_of_PTO_sick_leave_other_policy__c=NSP_ServiceConstants.REQUESTED;
        ip.Employee_Data_Collection_EDC_collected__c=NSP_ServiceConstants.NO;
        ip.Recent_Payroll_Register_Collected__c=NSP_ServiceConstants.NO;
        ip.NSP_List_Employee_Names_Levies__c='SMRITHI';
        ip.NSP_Employee_Names_List_garnishments__c='Anil';
        ip.RecordTypeId =fsoRecordTypeId;
        ipRecords.add(ip);
        
        
        
        Implementation_Profile__c ip1 = new Implementation_Profile__c();
        ip1.NSP_Project__c=oProject2.Id;
        ip1.Has_FEIN_documentation_been_collected__c=NSP_ServiceConstants.NO;
        ip1.RecordTypeId =ipMMRecordTypeId;
        ip1.Received_Section_125_Questionnaire__c=NSP_ServiceConstants.NO;
        ipRecords.add(ip1);
        
        database.insert(ipRecords);
        List<NSP_Employee_Data__c> empDataList = new List<NSP_Employee_Data__c>();
        NSP_Employee_Data__c ed = new NSP_Employee_Data__c();
        ed.NSP_Name__c='Anil';
        ed.NSP_Documents__c='Requested - Not Collected';
        ed.NSP_Parent_Field_API_Name__c=NSP_ServiceConstants.GARNISH_API_NAME;
        ed.NSP_Implementation_Profile__c=ip.id;
        empDataList.add(ed);
        
        NSP_Employee_Data__c ed1 = new NSP_Employee_Data__c();
        ed1.NSP_Name__c='SMRITHI';
        ed1.NSP_Documents__c='Requested - Not Collected';
        ed1.NSP_Parent_Field_API_Name__c=NSP_ServiceConstants.LEVIES_API_NAME;
        ed1.NSP_Implementation_Profile__c=ip.id;
        empDataList.add(ed1);
        
        database.insert(empDataList);

		Test.startTest();
        pse__Project_Task__c projTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(),PROJECT_TASK_DEFAULTS, false);
        projTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask.Name = NSP_ServiceConstants.CERTIFICATE;
        projTask.pse__Started__c=true;
        projTask.pse__Project__c = oProject.Id;
        prjtaskList.add(projTask);
        
        pse__Project_Task__c projTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask1.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask1.Name = NSP_ServiceConstants.EEO;
        projTask1.pse__Project__c = oProject.Id;
        projTask1.pse__Started__c=true;
        prjtaskList.add(projTask1);
        
        pse__Project_Task__c projTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask2.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask2.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask2.Name = NSP_ServiceConstants.PRIMINGDATA;
        projTask2.pse__Project__c = oProject.Id;
        projTask2.pse__Started__c=true;
        prjtaskList.add(projTask2);
        
        pse__Project_Task__c projTask3 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask3.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask3.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask3.Name = NSP_ServiceConstants.CPR;
        projTask3.pse__Project__c = oProject.Id;
        projTask3.pse__Started__c=true;
        prjtaskList.add(projTask3);
        
        pse__Project_Task__c projTask4 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask4.pse__Status__c = 'Not Started';
        projTask4.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask4.Name = NSP_ServiceConstants.LEVIEIS;
        projTask4.pse__Project__c = oProject.Id;
        projTask4.pse__Started__c=true;
        prjtaskList.add(projTask4);
        
        pse__Project_Task__c projTask10 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask10.pse__Status__c ='Not Started';
        projTask10.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask10.Name = NSP_ServiceConstants.GARNISHMENT;
        projTask10.pse__Project__c = oProject.Id;
        projTask10.pse__Started__c=true;
        prjtaskList.add(projTask10);
        
        pse__Project_Task__c projTask5 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask5.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask5.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask5.Name = NSP_ServiceConstants.SECTIONQUESTIONNAIRE;
        projTask5.pse__Project__c = oProject2.Id;
        projTask5.pse__Started__c=true;
        prjtaskList.add(projTask5);
        
        pse__Project_Task__c projTask7 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask7.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask7.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask7.Name = NSP_ServiceConstants.FEINDOCUMENT;
        projTask7.pse__Project__c = oProject2.Id;
        projTask7.pse__Started__c=true;
        prjtaskList.add(projTask7);
       
        List<pse__Project_Task__c> childTaskList = new List<pse__Project_Task__c>();
        pse__Project_Task__c projTask8 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask8.pse__Status__c = 'Not Started';
        projTask8.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask8.Name = 'SMRITHI levy documentation';
        projTask8.pse__Project__c = oProject.Id;
        projTask8.pse__Parent_Task__c=projTask4.Id;
        projTask8.pse__Started__c=true;
        childTaskList.add(projTask8);
        
        pse__Project_Task__c projTask11 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), PROJECT_TASK_DEFAULTS, false);
        projTask11.pse__Status__c = 'Not Started';
        projTask11.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask11.Name = 'Anil garnishment documentation';
        projTask11.pse__Project__c = oProject.Id;
        projTask11.pse__Parent_Task__c=projTask10.Id;
        projTask11.pse__Started__c=true;
        childTaskList.add(projTask11);
        
        
        database.insert(prjtaskList);
        database.insert(childTaskList);
        
       
        Test.stopTest();
    }

    @isTest
    static void afterUpdateProjectTaskTest(){
        List<pse__Project_Task__c> updateProjList = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> getPrjTasksList = [SELECT Id, pse__Status__c 
                                                      FROM pse__Project_Task__c 
                                                      WHERE pse__Parent_Task__c=null AND pse__Status__c =: NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS ];
        Test.startTest();
        for(pse__Project_Task__c prjtask : getPrjTasksList){
            prjtask.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSCOMPLETED;
            updateProjList.add(prjtask);
        }
        database.update(updateProjList, false);
        
        Test.stopTest();
        System.assertEquals(true, getPrjTasksList.size() > 0);
    }

    @isTest
    static void afterUpdateTaskTest(){
        List<pse__Project_Task__c> updateProjList = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> getPrjTasksList = [SELECT Id, pse__Status__c 
                                                      FROM pse__Project_Task__c 
                                                      WHERE  pse__Status__c='Not Started' ];
		for(pse__Project_Task__c prjtask : getPrjTasksList){
            
            prjtask.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
            updateProjList.add(prjtask);
        }
        Test.startTest();
        database.update(updateProjList);
        List<NSP_Employee_Data__c> edList =[SELECT Id,NSP_Name__c,NSP_Documents__c from NSP_Employee_Data__c WHERE NSP_Name__c='Anil'  ];
        system.assertEquals(edList[0].NSP_Documents__c, NSP_ServiceConstants.COLLECTED);
        
        Test.stopTest();   
    }
}