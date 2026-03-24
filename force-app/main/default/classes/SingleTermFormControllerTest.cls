@isTest
private class SingleTermFormControllerTest {
    
    @testSetup
    private static void testData() {
        Account acc1 = (Account) NSP_TestDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults');
        acc1.Name = 'acc1';
        acc1.NSP_AIMS_Client__c = 'client1';
        insert acc1;
        
        NSP_Account_Team__c AccTeam = (NSP_Account_Team__c) NSP_TestDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults');
        AccTeam.NSP_Account__c = acc1.Id;
        AccTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        AccTeam.NSP_PER_ID__c = '123';
        insert AccTeam;
        
        pse__Proj__c project = new pse__Proj__c(
            Name = 'Project1',
            pse__Is_Active__c = true,
            pse__Account__c = acc1.Id,
            pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED
        );
        insert project;
        
        // Termination task
        pse__Project_Task__c termTask = (pse__Project_Task__c) NSP_TestDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults');
        termTask.pse__Project__c = project.Id;
        termTask.Name = 'Submit Termination Checklist';
        insert termTask;
        
        NSP_Termination_Form__c TF1 = (NSP_Termination_Form__c) NSP_TestDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults');
        TF1.NSP_Status__c = 'Term Team Approved';
        TF1.NSP_Term_Code__c = 'Client Requested Termination Codes';
        TF1.NSP_Number_of_Active_Employees__c = 40;
        TF1.NSP_Benefit_Termination_Date__c = System.today();
        TF1.NSP_Project_Task__c = termTask.Id;
        TF1.Approval_Date__c = System.today();
        insert TF1;
        
        // Reinstatement Task
        pse__Project_Task__c reinTask = new pse__Project_Task__c(
            Name = NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK,
            pse__Project__c = project.Id
        );
        insert reinTask;
        
        NSP_Termination_Form__c ReinForm = (NSP_Termination_Form__c) NSP_TestDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults');
        ReinForm.NSP_Status__c = 'Term Team Approved';
        ReinForm.NSP_How_many_employees_were_moved__c = 15;
        ReinForm.NSP_Benefit_Termination_Date__c = System.today();
        ReinForm.NSP_Project_Task__c = reinTask.Id;
        ReinForm.Approval_Date__c = System.today();
        insert ReinForm;
        
        
        // Documents
        List<Document> docList = new List<Document>{
            new Document(Name = 'doc1', DeveloperName = 'Insperity_HR_Logo', ContentType = 'application/pdf', IsPublic = true, FolderId = UserInfo.getUserId()),
                new Document(Name = 'doc2', DeveloperName = 'Insperity_Copy_write_logo', ContentType = 'application/pdf', IsPublic = true, FolderId = UserInfo.getUserId()),
                new Document(Name = 'doc3', DeveloperName = 'Insperity_Service_Operations', ContentType = 'application/pdf', IsPublic = true, FolderId = UserInfo.getUserId())
                };
                    insert docList;
    }
    
    @isTest
    private static void getURLsTest() {
        Test.startTest();
        SingleTermFormController controller = new SingleTermFormController();
        String topUrl = controller.getTopLogoUrl();
        controller.getBottomLogoUrl();
        controller.getAddressLogoUrl();
        Test.stopTest();
        
        System.assertNotEquals(null, topUrl, 'Top logo URL should not be null');
    }
    
    @isTest
    private static void wrapTerminationTest() {
        NSP_Termination_Form__c tf = [
            SELECT
            Id, NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name, NSP_Client_Sub_Account_Numbers__c,
            NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,
            NSP_Number_of_Active_Employees__c, NSP_Term_Reason__c, NSP_Status__c,
            NSP_Last_Date_Wages_Paid_Through__c, NSP_Benefit_Termination_Date__c,
            NSP_Revision__c, NSP_New_Client_Name__c, NSP_New_Client_Number__c,
            Previous_term_date__c, NSP_SubTerm_reason__c, Previous_Bene_Date__c,
            NSP_Client_Term_Date__c, Previous_Term_Reason__c, Previous_Sub_Term_Reason__c,
            Previous_Client_Term_Date__c , NSP_How_many_employees_were_moved__c
            FROM NSP_Termination_Form__c
            WHERE NSP_Status__c = 'Term Team Approved'
            LIMIT 1
        ];
        
        Map<String, String> roleMapDetails = new Map<String, String>
        {
            NSP_ServiceConstants.PAYROLL_SPECIALIST => 'Payroll Specialist'
            , NSP_ServiceConstants.CLIENT_LIAISION => 'Client Liaison'
        };
        
        Test.startTest();
        WrapTermination wrapper = new WrapTermination(tf, roleMapDetails);
        String resultcst = wrapper.clientTermDate;
        String resultrsr = wrapper.reinstatementReason;
        Test.stopTest();
        
        System.assertEquals('acc1', wrapper.clinetName);
        System.assertEquals(40, wrapper.eeNumber);
        System.assertEquals('Payroll Specialist', wrapper.psName);
    }
    
    @isTest
    private static void test_getwrapTerminationList() {
        NSP_Termination_Form__c tf = [
            SELECT
            Id,
            NSP_Project_Task__r.Name,
            NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name
            FROM NSP_Termination_Form__c
            WHERE NSP_Project_Task__r.Name = 'Submit Termination Checklist'
            LIMIT 1
        ];
        
        SingleTermFormController controller = new SingleTermFormController();
        controller.passedRecordId = tf.Id;
        
        Test.startTest();
        List<WrapTermination> result = controller.getwrapTerminationList();
        Test.stopTest();
        
        System.assertEquals(1, result.size());
        System.assertEquals('acc1', result[0].clinetName);
    }
    
    @isTest
    private static void test_getwrapReinstatementList() {
        NSP_Termination_Form__c rf = [
            SELECT
            Id,
            NSP_Project_Task__r.Name,
            NSP_How_many_employees_were_moved__c,
            NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name
            FROM NSP_Termination_Form__c
            WHERE NSP_Status__c = 'Term Team Approved'
            AND NSP_Project_Task__r.Name = :NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK
            LIMIT 1
        ];
        
        SingleTermFormController controller = new SingleTermFormController();
        controller.passedRecordId = rf.Id;
        
        Test.startTest();
        List<WrapTermination> result = controller.getwrapReinstatementList();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Expected one reinstatement wrapper');
        System.assertEquals('acc1', result[0].clinetName);
    }
}