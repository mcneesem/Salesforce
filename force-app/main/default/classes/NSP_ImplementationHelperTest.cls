@isTest
private class NSP_ImplementationHelperTest {

    private static Id projectPEORecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();
    private static Id checklistBookingId = SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Booking_Checklist').getRecordTypeId();
    private static Id stpChecklistId = SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Sold_to_Paid_Checklist').getRecordTypeId();

    @testSetup
    private static void setupData() {
        //account creation
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        newAccount.Name = 'Test Account';
        insert newAccount;
        //Inserting Opportunity Object
        Opportunity opportuniytObject2 = new Opportunity();
        opportuniytObject2.Name = 'Test Oppty Email';
        opportuniytObject2.AccountId = newAccount.id;
        opportuniytObject2.StageName = 'Prospecting';
        opportuniytObject2.CloseDate = date.today();
        opportuniytObject2.NSP_PrimaryProduct__c = 'WO';
        opportuniytObject2.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject2.Type ='New Product';
        opportuniytObject2.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject2.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        //Inserting Opportunity Object
        insert opportuniytObject2;

        List<Task> taskList = new List<Task>();
        Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Task taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = opportuniytObject2.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Completed'
        );
        taskList.add(taskRec);
        insert taskList;




        //update opportunity
        opportuniytObject2.StageName = 'Closed Won';
        update opportuniytObject2;

        //Booklist checklist creation
        List<NSP_Checklist__c> cc = new List<NSP_Checklist__c>();
        NSP_Checklist__c checklist = new NSP_Checklist__c();
        checklist.NSP_Opportunity__c=opportuniytObject2.id;
        checklist.NSP_Does_company_have_more_than_one_FEIN__c=true;
        checklist.NSP_Commission_only_employees__c=true;
        checklist.recordTypeId=checklistBookingId;
        cc.add(checklist);
        //STP checklist creation
        NSP_Checklist__c stp = new NSP_Checklist__c();
        stp.NSP_Opportunity__c=opportuniytObject2.id;
        stp.NSP_Requested_Insperity_Effective_Date__c=system.today();
        stp.NSP_Requested_Medical_Effective_Date__c=system.today();
        stp.recordTypeId=stpChecklistId;
        stp.NSP_Client_FEIN__c='123456789';
        stp.NSP_SoftwareSysCurrentlyUseForPayroll__c='xyz';
        stp.NSP_Benefits_Waiting_Period__c='30 Days';
        stp.NSP_Requested_First_Pay_Date__c=system.today();
        stp.NSP_Client_CurrentMedicalPlan_Final_Date__c=system.today();
        stp.NSP_DBA_AKA_T_A_Name__c=UserInfo.getUserId();
        stp.NSP_ClientRelatedtootherInsperityClient__c='Yes';
        stp.NSP_Part_Time_Employees__c=100;
        stp.NSP_Version_Number__c=10;
        stp.NSP_Benefit_Classing__c='Yes';
        stp.NSP_Pay_Frequency__c='Weekly';
        stp.NSP_Has_company_ever_run_payroll_before__c='Yes';
        stp.NSP_Full_Time_Employees__c=50;
        cc.add(stp);

        if(!cc.isEmpty()){
            insert cc;
        }

        //project creation
       pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
       oProject.Name='test';
       oProject.pse__Project_Type__c =  NSP_ServiceConstants.ImplementationProjectType;
       oProject.pse__Start_Date__c = Date.Today();
       oProject.pse__End_Date__c = System.Today().addDays(100);
       oProject.RecordTypeId = projectPEORecordTypeId;
       oProject.TemplateName__c=label.Middle_Market_Implementation_Project;
       oProject.pse__Account__c=newAccount.id;
        insert oProject;
    }

    @isTest
    private static void checkPrepopulateIPDataMM() {
        test.startTest();


        List<Implementation_profile__c> ipList = [SELECT Id,Insperity_pay_frequency__c FROM Implementation_profile__c WHERE Id!=null LIMIT 1];

        System.assertEquals('Weekly',ipList[0].Insperity_pay_frequency__c);
        test.stopTest();
    }

    @isTest
    private static void checkPrepopulateIPDataFso() {
        test.startTest();
        Account acc=[SELECT Id, Name from Account WHERE Name = 'Test Account' LIMIT 1];

        Implementation_profile__c ip = new Implementation_profile__c();
        ip.account__c=acc.id;
        insert ip;

        System.assertEquals(acc.id,ip.account__c);
        test.stopTest();
    }

}
//