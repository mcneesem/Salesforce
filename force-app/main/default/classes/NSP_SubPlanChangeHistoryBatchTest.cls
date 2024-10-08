/**
* @description  :   Test class for NSP_SubPlanChangeHistoryBatch .
* @date 09/09/2022
* Author : Viendra Kumar
* Name : NSP_SubPlanChangeHistoryBatchTest
*/
@isTest
public class NSP_SubPlanChangeHistoryBatchTest {
    
    /***********************************************************************************************
    * MethodName: createTestData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    
    @testSetup
    public static void createTestData (){

        //Get Record Types Id for WO
        Id WOPlanRT = Schema.SObjectType.NSP_Plan__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_RT_NAME).getRecordTypeId();
        Id WOSubPlanRT = Schema.SObjectType.NSP_Plan_SubPlan__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_RT_NAME).getRecordTypeId();
        Id WOSubPlanHisRT = Schema.SObjectType.NSP_Sub_Plan_Change_History__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_RT_NAME).getRecordTypeId();
        
        //Insert new Plan with WO Record Type
        NSP_Plan__c plan = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        plan.RecordTypeId = WOPlanRT;
        insert plan;
        
        //Insert new Sub Plan with WO Record Type
        NSP_Plan_SubPlan__c subPlan = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        subPlan.NSP_Parent_Plan_ID__c = plan.Id;
        subPlan.RecordTypeId = WOSubPlanRT;
        insert subPlan ;
        
        //Insert new Sub Plan Change History with WO Record Type
        NSP_Sub_Plan_Change_History__c subPlanHist = (NSP_Sub_Plan_Change_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Plan_Change_History__c(), 'NSP_TestDataFactory.SubPlanChangeHistoryDefaults', false);
        subPlanHist.NSP_Plan_ID__c = plan.Id;
        subPlanHist.NSP_Plan_Subplan_Relationship__c = subPlan.Id;
        subPlanHist.RecordTypeId = WOSubPlanHisRT;
        insert subPlanHist ;
        
    } 
    
    /***********************************************************************************************
    * MethodName: shouldTestUpdateOfSubPlanFieldsFromSubPlanChangeHistory
    * Description : Unit test for updating NSP_Auto_Deferral__c, NSP_Status__c, NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c FROM SubPlanChangeHistory On Insert
    * ********************************************************************************************/
    public static testmethod void shouldTestUpdateOfSubPlanFieldsFromSubPlanChangeHistory(){
        Test.startTest();     
        
        NSP_SubPlanChangeHistoryBatch subPlanChangeHistoryBatch = new NSP_SubPlanChangeHistoryBatch();
        Database.executeBatch(subPlanChangeHistoryBatch);  
        String chroneExp = '0 0 23 * * ?';
        system.schedule('Test NSP_SubPlanChangeHistoryBatch', chroneExp, subPlanChangeHistoryBatch);
        
        Test.stopTest();
        NSP_Plan_SubPlan__c planSubRec = [SELECT Id,NSP_Parent_Plan_ID__c,NSP_Auto_Deferral__c,NSP_Status__c ,NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c  FROM NSP_Plan_SubPlan__c WHERE NSP_Status__c != '' LIMIT 1];
        NSP_Sub_Plan_Change_History__c subplanChanRec = [SELECT Id, NSP_Plan_ID__c, NSP_Plan_Subplan_Relationship__c,NSP_Auto_Deferral__c, NSP_Status__c ,NSP_Plan_Effective_Date__c , NSP_Plan_Type__c,RecordTypeId FROM NSP_Sub_Plan_Change_History__c WHERE NSP_Status__c != ''  LIMIT 1];
        
        System.assertEquals(planSubRec.NSP_Auto_Deferral__c, subplanChanRec.NSP_Auto_Deferral__c,'Sub Plan Auto Deferral should be same as Sub Plan Change History');
        System.assertEquals(planSubRec.NSP_Status__c, subplanChanRec.NSP_Status__c,'Sub Plan Status should be same as Sub Plan Change History');
        System.assertEquals(planSubRec.NSP_Plan_Effective_Date__c, subplanChanRec.NSP_Plan_Effective_Date__c,'Sub Plan Plan Effective Date should be same as Sub Plan Change History');
        System.assertEquals(planSubRec.NSP_Plan_Type__c, subplanChanRec.NSP_Plan_Type__c,'Sub Plan Plan Type should be same as Sub Plan Change History');
        
    }
   
}