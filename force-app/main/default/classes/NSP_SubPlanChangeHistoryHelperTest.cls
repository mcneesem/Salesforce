/**
* @description  :   Test class for NSP_SubPlanChangeHistoryHelper .
* @date 09/09/2022
* Author : Viendra Kumar
* Name : NSP_SubPlanChangeHistoryHelperTest
*/
@isTest
public class NSP_SubPlanChangeHistoryHelperTest {
    
    /***********************************************************************************************
    * MethodName: createTestData
    * Description : Setting the Test Data
    * ********************************************************************************************/
    @testSetup
    public static void createTestData (){
        
        //Get Record Types Id for Choice
        Id choicePlanRT = Schema.SObjectType.NSP_Plan__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.CHOICE_RT_NAME).getRecordTypeId();
        Id choiceSubPlanRT = Schema.SObjectType.NSP_Plan_SubPlan__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.CHOICE_RT_NAME).getRecordTypeId();
        Id choiceSubPlanHisRT = Schema.SObjectType.NSP_Sub_Plan_Change_History__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.CHOICE_RT_NAME).getRecordTypeId();
        
        //Insert new Plan with Choice Record Type
        NSP_Plan__c plan = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        plan.RecordTypeId = choicePlanRT;
        insert plan;
        
        //Insert new Sub Plan with Choice Record Type
        NSP_Plan_SubPlan__c subPlan = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        subPlan.NSP_Parent_Plan_ID__c = plan.Id;
        subPlan.RecordTypeId = choiceSubPlanRT;
        insert subPlan ;
        
        //Insert new Sub Plan Change History with Choice Record Type
        NSP_Sub_Plan_Change_History__c subPlanHist = (NSP_Sub_Plan_Change_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Plan_Change_History__c(), 'NSP_TestDataFactory.SubPlanChangeHistoryDefaults', false);
        subPlanHist.NSP_Plan_ID__c = plan.Id;
        subPlanHist.NSP_Plan_Subplan_Relationship__c = subPlan.Id;
        subPlanHist.RecordTypeId = choiceSubPlanHisRT;
        insert subPlanHist ;
        
    } 
    
    /***********************************************************************************************
    * MethodName: shouldTestUpdateOfSubPlanFieldsFromSubPlanChangeHistoryOnInsert
    * Description : Unit test for updating NSP_Auto_Deferral__c, NSP_Status__c, NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c FROM SubPlanChangeHistory On Insert
    * ********************************************************************************************/
    public static testmethod void shouldTestUpdateOfSubPlanFieldsFromSubPlanChangeHistoryOnInsert(){
        Test.startTest();      
        
        NSP_Plan_SubPlan__c planSubRec = [SELECT Id,NSP_Parent_Plan_ID__c,NSP_Auto_Deferral__c,NSP_Status__c ,NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c  FROM NSP_Plan_SubPlan__c WHERE NSP_Status__c != '' LIMIT 1];
        NSP_Sub_Plan_Change_History__c subplanChanRec = [SELECT Id, NSP_Plan_ID__c, NSP_Plan_Subplan_Relationship__c,NSP_Auto_Deferral__c, NSP_Status__c ,NSP_Plan_Effective_Date__c , NSP_Plan_Type__c,RecordTypeId FROM NSP_Sub_Plan_Change_History__c WHERE NSP_Status__c != '' LIMIT 1];
        
        Test.stopTest();
        System.assertEquals(planSubRec.NSP_Auto_Deferral__c,subplanChanRec.NSP_Auto_Deferral__c,'Sub Plan Auto Deferral should be same as Sub Plan Change History');
        System.assertEquals(planSubRec.NSP_Status__c,subplanChanRec.NSP_Status__c,'Sub Plan Status should be same as Sub Plan Change History');
        System.assertEquals(planSubRec.NSP_Plan_Effective_Date__c,subplanChanRec.NSP_Plan_Effective_Date__c,'Sub Plan Plan Effective Date should be same as Sub Plan Change History');
        System.assertEquals(planSubRec.NSP_Plan_Type__c,subplanChanRec.NSP_Plan_Type__c,'Sub Plan Plan Type should be same as Sub Plan Change History');
        
       
        
    }
    
    /***********************************************************************************************
    * MethodName: shouldTestUpdateOfSubPlanFieldsFromSubPlanChangeHistoryOnUpdate
    * Description : Unit test for updating NSP_Auto_Deferral__c, NSP_Status__c, NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c FROM SubPlanChangeHistory On Update
    * ********************************************************************************************/
    public static testmethod void shouldTestUpdateOfSubPlanFieldsFromSubPlanChangeHistoryOnUpdate(){
        Test.startTest();
        
        NSP_Plan_SubPlan__c planSubRec = [SELECT Id,NSP_Parent_Plan_ID__c,NSP_Auto_Deferral__c,NSP_Status__c ,NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c FROM NSP_Plan_SubPlan__c WHERE NSP_Status__c != '' LIMIT 1];
        NSP_Sub_Plan_Change_History__c subplanChanRec = [SELECT Id, NSP_Plan_ID__c, NSP_Plan_Subplan_Relationship__c,NSP_Auto_Deferral__c, NSP_Status__c ,NSP_Plan_Effective_Date__c , NSP_Plan_Type__c,RecordTypeId FROM NSP_Sub_Plan_Change_History__c WHERE NSP_Status__c != '' LIMIT 1 ];
        subplanChanRec.NSP_Auto_Deferral__c = 11;
        subplanChanRec.NSP_Plan_Effective_Date__c = System.today() - 2;
        Update subplanChanRec;
        
        Test.stopTest();
        NSP_Plan_SubPlan__c updatedSubPlan = [SELECT Id,NSP_Auto_Deferral__c,NSP_Status__c ,NSP_Plan_Effective_Date__c,NSP_Plan_Type__c ,NSP_Original_PE_Date__c FROM NSP_Plan_SubPlan__c  WHERE Id =:planSubRec.Id];
        
        System.assertEquals(updatedSubPlan.NSP_Auto_Deferral__c,subplanChanRec.NSP_Auto_Deferral__c,'Sub Plan Auto Deferral should be same as Sub Plan Change History');
        System.assertEquals(updatedSubPlan.NSP_Plan_Effective_Date__c,subplanChanRec.NSP_Plan_Effective_Date__c,'Sub Plan Plan Effective Date should be same as Sub Plan Change History');
                
    }
}