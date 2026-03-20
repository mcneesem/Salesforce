@isTest
private class NSP_MMImplProfile_UpdateTest {

    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    private static Id projectPEORecordTypeId = SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();
    private static final Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();

    @testSetup
    private static void setUpData() {

        //creating user
        User createUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);

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
        for(PermissionSet ps : permissionSets){
            permissionSetAssignments.add(new PermissionSetAssignment(
                AssigneeId = createUser.id,
                PermissionSetId = ps.Id
            ));
        }

        insert permissionSetAssignments;

        System.runAs(createUser) {
            //creating contact and assign user to contact
            Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
            //Assigning  Salesforce user to user id
            oContact.pse__Salesforce_User__c=createUser.Id;
            //inserting contact
            insert oContact;
            //Inserting Account
            Account accoutObject = new Account();
            accoutObject.Name = 'Test Account';
            insert accoutObject;
            //Inserting Asset
            Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
            woAsset.AccountId = accoutObject.Id;
            woAsset.recordTypeId = woRecordTypeId;
            insert woAsset;
            //Project creation
            List<pse__Proj__c> projList = new List<pse__Proj__c>();

            //creating another project record
            pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject1.Name='test record';
            oProject1.pse__Start_Date__c = Date.Today();
            oProject1.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
            oProject1.TemplateName__c=label.Middle_Market_Implementation_Project;
            oProject1.pse__End_Date__c = System.Today().addDays(100);
            oProject1.RecordTypeId = projectPEORecordTypeId;
            projList.add(oProject1);
            database.insert(projList);

            pse__Work_Calendar__c workRec = new pse__Work_Calendar__c();
            workRec.name = 'US 40';
            insert workRec;
        }
    }

    @isTest
    private static void handleIPForProjectTask() {
        pse__Proj__c project = [SELECT Id FROM pse__Proj__c WHERE  TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
        Contact cont = [select Id,pse__Salesforce_User__c from Contact WHERE LastName='ResourceLN' ];
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c=:project.Id LIMIT 1 ];
            ip.Recent_Payroll_Register_Collected__c=NSP_ServiceConstants.NO;
            ip.Received_Section_125_Questionnaire__c=NSP_ServiceConstants.NO;
            ip.Has_FEIN_documentation_been_collected__c=NSP_ServiceConstants.NO;
            ip.Gotten_Cvrg_Cert_Gen_Liability_Auto__c=NSP_ServiceConstants.REQUESTED;
            ip.Client_interested_in_NSP_tracking_PTO__c= NSP_ServiceConstants.YES;
            ip.PTO_Types__c=NSP_ServiceConstants.AIMS;
            ip.NSP_Where_will_PTO_be_tracked__c=NSP_ServiceConstants.AIMS;
            ip.Client_have_will_have_any_Seasonal_EEs__c=NSP_ServiceConstants.YES;
            ip.Does_the_client_have_any_union_EEs__c=NSP_ServiceConstants.YES;
            ip.Are_there_any_EEs_on_Leave_of_Absence__c=NSP_ServiceConstants.YES;
            ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.MILITARY_LEAVE;
            ip.Select_BPSes__c = 'Employment Screening;Recruiting Services';
            ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
            ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.JOBDESCRIPTION;
            ip.Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.Yes;
            ip.NSP_Payroll_Project_Manager__c=cont.id;
            ip.NSP_Project_Manager__c  = cont.id;
            ip.HR_Specialist__c=user.id;
            ip.NSP_Payroll_Specialist__c=cont.id;
            ip.NSP_Client_Sponsored_Plan__c = NSP_ServiceConstants.YES;
            ip.Sponsored_plan_contribution_type__c=NSP_ServiceConstants.PRETAX;
            ip.Allowances__c='Per Diem';
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c ='Health Care Flexible Spending Account (HCFSA);Health Savings Account;Dependent Care Flexible Spending Account (DCFSA);Medical (Pretax);Dental (Pretax);Vision (Pretax)';
            ip.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c=NSP_ServiceConstants.REQUESTED;
            ip.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c=NSP_ServiceConstants.REQUESTED;
            ip.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c= NSP_ServiceConstants.REQUESTED;
            ip.NSP_Form_Completed__c=true;
            ip.NSP_HSA_Ongoing_CSP_cafeteria_document__c = NSP_ServiceConstants.REQUESTED;
            ip.NSP_Sr_Onboarding_Benefit_Rep__c = cont.id;
            Test.startTest();
            //update ip record for the above fields
            update  ip;
            System.assertEquals(NSP_ServiceConstants.MILITARY_LEAVE,ip.Select_the_applicable_LOA_types__c);
            Test.stopTest();
        }
    }

    //test method handleProjectTask
    @isTest
    private static void handleProjectTask() {
        pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE  TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
        Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c= :project.Id LIMIT 1];
        Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.GREATER_THAN;
            ip.Client_has_any_post_tax_deductions__c = NSP_ServiceConstants.Yes;
            ip.Client_utilizing_Insperity_s_TimeStar__c = NSP_ServiceConstants.Yes;
            ip.Do_any_EEs_have_garnishments__c=NSP_ServiceConstants.YES;
            ip.Do_any_EEs_have_tax_levies__c=NSP_ServiceConstants.YES;
            ip.Type_of_retirement_plan_client_has_today__c=NSP_ServiceConstants.CSP401K;
            ip.Does_the_client_offer_a_HSA__c =NSP_ServiceConstants.Yes;
            ip.Is_client_s_current_HSA_with_Optum_Bank__c =NSP_ServiceConstants.No;
            ip.Select_BPSes__c = NSP_ServiceConstants.INSURANCE;
            ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
            ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.SEVERANCEAGREEMENT;
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c=NSP_ServiceConstants.HCFSA;
            ip.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c = NSP_ServiceConstants.REQUESTED;
            ip.NSP_Project_Manager__c  = cont.id;
            ip.NSP_Payroll_Project_Manager__c=cont.id;
            ip.NSP_Payroll_Specialist__c=cont.id;
            ip.NSP_Form_Completed__c=true;
            ip.NSP_Sr_Onboarding_Benefit_Rep__c = cont.id;
            //Insert Implementation Profile Settings (custom setting)
            Implementation_Profile_Settings__c ipSettings = Implementation_Profile_Settings__c.getInstance( UserInfo.getUserId() );
            upsert ipSettings;
            Test.startTest();
            //update ip record for the above fields
            update  ip;
            System.assertEquals(NSP_ServiceConstants.CSP401K,ip.Type_of_retirement_plan_client_has_today__c);
            Test.stopTest();
        }
    }

    //test method handleOptumProjectTask
    @isTest
    private static void handleOptumTask() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            Test.startTest();
            Asset asset =[SELECT Id FROM Asset WHERE recordTypeId=:woRecordTypeId LIMIT 1];
            pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE  TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c= :project.Id LIMIT 1];
            Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];
            ip.Does_the_client_offer_a_HSA__c =NSP_ServiceConstants.Yes;
            ip.Is_client_s_current_HSA_with_Optum_Bank__c =NSP_ServiceConstants.Yes;
            ip.Select_BPSes__c = NSP_ServiceConstants.INSURANCE;
            ip.NSP_Project_Manager__c  = cont.id;
            ip.NSP_Sr_Onboarding_Benefit_Rep__c=cont.id;
            ip.NSP_Form_Completed__c=true;
            ip.NSP_Asset__c = asset.id;
            //update ip record for the above fields
            update  ip;
            System.assertEquals(NSP_ServiceConstants.YES,ip.Is_client_s_current_HSA_with_Optum_Bank__c);
            Test.stopTest();
        }
    }

    //test method handleTaskCreation
    @isTest
    private static void handleTaskCreation() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c= :project.Id LIMIT 1];
            Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];

            ip.Participants_on_COBRA_eligibility_period__c = NSP_ServiceConstants.YES;
            ip.Reviewed_deductible_carryover_w_client__c=true;
            ip.Any_EEs_with_urgent_medical_needs__c = NSP_ServiceConstants.YES;
            ip.Any_EEs_in_clients_waiting_period__c = NSP_ServiceConstants.YES;
            ip.Insperity_benefits_waiting_period__c='90 days';
            ip.Client_s_previous_waiting_period__c='30 days';
            ip.Client_want_to_begin_401k_w_NSP_setup__c = NSP_ServiceConstants.Yes;
            IP.Client_has_existing_retirement_plan__c=NSP_ServiceConstants.Yes;
            ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.PEOMULTIPLIER;
            ip.Client_has_any_of_the_following__c = NSP_ServiceConstants.STANDARD_LETTER;
            ip.Does_client_perform_background_checks__c = NSP_ServiceConstants.Yes;
            ip.Client_does_pre_employment_drug_screen__c = NSP_ServiceConstants.Yes;
            ip.Select_BPSes__c = NSP_ServiceConstants.ORGANIZATIONAL;
            ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.SALARY;
            ip.Spnsrd_pln_when_Insperity_hndles_payroll__c=NSP_ServiceConstants.Yes;
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c=NSP_ServiceConstants.MEDICAL;
            ip.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c=NSP_ServiceConstants.REQUESTED;
            ip.NSP_Project_Manager__c  = cont.id;
            ip.NSP_Payroll_Project_Manager__c=cont.id;
            ip.NSP_Payroll_Specialist__c=cont.id;
            ip.NSP_Form_Completed__c = true;
            ip.Does_this_client_have_an_AWW__c = NSP_ServiceConstants.Yes;
            ip.NSP_Insperity_1st_pay_date__c = system.today();
            ip.NSP_Sr_Onboarding_Benefit_Rep__c = cont.id;
            Test.startTest();
            //update ip record for the above fields
            update  ip;
            System.assertEquals(NSP_ServiceConstants.PEOMULTIPLIER,ip.Type_of_retirement_plan_client_has_today__c);
            Test.stopTest();
        }
    }

    //test method handleBPSTaskCreation
    @isTest
    private static void handleBPSTaskCreation() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c project = [SELECT Id,Name FROM pse__Proj__c WHERE TemplateName__c=:label.Middle_Market_Implementation_Project LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c,Select_BPSes__c FROM Implementation_Profile__c WHERE NSP_Project__c =:project.Id LIMIT 1];
            Contact cont = [SELECT Id,pse__Salesforce_User__c FROM Contact WHERE LastName='ResourceLN' ];

            ip.Select_the_applicable_LOA_types__c = NSP_ServiceConstants.MILITARY_LEAVE;
            ip.Employees_work_in_the_following_states__c = 'CA';
            ip.Spnsrd_pln_when_Insperity_hndles_payroll__c = NSP_ServiceConstants.YES;
            ip.Sponsored_plan_contribution_type__c=NSP_ServiceConstants.PRETAX;
            ip.Client_has_any_post_tax_deductions__c=NSP_ServiceConstants.YES;
            ip.NSP_Employees_with_multiple_types_of_pay__c =NSP_ServiceConstants.HOUSINGALLOWANCE;
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c =NSP_ServiceConstants.DCFSA;
            ip.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c = NSP_ServiceConstants.REQUESTED;
            ip.Client_have_any_urgent_HR_needs__c = NSP_ServiceConstants.YES;
            ip.Select_client_urgent_HR_needs__c=NSP_ServiceConstants.HANDBOOK;
            ip.Client_has_any_of_the_following__c =NSP_ServiceConstants.SUBSTANCE;
            ip.Select_BPSes__c=NSP_ServiceConstants.CERTIFY;
            ip.NSP_Project_Manager__c  = cont.id;
            ip.NSP_Payroll_Project_Manager__c=cont.id;
            ip.NSP_Payroll_Specialist__c=cont.id;
            ip.NSP_Form_Completed__c = true;
            Test.startTest();
            //update ip record for the above fields
            update  ip;
            System.assertEquals(NSP_ServiceConstants.YES,ip.Client_have_any_urgent_HR_needs__c);
            Test.stopTest();
        }
    }

    @isTest
    private static void handleCSPMedicalMMTaskCreation() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c project = [SELECT Id, Name FROM pse__Proj__c WHERE TemplateName__c = :label.Middle_Market_Implementation_Project LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c = :project.Id LIMIT 1];
            Contact cont = [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE LastName = 'ResourceLN'];

            ip.NSP_Client_Sponsored_Plan__c = NSP_ServiceConstants.YES;
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c = NSP_ServiceConstants.MEDICAL;
            ip.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c = NSP_ServiceConstants.REQUESTED;
            ip.NSP_Project_Manager__c = cont.id;
            ip.NSP_Payroll_Project_Manager__c = cont.id;
            ip.NSP_Payroll_Specialist__c = cont.id;
            ip.NSP_Form_Completed__c = true;


            Test.startTest();
            update ip;

            System.assertEquals(NSP_ServiceConstants.MEDICAL, ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c);
            Test.stopTest();
        }

    }

    @isTest
    private static void handleCSDentalMMTaskCreation() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c project = [SELECT Id, Name FROM pse__Proj__c WHERE TemplateName__c = :label.Middle_Market_Implementation_Project LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c = :project.Id LIMIT 1];
            Contact cont = [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE LastName = 'ResourceLN'];

            ip.NSP_Client_Sponsored_Plan__c = NSP_ServiceConstants.YES;
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c = NSP_ServiceConstants.DENTAL;
            ip.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c = NSP_ServiceConstants.REQUESTED;
            ip.NSP_Project_Manager__c = cont.id;
            ip.NSP_Payroll_Project_Manager__c = cont.id;
            ip.NSP_Payroll_Specialist__c = cont.id;
            ip.NSP_Form_Completed__c = true;

            Test.startTest();
            update ip;

            System.assertEquals(NSP_ServiceConstants.DENTAL, ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c);
            Test.stopTest();
        }
    }

    @isTest
    private static void handleCSVisionMMTaskCreation() {
        User user=[SELECT  Id, Username FROM User WHERE Id != null AND Alias = 'sas' LIMIT 1];
        System.runAs(user) {
            pse__Proj__c project = [SELECT Id, Name FROM pse__Proj__c WHERE TemplateName__c = :label.Middle_Market_Implementation_Project LIMIT 1];
            Implementation_Profile__c ip = [SELECT Id, NSP_Project__c FROM Implementation_Profile__c WHERE NSP_Project__c = :project.Id LIMIT 1];
            Contact cont = [SELECT Id, pse__Salesforce_User__c FROM Contact WHERE LastName = 'ResourceLN'];
            ip.NSP_Client_Sponsored_Plan__c = NSP_ServiceConstants.YES;
            ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c = NSP_ServiceConstants.VISION;
            ip.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c = NSP_ServiceConstants.REQUESTED;
            ip.NSP_Project_Manager__c = cont.id;
            ip.NSP_Payroll_Project_Manager__c = cont.id;
            ip.NSP_Payroll_Specialist__c = cont.id;
            ip.NSP_Form_Completed__c = true;

            Test.startTest();
            update ip;

            System.assertEquals(NSP_ServiceConstants.VISION, ip.Pre_tax_Client_Sponsored_Plan_CSP_Type__c);
            Test.stopTest();
        }
    }

}
//