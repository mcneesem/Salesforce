/**************************************************************************************************************************
*  Test Class for NSP_RET_ProjectSyncWithPlanSubplanBatch 
* Created By: Ramya Ravi
* Dated:      23/11/2022
* Version:     V1
*************************************************************************************************************************/
@isTest
public class NSP_RET_ProjectSyncWithPlanSubplanTest {

     @testSetup
    static void testDataSetup(){
       User testUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        
       //create Account Record
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert oAccount;
        
        //create Contact Record
		Contact contactObject = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);        
        contactObject.AccountId = oAccount.Id;
        contactObject.lastName= 'Test';
        contactObject.pse__Salesforce_User__c=testUser.Id;
        update contactObject;
      
        
         //inserting Project
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_RET_RECORDTYPE);
        pse__Proj__c oProject = (pse__Proj__c) NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults');       
        oProject.pse__Start_Date__c = Date.Today();
        oProject.Name = 'Test';
        oProject.pse__Account__c =oAccount.ID;
        oProject.pse__Is_Active__c = true;
        oProject.TemplateName__c = 'RET Deconversion 2020';
        oProject.RecordTypeId = retProjectRecordTypeId;
        oProject.pse__Is_Template__c = false;
        oProject.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSACTIVE;
        insert oProject;
        
         //create Plan Record
        Id choicePlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', NSP_ServiceConstants.CHOICE_RT_NAME);         
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = choicePlanRT;
        insert planRec;       

        //create Plan Sub Plan Record
        Id choiceSubPlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', NSP_ServiceConstants.CHOICE_RT_NAME);        
        NSP_Plan_SubPlan__c planSubplanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubplanRec.NSP_Subplan_Name__c = 'Test Subplan';
        planSubplanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubplanRec.NSP_Subplan_ID__c = '123';
        planSubplanRec.RecordTypeId = choiceSubPlanRT;
        insert planSubplanRec;  
        
        //inserting Asset
        Id RETCHOICEASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
        Asset asst = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        asst.AccountId = oAccount.Id;
        asst.ContactId = contactObject.Id;
        asst.NSP_Client__c = 'asset1';
        asst.name = 'assetLinked';
        asst.Status='Active';
        asst.recordTypeId = RETCHOICEASSETRECORDTYPE;
        asst.NSP_RET_Plan_and_Sub_Plan__c = planSubplanRec.ID;
        insert asst;
        
        //inserting project asset record
        Project_Asset__c projAssetLink = new Project_Asset__c();
        projAssetLink.Asset__c =asst.ID;
        projAssetLink.Project__c =oProject.ID;       
        insert projAssetLink;
                  
    }
     /***********************************************************************************************
    * MethodName: testBatchClass
    * Description : Unit test for NSP_RET_ProjectSyncWithPlanSubplanBatch 
    * ********************************************************************************************/
    @isTest
    static void testBatchClass(){
            test.startTest();                                                                                              
            NSP_RET_ProjectSyncWithPlanSubplanBatch batchSch = new NSP_RET_ProjectSyncWithPlanSubplanBatch();
            Database.executeBatch(batchSch, 200);
            batchSch.execute(null);
            test.stopTest(); 
        NSP_Plan__c planID = [SELECT Id FROM NSP_Plan__c WHERE Id != NULL LIMIT 1];
            pse__Proj__c proj = [SELECT id,NSP_Plan__c,NSP_Sub_Plan_Relationship__c, pse__Is_Active__c FROM pse__Proj__c WHERE pse__Is_Active__c = true LIMIT 1]    ;
            system.assertEquals(planID.ID , proj.NSP_Plan__c);
        
        
    }
    
}