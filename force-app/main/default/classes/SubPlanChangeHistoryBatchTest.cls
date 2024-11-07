@isTest private class SubPlanChangeHistoryBatchTest {

    @testSetup private static void Prepare_Test_Data () {
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
        subPlanHist.Exemption_Date__c = Date.today()-5;
        subPlanHist.Exemption_Type__c = 'Grandfathered';
        subPlanHist.LTPT_Term_Date__c = Date.today()-5;
        subPlanHist.LTPT_Effective_Date__c = Date.today()-5;
        subPlanHist.Allows_LT_Employer_Contributions__c = true;
        subPlanHist.Is_Mandatory__c = true;
        subPlanHist.Is_QACA__c = true;
        subPlanHist.Escalation_Max__c = 2;
        subPlanHist.Auto_Escalate__c = 3;
        subPlanHist.Auto_Enroll_Effective_Date__c = Date.today()-4;
        subPlanHist.NSP_Status__c = 'Transferred';
        insert subPlanHist ;
        
        // ASSERTS
        Assert.isNotNull(subPlanHist, 'Should not be null for the batch execution');
        Assert.isNotNull(subPlan, 'Should not be null for the batch execution');
        Assert.isTrue(subPlanHist.NSP_Plan_Subplan_Relationship__c == subPlan.Id);
        Assert.isTrue(subPlanHist.NSP_Plan_ID__c == plan.Id);
        Assert.areEqual(subPlanHist.NSP_Status__c, 'Transferred');
        Assert.areEqual(subPlanHist.Exemption_Type__c, 'Grandfathered');
    }

    // Testing the batch execution
    @isTest private static void Test_Batch_Logic() {
        Database.executeBatch(new SubPlanChangeHistoryBatch(), 200);
    }

    // Testing the schedule
    @isTest private static void Test_ScheduleBatch(){ 
        // Insert custom setting
        SubPlanChangeHistoryBatchSettings__c testSetting = new SubPlanChangeHistoryBatchSettings__c();
        testSetting.IsEnabled__c = true;
        insert testSetting;
        
        NSP_SubPlanChangeHistoryBatch subPlanChangeHistoryBatch = new NSP_SubPlanChangeHistoryBatch();
        String chroneExp = '0 0 23 * * ?';
        system.schedule('Test NSP_SubPlanChangeHistoryBatch', chroneExp, subPlanChangeHistoryBatch);
    } 

    // Testing the schedule
    @isTest private static void Test_NSP_SubPlanChangeHistoryBatch(){ 
        NSP_SubPlanChangeHistoryBatch subPlanChangeHistoryBatch = new NSP_SubPlanChangeHistoryBatch();
        String chroneExp = '0 0 23 * * ?';
        system.schedule('Test NSP_SubPlanChangeHistoryBatch', chroneExp, subPlanChangeHistoryBatch);
    }

    // Testing the NSP_SubPlanChangeHistoryBatch
    @isTest private static void Test_NSP_SubPlanChangeHistoryBatch_Execution(){ 
        // Insert custom setting
        SubPlanChangeHistoryBatchSettings__c testSetting = new SubPlanChangeHistoryBatchSettings__c();
        testSetting.IsEnabledRetFields__c = true;
        insert testSetting;
        Database.executeBatch(new NSP_SubPlanChangeHistoryBatch(), 200);
    }

}