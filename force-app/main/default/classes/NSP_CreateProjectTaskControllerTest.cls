/**
Apex Class Name      :  NSP_CreateProjectTaskControllerTest
Version              :  1.0  
Created Date         :  02/28/23  
Function             :  This class is used as a test class for  NSP_CreateProjectTaskController
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest(SeeAllData=false)
private class NSP_CreateProjectTaskControllerTest {
    
    private static final Id peoProjectRecordType = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c','PEO_Project');
    private static final List<String> PROJECT_FIELDS = new List<String>{'Id','recordTypeId','recordType.DeveloperName'};
    private static final List<String> PROJECT_TASK_FIELDS = new List<String>{'Id','pse__Project__c'};
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final Id PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c', NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    private static void setupTestData(){
        
        Test.startTest();
        pse__Proj__c projectObj = new pse__Proj__c();
        projectObj.RecordTypeId=peoProjectRecordType;
        projectObj.pse__Project_Type__c = 'Implementation';
        projectObj.pse__Project_Status__c = 'Active';
        projectObj.Name = 'Test Delete 1';
        projectObj.pse__Is_Active__c = true;
        
        pse__Proj__c bpsProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        bpsProject.RecordTypeId = bpsProjectRecordTypeId;
        bpsProject.Templates_Used__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
        bpsProject.pse__Project_Status__c = 'Active';
        bpsProject.pse__Is_Active__c = true; 
        
        List<pse__Proj__c> listProject = new List<pse__Proj__c>();
        listProject.add(projectObj);
        listProject.add(bpsProject);
        
        insert listProject;
        
        List<pse__Project_Task__c> projectTasks = new List<pse__Project_Task__c>();
        pse__Project_Task__c prjcTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        prjcTask.Name = 'projTask3';
        prjcTask.pse__Project__c = projectObj.Id;
        prjcTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        prjcTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
		projectTasks.add(prjcTask);
        
        insert projectTasks;
        
        Test.stopTest();
    }
    
    /***********************************************************************************************
* MethodName: getPeoProjectRelatedRecordTypesNegativeTest
* Description :  Negative Test
* ********************************************************************************************/
    @isTest
    private static void getPeoProjectRelatedRecordTypesNegativeTest(){
        
        String bpsPrjQuery = new NSP_QueryBuilder('pse__Proj__c', PROJECT_FIELDS)
            .addFilter('Templates_Used__c', NSP_ServiceConstants.ITA_IMPLEMENTATION)
            .addLimit(1).build();
        pse__Proj__c bpsProject = Database.query(bpsPrjQuery);
        
        Test.startTest();
        Boolean isPeoProject = NSP_CreateProjectTaskController.getPeoProjectRelatedRecordTypes(NSP_ServiceConstants.PEO_PROJECT_TASK_NAME, bpsProject.Id);
        Test.stopTest();
        System.assertEquals(isPeoProject, false, 'Selected Project and Project Task combination did not match');   
    }
       
    /***********************************************************************************************
* MethodName: getPeoProjectRelatedRecordTypesPositiveTest
* Description :  Positive Test
* ********************************************************************************************/
    @isTest
    private static void getPeoProjectRelatedRecordTypesPositiveTest(){
        
        String peoPrjQuery = new NSP_QueryBuilder('pse__Proj__c', PROJECT_FIELDS)
            .addFilter('pse__Project_Type__c', 'Implementation')
            .addLimit(1).build();
        pse__Proj__c peoProject = Database.query(peoPrjQuery);
        
        Test.startTest();
        Boolean isPeoProject = NSP_CreateProjectTaskController.getPeoProjectRelatedRecordTypes(NSP_ServiceConstants.PEO_PROJECT_TASK_NAME, peoProject.Id);
        Test.stopTest();
        System.assertEquals(isPeoProject, true, 'Selected Project and Project Task combination matches');   
    } 
    /***********************************************************************************************
* MethodName: getProjectIdFromProjectTaskTest
* Description :  Positive Test
* ********************************************************************************************/
    @isTest
    private static void getProjectIdFromProjectTaskTest(){
        String peoPrjTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', PROJECT_TASK_FIELDS)
            .addFilter('RecordTypeId', PEOProjectTaskRecordTypeId)
            .addLimit(1).build();
        pse__Project_Task__c peoProjectTask = Database.query(peoPrjTaskQuery);
        
        Test.startTest();
        NSP_CreateProjectTaskController.getProjectIdFromProjectTask(peoProjectTask.Id);
        Test.stopTest();
        system.assert(peoProjectTask.pse__Project__c != null);
    }
    
}