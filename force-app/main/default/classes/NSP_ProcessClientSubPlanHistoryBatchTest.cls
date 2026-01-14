@isTest
private class NSP_ProcessClientSubPlanHistoryBatchTest {

    private static final Id CHOICECLIENTSUBPLANRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('NSP_Client_Sub_Plan_History__c', 'Choice');
    private static final Id RETSERVICESASSETRECORDTYPEID = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);

    @testSetup
    private static void setUpTestData() {
        ProcessClientSubPlanHistoryBatchSettings__c settings = ProcessClientSubPlanHistoryBatchSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.IsEnabledCurrentSubPlan__c = true;
        settings.BatchSize__c = 10;
        upsert settings;

        Id choicePlanSubPlanRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', 'Choice');
        Id choicePlanRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', 'Choice');

        //Creat a new Asset Record
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        newAsset.NSP_Client_is_Lead_Parent__c = true;
        newAsset.NSP_Price_Level__c= 'RET - Bundled Plus #2';
        Database.insert(newAsset);

        Asset newMemberAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        newMemberAsset.RecordTypeId = RETSERVICESASSETRECORDTYPEID;
        Database.insert(newMemberAsset);

        //Create a new Plan Record
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = choicePlanRecordTypeId;
        Database.insert(planRec);

        //Creat a new Plan Sub Plan Record and link it to Plan Record
        NSP_Plan_SubPlan__c planSubPlanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubPlanRec.RecordTypeId = choicePlanSubPlanRecordTypeId;
        planSubPlanRec.NSP_Subplan_ID__c = 'Test Plan Sub Plan 1';
        planSubPlanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubPlanRec.NSP_Subplan_Lead_Parent__c = newMemberAsset.Id;
        Database.insert(planSubPlanRec);

        //Create a new Client Sub Plan History Record and link it to Asset and Plan Sub Plan
        NSP_Client_Sub_Plan_History__c clientSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        clientSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        clientSubPlanHistRec.NSP_Asset__c = newAsset.Id;
        clientSubPlanHistRec.NSP_End_Date__c = null;
        clientSubPlanHistRec.NSP_Current_Subplan__c = true;
        clientSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientSubPlanHistRec.NSP_Start_Date__c = Date.today();
        clientSubPlanHistRec.NSP_Future_Lead_Parent__c = Date.today();
        Database.insert(clientSubPlanHistRec);

        NSP_Client_Sub_Plan_History__c clientMSubPlanHistRec = new NSP_Client_Sub_Plan_History__c();
        clientMSubPlanHistRec.RecordTypeId = CHOICECLIENTSUBPLANRECORDTYPEID;
        clientMSubPlanHistRec.NSP_Asset__c = newMemberAsset.Id;
        clientMSubPlanHistRec.NSP_End_Date__c = null;
        clientMSubPlanHistRec.NSP_Current_Subplan__c = true;
        clientMSubPlanHistRec.NSP_Plan_Subplan_Relationship__c = planSubPlanRec.Id;
        clientMSubPlanHistRec.NSP_Start_Date__c = Date.today();
        Database.insert(clientMSubPlanHistRec);
    }

    @isTest
    private static void runBatchTest() {
        list<NSP_Client_Sub_Plan_History__c> eacHistroy = new list<NSP_Client_Sub_Plan_History__c>([SELECT id,NSP_Current_Subplan__c from  NSP_Client_Sub_Plan_History__c WHERE NSP_Asset__c != null]);
        for(NSP_Client_Sub_Plan_History__c csph : eacHistroy){
            csph.NSP_Current_Subplan__c = false;
        }
        update eacHistroy;
        Test.startTest();
        NSP_ProcessClientSubPlanHistoryBatch bch = new NSP_ProcessClientSubPlanHistoryBatch();
        Database.executeBatch(bch,10);
        System.assert(eacHistroy[0].NSP_Current_Subplan__c == false);
        Test.stopTest();
    }

    @isTest
    private static void runBatchAssetTest() {
        Asset assobj  = [Select id,NSP_Client_is_Lead_Parent__c from Asset WHERE NSP_Client_is_Lead_Parent__c = true limit 1];
        assobj.NSP_Client_is_Lead_Parent__c = false;
        update  assobj;


        Test.startTest();
        NSP_ProcessClientSubPlanHistoryBatch bch = new NSP_ProcessClientSubPlanHistoryBatch();
        String sch = '20 30 8 10 2 ?';
        System.schedule('ClientSubP '+system.Now(), sch, bch);
        Test.stopTest();
        System.assert(assobj.NSP_Client_is_Lead_Parent__c == false);
    }

    @isTest
    private static void testSelfSchedulable() {
        Test.startTest();
        NSP_ProcessClientSubPlanHistoryBatch.schedule();
        Test.stopTest();
    }

}
//