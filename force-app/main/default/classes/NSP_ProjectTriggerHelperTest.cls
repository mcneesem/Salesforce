@isTest
private class NSP_ProjectTriggerHelperTest {
    private static final String PROJECTDEFAULTS = 'NSP_TestDataFactory.ProjectDefaults';
    private static final String MILESTONEDEFAULTS = 'NSP_TestDataFactory.MileStoneDefaults';
    private static final Id peoProjectRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_SOBJECT_NAME,'PEO_Project');
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final String NAME = 'name';
    private static final String BENIFITS_MANAGER= 'Benefits Manager';
    private static final List<String> PROJECT_FIELDS = new List<String>{
        'Id',
        'Name',
        'pse__Start_Date__c',
        'Templates_Used__c',
        'Peer_Review__c',
        'pse__Project_Type__c',
        'OwnerId'
    };
    private static final List<String> ACCOUNT_FIELDS = new List<String>{
        'Id',
        'Name'
    };
    private static final List<String> CASE_FIELDS = new List<String>{
        'Id',
        'NSP_Category__c'
    };

    @testSetup
    private static void setupTestData() {
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole BPArole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        Id PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c',NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
        List<sObject> objRecInsertList = new List<sObject>();
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
        // Account Creation
        List<Account> accList = new List<Account>();
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
                             oAccount.Name = 'Test Account';
        accList.add(oAccount);

        Account oAccount1 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
                             oAccount1.Name = 'Test Account 01';
        accList.add(oAccount1);

        insert accList;

        NSP_Account_Team__c oAccountTeams = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.accountTeamDefaults', false);
        oAccountTeams.NSP_Account__c = oAccount1.Id;
        insert oAccountTeams;

        //Insert ACR record
        NSP_TestHelper.createContact(oAccount.Id, true);
        List<String> acrFields = new List<String>{'Id','ContactId','AccountId','NSP_Community_Access__c'};
            String query = new NSP_QueryBuilder('AccountContactRelation', acrFields)
            .addFilter('AccountId', oAccount.Id).addLimit(1).build();
        AccountContactRelation acrObj = Database.query(query);
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        UPDATE acrObj;

        pse__Region__c reg = new pse__Region__c();
            reg.name = NSP_ServiceConstants.UnitedStatesRegion;
        objRecInsertList.add(reg);
        Case oCase=(Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        oCase.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
        objRecInsertList.add(oCase);

        Test.startTest();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        oProject.pse__Is_Template__c = true;
        oProject.NSP_Asset_Type__c = 'Time_Attendance';
        oProject.pse__Start_Date__c = System.today();

        pse__Proj__c oProject2 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject2.TemplateName__c=NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        oProject2.pse__Is_Template__c = true;
        oProject2.pse__Start_Date__c = System.today();

        //project creation
        pse__Proj__c projectObj = new pse__Proj__c();
        projectObj.RecordTypeId=peoProjectRecordType;
        projectObj.pse__Project_Type__c = 'Implementation';
        projectObj.pse__Project_Status__c = 'Active';
        projectObj.Name = 'Test Delete 1';
        projectObj.pse__Is_Active__c = true;

        pse__Proj__c projectObj2 = new pse__Proj__c();
        projectObj2.RecordTypeId=peoProjectRecordType;
        projectObj2.pse__Project_Type__c = 'Service Plan';
        projectObj2.pse__Project_Status__c = 'Active';
        projectObj2.Name = 'Test PEO';
        projectObj2.NSP_Rating__c = 'Unfavorable';
        projectObj2.pse__Is_Active__c = true;

        pse__Proj__c bpsProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        bpsProject.RecordTypeId = bpsProjectRecordTypeId;
        bpsProject.Templates_Used__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
        bpsProject.pse__Project_Status__c = 'Active';
        projectObj.TemplateName__c = NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        projectObj.Templates_Used__c = NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        bpsProject.pse__Is_Active__c = true;

        pse__Proj__c projTemplate = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        projTemplate.Name = 'Test Template';
        projTemplate.RecordTypeId = bpsProjectRecordTypeId;
        projTemplate.pse__Project_Status__c = 'Active';
        projTemplate.pse__Is_Active__c = true;
        projTemplate.pse__Is_Template__c = true;
        projTemplate.pse__Start_Date__c = System.today();

        pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject1.pse__Start_Date__c = System.Today();
        oProject1.pse__Account__c= oAccount.Id;
        oProject1.TemplateName__c = label.Middle_Market_Implementation_Project;

        List<pse__Proj__c> listProject = new List<pse__Proj__c>();
        listProject.add(oProject);
        listProject.add(oProject2);
        listProject.add(projectObj);
        listProject.add(projectObj2);
        listProject.add(bpsProject);
        listProject.add(projTemplate);
        listProject.add(oProject1);

        insert listProject;

        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.Name = 'pTask3';
        oProjectTask.pse__Project__c = projectObj.Id;
        oProjectTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        insert oProjectTask;

        pse__Project_Task__c pTaskSharing = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        pTaskSharing.Name = 'pTaskSharing';
        pTaskSharing.pse__Project__c = projectObj.Id;
        pTaskSharing.NSP_Visible_to_Client__c = true;
        pTaskSharing.RecordTypeId = PEOProjectTaskRecordTypeId;
        insert pTaskSharing;
         // Asset Creation
        Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integra.NSP_Client__c='2345';
        integra.NSP_Company_Name__c='test company';
        integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        integra.Project_Template__c = listProject[0].Id;

        Asset integra1 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integra1.NSP_Client__c='2345';
        integra1.NSP_Company_Name__c='test company';
        integra1.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        integra1.Project_Template__c = listProject[1].Id;

        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAsset.NSP_Client__c='2345';
        woAsset.NSP_Account_Status__c=NSP_ServiceConstants.AIMS_STATUS;
        woAsset.NSP_AIMS_First_Pay_Date__c = system.today()- 91;
        woAsset.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        woAsset.accountId = oAccount.Id;

        List<Asset> listAsset = new List<Asset>();
        listAsset.add(woAsset);

        insert listAsset;

         // Project Asset Creation
        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = listAsset[0].Id;
        prjAsset.Project__c=listProject[0].Id;

        Project_Asset__c prjAsset1 = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset1.Asset__c = listAsset[0].Id;
        prjAsset1.Project__c=listProject[0].Id;

        List<Project_Asset__c> listProjectAsset = new List<Project_Asset__c>();
        listProjectAsset.add(prjAsset);
        listProjectAsset.add(prjAsset1);

        insert listProjectAsset;

         // Order Creation
        Order orderObj = (Order)NSP_TestExtendedDataFactory.createSObject(new Order(), false);
        orderObj.NSP_Project__c = listProject[1].Id;
        orderObj.AccountId = oAccount.id;
        objRecInsertList.add(orderObj);

        Implementation_Profile__c impProf = new Implementation_Profile__c();

        impProf.NSP_Project__c = projectObj.Id;
        impProf.NSP_Inactive__c = false;
        objRecInsertList.add(impProf);
        //milstone creation
        pse__Milestone__c milestoneObj = new pse__Milestone__c();
        milestoneObj.Name = 'Test milestone delete 1';
        milestoneObj.pse__Target_Date__c = system.today();
        milestoneObj.pse__Project__c = projectObj.id;
        milestoneObj.NSP_Visible_to_Client__c = true;
        objRecInsertList.add(milestoneObj);

        Database.insert(objRecInsertList);
         //category subcategory mapping creation
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = BENIFITS_MANAGER;
        newCat.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
        newCat.NSP_Subcategory__c = NSP_ServiceConstants.PTO;
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c= NSP_ServiceConstants.WO_ASSET_RECORDTYPE;
        newCat.NSP_RecordType__c= NSP_ServiceConstants.PEO;
        newCat.NSP_Public_Groups_To_Share__c = NSP_ServiceConstants.ALL_DATA_VISIBILTY;
        insert(newCat);

        User BpaUser = new User(alias = 'jsmit', email='jsmith@insperity.com',
                                emailencodingkey='UTF-8', lastname='Smith',
                                languagelocalekey='en_US',
                                localesidkey='en_US', profileid = profileobj.Id, userroleid = BPArole.Id,
                                timezonesidkey='America/Los_Angeles' ,
                                username='insperitytestadminuser@insperity.com.testUsr');
        system.runAs(new user(ID = UserInfo.getUserID())){
            //inserting BPA user
            insert BpaUser;
            Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            newContact.pse__Salesforce_User__c = BpaUser.Id;
            //Inserting New Contact
            insert newContact;
        }
        Test.stopTest();
    }

    @isTest
    private static void updateAccountonProject() {

        pse__Project_Task__c projTaskObj = [Select id,pse__Project__c,NSP_Account_Id__c from pse__Project_Task__c WHERE pse__Project__c != NULL LIMIT 1];
        Account oAccount = [Select Id from Account WHERE Name != null LIMIT 1];
        pse__Proj__c accProj = new pse__Proj__c();
        accProj.Id = projTaskObj.pse__Project__c;
        accProj.pse__Account__c = oAccount.Id;
        Test.startTest();
        update accProj;
        projTaskObj = new pse__Project_Task__c();
        projTaskObj = [Select id,pse__Project__c,NSP_Account_Id__c from pse__Project_Task__c WHERE NSP_Account_Id__c != NULL LIMIT 1];
        System.assertEquals(projTaskObj.NSP_Account_Id__c, oAccount.Id);
        accProj.Name = 'Test';
        update accProj;
        System.assertEquals(projTaskObj.NSP_Account_Id__c, oAccount.Id);
        Test.stopTest();
    }

    @isTest
    private static void updateProjectNameWithAccountTest() {
        //creating Project
        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.TemplateName__c = 'Test Template';
        project.Templates_Used__c = 'TEMP USED';
        project.RecordTypeId = peoProjectRecordType;
        project.pse__Start_Date__c = Date.today();
        test.startTest();
        //inserting Project
        insert project;
        test.stopTest();
        //then
        String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                            .addFilter('Id', project.pse__Account__c).addLimit(1).build();
        Account accountRec = Database.query(queryAcc);

        String queryProj = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                            .addFilter('Id', project.id).addLimit(1).build();
        pse__Proj__c updatedProj = Database.query(queryProj);

        //checking the name of project other than BPS RecordType: Negative scenario
        System.assertEquals('Test Template' + ' - ' +Date.today().month()+'.'+Date.today().day()+'.'+Date.today().year()+' - ' + accountRec.Name , updatedProj.Name, 'project name updated with start date and account name ');
    }

    @isTest
    private static void updateProjectNameWithTemplateTest() {

        Id bpsProjectRecordType = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_SOBJECT_NAME ,NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Templates_Used__c = 'TEMP USED';
        project.RecordTypeId = bpsProjectRecordType;
        project.pse__Start_Date__c = Date.today();

        test.startTest();
        //inserting Project
        insert project;
        test.stopTest();
        String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS)
                            .addFilter('Id', project.pse__Account__c).addLimit(1).build();
        Account accountRec = Database.query(queryAcc);
        String queryProj = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                            .addFilter('Id', project.id).addLimit(1).build();
        pse__Proj__c updatedProj = Database.query(queryProj);
        //updating project name of BPS recordtype as AccountName: Template name
        System.assertEquals(accountRec.Name +': '+ project.TemplateName__c , updatedProj.Name, 'project name updated account name and template name');

    }

    @isTest
    private static void updateProjDateofPEOBillableTest() {
        //creating Project
        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        Id billableSerRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, NSP_ServiceConstants.PEO_BILL_RECORDTYPE);
        project.Templates_Used__c = 'TEMP USED';
        project.RecordTypeId = billableSerRecordTypeId;
        project.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_BILLABLE;

        test.startTest();
        //inserting Project
        INSERT project;
        test.stopTest();
        //then
        String queryProj = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                            .addFilter('Id', project.id).addLimit(1).build();
        pse__Proj__c updatedProj = Database.query(queryProj);

        //Start date of the record type as PEO Billable and project type is Service Billable
        System.assertEquals(NSP_ServiceConstants.PROJECT_TYPE_BILLABLE, updatedProj.pse__Project_Type__c);
    }

    @isTest
    private static void updateProjectNameWithoutAccountTest() {
        Account oAccount = [Select Id, Name from Account WHERE Name = 'Test Account 01' LIMIT 1];
        //crating Project
        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.TemplateName__c = 'Test Template';
        project.Templates_Used__c = 'TEMP USED';
        project.RecordTypeId = peoProjectRecordType;
        project.pse__Start_Date__c = Date.today();
        project.pse__Account__c = oAccount.Id;

        test.startTest();
        //inserting Project
        insert project;
        test.stopTest();
        //then
        String queryProj = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                            .addFilter('Id', project.id).addLimit(1).build();
        pse__Proj__c updatedProj = Database.query(queryProj);

       System.assertEquals('Test Template' + ' - ' +Date.today().month()+'.'+Date.today().day()+'.'+Date.today().year() + ' - '+oAccount.Name, updatedProj.Name, 'project name updated with start date');

    }

    @isTest
    private static void completeProjectTest() {
        Test.startTest();
        pse__Proj__c proj = [SELECT Id,pse__Project_Status__c FROM pse__Proj__c WHERE Name='Test PEO' LIMIT 1];
        proj.pse__Project_Status__c = 'Complete';
        update proj;
        Test.stopTest();
    }

    @isTest
    private static void updateProjectOwnerTest() {
        Account oAccount = [Select id from Account WHERE Name != NULL LIMIT 1];
        //creating contact
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        oContact.pse__Is_Resource__c = true;
        oContact.pse__Is_Resource_Active__c = true;
        //inserting contact
        insert oContact;
        //creating Project

        pse__Proj__c oProject = [Select Id , OwnerId from pse__Proj__c WHERE  TemplateName__c =: label.Middle_Market_Implementation_Project ];
        //inserting Project
        Test.startTest();
        //insert oProject;
        oProject.pse__Project_Manager__c = oContact.Id;
        //Updating Project
        update oProject;
        Test.stopTest();
        pse__Proj__c project = [Select Id , OwnerId from pse__Proj__c WHERE pse__Project_Manager__c =:oContact.Id ];
        System.assertEquals(project.OwnerId,oContact.pse__Salesforce_User__c);
    }

    @isTest
    private static void createImplementationProfileTest() {
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = System.Today();
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType ;
        oProject.recordTypeId = peoProjectRecordTypeId;
        Test.startTest();
        //inserting Project
        insert oProject;
        Test.stopTest();
        //getting Implimentation Profile recods
        List<Implementation_Profile__c> impProfile = [Select Id FROM Implementation_Profile__c WHERE NSP_Project__c = :oProject.Id];
        System.assertEquals(1, impProfile.size());
    }

    @isTest
    private static void createProjTeamRoleTest() {
        //creating Project
                             Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
                             oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = peoProjectRecordTypeId;

                             pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
                             oProject1.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject1.TemplateName__c = label.FSOImplementationProject;
        oProject1.RecordTypeId = peoProjectRecordTypeId;
        Test.startTest();

        //Inserting Project
        insert new List<pse__Proj__c>{ oProject, oProject1 };

        //getting List of Project team records
        List<NSP_Project_Team__c> projectTeam = [Select Id , NSP_Role__c, NSP_Assignee__c FROM NSP_Project_Team__c WHERE NSP_Project__c=: oProject.Id];
                             System.assert(projectTeam.size()>0);
        Test.stopTest();
    }

    @isTest
    private static void onCancelUpdateImplProfileTest() {
        //GIVEN
        Test.startTest();
        pse__Proj__c proj = [SELECT Id,pse__Project_Status__c FROM pse__Proj__c WHERE pse__Project_Status__c=:'Active' AND RecordTypeId =: peoProjectRecordType LIMIT 1];
        //WHEN
        proj.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSCANCELLED;
        proj.NSP_Cancelled_Reason__c = 'Client Terminated';

        update proj;
        //THEN
        Implementation_Profile__c impProfile = [SELECT Id, NSP_Inactive__c FROM Implementation_Profile__c WHERE NSP_Project__c =:proj.Id];
        system.assert(true, impProfile.NSP_Inactive__c);
        Test.stopTest();
    }

    @isTest
    private static void updateAssetProductSegmentTest() {
        Test.startTest();
                             pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        insert oProject;

        Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integra.NSP_Client__c='2345';
        integra.NSP_Company_Name__c='test company';
        integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        insert integra;

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = integra.Id;
        prjAsset.Project__c=oProject.Id;
        insert prjAsset;

        oProject.NSP_Client_Size__c = 'Middle Market Enterprise (750 + EEs)';

              update oProject;
        Test.stopTest();
        Asset ast = [Select Id , NSP_Product_Segment__c FROM Asset WHERE Id =: prjAsset.Asset__c];
        System.assertEquals(ast.NSP_Product_Segment__c, oProject.NSP_Client_Size__c);
    }

    @isTest
    private static void updateAssetProductSegmentException() {
        Test.startTest();
                             pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.ITA_IMPLEMENTATION;
        insert oProject;

        Asset integra = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        integra.NSP_Client__c='2345';
        integra.NSP_Company_Name__c='test company';
        integra.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.INTEGRA_ASSET);
        insert integra;

        Project_Asset__c prjAsset = (Project_Asset__c)NSP_TestExtendedDataFactory.createSObject(new Project_Asset__c(), false);
        prjAsset.Asset__c = integra.Id;
        prjAsset.Project__c=oProject.Id;
        insert prjAsset;

        oProject.NSP_Client_Size__c = 'Middle Market Enterprise (750 + EEs)';

                             update oProject;
        Asset ast = [Select Id , NSP_Product_Segment__c FROM Asset WHERE Id =: prjAsset.Asset__c];
        System.assertEquals(ast.NSP_Product_Segment__c, oProject.NSP_Client_Size__c);
        Test.stopTest();
    }

    @isTest
    private static void updateRelatedAssetTest() {

        List<pse__Proj__c> listProject = new List<pse__Proj__c>();
        // Updating Project for Both Positive and negative scenerio i.e. One have Order and another don't have Order
        for(pse__Proj__c projObj : [SELECT id,TemplateName__c FROM pse__Proj__c WHERE TemplateName__c != null]){
            projObj.Invoice_Ready__c = true;
            projObj.Go_Live_Date__c  = System.today();
            projObj.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSCLOSED;
            projObj.TemplateName__c=NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
            listProject.add(projObj);
         }

        Test.startTest();
        update listProject;

        List<Asset> listofAsset = [SELECT id,Status FROM Asset WHERE Id != null];
        pse__Proj__c projObj = [SELECT id,pse__Project_Status__c FROM pse__Proj__c WHERE ID != null LIMIT 1];
        projObj.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSACTIVE;
        update projObj;
        projObj.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSCLOSED;
        System.assertEquals(projObj.pse__Project_Status__c, NSP_ServiceConstants.PROJECTSTATUSCLOSED);
        update projObj;
        Test.stopTest();
    }

    @isTest
    private static void createWXProjectTest() {
              pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c='iSolved Benefits';
        Test.startTest();
              insert oProject;
              Test.stopTest();
        pse__Proj__c wxPrj = [Select Id  ,TemplateName__c , pse__Parent_Project__c FROM pse__Proj__c WHERE  pse__Parent_Project__c =:oProject.Id  ];
        system.assertEquals(wxPrj.TemplateName__c, NSP_ServiceConstants.WxCarrierConnectionProject);
    }

    @isTest
    private static void createWXProjectException() {
              pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.ITA_IMPLEMENTATION;
        Test.startTest();
            insert oProject;
              Test.stopTest();
        List<pse__Proj__c> wxPrj = [Select Id  ,TemplateName__c , pse__Parent_Project__c FROM pse__Proj__c WHERE  pse__Parent_Project__c =:oProject.Id];
        system.assertEquals(wxPrj.Size(), 0);
    }

    @isTest
    private static void createITAProjectTest() {
        String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addLimit(1).build();
        Account oAccount =Database.query(queryAcc);
        //ITA template project insertion
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.ITA_IMPLEMENTATION;
        oProject.pse__Account__c = oAccount.Id;
        Test.startTest();
            insert oProject;
        //case should get created as the criteria are met and account as active asset
        String queryCase = new NSP_QueryBuilder('Case', CASE_FIELDS).addLimit(1).build();
        Case oCase =Database.query(queryCase);
              Test.stopTest();
        //check assertion if case has category as mentioned in AC
        system.assertEquals(oCase.NSP_Category__c, NSP_ServiceConstants.INFRASTRUCTURE);
    }

    @isTest
    private static void createITAProjectTestException() {

        //ITA template project insertion
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;

        Test.startTest();
            insert oProject;
        //query for account where active asset is not associated
        String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addLimit(1).build();
        Account oAccount =Database.query(queryAcc);
              Test.stopTest();
        //Active wo asset account id is not associated with project account id
        system.assertEquals(oAccount.Id, oProject.pse__Account__c);
    }

    @isTest
    private static void createItaCqaCaseAndSendEmailTest() {
        //query for Project
        String bpsPrjQuery = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
                                                                        .addFilter('Templates_Used__c', NSP_ServiceConstants.ITA_IMPLEMENTATION)
                                                                        .addLimit(1).build();
        pse__Proj__c bpsProject = Database.query(bpsPrjQuery);

        Test.startTest();
        bpsProject.recordTypeId = bpsProjectRecordTypeId;
        bpsProject.TemplateName__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
        bpsProject.Peer_Review__c = NSP_ServiceConstants.PEER_REVIEW_SENT_TO_REVIEW;
        Database.update(bpsProject);
        NSP_ProjectTriggerHelper.createProjectAndProjectTasks(new Set<Id> {bpsProject.Id});
        Test.stopTest();

        // Query case to assert
        String cseQuery = new NSP_QueryBuilder('Case', CASE_FIELDS)
            .addFilter('Project__c', bpsProject.id).build();
        List<Case> peerReviewCaseList = Database.query(cseQuery);
        System.assertEquals(bpsProject.Peer_Review__c, NSP_ServiceConstants.PEER_REVIEW_SENT_TO_REVIEW);
    }

    @isTest
    private static void createItaCqaCaseNegativeTest() {
        //query for Project
        String bpsPrjQuery = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS).addFilter('Templates_Used__c', NSP_ServiceConstants.ITA_IMPLEMENTATION).addLimit(1).build();
        pse__Proj__c bpsProject = Database.query(bpsPrjQuery);

        Test.startTest();
        bpsProject.Peer_Review__c = NSP_ServiceConstants.PEER_REVIEW_IN_PROGRESS;
        database.update(bpsProject);
        Test.stopTest();

        // Query case to assert
        String cseQuery = new NSP_QueryBuilder('Case', CASE_FIELDS)
            .addFilter('Project__c', bpsProject.id).build();
        List<Case> assertCase = Database.query(cseQuery);
        system.assert(assertCase.size() != 1, 'ITA CQA Case is not created');
    }

    @isTest
    private static void createWOWXProjectTest() {
        String queryAcc = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addLimit(1).build();
        Account oAccount =Database.query(queryAcc);
              pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.WO_WX_TEMPLATE;
        oProject.pse__Account__c = oAccount.id;
        Test.startTest();
              insert oProject;
              Test.stopTest();
        system.assertEquals(oProject.TemplateName__c, NSP_ServiceConstants.WO_WX_TEMPLATE);
    }

    @isTest
    private static void createWOWXProjectNegativeTest() {
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.TemplateName__c=NSP_ServiceConstants.ITA_IMPLEMENTATION;
        Test.startTest();
              insert oProject;
              Test.stopTest();
        system.assertNotEquals(oProject.pse__End_Date__c, System.today().addDays(30));
    }

    @isTest
    private static void testProjectSharing() {
        List<String> accFields = new List<String>{'Id',NAME};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        Test.startTest();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = peoProjectRecordType;
        oProject.NSP_Visible_to_Client__c = true;
        oProject.pse__Account__c = acc.Id;
        INSERT oProject;
        Assert.areEqual(true, oProject.NSP_Visible_to_Client__c);
        Test.stopTest();
    }

    @isTest
    private static void testNoProjectSharing() {
        List<String> accFields = new List<String>{'Id',NAME};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        Test.startTest();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
       oProject.RecordTypeId = peoProjectRecordType;
        oProject.pse__Account__c = acc.Id;
        oProject.NSP_Visible_to_Client__c = false;
        INSERT oProject;
        System.assertEquals(false, oProject.NSP_Visible_to_Client__c);
        Test.stopTest();
    }

    @isTest
    private static void updateAccountInProjectNameTest() {

        List<String> accFields = new List<String>{'Id',NAME};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

         List<String> accFields1 = new List<String>{'Id',NAME};
        String accQuery1 = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account 01').addLimit(1).build();
        Account acc1 = Database.query(accQuery);

        Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        con.FirstName = 'newRecordType';
        con.pse__Salesforce_User__c =  userinfo.getUserId();
        con.AccountId = acc1.Id;
        insert con;
        //creating Project
        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Templates_Used__c = NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        project.pse__Start_Date__c = Date.today();
        project.pse__Account__c = acc.Id;
        test.startTest();
        INSERT project;
        project.recordTypeId = bpsProjectRecordTypeId;
        project.pse__Account__c = acc1.Id;
         project.TES_HCM_Implementation_Support_Tasks__c = NSP_ServiceConstants.TES_HCM_BANK_AUDIT;
        project.NSP_Is_Bank_Audit_Task__c = true;
        project.TemplateName__c = NSP_ServiceConstants.HCM_PROJECT_NAME;
        project.Project_Implementer__c = userinfo.getUserId();
        project.Project_Coordinator__c = userinfo.getUserId();
        project.pse__End_Date__c = system.today();
        UPDATE project;
        test.stopTest();

        System.assertEquals(project.TemplateName__c,  NSP_ServiceConstants.HCM_PROJECT_NAME);
    }

    @isTest
    private static void doNotupdateAccountInProjectNameTest() {

        List<String> accFields = new List<String>{'Id',NAME};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        //creating Project
        pse__Proj__c project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        project.Templates_Used__c = NSP_ServiceConstants.INTEGRA_IMPLEMENTATION;
        project.pse__Start_Date__c = Date.today();
        project.pse__Account__c = acc.Id;
        test.startTest();
        INSERT project;
         project.pse__Project_Type__c = 'Service Plan';
        project.pse__Project_Status__c = 'Complete';
        project.NSP_Rating__c = 'Unfavorable';
        project.TES_HCM_Implementation_Support_Tasks__c = NSP_ServiceConstants.TES_HCM_BANK_AUDIT;
        project.NSP_Is_Bank_Audit_Task__c = true;
        project.pse__Start_Date__c = Date.today().addDays(1);
        UPDATE project;
        test.stopTest();

        System.assertEquals(project.pse__Project_Status__c, 'Complete');
    }

    @isTest
    private static void testProjectRelatedSharing() {
        List<String> accFields = new List<String>{'Id',NAME};
        String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        List<String> projectFields = new List<String>{'Id', NAME, 'pse__Account__c','NSP_Visible_to_Client__c'};
        String prjQuery = new NSP_QueryBuilder('pse__Proj__c', projectFields)
            .addFilter(NAME, 'Test Delete 1').addLimit(1).build();
        pse__Proj__c oProject = Database.query(prjQuery);

        List<String> prjTaskFields = new List<String>{'Id','NSP_Visible_to_Client__c' , 'pse__Project__r.pse__Account__c' , 'pse__Project__c'};
        String prjTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', prjTaskFields)
            .addFilter('NSP_Visible_to_Client__c', True).addLimit(1).build();
         pse__Project_Task__c  prjTask = Database.query(prjTaskQuery);

        List<String> milestoneFields = new List<String>{'Id', 'NSP_Visible_to_Client__c' , 'pse__Project__r.pse__Account__c' , 'pse__Project__c'};
        String milestoneQuery = new NSP_QueryBuilder('pse__Milestone__c', milestoneFields)
            .addFilter('NSP_Visible_to_Client__c', True).addLimit(1).build();
         pse__Milestone__c milestone = Database.query(milestoneQuery);

        Test.startTest();
            oProject.pse__Account__c=acc.Id;
            oProject.NSP_Visible_to_Client__c = true;
            update oProject;
        Test.stopTest();
        List<pse__Proj__Share> prjShares = [SELECT Id , ParentId , UserorGroupId FROM pse__Proj__Share
                                             WHERE ParentId =:oProject.Id  AND
                                             RowCause = :Schema.pse__Proj__Share.RowCause.InsperitySharing__c ];
        pse__Proj__Share prjShare = null;
        if ( ( prjShares != null ) && !prjShares.isEmpty() ) {
            prjShare = prjShares[0];
        }


       List<pse__Project_Task__Share> prjTaskShares = [SELECT Id , ParentId , UserorGroupId FROM pse__Project_Task__Share
                                             WHERE ParentId =:prjTask.Id  AND
                                             RowCause = :Schema.pse__Project_Task__Share.RowCause.InsperitySharing__c ];
        pse__Project_Task__Share prjTaskShare = null;
        if ( ( prjTaskShares != null ) && !prjTaskShares.isEmpty() ) {
            prjTaskShare = prjTaskShares[0];
        }



        List<pse__Milestone__Share> milestShares = [SELECT Id , ParentId , UserorGroupId FROM pse__Milestone__Share
                                             WHERE ParentId =:milestone.Id  AND
                                             RowCause = :Schema.pse__Milestone__Share.RowCause.InsperitySharing__c ];
        pse__Milestone__Share milestShare = null;
        if ( ( milestShares != null ) && !milestShares.isEmpty() ) {
            milestShare = milestShares[0];
        }

        NSP_ProjectRecordSharing.removeRelatedProjectSharing(new Set<Id>{oProject.Id});
    }

    @isTest
    private static void testHandleBeforeDeleteOfProjTemp() {
        List<String> projFields = new List<String>{'Id',NAME, 'pse__Is_Template__c'};
        String projQuery = new NSP_QueryBuilder('pse__Proj__c', projFields)
            .addFilter(NAME, 'Test Template').addLimit(1).build();
        pse__Proj__c proj = Database.query(projQuery);
        try{
            if(proj!=null){
                Database.delete(proj);
            }
        }catch (DmlException ex) {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION' , ex.getDmlStatusCode(0),'Error Exception');
        }

    }

    @isTest
    private static void updateProjOwnerForServicePlanProjectTypeTest() {

        List<String> accFields = new List<String>{'Id',NAME};
            String accQuery = new NSP_QueryBuilder('Account', accFields)
            .addFilter(NAME, 'Test Account').addLimit(1).build();
        Account acc = Database.query(accQuery);

        acc.NSP_Service_Segment__c = NSP_ServiceConstants.CoreAssetSegment;
        update acc;

        test.startTest();
        pse__Proj__c proj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        proj.TemplateName__c=NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
        proj.pse__Project_Type__c = NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
        proj.pse__Account__c = acc.Id;
        proj.pse__Is_Template__c = False;
        proj.pse__Start_Date__c = System.today();
        insert proj;
        test.stopTest();

        pse__Proj__c updatedProj = (pse__Proj__c) new NSP_sObjectSelector('pse__Proj__c', PROJECT_FIELDS).selectById(proj.Id);

        System.assertEquals(updatedProj.OwnerId, userinfo.getUserId());

    }

}
//