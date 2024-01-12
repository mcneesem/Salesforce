/**
Apex Class Name      :  Nps_CloneServicePlanProjectCtrTest
Version              :  1.0                                                                          
Created Date         :  06/01/22 
Author               :  Jatin 
Function             :  This class is used as a helper to Opportunity Trigger Handler. 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin                 06/01/22           First Iteration
*/

@isTest
public class Nps_CloneServicePlanProjectCtrTest {
    
    @testSetup
    public static void setupProjectTaskdata(){
        Id WoAssetRecordType = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        String BPS_ProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_BPS_RECORDTYPE).getRecordTypeId();
        
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        pse__Work_Calendar__c workRec = new pse__Work_Calendar__c();
        workRec.name = 'US 40';
        insert workRec;
        
        // inserting account
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        
        // inserting asset
        Asset oAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        oAsset.AccountId = oAccount.Id;
        oAsset.RecordTypeId = WoAssetRecordType;
        oAsset.NSP_Client_Segment_type__c = 'Middle Market';
        insert oAsset;
        
        // inserting contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert oContact;
        
        //inserting Project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Account__c = oAccount.Id;
        oProject.pse__Copy_Child_Records_from_Template_Async__c = true;
        oProject.Name = 'Test Project'; 
        oProject.pse__Start_Date__c = Date.Today();
        oProject.pse__Project_Type__c = 'Service Plan';
        oProject.pse__Is_Template__c = true;
        insert oProject;
        
        //inserting Project
        pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject1.pse__Account__c = oAccount.Id;
        oProject1.pse__Copy_Child_Records_from_Template_Async__c = true;
        oProject1.Name = 'Test Project1'; 
        oProject1.pse__Start_Date__c = Date.Today();
        oProject1.pse__Project_Type__c = 'Service Plan';
        oProject1.pse__Is_Template__c = true;
        insert oProject1;
        
        //inserting Milestone
        Test.startTest();
        pse__Milestone__c milestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestone.pse__Project__c = oProject.id;
        insert milestone;
        
        // inserting Project Task
        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.Name = 'pTask1';
        oProjectTask1.pse__Status__c = NSP_ServiceConstants.PROJECTSTATUSCANCELLED;
        oProjectTask1.pse__Milestone__c = milestone.id;
        oProjectTask1.NSP_Template_Generated__c = true;
        oProjectTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        insert oProjectTask1;
        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask2.Name = 'pTask2';
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        oProjectTask2.pse__Milestone__c = milestone.id;
        oProjectTask2.NSP_Template_Generated__c = true;
        oProjectTask2.RecordTypeId = PEOProjectTaskRecordTypeId;
        insert oProjectTask2;
        Test.stopTest();
        
    }
    
    @isTest
    public static void methodName(){
        //Getting Project records
        List<pse__Proj__c> projList = [SELECT ID, pse__Start_Date__c FROM pse__Proj__c WHERE pse__Start_Date__c =: Date.Today()];
        String recdId = projList[0].Id ;
        
        System.assertEquals(2,[SELECT count() FROM pse__Proj__c WHERE pse__Start_Date__c =: Date.Today()]);
        Test.startTest();
        //creating list to store task records  
        List<pse__Project_Task__c> listTask = new List<pse__Project_Task__c>();
        for(pse__Project_Task__c eachTask : Nps_CloneServicePlanProjectController.retrieveProjectTask(recdId)){
            eachTask.Id =null;
            listTask.add(eachTask);
        }
        
        System.assertNotEquals(listTask, null,'value should not be null');
        String toTaskString = JSON.serialize(listTask);
        List<String> listTaskString = Nps_CloneServicePlanProjectController.saveProjectTask(toTaskString);
        
        List<pse__Milestone__c> listmilestone = new List<pse__Milestone__c>();
        for(pse__Milestone__c eachMilestone : Nps_CloneServicePlanProjectController.retrieveProjectMilestone(recdId)){
            eachMilestone.Id =null;
            listmilestone.add(eachMilestone);
        }
        String toMilestoneString = JSON.serialize(listmilestone);
        
        System.assertNotEquals(listmilestone, null,'value should not be null');
        
        List<String> listmilestoneString = Nps_CloneServicePlanProjectController.saveProjectMilestone(toMilestoneString);
        
        List<String> sobjList =  new List<String>{'pse__Project_Task__c', 'pse__Milestone__c'};
            
            List<RecordType>  recdTypeList = Nps_CloneServicePlanProjectController.retrieveRecordTypes(sobjList);
        
        System.assertNotEquals(recdTypeList, null,'value should not be null');
        Test.stopTest();
        
    }
    @isTest
    public static void getProjectRelatedRecordsDataByProjectIdAndAccountId(){
        pse__Proj__c projRec = [SELECT ID FROM pse__Proj__c WHERE Id != null LIMIT 1];
        Account accRecord =[SELECT Id,Name FROM Account WHERE Id != null LIMIT 1];
         Project_Account__c projAccounts3 =  new Project_Account__c();
    	projAccounts3.Account__c = accRecord.Id;
        projAccounts3.Project__c = projRec.Id;
        insert projAccounts3;
        List<NSP_LookupOption> projTemplateOption = Nps_CloneServicePlanProjectController.getProjectTemplatesBySegmentType('Core');
        List<NSP_LookupOption> projTemplateOptionEmergingGrowth = Nps_CloneServicePlanProjectController.getProjectTemplatesBySegmentType('Emerging Growth');
        List<NSP_LookupOption> projTemplateOptionEnterprise = Nps_CloneServicePlanProjectController.getProjectTemplatesBySegmentType('Middle Market Enterprise');
        List<NSP_LookupOption> projTemplateOptionMM = Nps_CloneServicePlanProjectController.getProjectTemplatesBySegmentType('Middle Market');
        Test.startTest();
        Map<String, String> relatedRecordsDataMap = Nps_CloneServicePlanProjectController.getProjectRelatedRecordsData(projRec.Id,accRecord.Id);
        Test.stopTest();
        System.assert(relatedRecordsDataMap.containsKey('openProjectTasksCount'));
        List<String> relatedRecordsDataMapValues = new List<String>(relatedRecordsDataMap.values());
        System.assertEquals(false, relatedRecordsDataMapValues.contains('0'));
        
        System.assertEquals(relatedRecordsDataMap.size(), 3);
    }
    
    @isTest
    public static void createProjectRelatedRecordsTest(){
        
        pse__Proj__c projrec = [SELECT Id FROM pse__Proj__c WHERE pse__Project_Type__c = 'Service Plan' AND NAME = 'Test Project1' LIMIT 1];
        pse__Proj__c projrec1 = [SELECT Id FROM pse__Proj__c WHERE pse__Project_Type__c = 'Service Plan' AND NAME = 'Test Project' LIMIT 1];
        pse__Proj__c projTemplate = [SELECT Id FROM pse__Proj__c WHERE pse__Is_Template__c = true LIMIT 1];
        pse__Project_Task__c projTask1 = [SELECT Id FROM pse__Project_Task__c WHERE Name = 'pTask1' LIMIT 1];
        pse__Project_Task__c projTask2 = [SELECT Id FROM pse__Project_Task__c WHERE Name = 'pTask2' LIMIT 1];
        String config = '{"projectTemplateId":"' + projTemplate.Id +'","projectId":"' + projrec.Id +'","oldProjectId":"' + projrec1.Id +'","prevProjectTaskIds":"[\\"'+projTask1.Id+'\\",\\"'+projTask2.Id+'\\"]","projectAccountIds":"[]"}';
        Test.startTest();
        system.debug('config'+config);
        List<String> relatedRecordsData = Nps_CloneServicePlanProjectController.createProjectRelatedRecords(config);
        List<pse__Proj__c> lstProjs = [SELECT Id FROM pse__Proj__c WHERE Id =: projTemplate.Id];
        System.assertEquals(lstProjs.size(), 1);
        Test.stopTest();
    }
    
    @isTest
    public static void createProjectFromTemplateTest(){
     List<String> PROJECT_FIELDS = new List<String>{
        'Id',
        'Name',
        'pse__Project_Status__c',
        'pse__End_Date__c',
        'pse__Account__c',
        'pse__Is_Active__c',
        'pse__Start_Date__c'
    };
    String projQuery = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                            .addFilter('pse__Project_Type__c', 'Service Plan')
                            .addLimit(1).build();
    pse__Proj__c projTemplate = Database.query(projQuery);
    String fields = '{"projectTemplateId":"' + projTemplate.Id +'","projectStartDate":"' + projTemplate.pse__Start_Date__c +'","projectAccount":"' + projTemplate.pse__Account__c +'"}';
    Test.startTest();
    
    Id projId = Nps_CloneServicePlanProjectController.createProjectFromTemplate(projTemplate.Id,fields);
    String projTestQuery = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                            .addFilter('Id', projTemplate.Id)
                            .addLimit(1).build();
    pse__Proj__c projTest = Database.query(projTestQuery);
    System.assertEquals(projTest.Id, projTemplate.Id, 'New Project Created from Template');
    Test.stopTest();
    }
    
}