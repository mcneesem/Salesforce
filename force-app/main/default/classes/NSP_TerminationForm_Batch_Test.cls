@isTest
private class NSP_TerminationForm_Batch_Test {
    @testSetup
    private static void testData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
    
        TerminationFormBatchSettings__c cs = new TerminationFormBatchSettings__c(
            SetupOwnerId = UserInfo.getUserId(),
            SoqlDaysBeforeLimit__c = 10,
            SoqlDaysAfterLimit__c  = 10,
            Account_Team_Roles__c  = NSP_ServiceConstants.CLIENT_LIAISION,
            CcAddresses__c         = 'cc1@example.com' + '\r\n' + 'cc2@example.com',
            OrgWideEmailAddressId__c = null
        );
        upsert cs;
        //inserting account
        Account acc1 = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
        acc1.Name = 'acc1';
        acc1.NSP_AIMS_Client__c = 'client1';
        insert acc1;
        //inserting account team
        NSP_Account_Team__c AccTeam = (NSP_Account_Team__c)NSP_TestDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.AccountTeamMemberDefaults');
        AccTeam.NSP_Account__c = acc1.Id;
        AccTeam.NSP_Role__c = NSP_ServiceConstants.CLIENT_LIAISION;
        insert AccTeam;
        //inserting project
        pse__Proj__c Project = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        Project.Name = 'Project1';
        Project.pse__Is_Active__c = true;
        Project.pse__Account__c = acc1.Id;
        Project.pse__Project_Status__c = NSP_ServiceConstants.PROJECTSTATUSNOTSTARTED;
        insert Project;
        //inserting project task
        pse__Project_Task__c ProjectTask= (pse__Project_Task__c) NSP_TestDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults');
        ProjectTask.pse__Project__c = Project.Id;
        insert ProjectTask;

        NSP_Termination_Form__c TF1 = (NSP_Termination_Form__c)NSP_TestDataFactory.createSObject(new NSP_Termination_Form__c(), 'NSP_TestDataFactory.TerminationFormDefaults');
        TF1.NSP_Status__c = 'Term Team Approved';
        TF1.NSP_Client_Term_Date__c = System.today()-21;
        TF1.NSP_Term_Code__c = 'Insperity Requested Termination Codes';
        TF1.NSP_Number_of_Active_Employees__c = 40;
        TF1.NSP_Benefit_Termination_Date__c = System.today() +21;
        TF1.NSP_Project_Task__c = ProjectTask.Id;
        TF1.Approval_Date__c = System.Today();
        insert TF1;
    }

    //Executes batch job for NSP_TerminationForm_Batch
    @isTest
    private static void termination() {
        try{
            Test.startTest();
            NSP_TerminationForm_Batch TFBatch = new NSP_TerminationForm_Batch();
            Database.executeBatch(TFBatch,1);
            system.assertEquals(0, Limits.getEmailInvocations());
            Test.stopTest();
        }catch(Exception ex){
            System.debug( ' ~ ex=' + ex );
        }
    }

    @isTest
    private static void terminate() {
        try{
            test.startTest();
            NSP_TerminationForm_Batch.schedule();
            test.stopTest();
        } catch(Exception ex){
            System.debug( ' ~ ex=' + ex );
        }
    }

    @isTest 
    private static void testCallMethodRoutingOnly() {
        NSP_TerminationForm_Batch batch = new NSP_TerminationForm_Batch();
        Object result = batch.call('invalidAction', null);
        System.assertEquals(null, result);
    }
    
}