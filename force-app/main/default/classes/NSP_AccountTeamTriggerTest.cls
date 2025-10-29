@isTest
private class NSP_AccountTeamTriggerTest {
    private static final string accountName = 'Testing Account';
    private static final string projectTaskName = 'Submit Termination Checklist';
    private static final string projectTaskTemplate = 'PEO Termination';
    private static final string status = 'Draft';
    private static final string EMP_PER_ID = 'EMP 1234';

    @testSetup
    private static void testData() {
        User userObj = NSP_TestHelper.createUser(false);
        userObj.NSP_Employee_Per_ID__c = EMP_PER_ID;
        userObj.EmployeeNumber = EMP_PER_ID;
        userObj.NSP_Service_Region__c = 'MMSO - Southwest';
        insert userObj;

        AccountTeamTriggerSettings__c setting = new AccountTeamTriggerSettings__c();
        setting.IsEnabledTermFormLookUps__c = true;
        insert setting;

        NSP_TestHelper.createAccount(true);
        String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();

        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        acc.Name = accountName;
        insert acc;

        List<pse__Proj__c> lstProject = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Account__c = acc.Id;
        oProject.pse__Start_Date__c = system.today();
        oProject.pse__End_Date__c = system.today().addDays(10);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = peoProjectRecordTypeId;
        lstProject.add(oProject);
        pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject1.pse__Account__c = acc.Id;
        oProject1.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject1.TemplateName__c = label.FSOImplementationProject;
        oProject1.RecordTypeId = peoProjectRecordTypeId;
        lstProject.add(oProject1);
        insert lstProject;

        pse__Milestone__c milestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestone.pse__Project__c = oProject.id;
        insert milestone;

        List<pse__Project_Task__c> projectTasks = new List<pse__Project_Task__c>();
        pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask1.pse__Project__c = oProject.Id;
        oProjectTask1.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_CANCELLED;
        oProjectTask1.pse__Milestone__c = milestone.id;
        oProjectTask1.NSP_Template_Generated__c = true;
        oProjectTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
        projectTasks.add(oProjectTask1);

        pse__Project_Task__c oProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask.pse__Project__c = oProject.Id;
        oProjectTask.Name = projectTaskName;
        oProjectTask.Template_Name__c = projectTaskTemplate;
        oProjectTask.NSP_Account_Id__c = acc.Id;
        oProjectTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_NOT_STARTED;
        projectTasks.add(oProjectTask);

        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.Name = projectTaskName;
        oProjectTask2.Template_Name__c = projectTaskTemplate;
        oProjectTask2.NSP_Account_Id__c = acc.Id;
        oProjectTask2.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projectTasks.add(oProjectTask2);
        insert projectTasks;




        //Added as part of STY-03667
        //Account team insertion
        NSP_Account_Team__c accTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults', true);
        accTeam.NSP_Primary__c=true;
        accTeam.NSP_User__c=userObj.Id;
        accTeam.NSP_Role__c = 'Client Liaison';
        update accTeam;

    }

    @isTest
    private static void testInsert() {
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];

        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_Role__c = 'Recruiting';
        test.startTest();
        insert accTeam;
        test.stopTest();
        User userObj = [SELECT Id FROM User WHERE NSP_Employee_Per_ID__c =: EMP_PER_ID];
        NSP_Account_Team__c accTeamObj = [SELECT Id,NSP_User__c FROM NSP_Account_Team__c WHERE NSP_Account__c =: accountObj.Id limit 1];
        system.assertEquals(userObj.Id, accTeamObj.NSP_User__c);
        accTeam.NSP_PER_ID__c = '7898';
        update accTeam;
    }

    @isTest
    private static void testUpdate() {
        test.startTest();
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];

        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_Role__c = 'Recruiting';
        insert accTeam;

        NSP_Account_Team__c accountTeamObj = [SELECT Id from NSP_Account_Team__c WHERE
                                              NSP_Account__c =: accountObj.Id Limit 1];

        accountTeamObj.NSP_Role__c = 'HR Specialist';

        update accountTeamObj;
        test.stopTest();

        NSP_Account_Team__c accountTeam = [SELECT Id,NSP_Role__c from NSP_Account_Team__c
                                           WHERE NSP_Account__c =: accountObj.Id Limit 1];

        system.assertEquals('HR Specialist', accountTeam.NSP_Role__c);
    }

    @isTest
    private static void testInsertAccountClientLiaison() {

        //GIVEN
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];

        test.startTest();
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        pse__Project_Task__c pt = [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                   NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE Id!=null limit 1];

        system.assertNotEquals(pt.NSP_Client_Liaison_Email__c, userInfo.getUserEmail());
        test.stopTest();
    }

    @isTest
    private static void updateAccountTeamNameToAssetNameTest() {

        //Account accountObj = [SELECT Id,Name FROM Account LIMIT 1];
        Test.startTest();
        Account accountObject = new Account(Name='TestAccountTeamObject');
        INSERT accountObject;
        Asset assetObject = new Asset(Name= 'TestAccountTeam',AccountId= accountObject.Id,CurrencyIsoCode= 'USD' );
        INSERT assetObject;
        NSP_Account_Team__c accountTeamObject = new NSP_Account_Team__c();
        accountTeamObject.NSP_Account__c = accountObject.Id;
        accountTeamObject.NSP_PER_ID__c = EMP_PER_ID;
        accountTeamObject.NSP_User__c = UserInfo.getUserId();
        accountTeamObject.NSP_Role__c = NSP_ServiceConstants.WXWA_BENEFITS;
        INSERT accountTeamObject;

        Asset assetObject1 = [SELECT ID, AccountId, NSP_WX_WA_Benefits_Specialist__c FROM Asset WHERE AccountId=: accountObject.Id ];
        System.Assert(String.isNotBlank(assetObject1.NSP_WX_WA_Benefits_Specialist__c));

        accountTeamObject.NSP_Role__c = NSP_ServiceConstants.WXWA_PAYROLL;
        UPDATE accountTeamObject;
        assetObject1 = [SELECT ID, AccountId, NSP_WA_WX_Payroll_Specialist__c FROM Asset WHERE AccountId=: accountObject.Id];
        System.Assert(String.isNotBlank(assetObject1.NSP_WA_WX_Payroll_Specialist__c));

        accountTeamObject.NSP_Role__c = NSP_ServiceConstants.PLAN_CONSULTANT;
        UPDATE accountTeamObject;

        AccountTeamTriggerSettings__c customSettingRec = new AccountTeamTriggerSettings__c();
        customSettingRec.Name = 'Test Record';
        customSettingRec.IsRetServiceNameChangeEnabled__c = true;
        customSettingRec.SetupOwnerId = userInfo.getUserId();
        insert customSettingRec;

        Test.stopTest();
    }

    @isTest
    private static void testInsertAccountHRSpecialist() {
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];

        test.startTest();
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.HRSpecialist;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        pse__Project_Task__c pt = [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                   NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE Id!=null limit 1];

        system.assertNotEquals(pt.NSP_Client_Liaison_Email__c, userInfo.getUserEmail());
        test.stopTest();
    }

    @isTest
    private static void testInsertBoth() {
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];
        test.startTest();
        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;
        pse__Project_Task__c pt = [SELECT Id,NSP_CC_Emails__c,NSP_Client_Liaison_Name__c,NSP_HR_Specialist_Email__c,NSP_AccountId__c,
                                   NSP_HR_Specialist_Name__c,NSP_Client_Liaison_Email__c FROM pse__Project_Task__c WHERE Id!=null LIMIT 1];

        system.assertNotEquals(pt.NSP_Client_Liaison_Email__c, userInfo.getUserEmail());
        test.stopTest();
    }

    @isTest
    private static void testErrorOnAccountTeam() {
        //GIVEN
        Account accountObj = [SELECT Id,Name from Account WHERE Id!=null limit 1];
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        accTeam.NSP_Primary__c=True;

        Test.startTest();
        try{
            insert accTeam;
        }catch (Exception ex){
            //test positive assertion on insertion record not inserted successfully and throws validation
            system.assertEquals('System.DmlException',ex.getTypeName());
        }
        accTeam.NSP_Primary__c=false;
        insert accTeam;
        List<NSP_Account_Team__c> accTeamList = [SELECT Id,NSP_Role__c
                                                 FROM NSP_Account_Team__c
                                                 WHERE NSP_Role__c=:NSP_ServiceConstants.CLIENT_LIAISION ];
        //test assertion negative scenario record saved successfully
        system.assertEquals(2, accTeamList.size());
        accTeam.NSP_Primary__c=true;
        try{
            update accTeam;
        }catch (Exception ex){
            //test assertion on update record not updated and throws validation
            system.assertEquals('System.DmlException',ex.getTypeName());
        }
        Test.stopTest();

    }

    @isTest
    private static void updateAssetServiceRegionTest() {
        Test.startTest();
        User user = [SELECT Id, NSP_Service_Region__c FROM User WHERE Id!=null LIMIT 1];
        Account accountObj = [SELECT Id, Name From Account WHERE Id!=null LIMIT 1];
        Id woRecord = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );

        Asset asset = new Asset();
        Asset.Name = 'Test Asset';
        asset.RecordTypeId = woRecord;
        asset.AccountId = accountObj.Id;
        asset.NSP_Account_Status__c = 'Active';
        insert asset;

        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_User__c = user.Id;
        accTeam.NSP_Role__c = 'Manager, HR Services';
        Insert accTeam;

        Test.stopTest();
        system.Assert(user.NSP_Service_Region__c == Asset.NSP_Service_Region__c);

    }

    @isTest
    private static void testUserUpdateOnAccountTeam() {
        //GIVEN
        User userObj = [SELECT Id from User WHERE NSP_Employee_Per_ID__c = 'EMP 1234'];
        NSP_Account_Team__c accTeam = [SELECT Id,NSP_Role__c,NSP_PER_ID__c
                                                 FROM NSP_Account_Team__c
                                                 WHERE Id != null
                                                 LIMIT 1 ];

        test.startTest();
        accTeam.NSP_User__c = userObj.Id;
        update accTeam;
        test.stopTest();
        system.assertEquals(accTeam.NSP_User__c, userObj.Id );
    }

    @isTest
    private static void validationOnDeletionOfAccountTeamTest() {
        List<String> accountTeamFields = new List<String>{'Id','NSP_Account__c'};
        Account accountObj = [SELECT Id, Name FROM Account WHERE Id != null LIMIT 1];

        List<NSP_Account_Team__c> lstAccTeam = new List<NSP_Account_Team__c>();
        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_PER_ID__c = EMP_PER_ID;
        accTeam.NSP_User__c = UserInfo.getUserId();
        accTeam.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        lstAccTeam.add(accTeam);
        insert lstAccTeam;

        Test.startTest();
        database.delete(lstAccTeam);
        Test.stopTest();

        String accTeamQuery = new NSP_QueryBuilder('NSP_Account_Team__c', accountTeamFields).addFilter('NSP_Account__c', accountObj.Id).addLimit(1).setSecurityEnforce(false).build();
        List<NSP_Account_Team__c> accTeamList =  Database.query(accTeamQuery);

      system.assertEquals(accTeamList.isEmpty(), false);
    }

    @isTest
    private static void populateUserIdOnATMBasedOnPerIdTest() {
        Account accountObj = [SELECT Id,Name from Account WHERE Name !=null limit 1];

        NSP_Account_Team__c accTeam = new NSP_Account_Team__c();
        accTeam.NSP_Account__c = accountObj.Id;
        accTeam.NSP_Role__c = 'Recruiting';
        accTeam.NSP_PER_ID__c = '545454';
        insert accTeam;

        NSP_Account_Team__c accTeam1 = new NSP_Account_Team__c();
        accTeam1.NSP_Account__c = accountObj.Id;
        accTeam1.NSP_Role__c = 'Recruiting';
        accTeam1.NSP_PER_ID__c = '765456';
        insert accTeam1;

        List<NSP_Account_Team__c> accountTeamObjList = [SELECT Id,NSP_User__c from NSP_Account_Team__c WHERE
                                              NSP_PER_ID__c = '545454' or NSP_PER_ID__c = '765456'];

        test.startTest();

         User userObj = [SELECT Id,EmployeeNumber FROM User WHERE NSP_Employee_Per_ID__c =: EMP_PER_ID];
        accountTeamObjList[0].NSP_Role__c = 'HR Specialist';
        accountTeamObjList[0].NSP_PER_ID__c = EMP_PER_ID;
        //update accountTeamObj;
        accountTeamObjList[1].NSP_PER_ID__c = '0';
        update accountTeamObjList;
        accTeam1.NSP_PER_ID__c = '765488';
        update accTeam1;


        NSP_Account_Team__c accountTeam = [SELECT Id,NSP_Role__c,NSP_User__c from NSP_Account_Team__c
                                           WHERE NSP_Account__c =: accountObj.Id Limit 1];
        test.stopTest();
        system.assertEquals(userObj.Id, accountTeam.NSP_User__c);
    }

    @isTest
    private static void updateUserLookupsTest() {
        test.startTest();
        Account accountObj = [SELECT Id,Name from Account WHERE Name =:accountName limit 1];
        User userObj = [SELECT Id from User WHERE NSP_Employee_Per_ID__c =: EMP_PER_ID];
        List<NSP_Account_Team__c> accTeams = new List<NSP_Account_Team__c>();
        List<NSP_Account_Team__c> accTeamsUpdate = new List<NSP_Account_Team__c>();
        List<NSP_Termination_Form__c> termForms = new List<NSP_Termination_Form__c>();

        NSP_Account_Team__c accTeam1 = new NSP_Account_Team__c();
        accTeam1.NSP_User__c = userObj.Id;
        accTeam1.NSP_Account__c = accountObj.Id;
        accTeam1.NSP_Role__c = NSP_ServiceConstants.PAYROLL_SUPERVISOR;
        accTeams.add(accTeam1);

        NSP_Account_Team__c accTeam2 = new NSP_Account_Team__c();
        accTeam2.NSP_User__c = userObj.Id;
        accTeam2.NSP_Account__c = accountObj.Id;
        accTeam2.NSP_Role__c = NSP_ServiceConstants.PAYROLL_SPECIALIST;
        accTeams.add(accTeam2);

        NSP_Account_Team__c accTeam3 = new NSP_Account_Team__c();
        accTeam3.NSP_User__c = userObj.Id;
        accTeam3.NSP_Account__c = accountObj.Id;
        accTeam3.NSP_Role__c = NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR;
        accTeams.add(accTeam3);

        NSP_Account_Team__c accTeam4 = new NSP_Account_Team__c();
        accTeam4.NSP_User__c = userObj.Id;
        accTeam4.NSP_Account__c = accountObj.Id;
        accTeam4.NSP_Primary__c=true;
        accTeam4.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        accTeams.add(accTeam4);

        NSP_Account_Team__c accTeam5 = new NSP_Account_Team__c();
        accTeam5.NSP_User__c = userObj.Id;
        accTeam5.NSP_Account__c = accountObj.Id;
        accTeam5.NSP_Role__c = NSP_ServiceConstants.MID_MARKET_ACC_EX;
        accTeams.add(accTeam5);

        NSP_Account_Team__c accTeam6 = new NSP_Account_Team__c();
        accTeam6.NSP_User__c = userObj.Id;
        accTeam6.NSP_Account__c = accountObj.Id;
        accTeam6.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
        accTeams.add(accTeam6);

        NSP_Account_Team__c accTeam7 = new NSP_Account_Team__c();
        accTeam7.NSP_User__c = userObj.Id;
        accTeam7.NSP_Account__c = accountObj.Id;
        accTeam7.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
        accTeams.add(accTeam7);

        insert accTeams;
        pse__Project_Task__c oProjectTask1 = [SELECT Id FROM pse__Project_Task__c WHERE pse__Status__c = 'Not Started'];
        pse__Project_Task__c oProjectTask2= [SELECT Id FROM pse__Project_Task__c WHERE pse__Status__c = 'In Progress'];
        NSP_Termination_Form__c termForm1 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Supervisor__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask1.Id
        );
        NSP_Termination_Form__c termForm2 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Payroll_Specialist__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask1.Id
        );
        termForms.add(termForm2);
        NSP_Termination_Form__c termForm3 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Insperity_Blended_Role__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask2.Id
        );
        termForms.add(termForm3);
        NSP_Termination_Form__c termForm4 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Client_Liaison__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask1.Id
        );
        termForms.add(termForm4);
        NSP_Termination_Form__c termForm5 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Manager_HR_Services__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask1.Id
        );
        termForms.add(termForm5);
        NSP_Termination_Form__c termForm6 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Account_Executive__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask1.Id
        );
        termForms.add(termForm6);
        NSP_Termination_Form__c termForm7 = new NSP_Termination_Form__c(
            NSP_Account__c = accountObj.Id,
            NSP_Credit_Specialist__c = UserInfo.getUserId(),
            NSP_Status__c = status,
            NSP_Project_Task__c = oProjectTask1.Id
        );
        termForms.add(termForm7);
        insert termForms;
        accTeam1.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam1);
        accTeam2.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam2);
        accTeam3.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam3);
        accTeam4.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam4);
        accTeam5.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam5);
        accTeam6.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam6);
        accTeam7.NSP_User__c = UserInfo.getUserId();
        accTeamsUpdate.add(accTeam7);

        update accTeamsUpdate;
    }

}
//