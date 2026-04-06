@isTest
private class NSP_SObjectHistoryTrackingHelperTest {

    @testSetup
    private static void testData() {
        HistoryTrackingSettings__c settings = HistoryTrackingSettings__c.getOrgDefaults();
        settings.IsEnabled__c = true;
        settings.AllowedSObjectNames__c = 'Account,Asset,Contact,Implementation_Profile__c,Lead,NSP_Account_Group__c,Opportunity';
        upsert settings;

        Id peoProjectRecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();

        //insert Account
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert acc;
        //insert Project
        List<pse__Proj__c> lstProject = new List<pse__Proj__c>();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Account__c = acc.Id;
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

    }

    @isTest
    private static void testContactHistoryTracking() {
        Contact sharedContact = new Contact(
            LastName='sharedContact'
        );
        insert sharedContact;
        Test.startTest();
        sharedContact.LastName = sharedContact.LastName + '.';
        update sharedContact;
        Test.stopTest();
    }

    @isTest
    private static void testSObjectHistoryTracking() {
        Test.startTest();
        //GIVEN
        List<Implementation_Profile__c> lstIPToUpdate = new List<Implementation_Profile__c>();
        for(Implementation_Profile__c ip: [SELECT Id,PEO_Name__c FROM Implementation_Profile__c LIMIT 2]){
            //WHEN
            ip.Recent_Payroll_Register_Collected__c=NSP_ServiceConstants.NO;
            ip.Received_Section_125_Questionnaire__c=NSP_ServiceConstants.NO;
            ip.Has_FEIN_documentation_been_collected__c=NSP_ServiceConstants.NO;
            ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c=NSP_ServiceConstants.REQUESTED;
            ip.Client_interested_in_NSP_tracking_PTO__c= NSP_ServiceConstants.YES;
            ip.NSP_Where_will_PTO_be_tracked__c=NSP_ServiceConstants.AIMS;
            ip.Client_have_will_have_any_Seasonal_EEs__c=NSP_ServiceConstants.YES;
            ip.Does_the_client_have_any_union_EEs__c=NSP_ServiceConstants.YES;
            ip.Are_there_any_EEs_on_Leave_of_Absence__c=NSP_ServiceConstants.YES;
            ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.MILITARY_LEAVE;
            ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
            ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.JOBDESCRIPTION;
            ip.Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.Yes;
            lstIPToUpdate.add(ip);
        }
        update lstIPToUpdate;
        //THEN
        System.assertEquals(lstIPToUpdate.size(), 2);
        Test.stopTest();
    }

}
//