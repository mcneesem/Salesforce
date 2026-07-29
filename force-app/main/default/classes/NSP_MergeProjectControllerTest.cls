@isTest
private class NSP_MergeProjectControllerTest {

    @testSetup
    private static void setupProjectData() {
        // Create Acc records with external id
        Account charlieAcc = new Account(Name = 'Charlie', NSP_OneVoice_External_ID__c = 'charlieAcc');
        Account charlieAccRef = new Account(NSP_OneVoice_External_ID__c = 'charlieAcc');

        Account rogerAcc = new Account(Name = 'Roger', NSP_OneVoice_External_ID__c = 'rogerAcc');
        Account rogerAccRef = new Account(NSP_OneVoice_External_ID__c = 'rogerAcc');

        // Create Asset Records
        Asset woAsset = new Asset(Name = 'WO', NSP_Asset_External_ID__c = 'woAsset', Account = charlieAccRef);
        Asset woAssetRef = new Asset(NSP_Asset_External_ID__c = 'woAsset');

        Asset wxAsset = new Asset(Name = 'WX', NSP_Asset_External_ID__c = 'wxAsset', Account = charlieAccRef);
        Asset wxAssetRef = new Asset(NSP_Asset_External_ID__c = 'wxAsset');

        // Create Project records
        pse__Proj__c hrSystemProj = new pse__Proj__c();
        hrSystemProj.name = 'HR Management System';
        hrSystemProj.pse__Is_Active__c = true;
        hrSystemProj.NSP_OneVoice_External_ID__c = 'hrSystemProj';
        hrSystemProj.pse__Account__r = charlieAccRef;

        pse__Proj__c hrSystemProjRef = new pse__Proj__c(NSP_OneVoice_External_ID__c = 'hrSystemProj');

        pse__Proj__c financeProj = new pse__Proj__c();
        financeProj.name = 'Finance Management System';
        financeProj.pse__Is_Active__c = true;
        financeProj.NSP_OneVoice_External_ID__c = 'financeProj';
        financeProj.pse__Account__r = charlieAccRef;

        // Create Milestone
        pse__Milestone__c milestoneRec = new pse__Milestone__c(Name = 'HR Project Onboarding UI', pse__Project__r = hrSystemProjRef);
        milestoneRec.pse__Target_Date__c = System.today();

        // Create Project Tasks
        pse__Project_Task__c configurationProjTask = new pse__Project_Task__c(Name = 'Configure Project', pse__Project__r = hrSystemProjRef);
        pse__Project_Task__c dataCreationProjTask = new pse__Project_Task__c(Name = 'Create required records', pse__Project__r = hrSystemProjRef);

        // Create Project Account records
        Project_Account__c hrSystem_rogerMapping = new Project_Account__c(Project__r = hrSystemProjRef, Account__r = rogerAccRef);

        // Create Project Asset records
        Project_Asset__c hrSystem_woMapping = new Project_Asset__c(Project__r = hrSystemProjRef, Asset__r = woAssetRef);
        Project_Asset__c hrSystem_wxMapping = new Project_Asset__c(Project__r = hrSystemProjRef, Asset__r = wxAssetRef);

        // Create Order
        Order orderObj = (Order)NSP_TestExtendedDataFactory.createSObject(new Order(), false);
        orderObj.NSP_Project__r = hrSystemProjRef;
        orderObj.Account = charlieAccRef;


        // Create the account, project, milestone, project accounts.
        Test.startTest();
        Database.SaveResult[] results = Database.insert(new SObject[] {
            charlieAcc, rogerAcc, hrSystemProj, financeProj, hrSystem_rogerMapping,
            milestoneRec, configurationProjTask, dataCreationProjTask, woAsset,
            wxAsset, hrSystem_woMapping, hrSystem_wxMapping,orderObj
        });
        Test.stopTest();
    }

    // Verify the related records of child project are getting deleted or not
    @isTest
    private static void mergeProjectMethodDeletesAllRelatedRecords() {
        // GIVEN
        pse__Proj__c parentProj = [SELECT Id FROM pse__Proj__c WHERE NSP_OneVoice_External_ID__c = 'financeProj' AND pse__Account__c != null LIMIT 1];
        pse__Proj__c childProj = [SELECT Id FROM pse__Proj__c WHERE NSP_OneVoice_External_ID__c = 'hrSystemProj' AND pse__Account__c != null LIMIT 1];
        String childProjId = childProj.Id;
        List<String> projectIdsToMerge = new List<String>{ parentProj.Id, childProjId };
        List<SObject> emptyList = new List<SObject>();

        // Fetch existing records
        List<pse__Milestone__c> existingMilestones = [SELECT Id FROM pse__Milestone__c WHERE pse__Project__c = :childProjId];
        List<Project_Account__c> existingProjAccs = [SELECT Id FROM Project_Account__c WHERE Project__c = :childProjId];
        List<pse__Project_Task__c> existingTasks = [SELECT Id FROM pse__Project_Task__c WHERE pse__Project__c = :childProjId];
        List<Project_Asset__c> existingProjAssets = [SELECT Id FROM Project_Asset__c WHERE Project__c = :childProjId];

        // Assert existing records
        System.assertEquals(1, existingMilestones.size());
        System.assertEquals(1, existingProjAccs.size());
        System.assertEquals(2, existingTasks.size());
        System.assertEquals(2, existingProjAssets.size());

        // WHEN
        Test.startTest();
        NSP_MergeProjectController.mergeProject(new List<List<String>>{ projectIdsToMerge });
        Test.stopTest();

        // THEN
        pse__Proj__c childProj1 = [SELECT Id, NSP_Queued_for_Delete__c FROM pse__Proj__c WHERE Id = :childProjId];
        System.assert(childProj1.NSP_Queued_for_Delete__c);
    }

    // Verify mapping records are moving to parent project or not
    @isTest
    private static void mergeProjectMethodCreateMappingRecordsOnParentProject() {
        // GIVEN
        pse__Proj__c parentProj = [SELECT Id FROM pse__Proj__c WHERE NSP_OneVoice_External_ID__c = 'financeProj' AND pse__Account__c != null LIMIT 1];
        pse__Proj__c childProj = [SELECT Id FROM pse__Proj__c WHERE NSP_OneVoice_External_ID__c = 'hrSystemProj' AND pse__Account__c != null LIMIT 1];

        String childProjId = childProj.Id;
        List<String> projectIdsToMerge = new List<String>{ parentProj.Id, childProjId };

        // WHEN
        Test.startTest();
        NSP_MergeProjectController.mergeProject(new List<List<String>>{ projectIdsToMerge });
        Test.stopTest();

        // THEN
        pse__Proj__c parentProjRec = [SELECT Id, (SELECT Id FROM Project_Accounts__r), (SELECT Id FROM Project_Assets__r) FROM pse__Proj__c WHERE Id = :parentProj.Id LIMIT 1];
        System.assertEquals(1, parentProjRec.Project_Accounts__r.size());
        System.assertEquals(2, parentProjRec.Project_Assets__r.size());
    }

    // Prepare set of ids by list of records
    private static Set<Id> getIdSetByRecordList( List<SObject> records ) {
        return new Map<Id, SObject>(records).keyset();
    }

}
//