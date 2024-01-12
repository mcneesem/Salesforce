/**
* @description  :   Test class for NSP_DeleteDuplicateMilestoneBatch .
* @date 12/16/2022
* Author : Abhishek Kumar
* Name : NSP_DeleteDuplicateMilestoneBatchTest
*/
@isTest
public class NSP_DeleteDuplicateMilestoneBatchTest {

    private static final List<String> MILESTONE_FIELDS = new List<String>{
        'Id',
        'Name'
    };

    /***********************************************************************************************
    * MethodName: testData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    @testSetup
    static void setupTestData(){
        //Get Record type Id of RET Project Type
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);

        pse__Proj__c newProj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        newProj.pse__Is_Template__c = false;
        newProj.TemplateName__c = NSP_ServiceConstants.PROJECT_GENERAL_BUSINESS_TEMPLATE;
        newProj.RecordTypeId = retProjectRecordTypeId;
        insert newProj;

        //inserting Milestone
        pse__Milestone__c milestoneOrig = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestoneOrig.pse__Project__c = newProj.id;
        milestoneOrig.Name = 'test';
        insert milestoneOrig;

        //inserting Milestone
        pse__Milestone__c milestoneDuplic = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestoneDuplic.pse__Project__c = newProj.id;
        milestoneDuplic.Name = 'test';
        insert milestoneDuplic;

        pse__Project_Task__c newProjTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        newProjTask.pse__Project__c = newProj.id;
        newProjTask.pse__Milestone__c = milestoneDuplic.id;
        newProjTask.Name = 'test projectTask';
        insert newProjTask;



        }
    
    /***********************************************************************************************
    * MethodName: projectTaskMilestoneUpdateTest
    * Description : Unit test for project task milestone update before duplicate milestone 
    * ********************************************************************************************/
    @isTest
    static void projectTaskMilestoneUpdateTest(){
        try{
            //Given
            
            //When
            test.startTest();
            NSP_DeleteDuplicateMilestoneBatch batchSch = new NSP_DeleteDuplicateMilestoneBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest();

            //Then
            pse__Project_Task__c projectTaskRec = [SELECT Id,pse__Milestone__c FROM pse__Project_Task__c WHERE Name = 'test projectTask' LIMIT 1 ];
            pse__Milestone__c milestoneOrig = [SELECT Id FROM pse__Milestone__c WHERE Name = 'test' AND NSP_isDuplicate__c = false LIMIT 1];
            System.assertEquals(projectTaskRec.pse__Milestone__c,milestoneOrig.Id,'Project tasks milestone updated');

        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    /***********************************************************************************************
    * MethodName: milestoneWithSameNameDeletionTest
    * Description : Unit test for duplicate milestone deletion 
    * ********************************************************************************************/
    @isTest
    static void milestoneWithSameNameDeletionTest(){
        try{
            //Given
            
            //When
            test.startTest();
            NSP_DeleteDuplicateMilestoneBatch batchSch = new NSP_DeleteDuplicateMilestoneBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest();

            //Then
            String query = new NSP_QueryBuilder('pse__Milestone__c', MILESTONE_FIELDS).addFilter('Name', 'test').build();
            List<pse__Milestone__c> milestoneRecs = (List<pse__Milestone__c>) Database.query(query);
            System.assertEquals(1,milestoneRecs.size(),'Duplicate Milestone Deleted');

        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    /***********************************************************************************************
    * MethodName: milestoneWithDiffNameTest
    * Description : Unit test for No duplicate milestone  
    * ********************************************************************************************/
    @isTest
    static void milestoneWithDiffNameTest(){
        try{
            //Given
            pse__Project_Task__c projectTaskRec = [SELECT Id,pse__Milestone__c FROM pse__Project_Task__c WHERE Name = 'test projectTask' LIMIT 1 ];

            //inserting Milestone
            pse__Milestone__c milestoneNonDuplic = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
            milestoneNonDuplic.pse__Project__c = projectTaskRec.id;
            milestoneNonDuplic.Name = 'New Name';
            insert milestoneNonDuplic;

            //When
            test.startTest();
            NSP_DeleteDuplicateMilestoneBatch batchSch = new NSP_DeleteDuplicateMilestoneBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest();

            //Then
            String query = new NSP_QueryBuilder('pse__Milestone__c', MILESTONE_FIELDS).addFilter('Name', 'New Name').build();
            List<pse__Milestone__c> milestoneRecs = (List<pse__Milestone__c>) Database.query(query);
            System.assertEquals(1,milestoneRecs.size(),'Not a Duplicate Milestone ');

        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
}