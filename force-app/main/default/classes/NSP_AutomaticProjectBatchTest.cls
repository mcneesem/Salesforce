@isTest
private class NSP_AutomaticProjectBatchTest {

    @testSetup
    private static void setupProjectdata() {
        Id assertWORTId = NSP_GenericRecordType.getRecordTypeId( NSP_ServiceConstants.ASSET_SOBJECT_TYPE , NSP_ServiceConstants.WO_ASSET_RECORDTYPE );

        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject( new Account() , 'NSP_TestDataFactory.AccountDefaults' , false );
        oAccount.Name = 'Account Test1';
        Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject( new Account() , 'NSP_TestDataFactory.AccountDefaults' , false );
        oAccount1.Name = 'Account Test2';
        Account oAccount2 = (Account)NSP_TestExtendedDataFactory.createSObject( new Account() , 'NSP_TestDataFactory.AccountDefaults' , false );
        oAccount2.Name = 'Account Test3';
        Database.insert( new List<Account>{ oAccount , oAccount1 , oAccount2 } );

        NSP_Account_Team__c oAccountTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject( new NSP_Account_Team__c() , 'NSP_TestDataFactory.AccountTeamMemberDefaults' , false );
        oAccountTeam.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        oAccountTeam.NSP_Account__c = oAccount.Id;
        NSP_Account_Team__c oAccountTeam1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject( new NSP_Account_Team__c() , 'NSP_TestDataFactory.AccountTeamMemberDefaults' , false );
        oAccountTeam1.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        oAccountTeam1.NSP_Account__c = oAccount1.Id;
        NSP_Account_Team__c oAccountTeam2 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject( new NSP_Account_Team__c() , 'NSP_TestDataFactory.AccountTeamMemberDefaults' , false );
        oAccountTeam2.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        oAccountTeam2.NSP_Account__c = oAccount2.Id;
        Database.insert( new List<NSP_Account_Team__c>{ oAccountTeam , oAccountTeam1 , oAccountTeam2 } );

        Asset oAsset = (Asset)NSP_TestExtendedDataFactory.createSObject( new Asset() , 'NSP_TestDataFactory.AssetDefaults' , false );
        oAsset.AccountId = oAccount.Id;
        oAsset.Name = 'Test Asset1';
        oAsset.RecordTypeId = assertWORTId;
        oAsset.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        oAsset.NSP_Account_Status_Date__c = System.today();
        oAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.BTAssetSegment;
        oAsset.NSP_Product_Line__c = NSP_ServiceConstants.INSURANCE;
        oAsset.NSP_ProductBundle__c = NSP_ServiceConstants.WA_PRODUCT_BUNDLE;
        oAsset.Status = NSP_ServiceConstants.ONBOARDING;
        Database.insert( oAsset );
    }

    @isTest
    private static void btEngagementProjectTest() {
        Id projectPEORTId = NSP_GenericRecordType.getRecordTypeId( NSP_ServiceConstants.PROJECT_SOBJECT_NAME , NSP_ServiceConstants.PROJECT_PEO_RECORDTYPE );
        pse__proj__c project = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject( new pse__proj__c() , 'NSP_TestDataFactory.ProjectDefaults' , false );
        project.Name = 'BT Engagement Plan Test';
        project.RecordTypeId = projectPEORTId;
        project.TemplateName__c = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
        project.pse__Start_Date__c = System.today();
        insert project;

        Account accObj = [ SELECT Id FROM Account WHERE Name = 'Account Test1' LIMIT 1 ];

        Test.startTest();
        NSP_AutomaticProjectBatchClass batchClass = new NSP_AutomaticProjectBatchClass();
        batchClass.opp = new NSP_OpportunityTriggerServiceHelper( new Set<Id>{ project.Id } );
        Database.executeBatch( batchClass , 1 );
        Test.stopTest();

        Date todayDate = System.today();
        List<pse__proj__c> proj = [
            SELECT Id , OwnerId , pse__Account__c
            FROM pse__Proj__c
            WHERE TemplateName__c = :NSP_ServiceConstants.PROJECT_TEMPLATE_NAME
              AND pse__Account__c = :accObj.Id
              AND pse__Start_Date__c = :todayDate
        ];
        List<NSP_Account_Team__c> accTeamRec = [
            SELECT Id , NSP_User__c
            FROM NSP_Account_Team__c
            WHERE NSP_Role__c = :NSP_ServiceConstants.MANAGER_HRSERVICES
              AND NSP_Account__c = :accObj.Id
            LIMIT 1
        ];
        Assert.areEqual( accTeamRec[0].NSP_User__c , proj[0].OwnerId , 'Project owner should match the account team member' );
    }

    @isTest
    private static void scheduleTest() {
        Test.startTest();
        NSP_AutomaticProjectBatchClass.schedule();
        Test.stopTest();
        Assert.isTrue( true , 'schedule() completed without error' );
    }

    @isTest
    private static void callableRunTest() {
        Test.startTest();
        NSP_AutomaticProjectBatchClass batch = new NSP_AutomaticProjectBatchClass();
        Object result = batch.call( 'run' , null );
        Test.stopTest();
        Assert.isNotNull( result , 'call(run) should return the enqueued batch job Id' );
    }

    @isTest
    private static void callableInvalidActionTest() {
        NSP_AutomaticProjectBatchClass batch = new NSP_AutomaticProjectBatchClass();
        Object result = batch.call( 'invalidAction' , null );
        Assert.isNull( result , 'call() with an unknown action should return null' );
    }

}
//
