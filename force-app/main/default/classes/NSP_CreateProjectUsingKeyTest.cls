/* Description : Test class for NSP_CreateProjectUsingKey
    Date        : 02/12/2021 */
@isTest
public class NSP_CreateProjectUsingKeyTest {
    @testSetup
    public static void testDataSetup(){
        //Create Account
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        //Create Project Template
        pse__Proj__c hcmProjectTemplate = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
        hcmProjectTemplate.Name = NSP_ServiceConstants.HCM_PROJECT_NAME;
        hcmProjectTemplate.pse__Start_Date__c = Date.Today();
        hcmProjectTemplate.pse__Account__c= oAccount.Id;
        hcmProjectTemplate.pse__Is_Template__c = true;
        hcmProjectTemplate.Project_Implementer__c = UserInfo.getUserId(); 
        INSERT hcmProjectTemplate;
    }
    
    @isTest
    static void returnProjectIdWithTemplate() {
        Id projResp = NSP_CreateProjectUsingKey.createProject(NSP_ServiceConstants.INTEGRA, System.today(),'Case');
        System.assert(projResp == Null);
    }
    
    /***************************************************************************************************
    * MethodName	: testCreateProjectFromTemplate
    * Description	: This Method will test creation of project from template using FinancialForce API
    * **************************************************************************************************/
    @IsTest
    private static void testCreateProjectFromTemplate(){
        Test.startTest();
        List<String> projectFields = new List<String>{'Id','Name'};
        String query = new NSP_QueryBuilder('pse__Proj__c', projectFields)
            			.addFilter('Name', NSP_ServiceConstants.HCM_PROJECT_NAME)
            			.addFilter('pse__Is_Template__c', true).addLimit(1).build();
        pse__Proj__c projectTemplate = Database.query(query);
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest = NSP_CreateProjectUsingKey.createProjectFromTemplate(projectTemplate.Id, System.today(), projectTemplate.Name);
        Set<Id> newProjectIdSet = NSP_CreateProjectUsingKey.createProjectAndDeleteBudget(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{projRequest});
        System.assertEquals(1, [SELECT count() FROM pse__Proj__c WHERE Id IN : newProjectIdSet]);
        System.assertEquals(0, [SELECT count() FROM pse__Budget__c WHERE pse__Project__c IN : newProjectIdSet]);
        Test.stopTest();
    }
    
    /*****************************************************************************************************
    * MethodName	: testNotCreateProjectFromTemplate
    * Description	: This Method will test no project will be created 
    * 				  from template using FinancialForce API
    * ****************************************************************************************************/
    @IsTest
    private static void testNotCreateProjectFromTemplate(){
        Test.startTest();
        List<String> projectFields = new List<String>{'Id','Name'};
        String query = new NSP_QueryBuilder('pse__Proj__c', projectFields)
            			.addFilter('Name', NSP_ServiceConstants.HCM_PROJECT_NAME)
            			.addFilter('pse__Is_Template__c', true).addLimit(1).build();
        pse__Proj__c projectTemplate = Database.query(query);
        pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest projRequest = NSP_CreateProjectUsingKey.createProjectFromTemplate(null, System.today(), projectTemplate.Name);
        Set<Id> newProjectIdSet = NSP_CreateProjectUsingKey.createProjectAndDeleteBudget(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateRequest>{projRequest});
        System.assertEquals(0, [SELECT count() FROM pse__Proj__c WHERE Id IN : newProjectIdSet]);
        Test.stopTest();
    }
}