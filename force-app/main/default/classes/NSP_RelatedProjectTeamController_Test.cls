/**
* @description  :   Test class for NSP_ProjectTeamTriggerHelper .
* @date 08/3/2022
* Author : Nischay Jindal
* Name : NSP_ProjectTeamTriggerHelperTest
*/
@isTest(SeeAllData=false)
private class NSP_RelatedProjectTeamController_Test {
    /***********************************************************************************************
    * MethodName: testData
    * Description : Setting the Test Data
    * ********************************************************************************************/
	@testSetup
    public static void setUpData(){
        //Middle_Market
        Id PEORecordTypeId  = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PEOProject);
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
		Contact con = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact());
        con.AccountId = acc.Id;
        con.LastName= 'Test';
        con.NSP_Work_email__c = 'test@test.com';
        con.NSP_Job_Title__c = 'Test Title';
        insert con;
        
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
		oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = PEORecordTypeId;
        oProject.pse__Account__c =acc.Id;
        insert oProject;
    }
    
    /***********************************************************************************************
    * MethodName: fetchProjectTeam
    * Description : Unit test for fetchProjectTeam 
    * ********************************************************************************************/
    @isTest
    private static void testFetchProjectTeam(){
        Test.startTest();
        List<String> accFields = new List<String>{'Id'};
        String accQuery = new NSP_QueryBuilder('Account', accFields).addLimit(1).build();
        Account accRec = Database.query(accQuery);
        
        List<String> conFields = new List<String>{'Id','LastName','AccountId','NSP_Work_email__c','NSP_Job_Title__c'};
        String conQuery = new NSP_QueryBuilder('Contact', conFields)
            			  .addFilter('AccountId', accRec.Id).addLimit(1).build();
        Contact conRec = Database.query(conQuery);
        
        List<String> projFields = new List<String>{'Id','TemplateName__c'};
        String projQuery = new NSP_QueryBuilder('pse__Proj__c', projFields)
                          .addFilter('TemplateName__c', label.Middle_Market_Implementation_Project).addLimit(1).build();
        pse__Proj__c projectRec = Database.query(projQuery);
        
        
 		List<String> projTeamFields = new List<String>{'Id',
            						  'NSP_Project__c' , 'NSP_Assignee__c',
            						  'NSP_Role__c','NSP_Assignee__r.Name','NSP_Assignee__r.NSP_Job_Title__c'};
        String query = new NSP_QueryBuilder('NSP_Project_Team__c', projTeamFields)
						  .addFilter('NSP_Project__c', projectRec.Id)              
                          .addFilter('NSP_Role__c', NSP_ServiceConstants.ProjectManager).addLimit(1).build();
        NSP_Project_Team__c projectTeamRec = Database.query(query);
        projectTeamRec.NSP_Assignee__c = conRec.Id;
        Update projectTeamRec; 
        
        NSP_RelatedProjectTeamController.setrecId(projectTeamRec.NSP_Project__c);
        NSP_RelatedProjectTeamController.getrecId();
        System.assertEquals(projectTeamRec.Id, NSP_RelatedProjectTeamController.projectTeam.Id);
		Test.stopTest();        

    }
}