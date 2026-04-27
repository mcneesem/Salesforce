@isTest
private class NSP_Implprofile_ServiceHelperUpdate_Test {

    private static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    private static Id projectPEORecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();
    private final static String PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
    private final static String employeeName = 'Test';
    private final static String documents = 'Test~Requested - Not Collected';
    private final static String employeeNameParentTask = 'Parent';
    private final static String documentParentTask = 'Parent~Requested - Not Collected';

    @testSetup
    private static void setUpData() {

        User userRec = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        // Getting the Permission Sets
        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE (
                Name = 'Implementation_Profile_Read_Only'
                OR
                Name = 'NSP_Implementation_Profile_permission_set')
        ];

        Assert.areNotEqual(null, permissionSets, 'Permission sets are needed for this test class');
        Assert.areEqual(2, permissionSets?.size(), 'Query results should match the count');

        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
        for(PermissionSet ps : permissionSets) {
            permissionSetAssignments.add(new PermissionSetAssignment(
                AssigneeId = userRec.id,
                PermissionSetId = ps.Id
            ));
        }

        insert permissionSetAssignments;
        System.runAs(userRec) {
            Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);
            oContact.pse__Salesforce_User__c=userRec.Id;
            oContact.NSP_Work_email__c='test@insperity.com';
            update oContact;
            List<pse__Proj__c> projList = new List<pse__Proj__c>();
            pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject.Name='test';
            oProject.pse__Project_Type__c =  NSP_ServiceConstants.ImplementationProjectType;
            oProject.pse__Start_Date__c = Date.Today();
            oProject.pse__End_Date__c = System.Today().addDays(100);
            oProject.RecordTypeId = projectPEORecordTypeId;
            oProject.TemplateName__c=label.FSOImplementationProject;
            projList.add(oProject);

            pse__Proj__c oProject2 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject2.Name='test project';
            oProject2.pse__Start_Date__c = Date.Today();
            oProject2.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
            oProject2.pse__End_Date__c = System.Today().addDays(100);
            oProject2.RecordTypeId = projectPEORecordTypeId;
            oProject2.TemplateName__c=label.Middle_Market_Implementation_Project;
            projList.add(oProject2);

            insert projList;

            List<Implementation_Profile__c> impProfList = new List<Implementation_Profile__c>();

            Implementation_Profile__c impProfile = new Implementation_Profile__c();
            impProfile.NSP_Project__c = oProject.Id;
            impProfile.NSP_Form_Completed__c = true;
            impProfile.NSP_Project_Manager__c = oContact.Id ;
            impProfile.NSP_HR_Quality_Support_Team_Member__c = oContact.Id;
            impProfile.NSP_HR_Specialist__c = oContact.Id;
            impProfile.RecordTypeId = ipFSORecordTypeId;
            impProfList.add(impProfile);

            Implementation_Profile__c impProfile1 = new Implementation_Profile__c();
            impProfile1.NSP_Project__c = oProject2.Id;
            impProfile1.NSP_Form_Completed__c = true;
            impProfile.NSP_Project_Manager__c = oContact.Id ;
            impProfile1.RecordTypeId=ipMMRecordTypeId;
            impProfList.add(impProfile1);

            insert impProfList;
            NSP_Employee_Data__c empData = new NSP_Employee_Data__c();
            empData.NSP_Form_Collected__c='';
            empData.NSP_Visa_Type__c='';

            //Account creation
            Account accoutObject = new Account();
            accoutObject.Name = 'Test Account';
            insert accoutObject;

            Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
            woAsset.AccountId = accoutObject.Id;
            woAsset.Status='Active';
            insert woAsset;

            List<pse__Project_Task__c> projTaskList = new List<pse__Project_Task__c>();

            pse__Project_Task__c pt = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            pt.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
            pt.RecordTypeId = PEOProjectTaskRecordTypeId;
            pt.Name = NSP_ServiceConstants.INTERNALDISCOVERY;
            pt.pse__Project__c = oProject.Id;
            projTaskList.add(pt);

            pse__Project_Task__c pt1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            pt1.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
            pt1.RecordTypeId = PEOProjectTaskRecordTypeId;
            pt1.Name = NSP_ServiceConstants.FIRSTPAYROLL;
            pt1.pse__Project__c = oProject.Id;
            projTaskList.add(pt1);

            pse__Project_Task__c pt2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            pt2.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
            pt2.RecordTypeId = PEOProjectTaskRecordTypeId;
            pt2.Name = NSP_ServiceConstants.ONSITEDISCOVERY;
            pt2.pse__Project__c = oProject2.Id;
            projTaskList.add(pt2);

            pse__Work_Calendar__c workRec = new pse__Work_Calendar__c();
            workRec.name = 'US 40';
            insert workRec;
        }

    }

    @isTest
    private static void allFalseTest() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c project = [SELECT Id, Name FROM pse__Proj__c WHERE pse__Project_Type__c =:  NSP_ServiceConstants.ImplementationProjectType LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c, NSP_Project__r.Name FROM Implementation_Profile__c WHERE NSP_Project__c =:project.Id LIMIT 1];

            //Implementation_Profile__c ip = new Implementation_Profile__c();
            ip.NSP_Project__c = null;
            ip.NSP_Form_Completed__c = false;
            //ip.NSP_Project_Manager__c = cont.Id ;
            ip.Type_of_retirement_plan_client_has_today__c  = NSP_ServiceConstants.SIMPLEIRA;
            ip.Employees_work_in_the_following_states__c = NSP_ServiceConstants.NY;
            ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CLIENTB;
            ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c = null;
            ip.Client_have_EEO_filing_under__c='No';
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c=null;
            ip.Client_Implementing_Premier_Performance__c ='No';
            Test.startTest();
            update ip;
            System.assertEquals(ip.Client_have_EEO_filing_under__c, 'No');
            Test.stopTest();
        }
    }

    @isTest
    private static void checkForClientSposoredPlansTest() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Contact cc =[SELECT Id from Contact WHERE Name != null limit 1];
            pse__Proj__c project = [SELECT Id, Name FROM pse__Proj__c WHERE TemplateName__c=:label.FSOImplementationProject LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c, NSP_Project__r.Name FROM Implementation_Profile__c WHERE NSP_Project__c =:project.Id LIMIT 1];

            ip.Spnsrd_pln_when_Insperity_hndles_payroll__c='Yes';
            ip.Sponsored_plan_contribution_type__c='Pre-Tax';
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c = 'Health Care Flexible Spending Account (HCFSA);Health Savings Account;Dependent Care Flexible Spending Account (DCFSA);Medical (Pretax);Dental (Pretax);Vision (Pretax)';
            ip.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c = NSP_ServiceConstants.REQUESTED;
            ip.NSP_HSA_Ongoing_CSP_cafeteria_document__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
            ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c = NSP_ServiceConstants.REQUESTED;
            ip.Client_have_EEO_filing_under__c = NSP_ServiceConstants.YES ;
            ip.Gave_copy_of_PTO_sick_leave_other_policy__c = NSP_ServiceConstants.REQUESTED;
            ip.Gave_copy_of_PTO_sick_leave_other_policy__c = NSP_ServiceConstants.NO;
            ip.Time_Entry_Method__c = NSP_ServiceConstants.XML;
            ip.Employee_Data_Collection_EDC_collected__c = NSP_ServiceConstants.NO ;
            ip.Client_has_any_special_payroll_needs__c = NSP_ServiceConstants.YES ;
            ip.Select_all_payroll_needs_that_apply__c = NSP_ServiceConstants.LOCATIONS;
            ip.NSP_Select_all_that_apply__c = NSP_ServiceConstants.REPORT401 ;
            ip.Have_name_s_of_COBRA_takeovr_employees__c= NSP_ServiceConstants.NO;
            ip.NSP_Form_Completed__c = true;
            ip.Do_you_have_the_LOA_information__c= NSP_ServiceConstants.NO;
            ip.Are_there_any_EEs_on_Leave_of_Absence__c = 'Yes';
            ip.NSP_Project_Manager__c = cc.Id ;
            Test.startTest();
            update  ip;
            List<pse__Project_Task__c> projTaskList = [Select Id from pse__Project_Task__c WHERE pse__Project__c=: project.id];
            system.assertEquals(projTaskList.size()>0, true);
            Test.stopTest();
        }
    }

    @isTest
    private static void checkforPayrollDepartments() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Contact cc =[SELECT Id from Contact WHERE Name != null limit 1];
            pse__Proj__c project  = [SELECT Id, Name, pse__Project_Type__c FROM pse__Proj__c WHERE TemplateName__c=:label.FSOImplementationProject LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id,Name, NSP_Project__c, NSP_Project__r.Name,Client_has_any_special_payroll_needs__c, Select_all_payroll_needs_that_apply__c, NSP_HR_Quality_Support_Team_Member__c,NSP_HR_Specialist__c FROM Implementation_Profile__c WHERE NSP_Project__c =: project.Id LIMIT 1];

            ip.Client_has_any_special_payroll_needs__c = NSP_ServiceConstants.YES ;
            ip.Select_all_payroll_needs_that_apply__c = NSP_ServiceConstants.DEPARTMENTS ;
            ip.NSP_Select_all_that_apply__c = NSP_ServiceConstants.INTEGRA_ASSET ;
            ip.Have_name_s_of_COBRA_takeovr_employees__c= NSP_ServiceConstants.YES;
            ip.NSP_COBRA_Takeover_Emp_Details__c='test1~No,test2~No';
            ip.Client_interested_in_NSP_tracking_PTO__c =NSP_ServiceConstants.YES;
            ip.NSP_Where_will_PTO_be_tracked__c=NSP_ServiceConstants.AIMS;
            ip.Do_you_have_the_LOA_information__c=NSP_ServiceConstants.YES;
            ip.NSP_Employee_Details_On_LOA__c='test1~date~No,test2~date~No';
            ip.NSP_Form_Completed__c=true;
            ip.Client_Implementing_Premier_Performance__c ='Yes';
            ip.Is_there_a_need_for_Integra__c = NSP_ServiceConstants.YES;
            ip.Does_this_client_have_an_AWW__c = NSP_ServiceConstants.YES;
            ip.First_Pay_Date__c = system.today();
            ip.Would_the_client_like_a_FLSA_Exemption__c= NSP_ServiceConstants.YES;
            ip.Is_the_client_Emerging_Growth__c= NSP_ServiceConstants.NO;
            ip.NSP_HR_Quality_Support_Team_Member__c = cc.Id ;
            ip.NSP_HR_Specialist__c = cc.Id ;
            Test.startTest();
            update ip;
            List<pse__Project_Task__c> projTaskList = [Select Id from pse__Project_Task__c WHERE pse__Project__c=: project.id];
            system.assertEquals(projTaskList.size()>0, true);
            Test.stopTest();
        }
    }

    @isTest
    private static void checkforPayrollJobCostingTest() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            pse__Proj__c project  = [SELECT Id, Name, pse__Project_Type__c FROM pse__Proj__c WHERE TemplateName__c=:label.FSOImplementationProject LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c=: project.Id LIMIT 1];

            ip.Client_has_any_special_payroll_needs__c = NSP_ServiceConstants.YES ;
            ip.Select_all_payroll_needs_that_apply__c = NSP_ServiceConstants.JOBCOSTING;
            ip.NSP_Is_there_an_Enrollment_fee__c = NSP_ServiceConstants.YES;
            ip.Recent_Payroll_Register_Collected__c = NSP_ServiceConstants.NOTCOLLECTED ;
            ip.Do_any_EEs_have_garnishments__c = NSP_ServiceConstants.YES ;
            ip.NSP_Employee_Names_List_garnishments__c = employeeName;
            ip.NSP_Documents_garnishments__c = documents;
            ip.Do_any_EEs_have_tax_levies__c = NSP_ServiceConstants.YES;
            ip.NSP_List_Employee_Names_Levies__c = employeeName;
            ip.Document_Levies__c = documents;
            ip.Spnsrd_pln_when_Insperity_hndles_payroll__c = NSP_ServiceConstants.YES;
            ip.Client_has_any_post_tax_deductions__c = NSP_ServiceConstants.YES;
            ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CLIENTB ;
            ip.Employees_work_in_the_following_states__c = NSP_ServiceConstants.NY;
            ip.NSP_Any_special_pay_codes_Needed__c = NSP_ServiceConstants.YES ;
            ip.NSP_Select_all_that_apply__c = NSP_ServiceConstants.COSTING ;
            ip.NSP_Form_Completed__c=true;

            update ip;
            List<pse__Project_Task__c> projTaskList = [Select Id from pse__Project_Task__c WHERE pse__Project__c=: project.id];
            system.assertEquals(true,projTaskList.size()>0);
            Test.stopTest();
        }
    }

    @isTest
    private static void createSubtaskIp() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            pse__Proj__c project  = [SELECT Id, Name, pse__Project_Type__c FROM pse__Proj__c WHERE TemplateName__c=:label.FSOImplementationProject LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c=: project.Id LIMIT 1];

            ip.Do_any_EEs_have_garnishments__c = NSP_ServiceConstants.YES ;
            ip.Do_any_EEs_have_tax_levies__c = NSP_ServiceConstants.YES;
            ip.NSP_Employee_Names_List_garnishments__c = employeeNameParentTask;
            ip.NSP_Documents_garnishments__c = documentParentTask;
            ip.NSP_List_Employee_Names_Levies__c = employeeNameParentTask;
            ip.Document_Levies__c = documentParentTask;
            ip.NSP_Form_Completed__c=true;
            update ip;
            ip.NSP_Employee_Names_List_garnishments__c = employeeName;
            ip.NSP_Documents_garnishments__c = documents;
            ip.NSP_List_Employee_Names_Levies__c = employeeName;
            ip.Document_Levies__c = documents;
            ip.NSP_Form_Completed__c=true;
            update ip;
            List<pse__Project_Task__c> projTaskList = [Select Id,name,Implementation_Profile__c from pse__Project_Task__c WHERE pse__Project__c=: project.id];
            system.assertEquals(true,projTaskList.size()>0);
            Test.stopTest();
        }
    }

    @isTest
    private static void checkforReportingOthertest() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c proj =[SELECT Id

                                FROM pse__Proj__c
                                WHERE TemplateName__c=:label.FSOImplementationProject];
            List<pse__Project_Task__c> projTaskList=[SELECT Id,Name,pse__Status__c
                                                     FROM pse__Project_Task__c
                                                     WHERE name=:NSP_ServiceConstants.INTERNALDISCOVERY limit 1];
            Implementation_Profile__c ip = [SELECT Id,NSP_Project__c,NSP_Project__r.pse__Project_Type__c
                                            FROM Implementation_Profile__c
                                            WHERE NSP_Project__r.TemplateName__c=:label.FSOImplementationProject
                                            LIMIT 1];

            ip.NSP_Select_all_that_apply__c = NSP_ServiceConstants.OTHREPORTS;
            ip.Effective_Date_Payroll_Worker_comp_EPLI__c=system.today()+1;
            ip.Insperity_benefits_effective_date__c=system.today()+1;
            ip.Benefits_Package__c='Independence';
            ip.Is_there_a_need_for_Integra__c = NSP_ServiceConstants.YES;
            ip.NSP_Form_Completed__c=true;
            pse__Project_Task__c pt3 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(),
                                                                                                       'NSP_TestDataFactory.ProjectTaskDefaults',
                                                                                                       false);
            pt3.pse__Status__c = NSP_ServiceConstants.COMPLETE_STATUS;
            pt3.RecordTypeId = PEOProjectTaskRecordTypeId;
            pt3.Name = NSP_ServiceConstants.CLIENTTRANSITION;
            pt3.pse__Project__c = proj.Id;
            pt3.Implementation_Profile__c = ip.Id;
            insert pt3;

            Test.startTest();
            if(projTaskList.size()>0){
                projTaskList[0].pse__Status__c=NSP_ServiceConstants.TASKCOMPLETE;
                update projTaskList[0];
            }
            else{
                pse__Project_Task__c pt2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(),
                                                                                                           'NSP_TestDataFactory.ProjectTaskDefaults',
                                                                                                           false);
                pt2.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                pt2.RecordTypeId = PEOProjectTaskRecordTypeId;
                pt2.Name = NSP_ServiceConstants.INTERNALDISCOVERY;
                pt2.pse__Project__c = proj.Id;
                insert pt2;

            }
            update ip;
            ip.Is_there_a_need_for_Integra__c = NSP_ServiceConstants.NO;
            update ip;
            pt3.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_CANCELLED;
            update pt3;
            System.assert(pt3.pse__Status__c == NSP_ServiceConstants.PROJECT_TASK_CANCELLED);
            System.assert(ip.Benefits_Package__c == 'Independence');
            Test.stopTest();
        }
    }

    @isTest
    private static void checkforOnsiteDiscovery() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Contact con=[SELECT Id ,NSP_Work_email__c FROM Contact WHERE Name != null LIMIT 1];
            pse__Proj__c proj =[SELECT Id,
                                (SELECT NSP_Assignee__c
                                 FROM Project_Teams__r
                                )
                                FROM pse__Proj__c
                                WHERE TemplateName__c=:label.Middle_Market_Implementation_Project];
            Test.startTest();
            List<pse__Project_Task__c> projTaskList=[SELECT Id,Name,pse__Status__c
                                                     FROM pse__Project_Task__c
                                                     WHERE name=:NSP_ServiceConstants.ONSITEDISCOVERY limit 1];
            List<NSP_Project_Team__c> projTeamList = new List<NSP_Project_Team__c>();
            if(proj.Project_Teams__r.size()>0){
                for(NSP_Project_Team__c projTeam : proj.Project_Teams__r){
                    projTeam.NSP_Assignee__c=con.Id;
                    projTeamList.add(projTeam);

                }
            }
            if(!projTeamList.isEmpty()){
                update projTeamList;
            }
            if(projTaskList.size()>0){
                projTaskList[0].pse__Status__c=NSP_ServiceConstants.TASKCOMPLETE;
                update projTaskList;
            }
            else{
                pse__Project_Task__c pt2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
                pt2.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
                pt2.RecordTypeId = PEOProjectTaskRecordTypeId;
                pt2.Name = NSP_ServiceConstants.ONSITEDISCOVERY;
                pt2.pse__Project__c = proj.Id;
                insert pt2;

            }


            Implementation_Profile__c ip = [SELECT Id,NSP_Project__c,NSP_Project__r.pse__Project_Type__c FROM Implementation_Profile__c WHERE NSP_Project__r.TemplateName__c=:label.Middle_Market_Implementation_Project  LIMIT 1];
            ip.Effective_Date_Payroll_Worker_comp_EPLI__c=system.today();
            ip.Insperity_benefits_effective_date__c=system.today();
            ip.Benefits_Package__c='Freedom';
            update ip;
            System.assert(ip.Benefits_Package__c == 'Freedom');
            Test.stopTest();
        }
    }

}
//