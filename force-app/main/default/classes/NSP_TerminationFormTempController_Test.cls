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
        ProjectTask.Name = 'Submit Termination Checklist';
        insert ProjectTask;
        
        NSP_Termination_Form__c TF1 = (NSP_Termination_Form__c)NSP_TestDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults');
        TF1.NSP_Status__c = 'Term Team Approved';
        TF1.NSP_Term_Code__c = 'Client Requested Termination Codes';
        TF1.NSP_Term_Reason__c = ' 5200 Health Benefits';
        TF1.NSP_Number_of_Active_Employees__c = 40;
        TF1.NSP_Benefit_Termination_Date__c = System.today();
        TF1.NSP_Project_Task__c = ProjectTask.Id;
        TF1.Approval_Date__c = System.Today();
        insert TF1;
        
        TerminationFormBatchSettings__c setting = new TerminationFormBatchSettings__c();
        setting.SoqlDaysBeforeLimit__c = 6;
        setting.SoqlDaysAfterLimit__c = 7;
        insert setting;
        
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
        NSP_Termination_Form__c TF1 = [
            SELECT
                Id ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                NSP_Number_of_Active_Employees__c ,
                NSP_Last_Date_Wages_Paid_Through__c ,
                NSP_Benefit_Termination_Date__c ,
                NSP_Term_Reason__c ,
                NSP_Revision__c ,
                NSP_New_Client_Name__c ,
                NSP_New_Client_Number__c ,
                Previous_term_date__c ,
                NSP_SubTerm_reason__c ,
                Previous_Bene_Date__c ,
                NSP_Client_Term_Date__c ,
                Previous_Term_Reason__c ,
                Previous_Sub_Term_Reason__c ,
                Previous_Client_Term_Date__c ,
                NSP_Client_Sub_Account_Numbers__c,
            	NSP_How_many_employees_were_moved__c
            FROM NSP_Termination_Form__c
            WHERE Approval_Date__c = Today
            LIMIT 1
        ];
        Map<String, String> roleMapDetails = new Map<String, String>{
            NSP_ServiceConstants.PAYROLL_SPECIALIST => 'Payroll Specialist',
                NSP_ServiceConstants.CLIENT_LIAISION => 'Client Liaison',
                NSP_ServiceConstants.BUS_TEAM_HRSP_CL => 'Bus Team HRSp CL',
                NSP_ServiceConstants.MID_MARKET_ACC_EX => 'MidMarket Account Exec',
                NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR => 'Business Performance Advisor',
                NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT => 'Business Performance Consultant'
                };
                    Test.startTest();
        WrapTermination wrapper = new WrapTermination(TF1,roleMapDetails);
        System.assertEquals('acc1', wrapper.clinetName);
        System.assertEquals(40, wrapper.eeNumber);
        System.assertEquals('Payroll Specialist', wrapper.psName);
        System.assertEquals('5200 Health Benefits', wrapper.reason);
        Test.stopTest();
    }

}
//