@isTest
private class NSP_MilestoneTriggerHelperTest {

    private static final String PROJECTDEFAULTS = 'NSP_TestDataFactory.ProjectDefaults';
    private static final String MILESTONEDEFAULTS = 'NSP_TestDataFactory.MileStoneDefaults';
    private static final String TEST1 = 'test';

    private static final List<String> MILESTONE_FIELDS = new List<String>{
        'Id',
        'NSP_isDuplicate__c'
    };
    private static final List<String> PROJECT_TASK_FIELDS = new List<String>{
        'Id',
        'Name'
    };

    @testSetup
    private static void setupData() {
        //Test Setup
        Id PEORecordTypeId  = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PEOProject);
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get('PEO_Project_Task').getRecordTypeId();

        //Insert Test Account record
        Account accountRec = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        accountRec.Name = 'Test Account';
        INSERT accountRec;

        //Insert ACR record
        NSP_TestHelper.createContact(accountRec.Id, true);
        List<String> acrFields = new List<String>{'Id','ContactId','AccountId','NSP_Community_Access__c'};
            String query = new NSP_QueryBuilder('AccountContactRelation', acrFields)
            .addFilter('AccountId', accountRec.Id).addLimit(1).build();
        AccountContactRelation acrObj = Database.query(query);
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        UPDATE acrObj;

        Case oCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        insert oCase;

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECTDEFAULTS, false);
        oProject.pse__Start_Date__c = Date.Today();
        oProject.Name = 'Test Project';
        oPRoject.Case__c = oCase.Id;
        insert oProject;

        // inserting project
        pse__Proj__c peoProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        peoProject.Name = 'Test Project 1';
        peoProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        peoProject.RecordTypeId = PEORecordTypeId;
        peoProject.pse__Start_Date__c = system.today();
        peoProject.pse__Account__c =accountRec.Id;
        INSERT peoProject;

        pse__Milestone__c oMilestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        oMilestone.pse__Project__c = oProject.id;
        oMilestone.Name = TEST1;
        oMilestone.pse__Target_Date__c = System.Today().addDays(10);
        insert oMilestone;

        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.pse__Milestone__c = oMilestone.id;
        oProjectTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        insert oProjectTask1;

        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
        region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
    }

    @isTest
    private static void handleMilestoneCompletion() {
        pse__Proj__c oProject = [SELECT Id, Name from pse__Proj__c WHERE Id != null LIMIT 1];
        List<pse__Project_Task__c> lProjectTasks = new List<pse__Project_Task__c>([SELECT Id FROM pse__Project_Task__c WHERE pse__Project__c = :oProject.Id LIMIT 1]);
        List<pse__Milestone__c> lMileStones = new List<pse__Milestone__c>([SELECT Id FROM pse__Milestone__c WHERE pse__Project__c = :oProject.Id LIMIT 1]);
        Test.startTest();
        try{
            lProjectTasks[0].pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
            lProjectTasks[0].pse__Synchronize_Milestone_And_Task__c = false;
            update lProjectTasks[0];
            lMileStones[0].pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
            update lMileStones[0];
            lProjectTasks[0].pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
        update lProjectTasks[0];
        lMileStones[0].pse__Status__c = NSP_ServiceConstants.MILESTONESTATUSCOMPLETE;
        update lMileStones[0];
        }catch(Exception ex){
            System.assertEquals(NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS,[SELECT pse__Status__c FROM pse__Milestone__c WHERE Id =: lMileStones[0].Id].pse__Status__c);
        }
        Test.stopTest();
    }

    @isTest
    private static void updateRecordTypeUnitTest() {
        // create BPS Project
        pse__Proj__c bpsProject =  (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECTDEFAULTS, false);
        bpsProject.pse__Start_Date__c = Date.Today();
        bpsProject.Name = 'TestBPS';
        bpsProject.RecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('TES_BPS')?.getRecordTypeId();
        insert bpsProject;

        // create PEOproject
        pse__Proj__c peoProject =  (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECTDEFAULTS, false);
        peoProject.pse__Start_Date__c = Date.Today();
        peoProject.Name = 'TestPEO';
        peoProject.RecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project')?.getRecordTypeId();
        insert peoProject;


        List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
        //create bps milestone
        pse__Milestone__c bpsMilestone =  (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        bpsMilestone.pse__Project__c = bpsProject.Id;
        bpsMilestone.pse__Target_Date__c = System.Today().addDays(10);
        milestoneList.add(bpsMilestone);

        // create  peo milestone
        pse__Milestone__c peoMilestone =  (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        peoMilestone.pse__Project__c = peoProject.Id;
        peoMilestone.pse__Target_Date__c = System.Today().addDays(10);
        milestoneList.add(peoMilestone);
        String peoAPIname = NSP_ServiceConstants.PEOMILSTONE;
        String bpsAPIname = NSP_ServiceConstants.BPSMILESTONE;

        Id recordTypeIdBPS = SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get(bpsAPIname).getRecordTypeId();
        Id recordTypeIdPEO = SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get(peoAPIname).getRecordTypeId();

        Test.startTest();
        insert milestoneList;
        System.assertEquals(recordTypeIdBPS ,[SELECT RecordTypeId FROM pse__Milestone__c WHERE ID = : milestoneList[0].Id ].RecordTypeId);
        System.assertEquals(recordTypeIdPEO ,[SELECT RecordTypeId FROM pse__Milestone__c WHERE ID = : milestoneList[1].Id ].RecordTypeId);
        Test.stopTest();

    }

    @isTest
    private static void updateTargetDateTest() {

        // create PEO project
        pse__Proj__c peoProject =  (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECTDEFAULTS, false);
        peoProject.pse__Start_Date__c = System.Today();
        peoProject.Name = 'TestPEO';
        peoProject.RecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project')?.getRecordTypeId();
        peoProject.TemplateName__c= label.Middle_Market_Implementation_Project;
        peoProject.pse__End_Date__c = System.Today().addDays(180);
        insert peoProject;

        // create milestone
        pse__Milestone__c peoMilestone =  (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        peoMilestone.pse__Project__c = peoProject.Id;
        peoMilestone.pse__Target_Date__c = System.Today().addDays(10);

        Test.startTest();
        Insert peoMilestone;
        Test.stopTest();
        pse__Milestone__c milestone = [Select Id , pse__Start_Date__c, pse__Target_Date__c from pse__Milestone__c WHERE  pse__Project__c = :peoProject.Id ];
        System.assertEquals(peoProject.pse__Start_Date__c, milestone.pse__Start_Date__c);
    }

    @isTest
    private static void checkDuplicateMilestoneTest() {
        //Given
        String query1 = new NSP_QueryBuilder('pse__Proj__c', PROJECT_TASK_FIELDS).addStartsWithFilter('Name' , 'Test').addLimit(1).build();
        pse__Proj__c projectRec =  Database.query(query1);

        // create milestone
        pse__Milestone__c milestoneDuplic =  (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        milestoneDuplic.pse__Project__c = projectRec.Id;
        milestoneDuplic.Name = TEST1;

        //When
        Test.startTest();
        Insert milestoneDuplic;
        Test.stopTest();

        //Then
        String query2 = new NSP_QueryBuilder('pse__Milestone__c', MILESTONE_FIELDS).addFilter('Name', TEST1).build();
        List<pse__Milestone__c> milestoneRecs = (List<pse__Milestone__c>) Database.query(query2);

        System.assertNotEquals(milestoneRecs[0].NSP_isDuplicate__c, milestoneRecs[1].NSP_isDuplicate__c,'One Milstone Marked as duplicate');
    }

    @isTest
    private static void testMilestoneSharing() {
        List<String> accFields = new List<String>{'Id','Name'};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter('Name', 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        List<String> projFields = new List<String>{'Id'};
        String query = new NSP_QueryBuilder('pse__Proj__c', projFields)
            .addFilter('pse__Account__c', acc.Id).addLimit(1).build();
        pse__Proj__c projRec = Database.query(query);

        pse__Milestone__c milestoneRec = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        milestoneRec.pse__Project__c = projRec.Id;
        milestoneRec.NSP_Visible_to_Client__c = true;
        milestoneRec.pse__Target_Date__c = System.Today().addDays(10);

        Test.startTest();
        INSERT milestoneRec;
        Test.stopTest();
    }

    @isTest
    private static void testNoMilestoneSharing() {
        List<String> accFields = new List<String>{'Id','Name'};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter('Name', 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        List<String> projFields = new List<String>{'Id'};
        String query = new NSP_QueryBuilder('pse__Proj__c', projFields)
            .addFilter('pse__Account__c', acc.Id).addLimit(1).build();
        pse__Proj__c projRec = Database.query(query);

        pse__Milestone__c milestoneRec = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
        milestoneRec.pse__Project__c = projRec.Id;
        milestoneRec.pse__Target_Date__c = System.Today().addDays(10);

        Test.startTest();
        INSERT milestoneRec;
        System.assertEquals(0,[SELECT Id , ParentId , UserorGroupId
                               FROM pse__Milestone__share
                               WHERE ParentId =:milestoneRec.Id
                               AND RowCause = :Schema.pse__Milestone__share.RowCause.InsperitySharing__c ].Size());
        Test.stopTest();
    }

}
//