@isTest private class CreateProjectFromTemplateAccountTest {
   
@testSetup private static void testDataSetup(){
        //Create Project Template 
        pse__proj__c oProj = (pse__proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProj.Name = NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
        oProj.pse__Is_Template__c = True;
        oProj.pse__Is_Active__c = True;
        oProj.pse__Start_Date__c = System.today();
        oProj.pse__End_Date__c = System.today().addDays(30);
        oProj.Go_Live_Date__c = System.today().addDays(-1);
        oProj.Invoice_Ready__c = false;
        Insert oProj;

        //Create Account
        Account projAccount = new Account();
        projAccount.Name = 'Test Account';
        insert projAccount;

        User userObj = NSP_TestHelper.createUser(false);
        userObj.NSP_Employee_Per_ID__c = 'EMP 1234';
        userObj.Username = 'testuser2@test.com' + System.currentTimeMillis();
        insert userObj;
    }

    //
    // MethodName    : testCreateProjectFromTemplate
    // Description   : This Method will test creation of project from template using FinancialForce API
    //
    @isTest private static void testCreateProjectFromTemplateInvo() {
        List<Account> accList = [SELECT ID, Name from Account WHERE Name = 'Test Account'];
        Account acc = accList[0];

        List<pse__proj__c> projTemplateList = [SELECT Id,Name, Template_Name__c, pse__Start_Date__c, pse__End_Date__c, NSP_Exclusively_Assign_Owner__c, recordtypeId from pse__Proj__c WHERE pse__Is_Template__c = True];
        pse__proj__c proj = projTemplateList[0];

        CreateProjectFromTemplateAccount.Request req;
        req = new CreateProjectFromTemplateAccount.Request();

        req.oaccountId = acc.Id;
        req.oprojectTemplateId = proj.Id;

        List<CreateProjectFromTemplateAccount.Response> responseList = new List<CreateProjectFromTemplateAccount.Response>();
        responseList = CreateProjectFromTemplateAccount.createProject(new List<CreateProjectFromTemplateAccount.Request>{req});
        System.assertEquals(1, responseList.size());
        
        req.oaccountId = null;
        req.oprojectTemplateId = null;

        responseList = CreateProjectFromTemplateAccount.createProject(new List<CreateProjectFromTemplateAccount.Request>{req});
        System.assertEquals(1, responseList.size());

    }
}