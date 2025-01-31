@isTest
private class NSP_TerminationFormTempController_Test {

    @testSetup private static void testData(){
        Account acc1 = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
        acc1.Name = 'acc1';
        acc1.NSP_AIMS_Client__c = 'client1';
        insert acc1;
        
        NSP_Account_Team__c AccTeam = (NSP_Account_Team__c)NSP_TestDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults');
        AccTeam.NSP_Account__c = acc1.Id;
        AccTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        insert AccTeam;
        
        pse__Proj__c Project = new pse__Proj__c();
        Project.Name = 'Project1';
        Project.pse__Is_Active__c = true;
        Project.pse__Account__c = acc1.Id;
        Project.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        insert Project;
        
        pse__Project_Task__c ProjectTask= (pse__Project_Task__c) NSP_TestDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults');
        ProjectTask.pse__Project__c = Project.Id;
        insert ProjectTask;
        
        NSP_Termination_Form__c TF1 = (NSP_Termination_Form__c)NSP_TestDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults');
        TF1.NSP_Status__c = NSP_ServiceConstants.TERM_SUPERVISOR_APPROVED;
        TF1.NSP_Last_Date_Wages_Paid_Through__c = System.today()-21;
        TF1.NSP_Term_Code__c = 'Client Requested Termination Codes';
        TF1.NSP_Term_Reason__c = ' 5200 Health Benefits';
        TF1.NSP_Number_of_Active_Employees__c = 40;
        TF1.NSP_Benefit_Termination_Date__c = System.today();
        TF1.NSP_Project_Task__c = ProjectTask.Id;
         TF1.Approval_Date__c = System.Today();
        insert TF1;
        
        
        Document doc1 = new Document();
        doc1.DeveloperName = 'Insperity_HR_Logo';
        doc1.ContentType = 'application/pdf';
        doc1.IsPublic = true;
        doc1.Name = 'doc1';
        doc1.FolderId = UserInfo.getUserId();
       
        Document doc2 = new Document();
        doc2.DeveloperName = 'Insperity_Copy_write_logo';
        doc2.ContentType = 'application/pdf';
        doc2.IsPublic = true;
        doc2.Name = 'doc2';
        doc2.FolderId = UserInfo.getUserId();
        
        Document doc3 = new Document();
        doc3.DeveloperName = 'Insperity_Service_Operations';
        doc3.ContentType = 'application/pdf';
        doc3.IsPublic = true;
        doc3.Name = 'doc3';
        doc3.FolderId = UserInfo.getUserId();
        
        List<Document> docList = new List<Document>();
        docList.add(doc1);
        docList.add(doc2);
        docList.add(doc3);
        insert docList;
    }

    @isTest private static void getURLsTest(){
        Test.startTest();
        NSP_TerminationFormTemplateController TFController = new NSP_TerminationFormTemplateController();
        String topUrl = TFController.getTopLogoUrl();
        TFController.getBottomLogoUrl();
        TFController.getAddressLogoUrl();
        //System.assertEquals(expected, actual)
        Test.stopTest();
        System.assert(topUrl != null);
    }
    
    @isTest private static void wrapTerminationTest(){
        NSP_Termination_Form__c TF1 = [SELECT Id, NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name, 
                                       NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c,
                                       NSP_Number_of_Active_Employees__c,
                                       NSP_Last_Date_Wages_Paid_Through__c,
                                       NSP_Benefit_Termination_Date__c,
                                       NSP_Term_Reason__c,
                                       NSP_Revision__c,NSP_New_Client_Name__c,NSP_New_Client_Number__c,Previous_term_date__c,NSP_SubTerm_reason__c
                                       FROM NSP_Termination_Form__c WHERE NSP_Last_Date_Wages_Paid_Through__c != NULL LIMIT 1];
        Test.startTest();
        NSP_TerminationFormTemplateController.wrapTermination wrapper = new NSP_TerminationFormTemplateController.wrapTermination(TF1, 'Test_PS','Test_CL');
        System.assertEquals('Test_PS', wrapper.psName);
        Test.stopTest();
    }

}
//