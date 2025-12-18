@isTest
private class NSP_ClientSubPlanHistoryBatchTest {
    private static final Id CHOICECLIENTSUBPLANRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
    private static final Id RETCHOICEASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
    private static final Id RETWOASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_WO');

    @testSetUp
    private static void setUpTestData() {
        ClientSubPlanHistoryBatchSettings__c settings = ClientSubPlanHistoryBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        settings.BatchSize__c = 200;
        settings.SkewedAssetOwnerIds__c = 'INVALIDID';
        upsert settings;

        Id choicePlanSubPlanRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', 'Choice');
        Id choicePlanRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', 'Choice');

        //Create a new Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset.RecordTypeId = RETCHOICEASSETRECORDTYPE;
        newAsset.Status = 'Purchased';
        Database.insert(newAsset);

        Asset newAsset1 = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset1.RecordTypeId = RETWOASSETRECORDTYPE;
        Database.insert(newAsset1);

        Asset newAsset2 = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset2.RecordTypeId = RETWOASSETRECORDTYPE;
        newAsset2.Status = NSP_ServiceConstants.TERMINATED;
        newAsset2.NSP_Termination_Date__c = System.today();
        Database.insert(newAsset2);

        //Create a new Plan Record
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = choicePlanRecordTypeId;
        Database.insert(planRec);

        //Creat a new Plan Sub Plan Record and link it to Plan Record
        NSP_Plan_SubPlan__c planSubPlanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubPlanRec.RecordTypeId = choicePlanSubPlanRecordTypeId;
        planSubPlanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubPlanRec.NSP_Subplan_ID__c = 'Test Plan Sub Plan 1';
        Database.insert(planSubPlanRec);

        //Create Client Sub Plan History Records and link it to Asset and Plan Sub Plan
        List<NSP_Client_Sub_Plan_History__c> clientSubPlanHistoryList = new List<NSP_Client_Sub_Plan_History__c>();
        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec = (NSP_Client_Sub_Plan_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Client_Sub_Plan_History__c(), 'NSP_TestDataFactory.clientSubPlanHistoryDefaults', false);
        clientSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        clientSubPlanHistRec.NSP_Asset__c = newAsset.Id;
        clientSubPlanHistRec.NSP_End_Date__c = System.today();
        clientSubPlanHistRec.NSP_Start_Date__c = System.today().addDays(+1);
        clientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistoryList.add(clientSubPlanHistRec);

        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec1 = (NSP_Client_Sub_Plan_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Client_Sub_Plan_History__c(), 'NSP_TestDataFactory.clientSubPlanHistoryDefaults', false);
        clientSubPlanHistRec1.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        clientSubPlanHistRec1.NSP_Asset__c = newAsset.Id;
        clientSubPlanHistRec1.NSP_End_Date__c = System.today();
        clientSubPlanHistRec1.NSP_Start_Date__c = System.today().addDays(+1);
        clientSubPlanHistRec1.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistoryList.add(clientSubPlanHistRec1);

        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec2 = (NSP_Client_Sub_Plan_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Client_Sub_Plan_History__c(), 'NSP_TestDataFactory.clientSubPlanHistoryDefaults', false);
        clientSubPlanHistRec2.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        clientSubPlanHistRec2.NSP_Asset__c = newAsset1.Id;
        clientSubPlanHistRec2.NSP_End_Date__c = NULL;
        clientSubPlanHistRec2.NSP_Start_Date__c = System.today().addDays(+1);
        clientSubPlanHistRec2.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistoryList.add(clientSubPlanHistRec2);

        Database.insert(clientSubPlanHistoryList);
    }

    @isTest
    private static void testSchedule() {
        Test.startTest();
        NSP_ClientSubPlanHistoryBatch.schedule();
        Test.stopTest();
    }

    @isTest
    private static void updateFieldsOnNonTerminatingAssetRecord() {
        Asset getAssetRec = [SELECT Id, Status, NSP_Termination_Date__c FROM Asset WHERE RecordTypeId =: RETCHOICEASSETRECORDTYPE AND Status = 'Purchased' LIMIT 1];
        NSP_Plan_SubPlan__c getPlanSubPlanRec = [SELECT Id FROM NSP_Plan_SubPlan__c
                                                 WHERE NSP_Subplan_ID__c = 'Test Plan Sub Plan 1' LIMIT 1];
        //Create another client sub plan history matching the criteria
        NSP_Client_Sub_Plan_History__c newClientSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        newClientSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        newClientSubPlanHistRec.NSP_Asset__c = getAssetRec.Id;
        newClientSubPlanHistRec.NSP_End_Date__c = System.today();
        newClientSubPlanHistRec.NSP_Start_Date__c = System.today().addDays(+1);
        newClientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = getPlanSubPlanRec.Id;

        test.startTest();
        NSP_ClientSubPlanHistoryBatch batchSch = new NSP_ClientSubPlanHistoryBatch();
        Database.executeBatch(batchSch, 200);
        batchSch.execute(null);
        test.stopTest();
        Asset updatedAssetRec = [SELECT Id, Status, NSP_Termination_Date__c FROM Asset WHERE RecordTypeId =: RETCHOICEASSETRECORDTYPE LIMIT 1];
        System.assertNotEquals('Purchased',updatedAssetRec.Status);
        System.assertEquals( NSP_ServiceConstants.TERMINATED, updatedAssetRec.Status);
        System.assertEquals(newClientSubPlanHistRec.NSP_End_Date__c, updatedAssetRec.NSP_Termination_Date__c);

    }

    @isTest
    private static void updateFieldsOnTerminatingAssetRecord() {
        Asset getAssetRec = [SELECT Id, Status, NSP_Termination_Date__c FROM Asset WHERE RecordTypeId =: RETWOASSETRECORDTYPE AND Status = 'Terminated' LIMIT 1];
        NSP_Plan_SubPlan__c getPlanSubPlanRec = [SELECT Id FROM NSP_Plan_SubPlan__c
                                                 WHERE NSP_Subplan_ID__c = 'Test Plan Sub Plan 1' LIMIT 1];

        //Create another client sub plan history matching the criteria
        NSP_Client_Sub_Plan_History__c newClientSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        newClientSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        newClientSubPlanHistRec.NSP_Asset__c = getAssetRec.Id;
        newClientSubPlanHistRec.NSP_End_Date__c = null;
        newClientSubPlanHistRec.NSP_Start_Date__c = System.today();
        newClientSubPlanHistRec.NSP_Current_Subplan__c = true;
        newClientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = getPlanSubPlanRec.Id;

        test.startTest();
        NSP_ClientSubPlanHistoryBatch batchSch = new NSP_ClientSubPlanHistoryBatch();
        Database.executeBatch(batchSch, 200);
        batchSch.execute(null);
        test.stopTest();
        Asset updatedAssetRec = [SELECT Id, Status, NSP_Termination_Date__c FROM Asset WHERE RecordTypeId =: RETWOASSETRECORDTYPE LIMIT 1];
        System.assertEquals( NULL, updatedAssetRec.Status);
        System.assertEquals(null, updatedAssetRec.NSP_Termination_Date__c);

    }

    @isTest
    private static void updateFieldsOnAssetRecordNegativeTest() {
        Asset getAssetRec = [SELECT Id, Status, NSP_Termination_Date__c FROM Asset WHERE RecordTypeId =: RETWOASSETRECORDTYPE LIMIT 1];
        test.startTest();
        NSP_ClientSubPlanHistoryBatch batchSch = new NSP_ClientSubPlanHistoryBatch();
        Database.executeBatch(batchSch, 200);
        batchSch.execute(null);
        test.stopTest();

        System.assertEquals(NULL, getAssetRec.Status);
        System.assertEquals(NULL, getAssetRec.NSP_Termination_Date__c);
    }

}
//