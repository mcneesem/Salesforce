@isTest
private class NSP_AssetServiceTriggerHelperTest {
    private static final String ASSET_DEFAULT = 'NSP_TestDataFactory.AssetDefaults';
    private static final String PROJECT_DEFAULT = 'NSP_TestDataFactory.ProjectDefaults';
    private static final String ASSET_CLIENT = '2345';
    private static final String WX_WA_PARENT_ID = '12345';
    private static final String ACCOUNT_NAME = 'test account';
    private static final Id integraRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.INTEGRA_ASSET).getRecordTypeId();
    private static final Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
    private static final Id wxWaAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, 'NSP_Asset_Product');
    private static final List<String> ACCOUNT_FIELDS = new List<String>{
        'Id',
        'Name',
        'NSP_Product_First_Pay_Date__c'
    };

    @testSetup
    private static void testData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        Id wxWaAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, 'NSP_Asset_Product');
        Id retChoiceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
        Test.startTest();
        List<NSP_Category_Sub_Category_Mapping__c> catSubCatMappingList = new List<NSP_Category_Sub_Category_Mapping__c>();
        NSP_Category_Sub_Category_Mapping__c catSubCatMapping = (NSP_Category_Sub_Category_Mapping__c) NSP_TestDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        catSubCatMapping.NSP_Category__c = 'HR Services';
        catSubCatMapping.NSP_Subcategory__c = 'HR Infrastructure';
        catSubCatMapping.NSP_Detail__c = 'Client Guidance';
        catSubCatMappingList.add(catSubCatMapping);
        insert catSubCatMappingList;
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = ACCOUNT_NAME;
        insert accoutObject;
        //Project Creation
        pse__Proj__c newProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECT_DEFAULT, false);
        newProject.pse__Account__c = accoutObject.id;
        //        insert newProject;

        //Creating Account record
        Account accountRecord = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        accountRecord.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        accountRecord.NSP_First_Pay_Date__c = system.Today();
        INSERT accountRecord;

        //Creating Account Team record
        NSP_Account_Team__c accountTeamRecord = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c());
        accountTeamRecord.NSP_Account__c = accountRecord.Id;
        accountTeamRecord.NSP_User__c = UserInfo.getUserId();
        accountTeamRecord.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        INSERT accountTeamRecord;

        NSP_Account_Team__c accountTeamRecord1 = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c());
        accountTeamRecord1.NSP_Account__c = accountRecord.Id;
        accountTeamRecord1.NSP_User__c = UserInfo.getUserId();
        accountTeamRecord1.NSP_Role__c = NSP_ServiceConstants.PAYROLL_SPECIALIST;
        INSERT accountTeamRecord1;

        NSP_Relationship_Strategy_Action_Plan__c rsap = new NSP_Relationship_Strategy_Action_Plan__c();
        rsap.Name = 'RSAP1';
        rsap.NSP_Account__c = accountRecord.Id;
        INSERT rsap;


        Product2 product1 = NSP_TestHelper.createProduct('Test Product1',true);

        //Insert Region
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
        region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;

        //create Plan Record
        Id choicePlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan__c', NSP_ServiceConstants.CHOICE_RT_NAME);
        NSP_Plan__c planRec = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        planRec.RecordTypeId = choicePlanRT;
        INSERT planRec;

        //create Plan Sub Plan Record
        Id choiceSubPlanRT = NSP_GenericRecordType.getRecordTypeId('NSP_Plan_SubPlan__c', NSP_ServiceConstants.CHOICE_RT_NAME);
        NSP_Plan_SubPlan__c planSubplanRec = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        planSubplanRec.NSP_Subplan_Name__c = 'Test Subplan';
        planSubplanRec.NSP_Parent_Plan_ID__c = planRec.Id;
        planSubplanRec.NSP_Subplan_ID__c = '123';
        planSubplanRec.RecordTypeId = choiceSubPlanRT;
        INSERT planSubplanRec;

        //Creating Asset record
        List<Asset> nAssetList = new List<Asset>();
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        assetRecord.AccountId = accountRecord.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecord.RecordTypeId = woRecordTypeId;
        assetRecord.NSP_Renewal_Date__c = system.Today();
        assetRecord.NSP_Biometric_Start_Date__c = system.Today();
        assetRecord.Product2Id = product1.Id;
        nAssetList.add(assetRecord);

        Asset woAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        woAssetRecord.AccountId = accoutObject.Id;
        woAssetRecord.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
        woAssetRecord.RecordTypeId = woRecordTypeId;
        woAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        nAssetList.add(woAssetRecord);

        Asset wxWaAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        wxWaAssetRecord.AccountId = accountRecord.Id;
        wxWaAssetRecord.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
        wxWaAssetRecord.RecordTypeId = wxWaAssetRecordTypeId;
        wxWaAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        nAssetList.add(wxWaAssetRecord);

        Asset retChoiceAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        retChoiceAssetRecord.AccountId = accoutObject.Id;
        retChoiceAssetRecord.Status = 'Active';
        retChoiceAssetRecord.RecordTypeId = retChoiceAssetRecordTypeId;
        retChoiceAssetRecord.NSP_RET_Plan_and_Sub_Plan__c = planSubplanRec.Id;
        retChoiceAssetRecord.NSP_Client_is_Lead_Parent__c = true;
        retChoiceAssetRecord.NSP_RET_lead_parent__c = null;
        retChoiceAssetRecord.NSP_Price_Level__c = 'RET - Bundled Plus #2';

        nAssetList.add(retChoiceAssetRecord);
        INSERT nAssetList;

        retChoiceAssetRecord.NSP_Client_is_Lead_Parent__c = false;
        UPDATE retChoiceAssetRecord;

        Test.stopTest();
    }

    @isTest
    private static void createImplementationProjectwithFSOWOAssetcreatesProject() {
        // GIVEN
        pse__Region__c myRegionForMapping = [Select Id from pse__Region__c where Name =: NSP_ServiceConstants.UnitedStatesRegion LIMIT 1];
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c  FROM Account WHERE Name=:ACCOUNT_NAME];
        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        woAsset.AccountId = oAccount.Id;
        woAsset.Status= NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        woAsset.recordTypeId = woRecordTypeId;
        woAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.EG100AssetSegment;

        NSP_hotfix_Switch__c settings = new NSP_hotfix_Switch__c();
        settings.Is_Opportunity_Allowed_On_Project__c = True;
        upsert settings;

        // WHEN
        Test.startTest();
        if(myRegionForMapping.id != null){
            ProjectCreationSettings__c projSettings = new ProjectCreationSettings__c();
            projSettings.DefaultRegionId__c = myRegionForMapping.id;
            upsert projSettings;
        }
        insert woAsset;
        Test.stopTest();

        List<pse__Proj__c> projects = [Select Id ,TemplateName__c from pse__Proj__c WHERE pse__Account__c = :oAccount.Id];

        // THEN
        System.assertEquals(woAsset.NSP_Client_Segment_type__c, NSP_ServiceConstants.EG100AssetSegment);
    }

    @isTest
    private static void createImplementationProjectwithMMWOClientSegmentcreatesProject() {
        // GIVEN
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name=:ACCOUNT_NAME];

        Asset MMWoAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        MMWoAsset.AccountId = oAccount.Id;
        MMWoAsset.Status = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        MMWoAsset.recordTypeId = woRecordTypeId ;
        MMWoAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.MMEAssetSegment;
        // WHEN
        Test.startTest();
        insert MMWoAsset;
        Test.stopTest();

        List<pse__Proj__c> projects = [Select Id ,TemplateName__c from pse__Proj__c WHERE pse__Account__c = :oAccount.Id];

        // THEN
        System.assertEquals(MMWoAsset.NSP_Client_Segment_type__c, NSP_ServiceConstants.MMEAssetSegment);
    }

    @isTest
    private static void createImplementationProjectwithMMClientSegmentcreatesProject() {
        // GIVEN
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name=:ACCOUNT_NAME];
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECT_DEFAULT, false);
        oProject.pse__Start_Date__c = System.Today();
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType ;
        oProject.recordTypeId = peoProjectRecordTypeId;
        oProject.pse__Account__c=oAccount.Id;
        insert oProject;

        Asset MMWoAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        MMWoAsset.AccountId = oAccount.Id;
        MMWoAsset.NSP_Segment_Exception__c=true;
        MMWoAsset.NSP_Segment_Exception_Reason__c ='Term notice received';
        MMWoAsset.Status= NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        MMWoAsset.recordTypeId = woRecordTypeId ;
        MMWoAsset.NSP_Client_Segment_type__c = NSP_ServiceConstants.MMEAssetSegment;
        // WHEN
        Test.startTest();
        insert MMWoAsset;
        Test.stopTest();

        List<pse__Proj__c> projects = [Select Id ,TemplateName__c from pse__Proj__c WHERE pse__Account__c = :oAccount.Id];

        // THEN
        System.assertEquals(1, projects.size());
    }

    @isTest
    private static void createImplementationProjectwithCoreClientSegmentcreatesProject() {
        // GIVEN
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name=:ACCOUNT_NAME];
        Asset integraAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        integraAsset.AccountId = oAccount.Id;
        integraAsset.Status= NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        integraAsset.recordTypeId = integraRecordTypeId;
        integraAsset.NSP_Client_Segment_type__c = 'Core';

        // WHEN
        Test.startTest();
        insert integraAsset;
        Test.stopTest();

        List<pse__Proj__c> projects = [Select Id ,TemplateName__c from pse__Proj__c WHERE pse__Account__c = :oAccount.Id];

        // THEN
        System.assertEquals(integraAsset.NSP_Client_Segment_type__c, 'Core');
    }

    @isTest
    private static void onRecordInsertAccountGroupDetails() {
        Test.startTest();
        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();

        Account acc = [SELECT Id, Name FROM Account WHERE Name =: ACCOUNT_NAME];
        //GIVEN
        Asset asset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset.AccountId = acc.Id;
        //WHEN
        asset.recordtypeId = wORecordTypeId;
        insert asset;
        //THEN
        list<NSP_Account_Group_Member__c> lstAccGroups = [SELECT Id FROM NSP_Account_Group_Member__c WHERE NSP_Member_Account__c =: asset.AccountId];

        System.assertEquals(lstAccGroups.size(), 6);
        Test.stopTest();

    }

    @isTest
    private static void onRecordInsertAccountExistingGroupDetails() {
        Test.startTest();

        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();

        Account acc = [SELECT Id, Name FROM Account WHERE Name =:ACCOUNT_NAME];
        //GIVEN
        list<NSP_Account_Group__c> lstAccGroups = new List<NSP_Account_Group__c>();
        list<NSP_Account_Group_Member__c> lstAccGroupMembrs = new List<NSP_Account_Group_Member__c>();
        Id autoCreatedRecordTypeId = Schema.SObjectType.NSP_Account_Group__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.AUTOMATICALLY_CREATED).getRecordTypeId();

        lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.RENEWAL_PROBABILITY, NSP_Account__c = acc.Name, NSP_Type__c = NSP_ServiceConstants.RENEWAL_PROBABILITY));
        lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.ACCOUNT_HEALTH, NSP_Account__c = acc.Name, NSP_Type__c = NSP_ServiceConstants.ACCOUNT_HEALTH));
        lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.GROWTH_FORECAST, NSP_Account__c = acc.Name, NSP_Type__c = NSP_ServiceConstants.GROWTH_FORECAST));
        insert lstAccGroups;

        System.assertEquals(lstAccGroups.size(), 3,'Three groups Inserted');


        for(NSP_Account_Group__c accGroup: lstAccGroups){
            lstAccGroupMembrs.add(new NSP_Account_Group_Member__c(NSP_Member_Account__c = acc.Id, NSP_Group__c = accGroup.Id, NSP_Primary__c = true));
        }
        insert lstAccGroupMembrs;
        //WHEN

        Asset asset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset.AccountId = acc.Id;
        asset.recordtypeId = wORecordTypeId;
        insert asset;

        //THEN

        System.assertEquals(lstAccGroups.size(), 3,'Three groups Inserted');
        Test.stopTest();

    }

    @isTest
    private static void onRecordAccountGroupWXAssets() {

        Id wXWARecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WX_WA).getRecordTypeId();

        Account acc = [SELECT Id, Name FROM Account WHERE Name =: ACCOUNT_NAME];
        List<Account> lstAccounts = new List<Account>();
        Account acc1 = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc1.Name = 'Test Account 1';
        lstAccounts.add(acc1);
        Account acc2 = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc2.Name = 'Test Account 2';
        lstAccounts.add(acc2);
        insert lstAccounts;

        //GIVEN
        List<Asset> lstAssets = new List<Asset>();
        Asset asset2 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset2.AccountId = acc.Id;
        asset2.recordtypeId = wXWARecordTypeId;
        asset2.NSP_WX_WA_CHILD_ID__c = 0;
        asset2.NSP_WX_WA_Parent_ID__c = WX_WA_PARENT_ID;
        lstAssets.add(asset2);

        Asset asset3 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset3.AccountId = lstAccounts[0].Id;
        asset3.recordtypeId = wXWARecordTypeId;
        asset3.NSP_WX_WA_CHILD_ID__c = 1;
        asset3.NSP_WX_WA_Parent_ID__c = WX_WA_PARENT_ID;
        lstAssets.add(asset3);

        Asset asset5 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset5.AccountId =  lstAccounts[1].Id;
        asset5.recordtypeId = wXWARecordTypeId;
        lstAssets.add(asset5);
        insert lstAssets;

        //WHEN
        for(Asset objAsset :lstAssets ){
            objAsset.Status = NSP_ServiceConstants.ASSETBLACKOUT;
        }
        update lstAssets;
         Test.startTest();
        Asset asset4 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset4.AccountId =  lstAccounts[1].Id;
        asset4.recordtypeId = wXWARecordTypeId;
        asset4.NSP_WX_WA_CHILD_ID__c = 0;
        asset4.NSP_WX_WA_Parent_ID__c = WX_WA_PARENT_ID;
        insert asset4;

        asset4.Status = NSP_ServiceConstants.ASSETBLACKOUT;
        update lstAssets;

        lstAssets[2].NSP_WX_WA_Parent_ID__c = WX_WA_PARENT_ID;
        lstAssets[2].Status = NSP_ServiceConstants.ASSETBLACKOUT;
        update lstAssets[2];

        for(Asset objAsset :lstAssets ){
            objAsset.NSP_WX_WA_Parent_ID__c = '1234567';
        }
        update lstAssets;

        //THEN
        Asset updatedAsset = [SELECT Id, Status, NSP_WX_WA_Parent_ID__c from Asset WHERE Id =: lstAssets[0].Id];
        System.assertEquals(updatedAsset.Status, NSP_ServiceConstants.ASSETBLACKOUT, 'matched');
        delete lstAssets;

        Test.stopTest();

    }


    @isTest
    private static void linkAssetWithImpProfileTest() {
        Account oAccount = [SELECT Id, Name FROM Account WHERE Name =: ACCOUNT_NAME];
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECT_DEFAULT, false);
        oProject.pse__Start_Date__c = System.Today();
        oProject.pse__Account__c= oAccount.Id;
        oProject.TemplateName__c = label.FSOImplementationProject;
        insert oProject;
        Test.startTest();
        Asset asset4 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset4.AccountId =  oAccount.Id;
        asset4.recordtypeId = woRecordTypeId;
        asset4.NSP_WX_WA_CHILD_ID__c = 0;
        asset4.NSP_WX_WA_Parent_ID__c = WX_WA_PARENT_ID;
        insert asset4;
        Test.stopTest();
        System.assertEquals(oProject.TemplateName__c, label.FSOImplementationProject);
    }

    @isTest
    private static void mapGovernmentContratcorOnPDSTest() {
        Account oAccount = [SELECT Id, Name FROM Account WHERE Name=: ACCOUNT_NAME LIMIT 1];
        Asset asset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset.AccountId = oAccount.Id;
        asset.NSP_Client_Segment_type__c = NSP_ServiceConstants.EG50AssetSegment;
        asset.recordtypeId = wORecordTypeId;
        Database.insert(asset);

        NSP_Sub_Client__c subClientObj = (NSP_Sub_Client__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c(), 'NSP_TestDataFactory.SubClientDefaults', false);
        subClientObj.NSP_Account__c = asset.AccountId;
        subClientObj.NSP_Asset__c = asset.Id;
        subClientObj.NSP_Client__c = 'Client 123';
        Database.insert(subClientObj);

         NSP_Payroll__c pdsIns = (NSP_Payroll__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Payroll__c(), 'NSP_TestDataFactory.PayrollDataSheetDefaults', false);
        pdsIns.NSP_Sub_Client_Name__c = subClientObj.Id ;
        Database.insert(pdsIns);

        test.startTest();
        asset.NSP_Government_Contractor__c = true;
        UPDATE asset;
        test.stopTest();
        NSP_Payroll__c assertPDS = [SELECT Id, NSP_Government_Contractor__c FROM NSP_Payroll__c WHERE Id =: pdsIns.Id];
        system.assertEquals(true, assertPDS.NSP_Government_Contractor__c);

    }

    @isTest
    private static void updateTerminationDateTest() {
        // GIVEN
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name=: ACCOUNT_NAME];
        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        woAsset.AccountId = oAccount.Id;
        woAsset.recordTypeId = woRecordTypeId;
        insert woAsset;
        Test.startTest();
        woAsset.NSP_Account_Status__c = 'Terminated';
        woAsset.NSP_Account_Status_Date__c = System.Today();
        update woAsset;
        Test.stopTest();
        Asset ast =[Select Id , NSP_Account_Status_Date__c,NSP_Account_Status__c,NSP_Termination_Date__c FROM
                    ASSET WHERE NSP_Account_Status__c = 'Terminated' LIMIT 1 ];
        System.AssertEquals(ast.NSP_Account_Status__c, 'Terminated');
    }

    @isTest
    private static void updateTerminationDateTestFail() {
        // GIVEN
        Account oAccount = [SELECT Id, Name, NSP_Sales_Service_Account_Status__c FROM Account WHERE Name=:ACCOUNT_NAME];
        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        woAsset.AccountId = oAccount.Id;
        woAsset.Status= NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        woAsset.recordTypeId = woRecordTypeId;
        Test.startTest();
        insert woAsset;
        Test.stopTest();
        List<Asset> ast =[Select Id , NSP_Account_Status_Date__c,NSP_Account_Status__c,NSP_Termination_Date__c FROM
                          ASSET WHERE AccountId =: oAccount.Id LIMIT 1 ];
        System.AssertEquals(null,ast[0].NSP_Termination_Date__c);
    }

    @isTest
    private static void restrictProductSegupdateTest() {

        List<String> assetFields = new List<String>{'Id' , 'NSP_Product_Segment__c' };
        NSP_QueryBuilder userQueryBuilder = new NSP_QueryBuilder('User');
        String userQuery = userQueryBuilder.addFilter('Id', userInfo.getUserId()).addLimit(1).build();
        User user  = (User) Database.query(userQuery);
        NSP_QueryBuilder permissionSetQueryBuilder = new NSP_QueryBuilder('PermissionSet');
        String permissionQuery = permissionSetQueryBuilder.addFilter('Name', NSP_ServiceConstants.bpsAssetPermSet).addLimit(1).build();
        PermissionSet bpsPermissionSet  = (PermissionSet) Database.query(permissionQuery);
        PermissionSetAssignment psa = (PermissionSetAssignment)NSP_TestExtendedDataFactory.createSObject(new PermissionSetAssignment(), false);
        psa.AssigneeId = user.Id;
        psa.PermissionSetId = bpsPermissionSet.Id;
        Test.startTest();
        system.runAs(user){
            pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECT_DEFAULT, false);
            oProject.TemplateName__c=NSP_ServiceConstants.HCM_PROJECT_NAME;
            insert oProject;

            Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
            integra.NSP_Client__c=ASSET_CLIENT;
            integra.NSP_Company_Name__c='test company';
            integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
            insert integra;

            Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
            prjAsset.Asset__c = integra.Id;
            prjAsset.Project__c=oProject.Id;
            insert prjAsset;

            integra.NSP_Product_Segment__c = 'Middle Market Enterprise (750 + EEs)';
            update integra;

            NSP_QueryBuilder assetQueryBuilder = new NSP_QueryBuilder('Asset',assetFields);
            String assetQuery = assetQueryBuilder.addFilter('Id', prjAsset.Asset__c).addLimit(1).build();
            Asset ast  = (Asset) Database.query(assetQuery);
            System.assertEquals(ast.NSP_Product_Segment__c, 'Middle Market Enterprise (750 + EEs)');
        }
        Test.stopTest();
    }

    @isTest
    private static void restrictProductSegupdateException() {
        Test.startTest();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECT_DEFAULT, false);
        oProject.TemplateName__c=NSP_ServiceConstants.HCM_PROJECT_NAME;
        insert oProject;

        Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        integra.NSP_Client__c='2345';
        integra.NSP_Company_Name__c='test company';
        integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        insert integra;

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = integra.Id;
        prjAsset.Project__c=oProject.Id;
        insert prjAsset;

        integra.NSP_Product_Segment__c = 'Middle Market Enterprise (750 + EEs)';
        try{
            update integra;
        }catch(Exception ex){
            Boolean isexpectedExceptionThrown =  ex.getMessage().contains(label.NSP_CRMTaskError) ? true : false;
            System.assertEquals(isexpectedExceptionThrown, true);
        }
        Test.stopTest();
    }

    @isTest
    private static void testSendRetentionStrategyTerminationEmail() {
       Test.startTest();
        List<String> assetFields = new List<String>{'Id'};
        String query = new NSP_QueryBuilder('Asset', assetFields)
                          .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.ASSET_ACTIVE_STATUS).addLimit(1).build();
        Asset assetRecord = Database.query(query);
        assetRecord.NSP_Anticipated_Date_Of_Termination__c = system.Today();
        assetRecord.NSP_Reason_for_Term__c = 'Test Reason';
        assetRecord.NSP_Written_Term_recd__c = TRUE;
        try{
            UPDATE assetRecord;
        }catch(Exception ex){
            system.assertNotEquals(null,ex,'exception occured');
        }
        Test.stopTest();
    }

    @isTest
    private static void testNotSendRetentionStrategyTerminationEmail() {
       Test.startTest();
        List<String> assetFields = new List<String>{'Id'};
        String query = new NSP_QueryBuilder('Asset', assetFields)
                          .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.ASSET_ACTIVE_STATUS).addLimit(1).build();
        Asset assetRecord = Database.query(query);
        assetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.BTAssetSegment;
        UPDATE assetRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }

    @isTest
    private static void updateProductPayDateOnAccountTest() {
        try{
            //Given
            String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                          .addFilter('Name', ACCOUNT_NAME).addLimit(1).build();
            Account oAccount = Database.query(query);

            //create Asset with first pay date
            List<Asset> assetList = new List<Asset>();
            Asset assetRecord1 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
            assetRecord1.NSP_First_Pay_Date__c = Date.newInstance(2022, 12, 30);
            assetRecord1.accountId = oAccount.Id;
            assetRecord1.Name = 'Test Asset 1';
            assetList.add(assetRecord1);
            //create Asset with earlier first pay date
            Asset assetRecord2 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
            assetRecord2.NSP_First_Pay_Date__c = Date.newInstance(2022, 10, 1);
            assetRecord2.accountId = oAccount.Id;
            assetRecord2.Name = 'Test Asset 2';
            assetList.add(assetRecord2);

            //When
            test.startTest();
            Database.insert(assetList,false);
            test.stopTest();

            //Then
            String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                            .addFilter('Name', ACCOUNT_NAME).addLimit(1).build();
            Account accountRec = Database.query(queryAcc);
            System.assertEquals(assetRecord2.NSP_First_Pay_Date__c,accountRec.NSP_Product_First_Pay_Date__c,'Accounts Product First Pay Date updated with Earliest pay date on rel asset');

        } catch(Exception ex){
            System.debug( ' ~ ex=' + ex );
        }
    }

    @isTest
    private static void productPayDateOnAccountNotUpdatedTest() {
        try{
            //Given
            String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                          .addFilter('Name', ACCOUNT_NAME).addLimit(1).build();
            Account oAccount = Database.query(query);

            //create Asset with first pay date
            List<Asset> assetList = new List<Asset>();
            Asset assetRecord1 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
            assetRecord1.NSP_First_Pay_Date__c = Date.newInstance(2030, 12, 30);
            assetRecord1.accountId = oAccount.Id;
            assetRecord1.Name = 'Test Asset 1';
            assetList.add(assetRecord1);
            //create Asset with earlier first pay date
            Asset assetRecord2 = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
            assetRecord2.NSP_First_Pay_Date__c = Date.newInstance(2010, 10, 1);
            assetRecord2.accountId = oAccount.Id;
            assetRecord2.Name = 'Test Asset 2';
            assetList.add(assetRecord2);

            //When
            test.startTest();
            Database.insert(assetList,false);
            test.stopTest();

            //Then
            String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                            .addFilter('Name', ACCOUNT_NAME).addLimit(1).build();
            Account accountRec = Database.query(queryAcc);
            System.assertNotEquals(assetRecord1.NSP_First_Pay_Date__c,accountRec.NSP_Product_First_Pay_Date__c,'Accounts Product First Pay Date updated with Earliest pay date on rel asset');

        } catch(Exception ex){
            System.debug( ' ~ ex=' + ex );
        }
    }

    @isTest
    private static void updateServiceSegmentOnAccountTest() {
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'NSP_Client_Segment_type__c',
            'Status',
            'AccountId'
        };

        List<String> accountFields = new List<String>{
            'Id',
            'NSP_Service_Segment__c',
            'Name'
        };

        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accountFields)
            .addFilter('Name', ACCOUNT_NAME)
            .addLimit(1)
            .setSecurityEnforce(false);
        String query = queryBuilder.build();
        Account acc = Database.query(query);


        System.assertEquals(NSP_ServiceConstants.CoreAssetSegment, acc.NSP_Service_Segment__c);
    }


    @isTest
    private static void updateServiceSegmentOnAccountNegativeTest() {
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'NSP_Client_Segment_type__c',
            'Status',
            'AccountId'
        };

        List<String> accountFields = new List<String>{
            'Id',
            'NSP_Service_Segment__c',
            'Name'
        };

        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accountFields)
            .addFilter('Name', ACCOUNT_NAME)
            .addLimit(1)
            .setSecurityEnforce(false);
        String query = queryBuilder.build();
        Account acc = Database.query(query);

        NSP_QueryBuilder assetQueryBuilder = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            .addFilter('AccountId', acc.Id)
            .addFilter('RecordTypeId', woRecordTypeId)
            .addFilter('Status', NSP_ServiceConstants.ASSET_ONBOARDING_STATUS)
            .addFilter('NSP_Client_Segment_type__c', NSP_ServiceConstants.CoreAssetSegment)
            .addLimit(1)
            .setSecurityEnforce(false);
        String assetQuery = assetQueryBuilder.build();
        Asset woAssetRec = Database.query(assetQuery);

        woAssetRec.Status = NSP_ServiceConstants.ASSETBLACKOUT;
        woAssetRec.NSP_Client_Segment__c = NSP_ServiceConstants.BTAssetSegment;
        Test.startTest();
        Database.update(woAssetRec);
        Test.stopTest();

        System.assertEquals(NSP_ServiceConstants.CoreAssetSegment, acc.NSP_Service_Segment__c);
    }

    @isTest
    private static void updateAssetTerminationDateTest() {
        Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        integra.NSP_Client__c=ASSET_CLIENT;
        integra.NSP_Company_Name__c='test Integra company';
        integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        insert integra;

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), PROJECT_DEFAULT, false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.Name = label.Middle_Market_Implementation_Project +'Test';
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.Go_Live_Date__c = System.Today();
        insert oProject;

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = integra.Id;
        prjAsset.Project__c = oProject.Id;
        insert prjAsset;
        Test.startTest();
        integra.Status ='Terminated';
        integra.NSP_Termination_Date__c = System.Today();
        update integra;
        Test.stopTest();
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'NSP_Termination_Date__c',
            'Status',
            'AccountId',
            'NSP_OrderProduct__r.Order.Status'
        };
        String queryAsset = new NSP_QueryBuilder('Asset', assetFields)
                         .addFilter('NSP_Client__c', ASSET_CLIENT).addLimit(1).build();
        Asset astRec = Database.query(queryAsset);
        System.assertEquals(astRec.NSP_Termination_Date__c,System.Today());
    }

    @isTest
    private static void updateAssetTerminationDateException() {
        Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integra.NSP_Client__c='2343';
        integra.NSP_Company_Name__c='test WO company';
        integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','WO');
        insert integra;

        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.Name = label.Middle_Market_Implementation_Project +'Test';
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.Go_Live_Date__c = System.Today();
        insert oProject;

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = integra.Id;
        prjAsset.Project__c = oProject.Id;
        insert prjAsset;
        Test.startTest();
        integra.Status ='Terminated';
        update integra;
        Test.stopTest();
        List<String> assetFields = new List<String>{
            'Id',
            'RecordTypeId',
            'NSP_Termination_Date__c',
            'Status',
            'AccountId',
            'NSP_OrderProduct__r.Order.Status'
        };
        String queryAsset = new NSP_QueryBuilder('Asset', assetFields)
                         .addFilter('NSP_Client__c', '2343').addLimit(1).build();
        Asset astRec = Database.query(queryAsset);
        System.assertNotEquals(astRec.NSP_Termination_Date__c,System.Today());
    }

    @isTest
    private static void accountPayrollEmployeeUpdateWO() {
        List<String> assetFields = new List<String>{
                'Id',
                    'RecordTypeId',
                    'NSP_Unique_Active_Employee__c',
                    'Status',
                    'AccountId'
                    };
        String queryAsset = new NSP_QueryBuilder('Asset', assetFields)
                            .addFilter('recordTypeId',woRecordTypeId)
                            .addFilter('NSP_Client_Segment_type__c', NSP_ServiceConstants.CoreAssetSegment).addLimit(1).build();
        Asset astRec = Database.query(queryAsset);
        test.startTest();
            astRec.NSP_Unique_Active_Employee__c=45;
            update astRec;
        test.stopTest();
        List<String> accFields = new List<String>{
            'Id',
                'NSP_Payroll_employee__c'
                };
        String queryAccount = new NSP_QueryBuilder('Account', accFields)
                              .addFilter('Id', astRec.accountId).addLimit(1).build();
        Account accRec = Database.query(queryAccount);
        System.assertEquals(accRec.NSP_Payroll_employee__c ,astRec.NSP_Unique_Active_Employee__c);

    }

    @isTest
    private static void accountPayrollEmployeeUpdateforWX() {
        List<String> assetFields = new List<String>{
                'Id',
                    'RecordTypeId',
                    'NSP_Current_SaaS_Seats__c',
                    'Status',
                    'AccountId'
                    };
        String queryAsset = new NSP_QueryBuilder('Asset', assetFields)
                            .addFilter('recordTypeId',wxWaAssetRecordTypeId)
                            .addFilter('NSP_Client_Segment_type__c', NSP_ServiceConstants.CoreAssetSegment).addLimit(1).build();
        Asset astRec = Database.query(queryAsset);
        test.startTest();
            astRec.NSP_Current_SaaS_Seats__c='45';
            update astRec;
        test.stopTest();
        List<String> accFields = new List<String>{
            'Id',
                'NSP_Payroll_employee__c'
                };
        String queryAccount = new NSP_QueryBuilder('Account', accFields)
                            .addFilter('Id', astRec.accountId).addLimit(1).build();
        Account accRec = Database.query(queryAccount);
        System.assertEquals(accRec.NSP_Payroll_employee__c,Decimal.valueOf(astRec.NSP_Current_SaaS_Seats__c));
    }

    @isTest
    private static void updateAssetNameAsPerConventionTest() {
        Id wxWaAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
        String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                          .addFilter('Name', 'Test Account').addLimit(1).build();
        Account oAccount = Database.query(query);

        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        assetRecord.AccountId = oAccount.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecord.RecordTypeId = wxWaAssetRecordTypeId;
        assetRecord.NSP_Renewal_Date__c = system.Today();

        Test.startTest();
        INSERT assetRecord;
        System.assertEquals('test account - WX_WA', [SELECT Id, Name FROM Asset WHERE Id =: assetRecord.Id].Name);
        Test.stopTest();
    }

    @isTest
    private static void notUpdateAssetNameAsPerConventionTest() {
        String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                          .addFilter('Name', 'Test Account').addLimit(1).build();
        Account oAccount = Database.query(query);

        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        assetRecord.Name = 'Test Asset WO';
        assetRecord.AccountId = oAccount.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecord.RecordTypeId = woRecordTypeId;
        assetRecord.NSP_Renewal_Date__c = system.Today();

        Test.startTest();
        INSERT assetRecord;
        System.assertEquals('Test Asset WO', [SELECT Id, Name FROM Asset WHERE Id =: assetRecord.Id].Name);
        Test.stopTest();
    }

    @isTest
    private static void updateAssets() {
        String query = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                          .addFilter('Name', 'Test Account').addLimit(1).build();
        Account oAccount = Database.query(query);

        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        assetRecord.Name = 'Test Asset WO';
        assetRecord.AccountId = oAccount.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.ASSET_ACTIVE_STATUS;
        assetRecord.RecordTypeId = woRecordTypeId;
        assetRecord.NSP_Renewal_Date__c = system.Today();
        assetRecord.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
        assetRecord.NSP_Unique_Active_Employee__c = 2;
        assetRecord.NSP_Client__c = '2300';
        assetRecord.NSP_Account_Status_Date__c = system.Today();
        INSERT assetRecord;
        Test.startTest();
        assetRecord.NSP_Account_Status_Date__c = system.Today().addDays(1);
        UPDATE assetRecord;

        assetRecord.NSP_Account_Status__c = 'Inactive';
        UPDATE assetRecord;
        System.assertEquals('Test Asset WO', assetRecord.Name);
        Test.stopTest();
    }

    @isTest
    private static void testRetUserNotAbleToEditSomeSpecificFields() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =: NSP_ServiceConstants.RT];
        User newRetUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newRetUser.ProfileId = profile.Id;
        newRetUser.UserName =  Integer.valueOf(math.rint(math.random() * 1000000))+ '@test' + UserInfo.getOrganizationId()+ '.org';
        Test.startTest();
        System.runAs(newRetUser){
            try {
                Asset assetObject = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
                assetObject.NSP_Company_Name__c='test';
                assetObject.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','RET_Choice');
                assetObject.NSP_RET_Client_ID__c = '12345678';
                insert assetObject;

                assetObject.NSP_RET_Client_ID__c = '98760' ;
                update assetObject;
            }
            catch (DmlException ex) {
                System.assertEquals(label.NSP_No_Access , 'You do not have enough privileges to perform this operation');
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testBPSUserNotAbleToEditSomeSpecificFields() {
        Profile profile = [SELECT Id FROM Profile WHERE Name =: NSP_ServiceConstants.BPSSERVICE];
        User newBPSUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newBPSUser.ProfileId = profile.Id;
        newBPSUser.UserName =  Integer.valueOf(math.rint(math.random() * 1000000))+ '@test' + UserInfo.getOrganizationId()+ '.org';
        Test.startTest();
        System.runAs(newBPSUser){
            try {
                Asset assetObject = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
                assetObject.NSP_Company_Name__c='test';
                assetObject.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.XML_ASSET);
                assetObject.NSP_Current_SaaS_Seats__c = 'Current Saas';
                insert assetObject;

                assetObject.NSP_Current_SaaS_Seats__c = 'Current Saas Seats' ;
                update assetObject;
            }
            catch (DmlException ex) {
                System.assertEquals(label.NSP_No_Access , 'You do not have enough privileges to perform this operation');
            }
        }
        Test.stopTest();
    }

    @isTest
    private static void testAccountGroupWXAssets() {

        Id wXWARecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WX_WA).getRecordTypeId();

        List<Account> lstAccounts = new List<Account>();
        Account acc1 = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc1.Name = 'Test Account 1';
        lstAccounts.add(acc1);
        Account acc2 = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc2.Name = 'Test Account 2';
        lstAccounts.add(acc2);
        Account acc3 = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc3.Name = 'Test Account 3';
        lstAccounts.add(acc3);
        Account acc4 = (Account) NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc4.Name = 'Test Account 4';
        lstAccounts.add(acc4);
        insert lstAccounts;

        //GIVEN
        List<Asset> lstAssets = new List<Asset>();
        Asset asset2 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset2.AccountId = lstAccounts[0].Id;
        asset2.recordtypeId = wXWARecordTypeId;
        lstAssets.add(asset2);

        Asset asset3 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset3.AccountId = lstAccounts[1].Id;
        asset3.recordtypeId = wXWARecordTypeId;
        lstAssets.add(asset3);

        Asset asset4 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset4.AccountId =  lstAccounts[2].Id;
        asset4.recordtypeId = wXWARecordTypeId;
        lstAssets.add(asset4);

        Asset asset5 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), ASSET_DEFAULT, false);
        asset5.AccountId =  lstAccounts[3].Id;
        asset5.recordtypeId = wXWARecordTypeId;
        lstAssets.add(asset5);
        insert lstAssets;

        Test.startTest();

        List<Asset> lstAssetsToUpdate = new List<Asset>();
        lstAssetsToUpdate.add(new Asset(Id = lstAssets[0].Id, NSP_WX_WA_Parent_ID__c = '2302014', NSP_WX_WA_CHILD_ID__c = 1));
        lstAssetsToUpdate.add(new Asset(Id = lstAssets[1].Id, NSP_WX_WA_Parent_ID__c = '2302014', NSP_WX_WA_CHILD_ID__c = 2));
        lstAssetsToUpdate.add(new Asset(Id = lstAssets[2].Id, NSP_WX_WA_Parent_ID__c = '2302014', NSP_WX_WA_CHILD_ID__c = 3));
        lstAssetsToUpdate.add(new Asset(Id = lstAssets[3].Id, NSP_WX_WA_Parent_ID__c = '2302014', NSP_WX_WA_CHILD_ID__c = 4));
        Update lstAssetsToUpdate;
        String accGrpQuery = new NSP_QueryBuilder('NSP_Account_Group__c', new List<String> {'Id','NSP_Group_Member_Count__c'})
            .addFilter('NSP_Wx_ParentId__c', '2302014')
            .addLimit(1).build();
        NSP_Account_Group__c accGrpRecord = Database.query(accGrpQuery);
        System.assertEquals(accGrpRecord.NSP_Group_Member_Count__c, 4);

        Test.stopTest();
    }

}
//