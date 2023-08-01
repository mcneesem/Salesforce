/**
* @description  :   Test class for NSP_RetEducationRecSyncBatch .
* @date 10/14/2022
* Author : Abhishek Kumar
* Name : NSP_RetEducationRecSyncBatchTest
*/
@isTest
public class NSP_RetEducationRecSyncBatchTest {
    /***********************************************************************************************
    * MethodName: testData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    
    @testSetup
    static void setupTestData(){
        //Get Record type Id of Retirement_Services
        Id AssetRecordTypeId  = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
        Id choicePlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', NSP_ServiceConstants.CHOICE_RT_NAME);
        Id choiceSubPlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', NSP_ServiceConstants.CHOICE_RT_NAME);

        //User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        
        //create Account Record
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert accoutObject;

        //create Asset Record
        Asset assetObj1 = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj1.NSP_Client__c = 'asset1';
        assetObj1.name = 'assetLinkedWithPlanSubPlan';
        assetObj1.RecordTypeId = AssetRecordTypeId;
        insert assetObj1;

        //Insert new Plan with Choice Record Type
        NSP_Plan__c plan = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        plan.RecordTypeId = choicePlanRT;
        insert plan;
        
        //Insert new Sub Plan with Choice Record Type
        NSP_Plan_SubPlan__c subPlan = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        subPlan.NSP_Parent_Plan_ID__c = plan.Id;
        subPlan.NSP_Subplan_Lead_Parent__c = assetObj1.Id;
        subPlan.RecordTypeId = choiceSubPlanRT;
        subPlan.NSP_Subplan_Name__c = 'Test Subplan';
        insert subPlan ;
        
        //Insert new RET Education
        AssetRETEducationAssociation__c retEducation = new AssetRETEducationAssociation__c();
        retEducation.NSP_Education_Client__c = assetObj1.Id;
        retEducation.NSP_Subplan__c = subPlan.Id;
        retEducation.NSP_Status__c = 'Active';
        insert retEducation;

        }
    
    /***********************************************************************************************
    * MethodName: retEdRecSyncWithAsset
    * Description : Unit test for retEdRecSyncWithAsset 
    * ********************************************************************************************/
    @isTest
    static void retEdRecSyncWithAsset(){
        try{
            //Given
            List<AssetRETEducationAssociation__c> retEdRecList = [SELECT ID,NSP_Subplan__c
                                                       FROM AssetRETEducationAssociation__c 
                                                       WHERE Name = 'Test RET Education' ];
            NSP_Plan_SubPlan__c subPlan = [SELECT Id FROM NSP_Plan_SubPlan__c 
                                           WHERE NSP_Subplan_Name__c = 'Test Subplan' ];
            
            //When
            test.startTest();
            NSP_RetEducationRecSyncBatch batchSch = new NSP_RetEducationRecSyncBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest();
            //Then
            System.assertEquals(subPlan.Id, retEdRecList[0].NSP_Subplan__c,'Synced with Asset');
        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
}