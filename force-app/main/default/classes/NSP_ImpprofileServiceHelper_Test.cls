@isTest
private class NSP_ImpprofileServiceHelper_Test {
    private static final String TEST_NAME = 'test';
    private static final String ASSET_DEFAULT = 'NSP_TestDataFactory.AssetDefaults';
    private static final Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    private static final Id fsoRecordTypeId =  Schema.SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get('FSO').getRecordTypeId();
    private static final Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();

    @testSetup
    private static void setUpData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        User userRec = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        Account acc = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert acc;

        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.lastName= TEST_NAME;
        con.pse__Salesforce_User__c=userRec.Id;
        con.NSP_Work_email__c='test@pwc.com';
        insert con;

        Asset woAsset = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAsset.Name = 'Test Asset';
        woAsset.AccountId = acc.Id;
        woAsset.NSP_Legal_Name__c = 'Test Legal Name';
        woAsset.Status= NSP_ServiceConstants.AIMS_STATUS;
        insert woAsset;

        list<Implementation_Profile__c> ipListFSA = new list<Implementation_Profile__c>();

        Implementation_Profile__c impl = (Implementation_Profile__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c());
        impl.RecordTypeId = fsoRecordTypeId;
        impl.NSP_Form_Completed__c = True;
        impl.Client_Profile_Information__c = 'Related Clients';
        impl.Select_BPSes__c = 'Employment Screening';
        impl.NSP_CheckToSendTheClient_Summary_email__c = true;
        impl.NSP_Orientation_Coordinator__c=con.id;
        ipListFSA.add(impl);

        Implementation_Profile__c impl4 = (Implementation_Profile__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c());
        impl4.Client_have_will_have_any_Seasonal_EEs__c = 'No';
        impl4.RecordTypeId = ipMMRecordTypeId;
        impl4.NSP_Asset__c = woAsset.Id;
        impl4.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.SIMPLEIRA;
        impl4.Client_have_EEO_filing_under__c=NSP_ServiceConstants.YES ;
        impl4.Can_client_provide_EEO_filing_address__c = NSP_ServiceConstants.YES;
        impl4.EEO__c = 'Test';
        impl4.Filing_address__c =  'Test';
        impl4.NSP_co_employ_100_of_client_workforce__c = NSP_ServiceConstants.YES;
        impl4.Client_part_of_entity_w_o_NSP__c = NSP_ServiceConstants.YES;
        impl4.NSP_Transition_Specialist__c = con.Id;
        impl4.NSP_Orientation_Coordinator__c=con.id;
        impl4.Would_the_client_like_a_FLSA_Exemption__c = NSP_ServiceConstants.YES;
        impl4.NSP_HR_Specialist__c = con.id;
        impl4.NSP_Related_Clients__c = acc.Id;
        impl4.Who_should_the_FLSA_team_reach_out_to__c = 'Test, Test2';
        impl4.NSP_CheckToSendTheClient_Summary_email__c = true;
        ipListFSA.add(impl4);

        Implementation_Profile__c impl7 = (Implementation_Profile__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c());
        impl7.Does_the_client_offer_a_HSA__c = NSP_ServiceConstants.YES;
        impl7.Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.YES;
        impl7.Does_client_have_their_code_group_ID__c = NSP_ServiceConstants.NO;
        impl7.NSP_Orientation_Coordinator__c=con.id;
        impl7.NSP_CheckToSendTheClient_Summary_email__c = true;
        ipListFSA.add(impl7);

        //CHECK FOR EMAIL TRIGGER FOR FSO IP
        Implementation_Profile__c fsoIp = (Implementation_Profile__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c());
        fsoIp.RecordTypeId = fsoRecordTypeId;
        fsoIp.Client_s_previous_payroll_provider__c='test abc';
        fsoIp.Client_does_business_in_MA_NY_or_VA__c=NSP_ServiceConstants.Yes;
        fsoIp.Employees_work_in_the_following_states__c = 'NH';
        fsoIp.Effective_Date_Payroll_Worker_comp_EPLI__c=System.today();
        fsoIp.Client_maintaining_existing_EPLI_policy__c=NSP_ServiceConstants.YES;
        fsoIp.Wnt_cpy_of_Insperity_EPLI_policy_cert__c=NSP_ServiceConstants.YES;
        fsoIp.NSP_Has_the_client_s_logo_been_collected__c=NSP_ServiceConstants.YES;
        fsoIp.NSP_Does_the_client_more_FEIN__c=NSP_ServiceConstants.YES;
        fsoIp.Is_there_a_need_for_a_subaccount__c=NSP_ServiceConstants.YES;
        fsoIp.classing_req_a_new_download_for_Subacc__c=NSP_ServiceConstants.YES;
        fsoIp.Why_is_subaccount_needed__c= 'Multiple pay frequencies or pay dates';
        fsoIp.Insperity_pay_frequency__c='Weekly';
        fsoIp.remove_employee_directory_from_premier__c=NSP_ServiceConstants.YES;
        fsoIp.Client_has_Service_Contract_Act_SCA_EEs__c=NSP_ServiceConstants.YES;
        fsoIp.Have_the_SCA_EEs_been_approved__c=NSP_ServiceConstants.YES;
        fsoIp.SCA_EEs_get_wages_in_lieu_of_benefits__c=NSP_ServiceConstants.YES;
        fsoIp.Does_client_employ_ministers_or_teachers__c=NSP_ServiceConstants.YES;
        fsoIp.Check_all_tht_apply_ministers_teachers__c='Client has Teacher retirement plan which is exempt from social security';
        fsoIp.Has_form_8973_been_discussed__c=NSP_ServiceConstants.YES;
        fsoIp.Form_8973_Contact__c=TEST_NAME;
        fsoIp.Contact_Information__c=TEST_NAME;
        fsoIp.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        fsoIP.Client_business_in_MA_NY_or_VA__c ='MA';
        fsoIP.NSP_Business_Meeting_States__c ='MA';
        fsoIp.NSP_Payroll_Specialist__c=con.id;
        fsoIp.NSP_Project_Manager__c=con.id;
        fsoIp.NSP_Orientation_Coordinator__c=con.id;
        fsoIp.Does_this_client_have_an_AWW__c = 'Yes';
        fsoIp.Is_client_CA_docs_submitted_for_approval__c = 'Yes';
        fsoIp.NSP_CheckToSendTheClient_Summary_email__c = true;

        ipListFSA.add(fsoIp);

        Implementation_Profile__c fsoIp1 = (Implementation_Profile__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c());
        fsoIp1.RecordTypeId = fsoRecordTypeId;
        fsoIp1.Is_there_a_need_for_a_tech_package__c=NSP_ServiceConstants.YES;
        fsoIp1.Chngs_for_cafeteria_plan_questionnaire__c=NSP_ServiceConstants.YES;
        fsoIp1.List_change_s__c=TEST_NAME;
        fsoIp1.Client_s_previous_payroll_provider__c=TEST_NAME;
        fsoIp1.Will_the_owner_s_be_on_payroll__c = NSP_ServiceConstants.YES;
        fsoIp1.Client_have_any_EEs_on_F1_or_J1_Visa_s__c = NSP_ServiceConstants.YES;
        fsoIp1.NSP_Select_all_that_apply__c='IRR';
        fsoIp1.NSP_Does_the_client_offer_Stock_Options__c=NSP_ServiceConstants.YES;
        fsoIp1.First_Pay_Date__c=system.today();
        fsoIp1.Num_of_Worksite_Employees_Full_Time__c=10;
        fsoIp1.Does_the_client_offer_a_Stock_Purchase__c=NSP_ServiceConstants.YES;
        fsoIp1.Client_has_any_special_payroll_needs__c=NSP_ServiceConstants.YES;
        fsoIp1.Select_all_payroll_needs_that_apply__c='Job Costing';
        fsoIp1.Time_Entry_Method__c=NSP_ServiceConstants.XML;
        fsoIp1.NSP_Payroll_Specialist__c=con.id;
        fsoIp1.NSP_Onboarding_Specialist_Coordinator__c=con.Id;
        fsoIp1.NSP_Project_Manager__c=con.id;
        fsoIp1.NSP_Orientation_Coordinator__c=con.id;
        fsoIp1.NSP_HR_Specialist__c = con.id;
        fsoIp1.NSP_HR_Quality_Support_Team_Member__c = con.Id;
        fsoIp1.Does_this_client_have_an_AWW__c = 'No';
        fsoIp1.Would_the_client_like_a_FLSA_Exemption__c = NSP_ServiceConstants.YES;
        fsoIp1.Is_the_client_Emerging_Growth__c = NSP_ServiceConstants.No;
        fsoIp1.NSP_Related_Clients__c = acc.Id;
        fsoIp1.Who_should_the_FLSA_team_reach_out_to__c = 'Test';
        fsoIp1.NSP_CheckToSendTheClient_Summary_email__c = true;
        ipListFSA.add(fsoIp1);

        Implementation_Profile__c fsoIpAutomationObj = (Implementation_Profile__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Profile__c());
        fsoIpAutomationObj.RecordTypeId = fsoRecordTypeId;
        fsoIpAutomationObj.NSP_Asset__c = woAsset.Id;
        fsoIpAutomationObj.Is_there_a_need_for_a_tech_package__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Chngs_for_cafeteria_plan_questionnaire__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.List_change_s__c=TEST_NAME;
        fsoIpAutomationObj.Client_s_previous_payroll_provider__c=TEST_NAME;
        fsoIpAutomationObj.Will_the_owner_s_be_on_payroll__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_have_any_EEs_on_F1_or_J1_Visa_s__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_Select_all_that_apply__c='IRR';
        fsoIpAutomationObj.NSP_Does_the_client_offer_Stock_Options__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.First_Pay_Date__c=system.today();
        fsoIpAutomationObj.Num_of_Worksite_Employees_Full_Time__c=10;
        fsoIpAutomationObj.Does_the_client_offer_a_Stock_Purchase__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_has_any_special_payroll_needs__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Select_all_payroll_needs_that_apply__c='Job Costing';
        fsoIpAutomationObj.Time_Entry_Method__c=NSP_ServiceConstants.XML;
        fsoIpAutomationObj.Implementing_biz_Performance_solutions__c = 'YES';
        fsoIpAutomationObj.NSP_Payroll_Specialist__c=con.id;
        fsoIpAutomationObj.NSP_Onboarding_Specialist_Coordinator__c=con.Id;
        fsoIpAutomationObj.NSP_Project_Manager__c=con.id;
        fsoIpAutomationObj.NSP_Orientation_Coordinator__c=con.id;
        fsoIpAutomationObj.NSP_PC_Client_Email__c = 'Test@Testmail.com';
        fsoIpAutomationObj.NSP_PC_Client_Name__c = 'Test';
        fsoIpAutomationObj.Employees_work_in_the_following_states__c = 'NH';
        fsoIpAutomationObj.Client_have_will_have_any_Seasonal_EEs__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_CheckToSendPayrollSpecialist_Summary__c = true;
        fsoIpAutomationObj.Has_expenses_allowances_through_payroll__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_runs_expenses_or_payroll__c = NSP_ServiceConstants.ALLOWANCES + ';' + NSP_ServiceConstants.EXPENSES;
        fsoIpAutomationObj.Will_the_owner_s_be_on_payroll__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_Is_there_an_Enrollment_fee__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_Any_special_pay_codes_Needed__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_Select_all_that_apply__c = NSP_ServiceConstants.INTEGRA_ASSET + ';' + NSP_ServiceConstants.DEPARTMENTS;
        fsoIpAutomationObj.NSP_BPA_BPC__c = UserInfo.getUserId();
        fsoIpAutomationObj.NSP_BPA_BPC_Ids__c =UserInfo.getUserId();
        fsoIpAutomationObj.Chngs_for_cafeteria_plan_questionnaire__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_have_any_Commission_only_EEs__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_OT_Representative__c =con.Id;
        fsoIpAutomationObj.NSP_HR_Specialist__c = con.id;
        fsoIpAutomationObj.Employees_work_in_the_following_states__c ='MA';
        fsoIpAutomationObj.Client_does_business_in_MA_NY_or_VA__c= 'Yes';
        fsoIpAutomationObj.Effective_Date_Payroll_Worker_comp_EPLI__c = system.today();
        fsoIpAutomationObj.Wnt_cpy_of_Insperity_EPLI_policy_cert__c =NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_Has_the_client_s_logo_been_collected__c  =NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_maintaining_existing_EPLI_policy__c =NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_CheckToSendPayrollSpecialist_Summary__c = True ;
        fsoIpAutomationObj.All_EEs_paid_under_same_FEIN_currently__c =NSP_ServiceConstants.NO;
        fsoIpAutomationObj.Is_there_a_need_for_a_subaccount__c=NSP_ServiceConstants.YES;
        fsoIpAutomationObj.classing_req_a_new_download_for_Subacc__c =NSP_ServiceConstants.YES;
        fsoIpAutomationObj.remove_employee_directory_from_premier__c =NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Is_there_a_need_for_a_subaccount__c= NSP_ServiceConstants.YES;
        fsoIpAutomationObj.classing_req_a_new_download_for_Subacc__c =NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Effective_Date_Payroll_Worker_comp_EPLI__c = system.today();
        fsoIpAutomationObj.Wnt_cpy_of_Insperity_EPLI_policy_cert__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_maintaining_existing_EPLI_policy__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_has_existing_retirement_plan__c ='Yes';
        fsoIpAutomationObj.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.SIMPLEIRA;
        fsoIpAutomationObj.Client_have_EEO_filing_under__c=NSP_ServiceConstants.YES ;
        fsoIpAutomationObj.Can_client_provide_EEO_filing_address__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.EEO__c = 'Test';
        fsoIpAutomationObj.Filing_address__c =  'Test';
        fsoIpAutomationObj.NSP_co_employ_100_of_client_workforce__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Client_part_of_entity_w_o_NSP__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Is_the_client_a_federal_contractor__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Does_this_client_have_an_AWW__c = 'No';
        fsoIpAutomationObj.Are_you_registered_with_the_CSLB__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Contractor_s_License__c = 'TestLicense';
        fsoIpAutomationObj.Would_the_client_like_a_FLSA_Exemption__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.Is_the_client_Emerging_Growth__c = NSP_ServiceConstants.YES;
        fsoIpAutomationObj.NSP_Related_Clients__c = acc.Id;
        fsoIpAutomationObj.Who_should_the_FLSA_team_reach_out_to__c = 'Test';
        ipListFSA.add(fsoIpAutomationObj);
        insert ipListFSA;

        Implementation_Pay_Period__c ipayPeriod = (Implementation_Pay_Period__c) NSP_TestExtendedDataFactory.createSObject(new Implementation_Pay_Period__c());
        ipayPeriod.Frequency__c= 'Weekly';
        ipayPeriod.Final_pay_period_prior_to_Insperity__c= 'Tomorrow';
        ipayPeriod.Final_pay_date_prior_to_Insperity__c= system.Today();
        ipayPeriod.Does_the_client_have_prior_wages__c= 'Yes';
        ipayPeriod.NSP_Implementation_Profile__c = ipListFSA[5].Id;
        insert ipayPeriod;

        NSP_Regulated_Area__c regulatedArea = (NSP_Regulated_Area__c) NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c());
        regulatedArea.NSP_Regulation_Type__c = 'State Retirement Plan';
        regulatedArea.NSP_State__c = 'MA';
        Insert regulatedArea;
    }

    @isTest
    private static void testPrivateMethodFSOEmails() {
        Test.StartTest();
        Map<Id,Implementation_Profile__c> ipRecordMap =new Map<Id,Implementation_Profile__c>([SELECT Id,NSP_COBRA_Takeover_Emp_Details__c,recordType.Name, OwnerId, Name,  RecordTypeId, Account__c, Addressee_for_each_worksite_location__c, All_EEs_paid_under_same_FEIN_currently__c, Allowances__c, Any_EEs_in_clients_waiting_period__c, Any_EEs_travel_internationally_for_work__c, Any_EEs_with_urgent_medical_needs__c, Any_employees_currently_enrolled__c, Any_employer_contributions_to_EE_HSA__c, Any_special_needs_for_EE_orientation__c, Any_users_who_cannot_see_salary__c, Arbitration_Agreement_been_discussed__c, Are_there_any_EEs_on_Leave_of_Absence__c, Are_there_any_non_paid_users__c, Are_there_multiple_worksite_locations__c, NSP_Documents_Collected_Leviesd__c,NSP_BPA_BPC__c,NSP_BPA_BPC_Ids__c,  NSP_Documents_garnishments__c, Benefit_effective_date_carry_from_tab_4__c, Benefits_Package__c, Brief_description_of_client__c, Business_Inception_Date__c, Can_client_show_EEO_filing_address__c, Carrier_notified_of_termination__c, Check_all_changes_that_apply__c, Check_all_sch_B_changes_that_apply__c, Check_all_tht_apply_ministers_teachers__c, Chngs_for_cafeteria_plan_questionnaire__c, Client_Address__c, Client_Contact_Notes__c, Client_FEIN__c, Client_Implementing_Premier_Performance__c, NSP_Client_Liaison__c,
                                                                                              Client_Name_del__c, Client_Number__c, Client_Profile_Information__c, Client_does_business_in_MA_NY_or_VA__c, Client_entity_owned_or_a_non_profit__c, Client_expect_chnges_in_the_organization__c, Client_has_Service_Contract_Act_SCA_EEs__c, Client_has_any_post_tax_deductions__c, Client_has_any_special_payroll_needs__c, Client_has_existing_retirement_plan__c, Client_have_EEO_filing_under__c, Client_have_any_Commission_only_EEs__c, Client_have_any_EEs_on_F1_or_J1_Visa_s__c, Client_have_any_EEs_that_work_in_NY__c, Client_have_any_urgent_HR_needs__c, Client_have_will_have_any_Seasonal_EEs__c, Client_interested_in_NSP_tracking_PTO__c, Client_internal_deadline_for_OEE_OBE__c, Client_is_making_employer_contributions__c, Client_maintain_own_FSA__c, Client_maintaining_existing_EPLI_policy__c, Client_part_of_entity_w_o_NSP__c, Client_runs_expenses_or_payroll__c, Client_s_previous_payroll_provider__c, Client_s_previous_waiting_period__c, Client_union_EE_Check_all_that_Apply__c, Client_utilizing_Insperity_s_TimeStar__c, Client_want_to_begin_401k_w_NSP_setup__c, Client_working_with_an_NSP_RS_rep__c, Contact_Information__c, Current_hours_tracking_method_infolet__c, DBA__c, Date_and_Time__c, Day_one_start__c, Did_the_sch_B_change_at_the_SKO__c, Do_any_EEs_have_garnishments__c, Do_any_EEs_have_tax_levies__c,
                                                                                              Do_you_have_the_LOA_information__c, Do_you_pay_non_exempt_employees__c, Does_client_employ_ministers_or_teachers__c, Does_client_have_any_Minor_EEs__c, Does_client_have_their_code_group_ID__c, Does_the_Cigna_takeover_apply_to_client__c, Does_the_client_currently_offer_a_FSA__c, Does_the_client_have_any_union_EEs__c, Does_the_client_offer_a_HSA__c, Does_the_client_offer_a_Stock_Purchase__c, Duration__c, EEO__c, EEO_name_phone_contact_email_for_info__c, EEs_to_punch_in_out_or_use_timesheet__c, Effective_Date_Payroll_Worker_comp_EPLI__c, Employee_Data_Collection_EDC_collected__c, Employees_currently_enrolled_in_FSA__c, Employees_work_in_the_following_states__c, Enter_non_paid_user_names__c, Enter_user_names_that_can_t_see_salary__c, Exempt_EEs_normal_of_hours_per_day__c, Expenses__c, FSA_Notes__c, Filing_address__c, First_Pay_Date__c, Form_8973_Contact__c, Gave_copy_of_PTO_sick_leave_other_policy__c, Gotten_Cvrg_Cert_Gen_Liability_Auto__c, NSP_Employee_Names_List_garnishments__c, NSP_List_Employee_Names_Levies__c, HR_Contact_Method__c, NSP_Account_Executive__c, NSP_OS_Coordinator__c, NSP_OT_Coordinator__c, NSP_HR_Quality_Support_Team_Member__c, HR_Specialist__c, HR_contact_is_same_as_OSS__c, Has_FEIN_documentation_been_collected__c, Has_FLSA_team_approved__c,
                                                                                              Has_expenses_allowances_through_payroll__c, Has_form_8973_been_discussed__c, Have_name_s_of_COBRA_takeovr_employees__c, Have_the_SCA_EEs_been_approved__c, Have_the_user_roles_been_updated_in_AIMS__c, Holiday_or_weekend_rule__c, How_will_EE_complete_their_enrollment__c, How_will_emp_deferral_loan_amnt__c, How_will_future_payments_be_made__c, Hush_Protocol__c, NSP_Immediate_need_for_Workers_Comp_Cert__c, Implementing_biz_Performance_solutions__c, Insperity_benefits_effective_date__c, Insperity_benefits_waiting_period__c, Insperity_grp_hlth_plan_replacing_prior__c, Is_client_s_current_HSA_with_Optum_Bank__c, Is_the_client_a_federal_contractor__c, Is_the_client_coming_from_another_PEO__c, Is_the_client_required_to_track__c, Is_there_a_need_for_a_GL_interface__c, Is_there_a_need_for_a_subaccount__c, Is_there_a_need_for_a_tech_package__c, Iss_translator_needed__c, NSP_OT_Planner__c, NSP_Orientation_Rep__c, Legal_Name__c, List_additional_FEIN_s__c, List_change_s__c, List_of_certificates_requested__c, Medical_Level__c, NSP_Payroll_Project_Manager__c, Misc_Contact_Contact_Method__c, NSP_Payroll_Specialist__c, NSP_Project_Manager__c,NSP_Project_Manager__r.NSP_Work_email__c, NSP_Sr_Benefit_Rep__c, Monthly_pay_freq_comply_w_state_laws__c, NA_cafeteria_doc_plan_provide_details__c, NSP_Anticipated_Growth_Plans_details__c,
                                                                                              NSP_Any_special_pay_codes_Needed__c, NSP_Are_Certified_Payroll_reports_needed__c, NSP_Are_the_subaccounts_set_up__c, NSP_Are_there_any_OT_exceptions__c, NSP_ArrearageInComplianceWithEachState__c, NSP_Asset__c, NSP_Back_up_Client_Cell_Phone__c, NSP_Back_up_Client_Contact_Method__c, NSP_Back_up_Client_Email__c, NSP_Back_up_Client_Office_Phone__c, NSP_Back_up_PC_Client_Name__c, NSP_Biweekly_Pay_Period__c, NSP_Business_Meeting_States__c, NSP_Chart_of_Accounts_GL_codes__c, NSP_CheckOnceYouDiscussEPAY_with_client__c, NSP_CheckToSendPayrollSpecialist_Summary__c, NSP_CheckToSendTheClient_Summary_email__c, NSP_Check_to_create_the_RRP_Case__c, NSP_ClientInterestedHavingAutoApproval__c, NSP_Client_s_holiday_calendar__c, NSP_Commission_Frequency__c, NSP_Commission_Type__c, NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c, NSP_DCFSA_Provide_details__c, NSP_Daily_Rate_approval_status__c, NSP_Dental_Ongoing_CSP_cafeteria_Doc__c, NSP_Dental_Pretax_Delayed_Start__c, NSP_Dental_Pretax_Provide_Details__c, NSP_Did_you_verify_Calendar_in_AIMS__c, NSP_Different_contact_for_subaccounts__c, NSP_Discretionary_Bonus_Input_Frequency__c, NSP_Discretionary_Bonus__c, NSP_Discussed_E_Verify_with_the_client__c, NSP_DoAIMSMatchAboveWorksite_information__c, NSP_DoTheEmployeeWorkA40HourWorkWeek__c, NSP_Do_you_have_GovernmentContracted_job__c,
                                                                                              NSP_Do_you_pay__c, NSP_Do_you_track_hours__c, NSP_Does_Client_have_Growth_Plans__c, NSP_Does_the_client_more_FEIN__c, NSP_Does_the_client_offer_Stock_Options__c, NSP_EEs_garnishments_details__c, NSP_Employee_Types__c, NSP_Employees_with_multiple_types_of_pay__c, NSP_Employer_contributions_details__c, NSP_Enter_Time_Entry_for_all_subaccounts__c, NSP_FormsAreNeededForFollowingDeduction__c, NSP_HCFSA_Delayed_Start_Date__c, NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c, NSP_HCFSA_Provide_Details__c, NSP_HSA_Ongoing_CSP_cafeteria_document__c, NSP_HSA_Provide_Details__c, NSP_Has_the_addendum_been_collected__c, NSP_Has_the_client_s_logo_been_collected__c, NSP_Health_Savings_Account_Delayed_Start__c, NSP_How_will_client_reimburse_expenses__c, NSP_Is_a_translator_needed__c, NSP_Is_there_an_Enrollment_fee__c, NSP_KDM_Client_Cell_Phone__c, NSP_KDM_Client_Contact_Method__c, NSP_KDM_Client_Email__c, NSP_KDM_Client_Name__c, NSP_KDM_Client_Office_Phone__c, NSP_List_BPS_Implementation_Timeframe__c, NSP_List_EEs_Names__c, NSP_List_Employee_Names__c, NSP_List_all_Default_Pay_Codes_in_AIMS__c, NSP_List_all_PTO_Codes__c, NSP_Medical_Ongoing_CSP_cafeteria_Doc__c, NSP_Medical_Pretax_Delayed_Start__c, NSP_Medical_Pretax_Provide_details__c, NSP_Monthly_Pay_Period__c, NSP_Name_of_accounting_software__c, NSP_No_back_up_PC__c,
                                                                                              NSP_NonDiscretionaryDiscretionaryPayCode__c, NSP_Non_Discretionary_Bonus__c, NSP_OSS_Client_Cell_Phone__c, NSP_OSS_Client_Contact_Method__c, NSP_OSS_Client_Email__c, NSP_OSS_Client_Name__c, NSP_OSS_Client_Office_Phone__c, NSP_OSS_contact_is_same_as_KDM__c, NSP_Office_Address__c, NSP_Orientation_Notes__c, NSP_PC_Client_Cell_Phone__c, NSP_PC_Client_Email__c, NSP_PC_Client_Name__c, NSP_PC_Client_Office_Phone__c, NSP_PC_is_same_as_OSS__c, NSP_PTO_Plan_Type__c, NSP_Payroll_Onboarding_Notes__c, NSP_Pre_SKO_Notes__c, NSP_Prepop_Timecards_w_Stndrd_hrs__c, NSP_Provide_Details__c, NSP_Provide_EEs_tax_levies_details__c, NSP_Provide_Monthly_pay_frequency_detail__c, NSP_Provide_Schedule_B_details__c, NSP_Provide_Tracking_details__c, NSP_Provide_previous_coverage_details__c, NSP_RS_Contact__c, NSP_SalaryExemptEmployeeReceiveOvertime__c, NSP_Sample_of_current_GL_report__c, NSP_Select_all_that_apply__c, NSP_Semimonthly_Pay_Period__c, NSP_Service_team_notes__c, NSP_States_added_since_Kickoff_Meeting__c, NSP_SubaccountNeededDifferentPayPeriod__c, NSP_TimeZone__c, NSP_Type__c, NSP_Vision_Ongoing_CSP_cafeteria_Doc__c, NSP_Vision_Pretax_Delayed_Start__c, NSP_Vision_Pretax_Provide_Details__c, NSP_WC_Client_Cell_Phone__c, NSP_WC_Client_Contact_Method__c, NSP_WC_Client_Email__c, NSP_WC_Client_Name__c, NSP_WC_Client_Office_Phone__c, NSP_WC_contact_is_same_as_OSS__c,
                                                                                              NSP_Weekly_Pay_Period__c, NSP_What_is_the_Live_Payroll_Call_Date__c, NSP_Where_will_PTO_be_tracked__c, NSP_Work_Hours__c, NSP_co_employ_100_of_client_workforce__c, NSP_non_Insperity_paid_emps_contractors__c, Non_Discretionary_Bonus_Input_frequency__c, Non_exempt_EE_pay_freq_provide_details__c, Non_exempt_EEs_on_semi_monthly_pay_freq__c, Num_of_Worksite_Employees_Full_Time__c, Num_of_Worksite_Employees_Part_Time__c, Num_of_Worksite_Employees_Seasonal__c, OEE_OBE_Notes__c, NSP_Sr_HR_Specialist__c, NSP_Transition_Specialist__c, NSP_OT_Representative__c, Old_grp_health_plan_coverage_period_was__c, Old_plan_administrator_was_another_PEO__c, NSP_Onboarding_Specialist_Coordinator__c, Ongoing_CSP_cafeteria_plan_doc_has_been__c, Optum_Bank_HSA_Code__c, Optum_Bank_HSA_Group__c, NSP_Orientation_Coordinator__c, NSP_Orientation_Planner__c, Orientation_Rep__c, Other_Health_Plan_Coverage_Type__c, Other_expense_details__c, Other_payroll_details__c, Owner_aware_they_will_not_get_W2_wages__c, Owner_not_on_payroll_addendum_collected__c, PC_Client_Contact_Method__c, NSP_Form_Completed__c, NSP_Provide_Details_Enrollment_fee__c, PEO_Name__c, PTO_Types__c, Participants_on_COBRA_eligibility_period__c, Past_employees_crntly_getting_severance__c, Payroll_Notes__c, NSP_Payroll_Supervisor__c,
                                                                                              Payroll_general_notes__c, Payroll_submitted_frm_multiple_contacts__c, Post_tax_suppl_insurance_provide_details__c, Pre_tax_Client_Sponsored_Plan_CSP_Type__c, Previous_group_health_plan_administrator__c, Previous_group_health_plan_carrier_s__c, Previous_group_health_plan_coverage_type__c, Previous_group_plan_is_terminating__c, Prior_Benefits_Termination_Date__c, Provide_Details__c, Provide_EE_travel_details__c, Provide_PEO_Name__c, Provide_PTO_details__c, Provide_Urgent_HR_Needs_details__c, Provide_allowance_details__c, Provide_benefit_package_change_details__c, Provide_deadline_date__c, Provide_details_for_no_COBRA_employees__c, Provide_expense_details__c, Provide_live_check_details__c, Provide_multiple_contact_details__c, Provide_multiple_worksite_details__c, Provide_non_insperity_worker_details__c, Provide_organization_change_details__c, Provide_start_end_dates_of_plan_year__c, Recent_Payroll_Register_Collected__c, Remove_client_employee_directory__c, Retirement_services_notes__c, SCA_EEs_get_wages_in_lieu_of_benefits__c, SUI_Tax_rate_notice_s_collected__c, Sales_Office__c, Schedule_B_version__c, Select_BPSes__c, Select_all_payroll_needs_that_apply__c, Select_the_applicable_LOA_types__c, Semi_monthly_pay_freq_comply_w_state_law__c, Semi_monthly_pay_st_law_provide_details__c, Send_the_certificates_to__c,
                                                                                              Sole_Proprietorship_or_partnership__c, Spnsrd_pln_when_Insperity_hndles_payroll__c, Sponsored_plan_contribution_type__c, State_Unemployment_Insurance_SUI_Num__c, Tech_pack_when_where_quantity_needed__c, Time_Entry_Method__c, Told_EE_ineligble_for_active_at_work_ben__c, Type_of_retirement_plan_client_has_today__c, NSP_AIMS_ClientNo_Backup_PC__c, NSP_AIMS_ClientNo_HR__c, What_are_the_FSA_plan_dates__c, What_current_payroll_reports_being_used__c, What_is_the_status_of_the_LOA_info__c, What_time_zone_do_EEs_work__c, When_Client_Wants_Solution_implemented__c, When_are_certificates_needed__c, Where_to_mail_EE__c, Who_will_be_the_TimeStar_admin__c, Who_will_enter_time_worked__c, Wht_language_whn_is_translator_needed__c, Why_did_the_client_join_Insperity__c, Why_is_subaccount_needed__c, Will_the_BPA_s_Be_attending_the_SKO__c, Will_the_owner_s_be_on_payroll__c, Will_there_be_benefits_classing__c, Wnt_cpy_of_Insperity_EPLI_policy_cert__c, Work_week__c, classing_req_a_new_download_for_Subacc__c, client_terminated_old_benefit_coverage__c, prior_med_contributions_tht_Insperity__c, Any_Special_Agreements_Addendum_in_CSA__c, Any_exempt_part_time_employees__c, Are_all_of_the_rates_in_agreement__c, Are_sample_intro_letters_being_provided__c, Are_there_any_DOL_audits__c, Are_there_employes_working_in__c,
                                                                                              Basis_of_wage_payment_options__c, Client_business_in_MA_NY_or_VA__c, Client_covering_addl_paid_life_insurance__c, Client_does_pre_employment_drug_screen__c, Client_has_any_of_the_following__c, Client_interested_NSP_time_attendance__c, Client_is_interested_NSP_PTO_tracking__c, Client_needs_to_e_verify_all_employees__c, Client_previously_filed_an_EEO_1_Report__c, Client_provided_copy_of_communication__c, Client_submitting_apprvl_for_spreadsheet__c, Confirm_w_RS_when_each_step_is_completed__c, Current_onboarding_process_for_new_empl__c, DOL_Audit_Provide_Details__c, Direct_deposit_offered_to_employees__c, Discovery_Meeting_Date_Time_Location__c, Discussed_predecessor_hours_w_client__c, Docs_emp_need_to_complete_for_onboarding__c, Does_client_have_taxable_fringe_benefits__c, Does_client_perform_background_checks__c, EE_check_delivered_diff_place_than_work__c, EE_enrollments_outside_of_Insperity__c, Earned_Sick_Time_Start_Date__c, Employee_Enrollment__c, Employees_reside_in_these_service_areas__c, Employees_work_in_more_than_one_state__c, Exemption_status_of_all_empl_explained__c, Freq_of_collecting_medical_contribution__c, Gen_liability_auto_coverage_details__c, Have_EEs_been_notified_of_the_transition__c, How_are_empl_hrs_reported_to_Insperity__c, How_do_employees_currently_enroll__c,
                                                                                              How_will_enrollments_be_handled__c, How_will_the_payroll_be_funded__c, Human_Resources_Notes__c, Inspection_details__c, Insperity_Empl_contrib_rate_determined__c, Interested_in_on_site_safety_inspections__c, Is_current_medical_provider_UHC__c, Is_exempt_from_MN_Statute_177__c, Is_exempt_from_Minimum_Wage__c, Is_there_a_separate_Vacation_policy__c, Labor_Dist_Job_Costing_or_cert_payroll__c, Leave_Benefits__c, Meeting_Notes__c, Meeting_Participants__c, Must_show_FLSA_EE_exemp_cat_for_all_EEs__c, Need_for_departments_and_locations__c, No_live_check_provide_details__c, Non_active_non_paid_empl_w_benefits_cov__c, ORK_Team_notified_about_the_new_client__c, Onboarding_Notes__c, Other_Post_Tax_Deduction_Details__c, Other_standard_work_hours_details__c, Other_urgent_HR_needs_provide_details__c, Overtime_owed_after_how_many_hrs_worked__c, Paid_Sick_Leave_Plan_Type__c, Paid_Sick_Leave_requirement__c, Paid_sick_leave_exemption_reason__c, Part_time_employees_enrolled_in_benefits__c, NSP_RS_Doc_Contact_Info__c, Pre_Discovery_Notes__c, Previous_challenge_provide_details__c, Previous_challenges_w_current_provider__c, Reason_for_eligibility__c, Received_Enrollment_Fee__c, Received_Section_125_Questionnaire__c, Regulatory_accreditation_inspections__c,
                                                                                              Review_Employee_Orientations__c, Review_Insperity_Online_Enrollment_Steps__c, Reviewed_deductible_carryover_w_client__c, San_Diego_Earned_Sick__c, Select_all_enrollments__c, Select_client_urgent_HR_needs__c, Sep_doc_specifying_pay_breakdown__c, Sick_Leave_balance_type__c, Special_Agreement_Addendum_details__c, NSP_Sr_Onboarding_Benefit_Rep__c, Terming_life_insurance_disability_plan__c, Uses_WageWorks_for_commuter_benefit_plan__c, What_type_and_how_many_splits__c, When_was_the_handbook_last_updated__c, When_was_the_last_Open_Enrollment_period__c, Where_is_the_policy_located__c, Who_in_client_gets_std_insperity_comm__c, Who_is_the_current_custodian_bank__c, Who_is_the_provider__c, Workers_Comp_Safety_Notes__c, Written_doc_pay_plan_for_how_EE_is_paid__c, sample_new_empl_info_packet_collected__c, PC_Client_Number__c, Back_up_PC_Client_Number__c, Back_up_PC__c, Can_client_provide_EEO_filing_address__c, Checks_delivered__c, Documentation_Status__c, EE_Visa_Type__c, Emp_deferral_loan_amount__c, HR_Contact_Cell_Phone__c, HR_Contact_Office_Phone__c, Insperity_last_day_of_2nd_pay_period__c, Is_Insperity_s_group_health_plan_replaci__c, KDM_Client_Number__c, KDM__c, Misc_Contact_Cell_Phone__c, Misc_Contact_Number__c, Misc_Contact_Office_Phone__c, Misc_Contact__c,
                                                                                              NSP_AIMS_ClientNo__c, NSP_AIMS_Client_Name__c, NSP_Any_active_severance_agreement__c, NSP_Any_employee_with_temporary_status__c, NSP_Assignment_Notes__c, NSP_BPS_Notes__c, NSP_Client_Sponsored_Plan__c, NSP_Client_retaining_benefit_plan__c, NSP_Does_arrearage_comply_with_state_law__c, NSP_Does_the_client_have_prior_wages__c, NSP_EE_Name__c, NSP_Employee_Notes__c, NSP_Employee_with_compensation_other__c, NSP_FLSA_EE_exemption_category_provided__c, NSP_Final_pay_date_prior_to_Insperity__c, NSP_Final_pay_period_prior_to_Insperity__c, NSP_Frequency__c, NSP_Have_credit_services_approved__c, NSP_How_e_verify_be_completed__c, NSP_How_employee_hours_be_reported_to_I__c, NSP_How_hours_currently_captured__c, NSP_Immediate_payroll_needs_or_concerns__c, NSP_Inspeirty_last_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_2nd_pay_period__c, NSP_Insperity_1st_pay_date__c, NSP_Insperity_2nd_pay_date__c, NSP_Is_arrearage_7_days__c, NSP_Onsite_Safety_Inspection_Details__c, NSP_Other_Urgent_HR_Needs__c, NSP_Overtime_owed_after_hours__c, NSP_Payment_Details__c, NSP_Payroll_Specialist_to_confirm__c, NSP_Plan_for_EE_Payment__c, NSP_Project__c, NSP_Review_Cigna_Enrollment_Process__c, NSP_Separate_Vacation_Policy__c, NSP_Service_Model__c, NSP_Standard_No_of_Hours_worked_for_EEs__c, NSP_State_require_specific_priming_field__c,
                                                                                              NSP_Subaccount__c, NSP_Urgent_HR_Needs_Details__c, NSP_When_where_and_quantity_needed__c, NSP_Who_receives_Insperity_Communication__c, NSP_Who_will_approve_the_payroll__c, NSP_Who_will_submit_payroll__c, NSP_collected_copies_of_state_WC_policy__c,NSP_current_waiting_period__c, NSP_how_future_payment_will_be_done__c, NSP_prior_medical_contributions__c, NSP_remote_EEs_not_working_physical_loc__c, NSP_separate_pay_document_specify__c, WC__c, received_introductory_email_frm_ORK_Team__c, remove_employee_directory_from_premier__c, NSP_AIMS_ClientNo_KDM__c, NSP_AIMS_ClientNo_OSS__c, NSP_AIMS_ClientNo_PC__c, NSP_AIMS_ClientNo_WC__c, NSP_Benefit_Notes__c, NSP_Commission_Provide_Details__c, NSP_DoYouPay_Other_Provide_details__c, NSP_Non_paid_users_Enter_User_Names__c, NSP_compensation_structu_Provide_Details__c, NSP_Govt_Type_Other_Provide_Details__c, NSP_employee_40_hour_work_Week_PDetails__c, NSP_Any_OT_Expections_Provide_Details__c, NSP_PD_different_contact_for_subaccount__c, NSP_Provide_Details_Relabeling_Needed__c, NSP_Any_special_pay_code_Provide_Details__c, Insperity_pay_frequency__c,
                                                                                              NSP_Payroll_Specialist__r.NSP_Work_email__c,NSP_Asset__r.AccountId, NSP_Payroll_Specialist__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__r.Email,NSP_Urgent_Medical_Needs_Emp_Details__c, NSP_Employees_on_LOA__c,NSP_Employee_Details_On_LOA__c ,NSP_Old_Benefits_Package__c,NSP_Old_Effective_Date_EPLI__c,NSP_Old_Insperity_Ben_effective_date__c,NSP_OT_Representative__r.NSP_Work_email__c,Does_this_client_have_an_AWW__c,Is_client_CA_docs_submitted_for_approval__c,Are_you_registered_with_the_CSLB__c,Contractor_s_License__c,NSP_Legal_Name__c,Federal_Labor_Law_poster__c,Would_the_client_like_a_FLSA_Exemption__c FROM Implementation_Profile__c WHERE Implementing_biz_Performance_solutions__c = 'YES' LIMIT 1]);

        Map<Id,Implementation_Profile__c> ipRecordMap2 =new Map<Id,Implementation_Profile__c>([SELECT ID, NSP_Form_Completed__c
                                                                                              FROM Implementation_Profile__c
                                                                                              WHERE Is_the_client_Emerging_Growth__c = 'No' LIMIT 1]);

        Implementation_Pay_Period__c additionalIpPayPeriods = [ SELECT Id, Frequency__c, NSP_Implementation_Profile__c, Final_pay_period_prior_to_Insperity__c, Final_pay_date_prior_to_Insperity__c,Does_the_client_have_prior_wages__c
                                                               FROM Implementation_Pay_Period__c WHERE NSP_Implementation_Profile__c IN: ipRecordMap.keyset() Limit 1 ];

        for(Implementation_Profile__c ip: ipRecordMap.values()){
            ip.NSP_Form_Completed__c = true;
            ip.Would_the_client_like_a_FLSA_Exemption__c = NSP_ServiceConstants.No;
        }
        update  ipRecordMap.values();
        for(Implementation_Profile__c ip: ipRecordMap2.values()){
            ip.NSP_Form_Completed__c = true;
        }
        update  ipRecordMap2.values();

        NSP_Implementationprofile_ServiceHelper helper = new NSP_Implementationprofile_ServiceHelper(ipRecordMap, new Map<Id, Implementation_Profile__c>());
        helper.isRerun = True;
        helper.executeAutomation();
        system.assertEquals( ipRecordMap.values()[0].Client_have_EEO_filing_under__c, NSP_ServiceConstants.YES);
        Test.stopTest();
    }


    @isTest
    private static void testMethodMiddleMarketEmails() {
        Test.StartTest();
        Map<Id,Implementation_Profile__c> ipRecordMap =new Map<Id,Implementation_Profile__c>([SELECT Id,NSP_COBRA_Takeover_Emp_Details__c,recordType.Name, OwnerId, Name,  RecordTypeId, Account__c, Addressee_for_each_worksite_location__c, All_EEs_paid_under_same_FEIN_currently__c, Allowances__c, Any_EEs_in_clients_waiting_period__c, Any_EEs_travel_internationally_for_work__c, Any_EEs_with_urgent_medical_needs__c, Any_employees_currently_enrolled__c, Any_employer_contributions_to_EE_HSA__c, Any_special_needs_for_EE_orientation__c, Any_users_who_cannot_see_salary__c, Arbitration_Agreement_been_discussed__c, Are_there_any_EEs_on_Leave_of_Absence__c, Are_there_any_non_paid_users__c, Are_there_multiple_worksite_locations__c, NSP_Documents_Collected_Leviesd__c,NSP_BPA_BPC__c,NSP_BPA_BPC_Ids__c,  NSP_Documents_garnishments__c, Benefit_effective_date_carry_from_tab_4__c, Benefits_Package__c, Brief_description_of_client__c, Business_Inception_Date__c, Can_client_show_EEO_filing_address__c, Carrier_notified_of_termination__c, Check_all_changes_that_apply__c, Check_all_sch_B_changes_that_apply__c, Check_all_tht_apply_ministers_teachers__c, Chngs_for_cafeteria_plan_questionnaire__c, Client_Address__c, Client_Contact_Notes__c, Client_FEIN__c, Client_Implementing_Premier_Performance__c, NSP_Client_Liaison__c,
                                                                                              Client_Name_del__c, Client_Number__c, Client_Profile_Information__c, Client_does_business_in_MA_NY_or_VA__c, Client_entity_owned_or_a_non_profit__c, Client_expect_chnges_in_the_organization__c, Client_has_Service_Contract_Act_SCA_EEs__c, Client_has_any_post_tax_deductions__c, Client_has_any_special_payroll_needs__c, Client_has_existing_retirement_plan__c, Client_have_EEO_filing_under__c, Client_have_any_Commission_only_EEs__c, Client_have_any_EEs_on_F1_or_J1_Visa_s__c, Client_have_any_EEs_that_work_in_NY__c, Client_have_any_urgent_HR_needs__c, Client_have_will_have_any_Seasonal_EEs__c, Client_interested_in_NSP_tracking_PTO__c, Client_internal_deadline_for_OEE_OBE__c, Client_is_making_employer_contributions__c, Client_maintain_own_FSA__c, Client_maintaining_existing_EPLI_policy__c, Client_part_of_entity_w_o_NSP__c, Client_runs_expenses_or_payroll__c, Client_s_previous_payroll_provider__c, Client_s_previous_waiting_period__c, Client_union_EE_Check_all_that_Apply__c, Client_utilizing_Insperity_s_TimeStar__c, Client_want_to_begin_401k_w_NSP_setup__c, Client_working_with_an_NSP_RS_rep__c, Contact_Information__c, Current_hours_tracking_method_infolet__c, DBA__c, Date_and_Time__c, Day_one_start__c, Did_the_sch_B_change_at_the_SKO__c, Do_any_EEs_have_garnishments__c, Do_any_EEs_have_tax_levies__c,
                                                                                              Do_you_have_the_LOA_information__c, Do_you_pay_non_exempt_employees__c, Does_client_employ_ministers_or_teachers__c, Does_client_have_any_Minor_EEs__c, Does_client_have_their_code_group_ID__c, Does_the_Cigna_takeover_apply_to_client__c, Does_the_client_currently_offer_a_FSA__c, Does_the_client_have_any_union_EEs__c, Does_the_client_offer_a_HSA__c, Does_the_client_offer_a_Stock_Purchase__c, Duration__c, EEO__c, EEO_name_phone_contact_email_for_info__c, EEs_to_punch_in_out_or_use_timesheet__c, Effective_Date_Payroll_Worker_comp_EPLI__c, Employee_Data_Collection_EDC_collected__c, Employees_currently_enrolled_in_FSA__c, Employees_work_in_the_following_states__c, Enter_non_paid_user_names__c, Enter_user_names_that_can_t_see_salary__c, Exempt_EEs_normal_of_hours_per_day__c, Expenses__c, FSA_Notes__c, Filing_address__c, First_Pay_Date__c, Form_8973_Contact__c, Gave_copy_of_PTO_sick_leave_other_policy__c, Gotten_Cvrg_Cert_Gen_Liability_Auto__c, NSP_Employee_Names_List_garnishments__c, NSP_List_Employee_Names_Levies__c, HR_Contact_Method__c, NSP_Account_Executive__c, NSP_OS_Coordinator__c, NSP_OT_Coordinator__c, NSP_HR_Quality_Support_Team_Member__c, HR_Specialist__c, HR_contact_is_same_as_OSS__c, Has_FEIN_documentation_been_collected__c, Has_FLSA_team_approved__c,
                                                                                              Has_expenses_allowances_through_payroll__c, Has_form_8973_been_discussed__c, Have_name_s_of_COBRA_takeovr_employees__c, Have_the_SCA_EEs_been_approved__c, Have_the_user_roles_been_updated_in_AIMS__c, Holiday_or_weekend_rule__c, How_will_EE_complete_their_enrollment__c, How_will_emp_deferral_loan_amnt__c, How_will_future_payments_be_made__c, Hush_Protocol__c, NSP_Immediate_need_for_Workers_Comp_Cert__c, Implementing_biz_Performance_solutions__c, Insperity_benefits_effective_date__c, Insperity_benefits_waiting_period__c, Insperity_grp_hlth_plan_replacing_prior__c, Is_client_s_current_HSA_with_Optum_Bank__c, Is_the_client_a_federal_contractor__c, Is_the_client_coming_from_another_PEO__c, Is_the_client_required_to_track__c, Is_there_a_need_for_a_GL_interface__c, Is_there_a_need_for_a_subaccount__c, Is_there_a_need_for_a_tech_package__c, Iss_translator_needed__c, NSP_OT_Planner__c, NSP_Orientation_Rep__c, Legal_Name__c, List_additional_FEIN_s__c, List_change_s__c, List_of_certificates_requested__c, Medical_Level__c, NSP_Payroll_Project_Manager__c, Misc_Contact_Contact_Method__c, NSP_Payroll_Specialist__c, NSP_Project_Manager__c, NSP_Sr_Benefit_Rep__c, Monthly_pay_freq_comply_w_state_laws__c, NA_cafeteria_doc_plan_provide_details__c, NSP_Anticipated_Growth_Plans_details__c,
                                                                                              NSP_Any_special_pay_codes_Needed__c, NSP_Are_Certified_Payroll_reports_needed__c, NSP_Are_the_subaccounts_set_up__c, NSP_Are_there_any_OT_exceptions__c, NSP_ArrearageInComplianceWithEachState__c, NSP_Asset__c, NSP_Back_up_Client_Cell_Phone__c, NSP_Back_up_Client_Contact_Method__c, NSP_Back_up_Client_Email__c, NSP_Back_up_Client_Office_Phone__c, NSP_Back_up_PC_Client_Name__c, NSP_Biweekly_Pay_Period__c, NSP_Business_Meeting_States__c, NSP_Chart_of_Accounts_GL_codes__c, NSP_CheckOnceYouDiscussEPAY_with_client__c, NSP_CheckToSendPayrollSpecialist_Summary__c, NSP_CheckToSendTheClient_Summary_email__c, NSP_Check_to_create_the_RRP_Case__c, NSP_ClientInterestedHavingAutoApproval__c, NSP_Client_s_holiday_calendar__c, NSP_Commission_Frequency__c, NSP_Commission_Type__c, NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c, NSP_DCFSA_Provide_details__c, NSP_Daily_Rate_approval_status__c, NSP_Dental_Ongoing_CSP_cafeteria_Doc__c, NSP_Dental_Pretax_Delayed_Start__c, NSP_Dental_Pretax_Provide_Details__c, NSP_Did_you_verify_Calendar_in_AIMS__c, NSP_Different_contact_for_subaccounts__c, NSP_Discretionary_Bonus_Input_Frequency__c, NSP_Discretionary_Bonus__c, NSP_Discussed_E_Verify_with_the_client__c, NSP_DoAIMSMatchAboveWorksite_information__c, NSP_DoTheEmployeeWorkA40HourWorkWeek__c, NSP_Do_you_have_GovernmentContracted_job__c,
                                                                                              NSP_Do_you_pay__c, NSP_Do_you_track_hours__c, NSP_Does_Client_have_Growth_Plans__c, NSP_Does_the_client_more_FEIN__c, NSP_Does_the_client_offer_Stock_Options__c, NSP_EEs_garnishments_details__c, NSP_Employee_Types__c, NSP_Employees_with_multiple_types_of_pay__c, NSP_Employer_contributions_details__c, NSP_Enter_Time_Entry_for_all_subaccounts__c, NSP_FormsAreNeededForFollowingDeduction__c, NSP_HCFSA_Delayed_Start_Date__c, NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c, NSP_HCFSA_Provide_Details__c, NSP_HSA_Ongoing_CSP_cafeteria_document__c, NSP_HSA_Provide_Details__c, NSP_Has_the_addendum_been_collected__c, NSP_Has_the_client_s_logo_been_collected__c, NSP_Health_Savings_Account_Delayed_Start__c, NSP_How_will_client_reimburse_expenses__c, NSP_Is_a_translator_needed__c, NSP_Is_there_an_Enrollment_fee__c, NSP_KDM_Client_Cell_Phone__c, NSP_KDM_Client_Contact_Method__c, NSP_KDM_Client_Email__c, NSP_KDM_Client_Name__c, NSP_KDM_Client_Office_Phone__c, NSP_List_BPS_Implementation_Timeframe__c, NSP_List_EEs_Names__c, NSP_List_Employee_Names__c, NSP_List_all_Default_Pay_Codes_in_AIMS__c, NSP_List_all_PTO_Codes__c, NSP_Medical_Ongoing_CSP_cafeteria_Doc__c, NSP_Medical_Pretax_Delayed_Start__c, NSP_Medical_Pretax_Provide_details__c, NSP_Monthly_Pay_Period__c, NSP_Name_of_accounting_software__c, NSP_No_back_up_PC__c,
                                                                                              NSP_NonDiscretionaryDiscretionaryPayCode__c, NSP_Non_Discretionary_Bonus__c, NSP_OSS_Client_Cell_Phone__c, NSP_OSS_Client_Contact_Method__c, NSP_OSS_Client_Email__c, NSP_OSS_Client_Name__c, NSP_OSS_Client_Office_Phone__c, NSP_OSS_contact_is_same_as_KDM__c, NSP_Office_Address__c, NSP_Orientation_Notes__c, NSP_PC_Client_Cell_Phone__c, NSP_PC_Client_Email__c, NSP_PC_Client_Name__c, NSP_PC_Client_Office_Phone__c, NSP_PC_is_same_as_OSS__c, NSP_PTO_Plan_Type__c, NSP_Payroll_Onboarding_Notes__c, NSP_Pre_SKO_Notes__c, NSP_Prepop_Timecards_w_Stndrd_hrs__c, NSP_Provide_Details__c, NSP_Provide_EEs_tax_levies_details__c, NSP_Provide_Monthly_pay_frequency_detail__c, NSP_Provide_Schedule_B_details__c, NSP_Provide_Tracking_details__c, NSP_Provide_previous_coverage_details__c, NSP_RS_Contact__c, NSP_SalaryExemptEmployeeReceiveOvertime__c, NSP_Sample_of_current_GL_report__c, NSP_Select_all_that_apply__c, NSP_Semimonthly_Pay_Period__c, NSP_Service_team_notes__c, NSP_States_added_since_Kickoff_Meeting__c, NSP_SubaccountNeededDifferentPayPeriod__c, NSP_TimeZone__c, NSP_Type__c, NSP_Vision_Ongoing_CSP_cafeteria_Doc__c, NSP_Vision_Pretax_Delayed_Start__c, NSP_Vision_Pretax_Provide_Details__c, NSP_WC_Client_Cell_Phone__c, NSP_WC_Client_Contact_Method__c, NSP_WC_Client_Email__c, NSP_WC_Client_Name__c, NSP_WC_Client_Office_Phone__c, NSP_WC_contact_is_same_as_OSS__c,
                                                                                              NSP_Weekly_Pay_Period__c, NSP_What_is_the_Live_Payroll_Call_Date__c, NSP_Where_will_PTO_be_tracked__c, NSP_Work_Hours__c, NSP_co_employ_100_of_client_workforce__c, NSP_non_Insperity_paid_emps_contractors__c, Non_Discretionary_Bonus_Input_frequency__c, Non_exempt_EE_pay_freq_provide_details__c, Non_exempt_EEs_on_semi_monthly_pay_freq__c, Num_of_Worksite_Employees_Full_Time__c, Num_of_Worksite_Employees_Part_Time__c, Num_of_Worksite_Employees_Seasonal__c, OEE_OBE_Notes__c, NSP_Sr_HR_Specialist__c, NSP_Transition_Specialist__c, NSP_OT_Representative__c, Old_grp_health_plan_coverage_period_was__c, Old_plan_administrator_was_another_PEO__c, NSP_Onboarding_Specialist_Coordinator__c, Ongoing_CSP_cafeteria_plan_doc_has_been__c, Optum_Bank_HSA_Code__c, Optum_Bank_HSA_Group__c, NSP_Orientation_Coordinator__c, NSP_Orientation_Planner__c, Orientation_Rep__c, Other_Health_Plan_Coverage_Type__c, Other_expense_details__c, Other_payroll_details__c, Owner_aware_they_will_not_get_W2_wages__c, Owner_not_on_payroll_addendum_collected__c, PC_Client_Contact_Method__c, NSP_Form_Completed__c, NSP_Provide_Details_Enrollment_fee__c, PEO_Name__c, PTO_Types__c, Participants_on_COBRA_eligibility_period__c, Past_employees_crntly_getting_severance__c, Payroll_Notes__c, NSP_Payroll_Supervisor__c,
                                                                                              Payroll_general_notes__c, Payroll_submitted_frm_multiple_contacts__c, Post_tax_suppl_insurance_provide_details__c, Pre_tax_Client_Sponsored_Plan_CSP_Type__c, Previous_group_health_plan_administrator__c, Previous_group_health_plan_carrier_s__c, Previous_group_health_plan_coverage_type__c, Previous_group_plan_is_terminating__c, Prior_Benefits_Termination_Date__c, Provide_Details__c, Provide_EE_travel_details__c, Provide_PEO_Name__c, Provide_PTO_details__c, Provide_Urgent_HR_Needs_details__c, Provide_allowance_details__c, Provide_benefit_package_change_details__c, Provide_deadline_date__c, Provide_details_for_no_COBRA_employees__c, Provide_expense_details__c, Provide_live_check_details__c, Provide_multiple_contact_details__c, Provide_multiple_worksite_details__c, Provide_non_insperity_worker_details__c, Provide_organization_change_details__c, Provide_start_end_dates_of_plan_year__c, Recent_Payroll_Register_Collected__c, Remove_client_employee_directory__c, Retirement_services_notes__c, SCA_EEs_get_wages_in_lieu_of_benefits__c, SUI_Tax_rate_notice_s_collected__c, Sales_Office__c, Schedule_B_version__c, Select_BPSes__c, Select_all_payroll_needs_that_apply__c, Select_the_applicable_LOA_types__c, Semi_monthly_pay_freq_comply_w_state_law__c, Semi_monthly_pay_st_law_provide_details__c, Send_the_certificates_to__c,
                                                                                              Sole_Proprietorship_or_partnership__c, Spnsrd_pln_when_Insperity_hndles_payroll__c, Sponsored_plan_contribution_type__c, State_Unemployment_Insurance_SUI_Num__c, Tech_pack_when_where_quantity_needed__c, Time_Entry_Method__c, Told_EE_ineligble_for_active_at_work_ben__c, Type_of_retirement_plan_client_has_today__c, NSP_AIMS_ClientNo_Backup_PC__c, NSP_AIMS_ClientNo_HR__c, What_are_the_FSA_plan_dates__c, What_current_payroll_reports_being_used__c, What_is_the_status_of_the_LOA_info__c, What_time_zone_do_EEs_work__c, When_Client_Wants_Solution_implemented__c, When_are_certificates_needed__c, Where_to_mail_EE__c, Who_will_be_the_TimeStar_admin__c, Who_will_enter_time_worked__c, Wht_language_whn_is_translator_needed__c, Why_did_the_client_join_Insperity__c, Why_is_subaccount_needed__c, Will_the_BPA_s_Be_attending_the_SKO__c, Will_the_owner_s_be_on_payroll__c, Will_there_be_benefits_classing__c, Wnt_cpy_of_Insperity_EPLI_policy_cert__c, Work_week__c, classing_req_a_new_download_for_Subacc__c, client_terminated_old_benefit_coverage__c, prior_med_contributions_tht_Insperity__c, Any_Special_Agreements_Addendum_in_CSA__c, Any_exempt_part_time_employees__c, Are_all_of_the_rates_in_agreement__c, Are_sample_intro_letters_being_provided__c, Are_there_any_DOL_audits__c, Are_there_employes_working_in__c,
                                                                                              Basis_of_wage_payment_options__c, Client_business_in_MA_NY_or_VA__c, Client_covering_addl_paid_life_insurance__c, Client_does_pre_employment_drug_screen__c, Client_has_any_of_the_following__c, Client_interested_NSP_time_attendance__c, Client_is_interested_NSP_PTO_tracking__c, Client_needs_to_e_verify_all_employees__c, Client_previously_filed_an_EEO_1_Report__c, Client_provided_copy_of_communication__c, Client_submitting_apprvl_for_spreadsheet__c, Confirm_w_RS_when_each_step_is_completed__c, Current_onboarding_process_for_new_empl__c, DOL_Audit_Provide_Details__c, Direct_deposit_offered_to_employees__c, Discovery_Meeting_Date_Time_Location__c, Discussed_predecessor_hours_w_client__c, Docs_emp_need_to_complete_for_onboarding__c, Does_client_have_taxable_fringe_benefits__c, Does_client_perform_background_checks__c, EE_check_delivered_diff_place_than_work__c, EE_enrollments_outside_of_Insperity__c, Earned_Sick_Time_Start_Date__c, Employee_Enrollment__c, Employees_reside_in_these_service_areas__c, Employees_work_in_more_than_one_state__c, Exemption_status_of_all_empl_explained__c, Freq_of_collecting_medical_contribution__c, Gen_liability_auto_coverage_details__c, Have_EEs_been_notified_of_the_transition__c, How_are_empl_hrs_reported_to_Insperity__c, How_do_employees_currently_enroll__c,
                                                                                              How_will_enrollments_be_handled__c, How_will_the_payroll_be_funded__c, Human_Resources_Notes__c, Inspection_details__c, Insperity_Empl_contrib_rate_determined__c, Interested_in_on_site_safety_inspections__c, Is_current_medical_provider_UHC__c, Is_exempt_from_MN_Statute_177__c, Is_exempt_from_Minimum_Wage__c, Is_there_a_separate_Vacation_policy__c, Labor_Dist_Job_Costing_or_cert_payroll__c, Leave_Benefits__c, Meeting_Notes__c, Meeting_Participants__c, Must_show_FLSA_EE_exemp_cat_for_all_EEs__c, Need_for_departments_and_locations__c, No_live_check_provide_details__c, Non_active_non_paid_empl_w_benefits_cov__c, ORK_Team_notified_about_the_new_client__c, Onboarding_Notes__c, Other_Post_Tax_Deduction_Details__c, Other_standard_work_hours_details__c, Other_urgent_HR_needs_provide_details__c, Overtime_owed_after_how_many_hrs_worked__c, Paid_Sick_Leave_Plan_Type__c, Paid_Sick_Leave_requirement__c, Paid_sick_leave_exemption_reason__c, Part_time_employees_enrolled_in_benefits__c, NSP_RS_Doc_Contact_Info__c, Pre_Discovery_Notes__c, Previous_challenge_provide_details__c, Previous_challenges_w_current_provider__c, Reason_for_eligibility__c, Received_Enrollment_Fee__c, Received_Section_125_Questionnaire__c, Regulatory_accreditation_inspections__c,
                                                                                              Review_Employee_Orientations__c, Review_Insperity_Online_Enrollment_Steps__c, Reviewed_deductible_carryover_w_client__c, San_Diego_Earned_Sick__c, Select_all_enrollments__c, Select_client_urgent_HR_needs__c, Sep_doc_specifying_pay_breakdown__c, Sick_Leave_balance_type__c, Special_Agreement_Addendum_details__c, NSP_Sr_Onboarding_Benefit_Rep__c, Terming_life_insurance_disability_plan__c, Uses_WageWorks_for_commuter_benefit_plan__c, What_type_and_how_many_splits__c, When_was_the_handbook_last_updated__c, When_was_the_last_Open_Enrollment_period__c, Where_is_the_policy_located__c, Who_in_client_gets_std_insperity_comm__c, Who_is_the_current_custodian_bank__c, Who_is_the_provider__c, Workers_Comp_Safety_Notes__c, Written_doc_pay_plan_for_how_EE_is_paid__c, sample_new_empl_info_packet_collected__c, PC_Client_Number__c, Back_up_PC_Client_Number__c, Back_up_PC__c, Can_client_provide_EEO_filing_address__c, Checks_delivered__c, Documentation_Status__c, EE_Visa_Type__c, Emp_deferral_loan_amount__c, HR_Contact_Cell_Phone__c, HR_Contact_Office_Phone__c, Insperity_last_day_of_2nd_pay_period__c, Is_Insperity_s_group_health_plan_replaci__c, KDM_Client_Number__c, KDM__c, Misc_Contact_Cell_Phone__c, Misc_Contact_Number__c, Misc_Contact_Office_Phone__c, Misc_Contact__c,
                                                                                              NSP_AIMS_ClientNo__c, NSP_AIMS_Client_Name__c, NSP_Any_active_severance_agreement__c, NSP_Any_employee_with_temporary_status__c, NSP_Assignment_Notes__c, NSP_BPS_Notes__c, NSP_Client_Sponsored_Plan__c, NSP_Client_retaining_benefit_plan__c, NSP_Does_arrearage_comply_with_state_law__c, NSP_Does_the_client_have_prior_wages__c, NSP_EE_Name__c, NSP_Employee_Notes__c, NSP_Employee_with_compensation_other__c, NSP_FLSA_EE_exemption_category_provided__c, NSP_Final_pay_date_prior_to_Insperity__c, NSP_Final_pay_period_prior_to_Insperity__c, NSP_Frequency__c, NSP_Have_credit_services_approved__c, NSP_How_e_verify_be_completed__c, NSP_How_employee_hours_be_reported_to_I__c, NSP_How_hours_currently_captured__c, NSP_Immediate_payroll_needs_or_concerns__c, NSP_Inspeirty_last_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_2nd_pay_period__c, NSP_Insperity_1st_pay_date__c, NSP_Insperity_2nd_pay_date__c, NSP_Is_arrearage_7_days__c, NSP_Onsite_Safety_Inspection_Details__c, NSP_Other_Urgent_HR_Needs__c, NSP_Overtime_owed_after_hours__c, NSP_Payment_Details__c, NSP_Payroll_Specialist_to_confirm__c, NSP_Plan_for_EE_Payment__c, NSP_Project__c, NSP_Review_Cigna_Enrollment_Process__c, NSP_Separate_Vacation_Policy__c, NSP_Service_Model__c, NSP_Standard_No_of_Hours_worked_for_EEs__c, NSP_State_require_specific_priming_field__c,
                                                                                              NSP_Subaccount__c, NSP_Urgent_HR_Needs_Details__c, NSP_When_where_and_quantity_needed__c, NSP_Who_receives_Insperity_Communication__c, NSP_Who_will_approve_the_payroll__c, NSP_Who_will_submit_payroll__c, NSP_collected_copies_of_state_WC_policy__c,NSP_current_waiting_period__c, NSP_how_future_payment_will_be_done__c, NSP_prior_medical_contributions__c, NSP_remote_EEs_not_working_physical_loc__c, NSP_separate_pay_document_specify__c, WC__c, received_introductory_email_frm_ORK_Team__c, remove_employee_directory_from_premier__c, NSP_AIMS_ClientNo_KDM__c, NSP_AIMS_ClientNo_OSS__c, NSP_AIMS_ClientNo_PC__c, NSP_AIMS_ClientNo_WC__c, NSP_Benefit_Notes__c, NSP_Commission_Provide_Details__c, NSP_DoYouPay_Other_Provide_details__c, NSP_Non_paid_users_Enter_User_Names__c, NSP_compensation_structu_Provide_Details__c, NSP_Govt_Type_Other_Provide_Details__c, NSP_employee_40_hour_work_Week_PDetails__c, NSP_Any_OT_Expections_Provide_Details__c, NSP_PD_different_contact_for_subaccount__c, NSP_Provide_Details_Relabeling_Needed__c, NSP_Any_special_pay_code_Provide_Details__c, Insperity_pay_frequency__c,
                                                                                              NSP_Payroll_Specialist__r.NSP_Work_email__c,NSP_Asset__r.AccountId, NSP_Payroll_Specialist__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__r.Email,NSP_Urgent_Medical_Needs_Emp_Details__c, NSP_Employees_on_LOA__c,NSP_Employee_Details_On_LOA__c ,NSP_Old_Benefits_Package__c,NSP_Old_Effective_Date_EPLI__c,NSP_Old_Insperity_Ben_effective_date__c,NSP_OT_Representative__r.NSP_Work_email__c,Federal_Labor_Law_poster__c,NSP_HR_Specialist__c,Would_the_client_like_a_FLSA_Exemption__c FROM Implementation_Profile__c WHERE recordType.Name= 'Middle Market' LIMIT 1 ]);

        for(Implementation_Profile__c ip: ipRecordMap.values()){
            ip.NSP_Form_Completed__c = true;
            ip.Effective_Date_Payroll_Worker_comp_EPLI__c = system.today();
            ip.Wnt_cpy_of_Insperity_EPLI_policy_cert__c = NSP_ServiceConstants.YES ;
            ip.Client_maintaining_existing_EPLI_policy__c = NSP_ServiceConstants.YES;
            ip.Client_has_existing_retirement_plan__c ='Yes';
            ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.SIMPLEIRA;
            ip.Client_have_EEO_filing_under__c=NSP_ServiceConstants.YES ;
            ip.Can_client_provide_EEO_filing_address__c = NSP_ServiceConstants.YES;
            ip.EEO__c = 'Test';
            ip.Filing_address__c =  'Test';
            ip.NSP_co_employ_100_of_client_workforce__c = NSP_ServiceConstants.YES;
            ip.Client_part_of_entity_w_o_NSP__c = NSP_ServiceConstants.YES;
            ip.Is_the_client_a_federal_contractor__c = NSP_ServiceConstants.YES;
            ip.remove_employee_directory_from_premier__c = NSP_ServiceConstants.YES;
            ip.Would_the_client_like_a_FLSA_Exemption__c = NSP_ServiceConstants.No;
        }
        update  ipRecordMap.values();

        NSP_Implementationprofile_ServiceHelper helper = new NSP_Implementationprofile_ServiceHelper(ipRecordMap, new Map<Id, Implementation_Profile__c>());
        helper.isRerun = True;
        helper.executeAutomation();
        system.assertEquals( ipRecordMap.values()[0].Client_have_EEO_filing_under__c, NSP_ServiceConstants.YES);
        Test.StopTest();
    }

    @isTest
    private static void testMMRetirementServiceEmails() {
        Test.StartTest();
        NSP_Regulated_Area__c regArea =  [SELECT Id, NSP_State__c,  NSP_Regulation_Type__c  FROM NSP_Regulated_Area__c  WHERE NSP_State__c != null  AND NSP_Regulation_Type__c =: NSP_ServiceConstants.STATE_RET_PLAN];

        Map<Id,Implementation_Profile__c> ipRecordMap =new Map<Id,Implementation_Profile__c>([SELECT Id,NSP_COBRA_Takeover_Emp_Details__c,recordType.Name, OwnerId, Name,  RecordTypeId, Account__c, Addressee_for_each_worksite_location__c, All_EEs_paid_under_same_FEIN_currently__c, Allowances__c, Any_EEs_in_clients_waiting_period__c, Any_EEs_travel_internationally_for_work__c, Any_EEs_with_urgent_medical_needs__c, Any_employees_currently_enrolled__c, Any_employer_contributions_to_EE_HSA__c, Any_special_needs_for_EE_orientation__c, Any_users_who_cannot_see_salary__c, Arbitration_Agreement_been_discussed__c, Are_there_any_EEs_on_Leave_of_Absence__c, Are_there_any_non_paid_users__c, Are_there_multiple_worksite_locations__c, NSP_Documents_Collected_Leviesd__c,NSP_BPA_BPC__c,NSP_BPA_BPC_Ids__c,  NSP_Documents_garnishments__c, Benefit_effective_date_carry_from_tab_4__c, Benefits_Package__c, Brief_description_of_client__c, Business_Inception_Date__c, Can_client_show_EEO_filing_address__c, Carrier_notified_of_termination__c, Check_all_changes_that_apply__c, Check_all_sch_B_changes_that_apply__c, Check_all_tht_apply_ministers_teachers__c, Chngs_for_cafeteria_plan_questionnaire__c, Client_Address__c, Client_Contact_Notes__c, Client_FEIN__c, Client_Implementing_Premier_Performance__c, NSP_Client_Liaison__c,
                                                                                              Client_Name_del__c, Client_Number__c, Client_Profile_Information__c, Client_does_business_in_MA_NY_or_VA__c, Client_entity_owned_or_a_non_profit__c, Client_expect_chnges_in_the_organization__c, Client_has_Service_Contract_Act_SCA_EEs__c, Client_has_any_post_tax_deductions__c, Client_has_any_special_payroll_needs__c, Client_has_existing_retirement_plan__c, Client_have_EEO_filing_under__c, Client_have_any_Commission_only_EEs__c, Client_have_any_EEs_on_F1_or_J1_Visa_s__c, Client_have_any_EEs_that_work_in_NY__c, Client_have_any_urgent_HR_needs__c, Client_have_will_have_any_Seasonal_EEs__c, Client_interested_in_NSP_tracking_PTO__c, Client_internal_deadline_for_OEE_OBE__c, Client_is_making_employer_contributions__c, Client_maintain_own_FSA__c, Client_maintaining_existing_EPLI_policy__c, Client_part_of_entity_w_o_NSP__c, Client_runs_expenses_or_payroll__c, Client_s_previous_payroll_provider__c, Client_s_previous_waiting_period__c, Client_union_EE_Check_all_that_Apply__c, Client_utilizing_Insperity_s_TimeStar__c, Client_want_to_begin_401k_w_NSP_setup__c, Client_working_with_an_NSP_RS_rep__c, Contact_Information__c, Current_hours_tracking_method_infolet__c, DBA__c, Date_and_Time__c, Day_one_start__c, Did_the_sch_B_change_at_the_SKO__c, Do_any_EEs_have_garnishments__c, Do_any_EEs_have_tax_levies__c,
                                                                                              Do_you_have_the_LOA_information__c, Do_you_pay_non_exempt_employees__c, Does_client_employ_ministers_or_teachers__c, Does_client_have_any_Minor_EEs__c, Does_client_have_their_code_group_ID__c, Does_the_Cigna_takeover_apply_to_client__c, Does_the_client_currently_offer_a_FSA__c, Does_the_client_have_any_union_EEs__c, Does_the_client_offer_a_HSA__c, Does_the_client_offer_a_Stock_Purchase__c, Duration__c, EEO__c, EEO_name_phone_contact_email_for_info__c, EEs_to_punch_in_out_or_use_timesheet__c, Effective_Date_Payroll_Worker_comp_EPLI__c, Employee_Data_Collection_EDC_collected__c, Employees_currently_enrolled_in_FSA__c, Employees_work_in_the_following_states__c, Enter_non_paid_user_names__c, Enter_user_names_that_can_t_see_salary__c, Exempt_EEs_normal_of_hours_per_day__c, Expenses__c, FSA_Notes__c, Filing_address__c, First_Pay_Date__c, Form_8973_Contact__c, Gave_copy_of_PTO_sick_leave_other_policy__c, Gotten_Cvrg_Cert_Gen_Liability_Auto__c, NSP_Employee_Names_List_garnishments__c, NSP_List_Employee_Names_Levies__c, HR_Contact_Method__c, NSP_Account_Executive__c, NSP_OS_Coordinator__c, NSP_OT_Coordinator__c, NSP_HR_Quality_Support_Team_Member__c, HR_Specialist__c, HR_contact_is_same_as_OSS__c, Has_FEIN_documentation_been_collected__c, Has_FLSA_team_approved__c,
                                                                                              Has_expenses_allowances_through_payroll__c, Has_form_8973_been_discussed__c, Have_name_s_of_COBRA_takeovr_employees__c, Have_the_SCA_EEs_been_approved__c, Have_the_user_roles_been_updated_in_AIMS__c, Holiday_or_weekend_rule__c, How_will_EE_complete_their_enrollment__c, How_will_emp_deferral_loan_amnt__c, How_will_future_payments_be_made__c, Hush_Protocol__c, NSP_Immediate_need_for_Workers_Comp_Cert__c, Implementing_biz_Performance_solutions__c, Insperity_benefits_effective_date__c, Insperity_benefits_waiting_period__c, Insperity_grp_hlth_plan_replacing_prior__c, Is_client_s_current_HSA_with_Optum_Bank__c, Is_the_client_a_federal_contractor__c, Is_the_client_coming_from_another_PEO__c, Is_the_client_required_to_track__c, Is_there_a_need_for_a_GL_interface__c, Is_there_a_need_for_a_subaccount__c, Is_there_a_need_for_a_tech_package__c, Iss_translator_needed__c, NSP_OT_Planner__c, NSP_Orientation_Rep__c, Legal_Name__c, List_additional_FEIN_s__c, List_change_s__c, List_of_certificates_requested__c, Medical_Level__c, NSP_Payroll_Project_Manager__c, Misc_Contact_Contact_Method__c, NSP_Payroll_Specialist__c, NSP_Project_Manager__c, NSP_Sr_Benefit_Rep__c, Monthly_pay_freq_comply_w_state_laws__c, NA_cafeteria_doc_plan_provide_details__c, NSP_Anticipated_Growth_Plans_details__c,
                                                                                              NSP_Any_special_pay_codes_Needed__c, NSP_Are_Certified_Payroll_reports_needed__c, NSP_Are_the_subaccounts_set_up__c, NSP_Are_there_any_OT_exceptions__c, NSP_ArrearageInComplianceWithEachState__c, NSP_Asset__c, NSP_Back_up_Client_Cell_Phone__c, NSP_Back_up_Client_Contact_Method__c, NSP_Back_up_Client_Email__c, NSP_Back_up_Client_Office_Phone__c, NSP_Back_up_PC_Client_Name__c, NSP_Biweekly_Pay_Period__c, NSP_Business_Meeting_States__c, NSP_Chart_of_Accounts_GL_codes__c, NSP_CheckOnceYouDiscussEPAY_with_client__c, NSP_CheckToSendPayrollSpecialist_Summary__c, NSP_CheckToSendTheClient_Summary_email__c, NSP_Check_to_create_the_RRP_Case__c, NSP_ClientInterestedHavingAutoApproval__c, NSP_Client_s_holiday_calendar__c, NSP_Commission_Frequency__c, NSP_Commission_Type__c, NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c, NSP_DCFSA_Provide_details__c, NSP_Daily_Rate_approval_status__c, NSP_Dental_Ongoing_CSP_cafeteria_Doc__c, NSP_Dental_Pretax_Delayed_Start__c, NSP_Dental_Pretax_Provide_Details__c, NSP_Did_you_verify_Calendar_in_AIMS__c, NSP_Different_contact_for_subaccounts__c, NSP_Discretionary_Bonus_Input_Frequency__c, NSP_Discretionary_Bonus__c, NSP_Discussed_E_Verify_with_the_client__c, NSP_DoAIMSMatchAboveWorksite_information__c, NSP_DoTheEmployeeWorkA40HourWorkWeek__c, NSP_Do_you_have_GovernmentContracted_job__c,
                                                                                              NSP_Do_you_pay__c, NSP_Do_you_track_hours__c, NSP_Does_Client_have_Growth_Plans__c, NSP_Does_the_client_more_FEIN__c, NSP_Does_the_client_offer_Stock_Options__c, NSP_EEs_garnishments_details__c, NSP_Employee_Types__c, NSP_Employees_with_multiple_types_of_pay__c, NSP_Employer_contributions_details__c, NSP_Enter_Time_Entry_for_all_subaccounts__c, NSP_FormsAreNeededForFollowingDeduction__c, NSP_HCFSA_Delayed_Start_Date__c, NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c, NSP_HCFSA_Provide_Details__c, NSP_HSA_Ongoing_CSP_cafeteria_document__c, NSP_HSA_Provide_Details__c, NSP_Has_the_addendum_been_collected__c, NSP_Has_the_client_s_logo_been_collected__c, NSP_Health_Savings_Account_Delayed_Start__c, NSP_How_will_client_reimburse_expenses__c, NSP_Is_a_translator_needed__c, NSP_Is_there_an_Enrollment_fee__c, NSP_KDM_Client_Cell_Phone__c, NSP_KDM_Client_Contact_Method__c, NSP_KDM_Client_Email__c, NSP_KDM_Client_Name__c, NSP_KDM_Client_Office_Phone__c, NSP_List_BPS_Implementation_Timeframe__c, NSP_List_EEs_Names__c, NSP_List_Employee_Names__c, NSP_List_all_Default_Pay_Codes_in_AIMS__c, NSP_List_all_PTO_Codes__c, NSP_Medical_Ongoing_CSP_cafeteria_Doc__c, NSP_Medical_Pretax_Delayed_Start__c, NSP_Medical_Pretax_Provide_details__c, NSP_Monthly_Pay_Period__c, NSP_Name_of_accounting_software__c, NSP_No_back_up_PC__c,
                                                                                              NSP_NonDiscretionaryDiscretionaryPayCode__c, NSP_Non_Discretionary_Bonus__c, NSP_OSS_Client_Cell_Phone__c, NSP_OSS_Client_Contact_Method__c, NSP_OSS_Client_Email__c, NSP_OSS_Client_Name__c, NSP_OSS_Client_Office_Phone__c, NSP_OSS_contact_is_same_as_KDM__c, NSP_Office_Address__c, NSP_Orientation_Notes__c, NSP_PC_Client_Cell_Phone__c, NSP_PC_Client_Email__c, NSP_PC_Client_Name__c, NSP_PC_Client_Office_Phone__c, NSP_PC_is_same_as_OSS__c, NSP_PTO_Plan_Type__c, NSP_Payroll_Onboarding_Notes__c, NSP_Pre_SKO_Notes__c, NSP_Prepop_Timecards_w_Stndrd_hrs__c, NSP_Provide_Details__c, NSP_Provide_EEs_tax_levies_details__c, NSP_Provide_Monthly_pay_frequency_detail__c, NSP_Provide_Schedule_B_details__c, NSP_Provide_Tracking_details__c, NSP_Provide_previous_coverage_details__c, NSP_RS_Contact__c, NSP_SalaryExemptEmployeeReceiveOvertime__c, NSP_Sample_of_current_GL_report__c, NSP_Select_all_that_apply__c, NSP_Semimonthly_Pay_Period__c, NSP_Service_team_notes__c, NSP_States_added_since_Kickoff_Meeting__c, NSP_SubaccountNeededDifferentPayPeriod__c, NSP_TimeZone__c, NSP_Type__c, NSP_Vision_Ongoing_CSP_cafeteria_Doc__c, NSP_Vision_Pretax_Delayed_Start__c, NSP_Vision_Pretax_Provide_Details__c, NSP_WC_Client_Cell_Phone__c, NSP_WC_Client_Contact_Method__c, NSP_WC_Client_Email__c, NSP_WC_Client_Name__c, NSP_WC_Client_Office_Phone__c, NSP_WC_contact_is_same_as_OSS__c,
                                                                                              NSP_Weekly_Pay_Period__c, NSP_What_is_the_Live_Payroll_Call_Date__c, NSP_Where_will_PTO_be_tracked__c, NSP_Work_Hours__c, NSP_co_employ_100_of_client_workforce__c, NSP_non_Insperity_paid_emps_contractors__c, Non_Discretionary_Bonus_Input_frequency__c, Non_exempt_EE_pay_freq_provide_details__c, Non_exempt_EEs_on_semi_monthly_pay_freq__c, Num_of_Worksite_Employees_Full_Time__c, Num_of_Worksite_Employees_Part_Time__c, Num_of_Worksite_Employees_Seasonal__c, OEE_OBE_Notes__c, NSP_Sr_HR_Specialist__c, NSP_Transition_Specialist__c, NSP_OT_Representative__c, Old_grp_health_plan_coverage_period_was__c, Old_plan_administrator_was_another_PEO__c, NSP_Onboarding_Specialist_Coordinator__c, Ongoing_CSP_cafeteria_plan_doc_has_been__c, Optum_Bank_HSA_Code__c, Optum_Bank_HSA_Group__c, NSP_Orientation_Coordinator__c, NSP_Orientation_Planner__c, Orientation_Rep__c, Other_Health_Plan_Coverage_Type__c, Other_expense_details__c, Other_payroll_details__c, Owner_aware_they_will_not_get_W2_wages__c, Owner_not_on_payroll_addendum_collected__c, PC_Client_Contact_Method__c, NSP_Form_Completed__c, NSP_Provide_Details_Enrollment_fee__c, PEO_Name__c, PTO_Types__c, Participants_on_COBRA_eligibility_period__c, Past_employees_crntly_getting_severance__c, Payroll_Notes__c, NSP_Payroll_Supervisor__c,
                                                                                              Payroll_general_notes__c, Payroll_submitted_frm_multiple_contacts__c, Post_tax_suppl_insurance_provide_details__c, Pre_tax_Client_Sponsored_Plan_CSP_Type__c, Previous_group_health_plan_administrator__c, Previous_group_health_plan_carrier_s__c, Previous_group_health_plan_coverage_type__c, Previous_group_plan_is_terminating__c, Prior_Benefits_Termination_Date__c, Provide_Details__c, Provide_EE_travel_details__c, Provide_PEO_Name__c, Provide_PTO_details__c, Provide_Urgent_HR_Needs_details__c, Provide_allowance_details__c, Provide_benefit_package_change_details__c, Provide_deadline_date__c, Provide_details_for_no_COBRA_employees__c, Provide_expense_details__c, Provide_live_check_details__c, Provide_multiple_contact_details__c, Provide_multiple_worksite_details__c, Provide_non_insperity_worker_details__c, Provide_organization_change_details__c, Provide_start_end_dates_of_plan_year__c, Recent_Payroll_Register_Collected__c, Remove_client_employee_directory__c, Retirement_services_notes__c, SCA_EEs_get_wages_in_lieu_of_benefits__c, SUI_Tax_rate_notice_s_collected__c, Sales_Office__c, Schedule_B_version__c, Select_BPSes__c, Select_all_payroll_needs_that_apply__c, Select_the_applicable_LOA_types__c, Semi_monthly_pay_freq_comply_w_state_law__c, Semi_monthly_pay_st_law_provide_details__c, Send_the_certificates_to__c,
                                                                                              Sole_Proprietorship_or_partnership__c, Spnsrd_pln_when_Insperity_hndles_payroll__c, Sponsored_plan_contribution_type__c, State_Unemployment_Insurance_SUI_Num__c, Tech_pack_when_where_quantity_needed__c, Time_Entry_Method__c, Told_EE_ineligble_for_active_at_work_ben__c, Type_of_retirement_plan_client_has_today__c, NSP_AIMS_ClientNo_Backup_PC__c, NSP_AIMS_ClientNo_HR__c, What_are_the_FSA_plan_dates__c, What_current_payroll_reports_being_used__c, What_is_the_status_of_the_LOA_info__c, What_time_zone_do_EEs_work__c, When_Client_Wants_Solution_implemented__c, When_are_certificates_needed__c, Where_to_mail_EE__c, Who_will_be_the_TimeStar_admin__c, Who_will_enter_time_worked__c, Wht_language_whn_is_translator_needed__c, Why_did_the_client_join_Insperity__c, Why_is_subaccount_needed__c, Will_the_BPA_s_Be_attending_the_SKO__c, Will_the_owner_s_be_on_payroll__c, Will_there_be_benefits_classing__c, Wnt_cpy_of_Insperity_EPLI_policy_cert__c, Work_week__c, classing_req_a_new_download_for_Subacc__c, client_terminated_old_benefit_coverage__c, prior_med_contributions_tht_Insperity__c, Any_Special_Agreements_Addendum_in_CSA__c, Any_exempt_part_time_employees__c, Are_all_of_the_rates_in_agreement__c, Are_sample_intro_letters_being_provided__c, Are_there_any_DOL_audits__c, Are_there_employes_working_in__c,
                                                                                              Basis_of_wage_payment_options__c, Client_business_in_MA_NY_or_VA__c, Client_covering_addl_paid_life_insurance__c, Client_does_pre_employment_drug_screen__c, Client_has_any_of_the_following__c, Client_interested_NSP_time_attendance__c, Client_is_interested_NSP_PTO_tracking__c, Client_needs_to_e_verify_all_employees__c, Client_previously_filed_an_EEO_1_Report__c, Client_provided_copy_of_communication__c, Client_submitting_apprvl_for_spreadsheet__c, Confirm_w_RS_when_each_step_is_completed__c, Current_onboarding_process_for_new_empl__c, DOL_Audit_Provide_Details__c, Direct_deposit_offered_to_employees__c, Discovery_Meeting_Date_Time_Location__c, Discussed_predecessor_hours_w_client__c, Docs_emp_need_to_complete_for_onboarding__c, Does_client_have_taxable_fringe_benefits__c, Does_client_perform_background_checks__c, EE_check_delivered_diff_place_than_work__c, EE_enrollments_outside_of_Insperity__c, Earned_Sick_Time_Start_Date__c, Employee_Enrollment__c, Employees_reside_in_these_service_areas__c, Employees_work_in_more_than_one_state__c, Exemption_status_of_all_empl_explained__c, Freq_of_collecting_medical_contribution__c, Gen_liability_auto_coverage_details__c, Have_EEs_been_notified_of_the_transition__c, How_are_empl_hrs_reported_to_Insperity__c, How_do_employees_currently_enroll__c,
                                                                                              How_will_enrollments_be_handled__c, How_will_the_payroll_be_funded__c, Human_Resources_Notes__c, Inspection_details__c, Insperity_Empl_contrib_rate_determined__c, Interested_in_on_site_safety_inspections__c, Is_current_medical_provider_UHC__c, Is_exempt_from_MN_Statute_177__c, Is_exempt_from_Minimum_Wage__c, Is_there_a_separate_Vacation_policy__c, Labor_Dist_Job_Costing_or_cert_payroll__c, Leave_Benefits__c, Meeting_Notes__c, Meeting_Participants__c, Must_show_FLSA_EE_exemp_cat_for_all_EEs__c, Need_for_departments_and_locations__c, No_live_check_provide_details__c, Non_active_non_paid_empl_w_benefits_cov__c, ORK_Team_notified_about_the_new_client__c, Onboarding_Notes__c, Other_Post_Tax_Deduction_Details__c, Other_standard_work_hours_details__c, Other_urgent_HR_needs_provide_details__c, Overtime_owed_after_how_many_hrs_worked__c, Paid_Sick_Leave_Plan_Type__c, Paid_Sick_Leave_requirement__c, Paid_sick_leave_exemption_reason__c, Part_time_employees_enrolled_in_benefits__c, NSP_RS_Doc_Contact_Info__c, Pre_Discovery_Notes__c, Previous_challenge_provide_details__c, Previous_challenges_w_current_provider__c, Reason_for_eligibility__c, Received_Enrollment_Fee__c, Received_Section_125_Questionnaire__c, Regulatory_accreditation_inspections__c,
                                                                                              Review_Employee_Orientations__c, Review_Insperity_Online_Enrollment_Steps__c, Reviewed_deductible_carryover_w_client__c, San_Diego_Earned_Sick__c, Select_all_enrollments__c, Select_client_urgent_HR_needs__c, Sep_doc_specifying_pay_breakdown__c, Sick_Leave_balance_type__c, Special_Agreement_Addendum_details__c, NSP_Sr_Onboarding_Benefit_Rep__c, Terming_life_insurance_disability_plan__c, Uses_WageWorks_for_commuter_benefit_plan__c, What_type_and_how_many_splits__c, When_was_the_handbook_last_updated__c, When_was_the_last_Open_Enrollment_period__c, Where_is_the_policy_located__c, Who_in_client_gets_std_insperity_comm__c, Who_is_the_current_custodian_bank__c, Who_is_the_provider__c, Workers_Comp_Safety_Notes__c, Written_doc_pay_plan_for_how_EE_is_paid__c, sample_new_empl_info_packet_collected__c, PC_Client_Number__c, Back_up_PC_Client_Number__c, Back_up_PC__c, Can_client_provide_EEO_filing_address__c, Checks_delivered__c, Documentation_Status__c, EE_Visa_Type__c, Emp_deferral_loan_amount__c, HR_Contact_Cell_Phone__c, HR_Contact_Office_Phone__c, Insperity_last_day_of_2nd_pay_period__c, Is_Insperity_s_group_health_plan_replaci__c, KDM_Client_Number__c, KDM__c, Misc_Contact_Cell_Phone__c, Misc_Contact_Number__c, Misc_Contact_Office_Phone__c, Misc_Contact__c,
                                                                                              NSP_AIMS_ClientNo__c, NSP_AIMS_Client_Name__c, NSP_Any_active_severance_agreement__c, NSP_Any_employee_with_temporary_status__c, NSP_Assignment_Notes__c, NSP_BPS_Notes__c, NSP_Client_Sponsored_Plan__c, NSP_Client_retaining_benefit_plan__c, NSP_Does_arrearage_comply_with_state_law__c, NSP_Does_the_client_have_prior_wages__c, NSP_EE_Name__c, NSP_Employee_Notes__c, NSP_Employee_with_compensation_other__c, NSP_FLSA_EE_exemption_category_provided__c, NSP_Final_pay_date_prior_to_Insperity__c, NSP_Final_pay_period_prior_to_Insperity__c, NSP_Frequency__c, NSP_Have_credit_services_approved__c, NSP_How_e_verify_be_completed__c, NSP_How_employee_hours_be_reported_to_I__c, NSP_How_hours_currently_captured__c, NSP_Immediate_payroll_needs_or_concerns__c, NSP_Inspeirty_last_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_2nd_pay_period__c, NSP_Insperity_1st_pay_date__c, NSP_Insperity_2nd_pay_date__c, NSP_Is_arrearage_7_days__c, NSP_Onsite_Safety_Inspection_Details__c, NSP_Other_Urgent_HR_Needs__c, NSP_Overtime_owed_after_hours__c, NSP_Payment_Details__c, NSP_Payroll_Specialist_to_confirm__c, NSP_Plan_for_EE_Payment__c, NSP_Project__c, NSP_Review_Cigna_Enrollment_Process__c, NSP_Separate_Vacation_Policy__c, NSP_Service_Model__c, NSP_Standard_No_of_Hours_worked_for_EEs__c, NSP_State_require_specific_priming_field__c,
                                                                                              NSP_Subaccount__c, NSP_Urgent_HR_Needs_Details__c, NSP_When_where_and_quantity_needed__c, NSP_Who_receives_Insperity_Communication__c, NSP_Who_will_approve_the_payroll__c, NSP_Who_will_submit_payroll__c, NSP_collected_copies_of_state_WC_policy__c,NSP_current_waiting_period__c, NSP_how_future_payment_will_be_done__c, NSP_prior_medical_contributions__c, NSP_remote_EEs_not_working_physical_loc__c, NSP_separate_pay_document_specify__c, WC__c, received_introductory_email_frm_ORK_Team__c, remove_employee_directory_from_premier__c, NSP_AIMS_ClientNo_KDM__c, NSP_AIMS_ClientNo_OSS__c, NSP_AIMS_ClientNo_PC__c, NSP_AIMS_ClientNo_WC__c, NSP_Benefit_Notes__c, NSP_Commission_Provide_Details__c, NSP_DoYouPay_Other_Provide_details__c, NSP_Non_paid_users_Enter_User_Names__c, NSP_compensation_structu_Provide_Details__c, NSP_Govt_Type_Other_Provide_Details__c, NSP_employee_40_hour_work_Week_PDetails__c, NSP_Any_OT_Expections_Provide_Details__c, NSP_PD_different_contact_for_subaccount__c, NSP_Provide_Details_Relabeling_Needed__c, NSP_Any_special_pay_code_Provide_Details__c, Insperity_pay_frequency__c,
                                                                                              NSP_Payroll_Specialist__r.NSP_Work_email__c,NSP_Asset__r.AccountId, NSP_Payroll_Specialist__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__r.Email,NSP_Urgent_Medical_Needs_Emp_Details__c, NSP_Employees_on_LOA__c,NSP_Employee_Details_On_LOA__c ,NSP_Old_Benefits_Package__c,NSP_Old_Effective_Date_EPLI__c,NSP_Old_Insperity_Ben_effective_date__c,NSP_OT_Representative__r.NSP_Work_email__c,Federal_Labor_Law_poster__c FROM Implementation_Profile__c WHERE recordType.Name= 'Middle Market' LIMIT 1 ]);

        for(Implementation_Profile__c ip: ipRecordMap.values()){
            ip.NSP_Form_Completed__c = true;
            ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.NO;
            ip.Client_want_to_begin_401k_w_NSP_setup__c = NSP_ServiceConstants.NO ;
            ip.Employees_work_in_the_following_states__c = 'MA';
        }
        update  ipRecordMap.values();

        NSP_Implementationprofile_ServiceHelper helper = new NSP_Implementationprofile_ServiceHelper(ipRecordMap, new Map<Id, Implementation_Profile__c>());
        helper.isRerun = True;
        helper.executeAutomation();
        system.assertEquals( ipRecordMap.values()[0].Filing_address__c, 'Test');
        Test.StopTest();
    }

    @isTest
    private static void testMMRetirementEmails() {
        Test.StartTest();
        NSP_Regulated_Area__c regArea =  [SELECT Id, NSP_State__c,  NSP_Regulation_Type__c  FROM NSP_Regulated_Area__c  WHERE NSP_State__c != null  AND NSP_Regulation_Type__c =: NSP_ServiceConstants.STATE_RET_PLAN];

        Map<Id,Implementation_Profile__c> ipRecordMap =new Map<Id,Implementation_Profile__c>([SELECT Id,NSP_COBRA_Takeover_Emp_Details__c,recordType.Name, OwnerId, Name,  RecordTypeId, Account__c, Addressee_for_each_worksite_location__c, All_EEs_paid_under_same_FEIN_currently__c, Allowances__c, Any_EEs_in_clients_waiting_period__c, Any_EEs_travel_internationally_for_work__c, Any_EEs_with_urgent_medical_needs__c, Any_employees_currently_enrolled__c, Any_employer_contributions_to_EE_HSA__c, Any_special_needs_for_EE_orientation__c, Any_users_who_cannot_see_salary__c, Arbitration_Agreement_been_discussed__c, Are_there_any_EEs_on_Leave_of_Absence__c, Are_there_any_non_paid_users__c, Are_there_multiple_worksite_locations__c, NSP_Documents_Collected_Leviesd__c,NSP_BPA_BPC__c,NSP_BPA_BPC_Ids__c,  NSP_Documents_garnishments__c, Benefit_effective_date_carry_from_tab_4__c, Benefits_Package__c, Brief_description_of_client__c, Business_Inception_Date__c, Can_client_show_EEO_filing_address__c, Carrier_notified_of_termination__c, Check_all_changes_that_apply__c, Check_all_sch_B_changes_that_apply__c, Check_all_tht_apply_ministers_teachers__c, Chngs_for_cafeteria_plan_questionnaire__c, Client_Address__c, Client_Contact_Notes__c, Client_FEIN__c, Client_Implementing_Premier_Performance__c, NSP_Client_Liaison__c,
                                                                                              Client_Name_del__c, Client_Number__c, Client_Profile_Information__c, Client_does_business_in_MA_NY_or_VA__c, Client_entity_owned_or_a_non_profit__c, Client_expect_chnges_in_the_organization__c, Client_has_Service_Contract_Act_SCA_EEs__c, Client_has_any_post_tax_deductions__c, Client_has_any_special_payroll_needs__c, Client_has_existing_retirement_plan__c, Client_have_EEO_filing_under__c, Client_have_any_Commission_only_EEs__c, Client_have_any_EEs_on_F1_or_J1_Visa_s__c, Client_have_any_EEs_that_work_in_NY__c, Client_have_any_urgent_HR_needs__c, Client_have_will_have_any_Seasonal_EEs__c, Client_interested_in_NSP_tracking_PTO__c, Client_internal_deadline_for_OEE_OBE__c, Client_is_making_employer_contributions__c, Client_maintain_own_FSA__c, Client_maintaining_existing_EPLI_policy__c, Client_part_of_entity_w_o_NSP__c, Client_runs_expenses_or_payroll__c, Client_s_previous_payroll_provider__c, Client_s_previous_waiting_period__c, Client_union_EE_Check_all_that_Apply__c, Client_utilizing_Insperity_s_TimeStar__c, Client_want_to_begin_401k_w_NSP_setup__c, Client_working_with_an_NSP_RS_rep__c, Contact_Information__c, Current_hours_tracking_method_infolet__c, DBA__c, Date_and_Time__c, Day_one_start__c, Did_the_sch_B_change_at_the_SKO__c, Do_any_EEs_have_garnishments__c, Do_any_EEs_have_tax_levies__c,
                                                                                              Do_you_have_the_LOA_information__c, Do_you_pay_non_exempt_employees__c, Does_client_employ_ministers_or_teachers__c, Does_client_have_any_Minor_EEs__c, Does_client_have_their_code_group_ID__c, Does_the_Cigna_takeover_apply_to_client__c, Does_the_client_currently_offer_a_FSA__c, Does_the_client_have_any_union_EEs__c, Does_the_client_offer_a_HSA__c, Does_the_client_offer_a_Stock_Purchase__c, Duration__c, EEO__c, EEO_name_phone_contact_email_for_info__c, EEs_to_punch_in_out_or_use_timesheet__c, Effective_Date_Payroll_Worker_comp_EPLI__c, Employee_Data_Collection_EDC_collected__c, Employees_currently_enrolled_in_FSA__c, Employees_work_in_the_following_states__c, Enter_non_paid_user_names__c, Enter_user_names_that_can_t_see_salary__c, Exempt_EEs_normal_of_hours_per_day__c, Expenses__c, FSA_Notes__c, Filing_address__c, First_Pay_Date__c, Form_8973_Contact__c, Gave_copy_of_PTO_sick_leave_other_policy__c, Gotten_Cvrg_Cert_Gen_Liability_Auto__c, NSP_Employee_Names_List_garnishments__c, NSP_List_Employee_Names_Levies__c, HR_Contact_Method__c, NSP_Account_Executive__c, NSP_OS_Coordinator__c, NSP_OT_Coordinator__c, NSP_HR_Quality_Support_Team_Member__c, HR_Specialist__c, HR_contact_is_same_as_OSS__c, Has_FEIN_documentation_been_collected__c, Has_FLSA_team_approved__c,
                                                                                              Has_expenses_allowances_through_payroll__c, Has_form_8973_been_discussed__c, Have_name_s_of_COBRA_takeovr_employees__c, Have_the_SCA_EEs_been_approved__c, Have_the_user_roles_been_updated_in_AIMS__c, Holiday_or_weekend_rule__c, How_will_EE_complete_their_enrollment__c, How_will_emp_deferral_loan_amnt__c, How_will_future_payments_be_made__c, Hush_Protocol__c, NSP_Immediate_need_for_Workers_Comp_Cert__c, Implementing_biz_Performance_solutions__c, Insperity_benefits_effective_date__c, Insperity_benefits_waiting_period__c, Insperity_grp_hlth_plan_replacing_prior__c, Is_client_s_current_HSA_with_Optum_Bank__c, Is_the_client_a_federal_contractor__c, Is_the_client_coming_from_another_PEO__c, Is_the_client_required_to_track__c, Is_there_a_need_for_a_GL_interface__c, Is_there_a_need_for_a_subaccount__c, Is_there_a_need_for_a_tech_package__c, Iss_translator_needed__c, NSP_OT_Planner__c, NSP_Orientation_Rep__c, Legal_Name__c, List_additional_FEIN_s__c, List_change_s__c, List_of_certificates_requested__c, Medical_Level__c, NSP_Payroll_Project_Manager__c, Misc_Contact_Contact_Method__c, NSP_Payroll_Specialist__c, NSP_Project_Manager__c, NSP_Sr_Benefit_Rep__c, Monthly_pay_freq_comply_w_state_laws__c, NA_cafeteria_doc_plan_provide_details__c, NSP_Anticipated_Growth_Plans_details__c,
                                                                                              NSP_Any_special_pay_codes_Needed__c, NSP_Are_Certified_Payroll_reports_needed__c, NSP_Are_the_subaccounts_set_up__c, NSP_Are_there_any_OT_exceptions__c, NSP_ArrearageInComplianceWithEachState__c, NSP_Asset__c, NSP_Back_up_Client_Cell_Phone__c, NSP_Back_up_Client_Contact_Method__c, NSP_Back_up_Client_Email__c, NSP_Back_up_Client_Office_Phone__c, NSP_Back_up_PC_Client_Name__c, NSP_Biweekly_Pay_Period__c, NSP_Business_Meeting_States__c, NSP_Chart_of_Accounts_GL_codes__c, NSP_CheckOnceYouDiscussEPAY_with_client__c, NSP_CheckToSendPayrollSpecialist_Summary__c, NSP_CheckToSendTheClient_Summary_email__c, NSP_Check_to_create_the_RRP_Case__c, NSP_ClientInterestedHavingAutoApproval__c, NSP_Client_s_holiday_calendar__c, NSP_Commission_Frequency__c, NSP_Commission_Type__c, NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c, NSP_DCFSA_Provide_details__c, NSP_Daily_Rate_approval_status__c, NSP_Dental_Ongoing_CSP_cafeteria_Doc__c, NSP_Dental_Pretax_Delayed_Start__c, NSP_Dental_Pretax_Provide_Details__c, NSP_Did_you_verify_Calendar_in_AIMS__c, NSP_Different_contact_for_subaccounts__c, NSP_Discretionary_Bonus_Input_Frequency__c, NSP_Discretionary_Bonus__c, NSP_Discussed_E_Verify_with_the_client__c, NSP_DoAIMSMatchAboveWorksite_information__c, NSP_DoTheEmployeeWorkA40HourWorkWeek__c, NSP_Do_you_have_GovernmentContracted_job__c,
                                                                                              NSP_Do_you_pay__c, NSP_Do_you_track_hours__c, NSP_Does_Client_have_Growth_Plans__c, NSP_Does_the_client_more_FEIN__c, NSP_Does_the_client_offer_Stock_Options__c, NSP_EEs_garnishments_details__c, NSP_Employee_Types__c, NSP_Employees_with_multiple_types_of_pay__c, NSP_Employer_contributions_details__c, NSP_Enter_Time_Entry_for_all_subaccounts__c, NSP_FormsAreNeededForFollowingDeduction__c, NSP_HCFSA_Delayed_Start_Date__c, NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c, NSP_HCFSA_Provide_Details__c, NSP_HSA_Ongoing_CSP_cafeteria_document__c, NSP_HSA_Provide_Details__c, NSP_Has_the_addendum_been_collected__c, NSP_Has_the_client_s_logo_been_collected__c, NSP_Health_Savings_Account_Delayed_Start__c, NSP_How_will_client_reimburse_expenses__c, NSP_Is_a_translator_needed__c, NSP_Is_there_an_Enrollment_fee__c, NSP_KDM_Client_Cell_Phone__c, NSP_KDM_Client_Contact_Method__c, NSP_KDM_Client_Email__c, NSP_KDM_Client_Name__c, NSP_KDM_Client_Office_Phone__c, NSP_List_BPS_Implementation_Timeframe__c, NSP_List_EEs_Names__c, NSP_List_Employee_Names__c, NSP_List_all_Default_Pay_Codes_in_AIMS__c, NSP_List_all_PTO_Codes__c, NSP_Medical_Ongoing_CSP_cafeteria_Doc__c, NSP_Medical_Pretax_Delayed_Start__c, NSP_Medical_Pretax_Provide_details__c, NSP_Monthly_Pay_Period__c, NSP_Name_of_accounting_software__c, NSP_No_back_up_PC__c,
                                                                                              NSP_NonDiscretionaryDiscretionaryPayCode__c, NSP_Non_Discretionary_Bonus__c, NSP_OSS_Client_Cell_Phone__c, NSP_OSS_Client_Contact_Method__c, NSP_OSS_Client_Email__c, NSP_OSS_Client_Name__c, NSP_OSS_Client_Office_Phone__c, NSP_OSS_contact_is_same_as_KDM__c, NSP_Office_Address__c, NSP_Orientation_Notes__c, NSP_PC_Client_Cell_Phone__c, NSP_PC_Client_Email__c, NSP_PC_Client_Name__c, NSP_PC_Client_Office_Phone__c, NSP_PC_is_same_as_OSS__c, NSP_PTO_Plan_Type__c, NSP_Payroll_Onboarding_Notes__c, NSP_Pre_SKO_Notes__c, NSP_Prepop_Timecards_w_Stndrd_hrs__c, NSP_Provide_Details__c, NSP_Provide_EEs_tax_levies_details__c, NSP_Provide_Monthly_pay_frequency_detail__c, NSP_Provide_Schedule_B_details__c, NSP_Provide_Tracking_details__c, NSP_Provide_previous_coverage_details__c, NSP_RS_Contact__c, NSP_SalaryExemptEmployeeReceiveOvertime__c, NSP_Sample_of_current_GL_report__c, NSP_Select_all_that_apply__c, NSP_Semimonthly_Pay_Period__c, NSP_Service_team_notes__c, NSP_States_added_since_Kickoff_Meeting__c, NSP_SubaccountNeededDifferentPayPeriod__c, NSP_TimeZone__c, NSP_Type__c, NSP_Vision_Ongoing_CSP_cafeteria_Doc__c, NSP_Vision_Pretax_Delayed_Start__c, NSP_Vision_Pretax_Provide_Details__c, NSP_WC_Client_Cell_Phone__c, NSP_WC_Client_Contact_Method__c, NSP_WC_Client_Email__c, NSP_WC_Client_Name__c, NSP_WC_Client_Office_Phone__c, NSP_WC_contact_is_same_as_OSS__c,
                                                                                              NSP_Weekly_Pay_Period__c, NSP_What_is_the_Live_Payroll_Call_Date__c, NSP_Where_will_PTO_be_tracked__c, NSP_Work_Hours__c, NSP_co_employ_100_of_client_workforce__c, NSP_non_Insperity_paid_emps_contractors__c, Non_Discretionary_Bonus_Input_frequency__c, Non_exempt_EE_pay_freq_provide_details__c, Non_exempt_EEs_on_semi_monthly_pay_freq__c, Num_of_Worksite_Employees_Full_Time__c, Num_of_Worksite_Employees_Part_Time__c, Num_of_Worksite_Employees_Seasonal__c, OEE_OBE_Notes__c, NSP_Sr_HR_Specialist__c, NSP_Transition_Specialist__c, NSP_OT_Representative__c, Old_grp_health_plan_coverage_period_was__c, Old_plan_administrator_was_another_PEO__c, NSP_Onboarding_Specialist_Coordinator__c, Ongoing_CSP_cafeteria_plan_doc_has_been__c, Optum_Bank_HSA_Code__c, Optum_Bank_HSA_Group__c, NSP_Orientation_Coordinator__c, NSP_Orientation_Planner__c, Orientation_Rep__c, Other_Health_Plan_Coverage_Type__c, Other_expense_details__c, Other_payroll_details__c, Owner_aware_they_will_not_get_W2_wages__c, Owner_not_on_payroll_addendum_collected__c, PC_Client_Contact_Method__c, NSP_Form_Completed__c, NSP_Provide_Details_Enrollment_fee__c, PEO_Name__c, PTO_Types__c, Participants_on_COBRA_eligibility_period__c, Past_employees_crntly_getting_severance__c, Payroll_Notes__c, NSP_Payroll_Supervisor__c,
                                                                                              Payroll_general_notes__c, Payroll_submitted_frm_multiple_contacts__c, Post_tax_suppl_insurance_provide_details__c, Pre_tax_Client_Sponsored_Plan_CSP_Type__c, Previous_group_health_plan_administrator__c, Previous_group_health_plan_carrier_s__c, Previous_group_health_plan_coverage_type__c, Previous_group_plan_is_terminating__c, Prior_Benefits_Termination_Date__c, Provide_Details__c, Provide_EE_travel_details__c, Provide_PEO_Name__c, Provide_PTO_details__c, Provide_Urgent_HR_Needs_details__c, Provide_allowance_details__c, Provide_benefit_package_change_details__c, Provide_deadline_date__c, Provide_details_for_no_COBRA_employees__c, Provide_expense_details__c, Provide_live_check_details__c, Provide_multiple_contact_details__c, Provide_multiple_worksite_details__c, Provide_non_insperity_worker_details__c, Provide_organization_change_details__c, Provide_start_end_dates_of_plan_year__c, Recent_Payroll_Register_Collected__c, Remove_client_employee_directory__c, Retirement_services_notes__c, SCA_EEs_get_wages_in_lieu_of_benefits__c, SUI_Tax_rate_notice_s_collected__c, Sales_Office__c, Schedule_B_version__c, Select_BPSes__c, Select_all_payroll_needs_that_apply__c, Select_the_applicable_LOA_types__c, Semi_monthly_pay_freq_comply_w_state_law__c, Semi_monthly_pay_st_law_provide_details__c, Send_the_certificates_to__c,
                                                                                              Sole_Proprietorship_or_partnership__c, Spnsrd_pln_when_Insperity_hndles_payroll__c, Sponsored_plan_contribution_type__c, State_Unemployment_Insurance_SUI_Num__c, Tech_pack_when_where_quantity_needed__c, Time_Entry_Method__c, Told_EE_ineligble_for_active_at_work_ben__c, Type_of_retirement_plan_client_has_today__c, NSP_AIMS_ClientNo_Backup_PC__c, NSP_AIMS_ClientNo_HR__c, What_are_the_FSA_plan_dates__c, What_current_payroll_reports_being_used__c, What_is_the_status_of_the_LOA_info__c, What_time_zone_do_EEs_work__c, When_Client_Wants_Solution_implemented__c, When_are_certificates_needed__c, Where_to_mail_EE__c, Who_will_be_the_TimeStar_admin__c, Who_will_enter_time_worked__c, Wht_language_whn_is_translator_needed__c, Why_did_the_client_join_Insperity__c, Why_is_subaccount_needed__c, Will_the_BPA_s_Be_attending_the_SKO__c, Will_the_owner_s_be_on_payroll__c, Will_there_be_benefits_classing__c, Wnt_cpy_of_Insperity_EPLI_policy_cert__c, Work_week__c, classing_req_a_new_download_for_Subacc__c, client_terminated_old_benefit_coverage__c, prior_med_contributions_tht_Insperity__c, Any_Special_Agreements_Addendum_in_CSA__c, Any_exempt_part_time_employees__c, Are_all_of_the_rates_in_agreement__c, Are_sample_intro_letters_being_provided__c, Are_there_any_DOL_audits__c, Are_there_employes_working_in__c,
                                                                                              Basis_of_wage_payment_options__c, Client_business_in_MA_NY_or_VA__c, Client_covering_addl_paid_life_insurance__c, Client_does_pre_employment_drug_screen__c, Client_has_any_of_the_following__c, Client_interested_NSP_time_attendance__c, Client_is_interested_NSP_PTO_tracking__c, Client_needs_to_e_verify_all_employees__c, Client_previously_filed_an_EEO_1_Report__c, Client_provided_copy_of_communication__c, Client_submitting_apprvl_for_spreadsheet__c, Confirm_w_RS_when_each_step_is_completed__c, Current_onboarding_process_for_new_empl__c, DOL_Audit_Provide_Details__c, Direct_deposit_offered_to_employees__c, Discovery_Meeting_Date_Time_Location__c, Discussed_predecessor_hours_w_client__c, Docs_emp_need_to_complete_for_onboarding__c, Does_client_have_taxable_fringe_benefits__c, Does_client_perform_background_checks__c, EE_check_delivered_diff_place_than_work__c, EE_enrollments_outside_of_Insperity__c, Earned_Sick_Time_Start_Date__c, Employee_Enrollment__c, Employees_reside_in_these_service_areas__c, Employees_work_in_more_than_one_state__c, Exemption_status_of_all_empl_explained__c, Freq_of_collecting_medical_contribution__c, Gen_liability_auto_coverage_details__c, Have_EEs_been_notified_of_the_transition__c, How_are_empl_hrs_reported_to_Insperity__c, How_do_employees_currently_enroll__c,
                                                                                              How_will_enrollments_be_handled__c, How_will_the_payroll_be_funded__c, Human_Resources_Notes__c, Inspection_details__c, Insperity_Empl_contrib_rate_determined__c, Interested_in_on_site_safety_inspections__c, Is_current_medical_provider_UHC__c, Is_exempt_from_MN_Statute_177__c, Is_exempt_from_Minimum_Wage__c, Is_there_a_separate_Vacation_policy__c, Labor_Dist_Job_Costing_or_cert_payroll__c, Leave_Benefits__c, Meeting_Notes__c, Meeting_Participants__c, Must_show_FLSA_EE_exemp_cat_for_all_EEs__c, Need_for_departments_and_locations__c, No_live_check_provide_details__c, Non_active_non_paid_empl_w_benefits_cov__c, ORK_Team_notified_about_the_new_client__c, Onboarding_Notes__c, Other_Post_Tax_Deduction_Details__c, Other_standard_work_hours_details__c, Other_urgent_HR_needs_provide_details__c, Overtime_owed_after_how_many_hrs_worked__c, Paid_Sick_Leave_Plan_Type__c, Paid_Sick_Leave_requirement__c, Paid_sick_leave_exemption_reason__c, Part_time_employees_enrolled_in_benefits__c, NSP_RS_Doc_Contact_Info__c, Pre_Discovery_Notes__c, Previous_challenge_provide_details__c, Previous_challenges_w_current_provider__c, Reason_for_eligibility__c, Received_Enrollment_Fee__c, Received_Section_125_Questionnaire__c, Regulatory_accreditation_inspections__c,
                                                                                              Review_Employee_Orientations__c, Review_Insperity_Online_Enrollment_Steps__c, Reviewed_deductible_carryover_w_client__c, San_Diego_Earned_Sick__c, Select_all_enrollments__c, Select_client_urgent_HR_needs__c, Sep_doc_specifying_pay_breakdown__c, Sick_Leave_balance_type__c, Special_Agreement_Addendum_details__c, NSP_Sr_Onboarding_Benefit_Rep__c, Terming_life_insurance_disability_plan__c, Uses_WageWorks_for_commuter_benefit_plan__c, What_type_and_how_many_splits__c, When_was_the_handbook_last_updated__c, When_was_the_last_Open_Enrollment_period__c, Where_is_the_policy_located__c, Who_in_client_gets_std_insperity_comm__c, Who_is_the_current_custodian_bank__c, Who_is_the_provider__c, Workers_Comp_Safety_Notes__c, Written_doc_pay_plan_for_how_EE_is_paid__c, sample_new_empl_info_packet_collected__c, PC_Client_Number__c, Back_up_PC_Client_Number__c, Back_up_PC__c, Can_client_provide_EEO_filing_address__c, Checks_delivered__c, Documentation_Status__c, EE_Visa_Type__c, Emp_deferral_loan_amount__c, HR_Contact_Cell_Phone__c, HR_Contact_Office_Phone__c, Insperity_last_day_of_2nd_pay_period__c, Is_Insperity_s_group_health_plan_replaci__c, KDM_Client_Number__c, KDM__c, Misc_Contact_Cell_Phone__c, Misc_Contact_Number__c, Misc_Contact_Office_Phone__c, Misc_Contact__c,
                                                                                              NSP_AIMS_ClientNo__c, NSP_AIMS_Client_Name__c, NSP_Any_active_severance_agreement__c, NSP_Any_employee_with_temporary_status__c, NSP_Assignment_Notes__c, NSP_BPS_Notes__c, NSP_Client_Sponsored_Plan__c, NSP_Client_retaining_benefit_plan__c, NSP_Does_arrearage_comply_with_state_law__c, NSP_Does_the_client_have_prior_wages__c, NSP_EE_Name__c, NSP_Employee_Notes__c, NSP_Employee_with_compensation_other__c, NSP_FLSA_EE_exemption_category_provided__c, NSP_Final_pay_date_prior_to_Insperity__c, NSP_Final_pay_period_prior_to_Insperity__c, NSP_Frequency__c, NSP_Have_credit_services_approved__c, NSP_How_e_verify_be_completed__c, NSP_How_employee_hours_be_reported_to_I__c, NSP_How_hours_currently_captured__c, NSP_Immediate_payroll_needs_or_concerns__c, NSP_Inspeirty_last_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_1st_pay_period__c, NSP_Insperity_1st_day_of_2nd_pay_period__c, NSP_Insperity_1st_pay_date__c, NSP_Insperity_2nd_pay_date__c, NSP_Is_arrearage_7_days__c, NSP_Onsite_Safety_Inspection_Details__c, NSP_Other_Urgent_HR_Needs__c, NSP_Overtime_owed_after_hours__c, NSP_Payment_Details__c, NSP_Payroll_Specialist_to_confirm__c, NSP_Plan_for_EE_Payment__c, NSP_Project__c, NSP_Review_Cigna_Enrollment_Process__c, NSP_Separate_Vacation_Policy__c, NSP_Service_Model__c, NSP_Standard_No_of_Hours_worked_for_EEs__c, NSP_State_require_specific_priming_field__c,
                                                                                              NSP_Subaccount__c, NSP_Urgent_HR_Needs_Details__c, NSP_When_where_and_quantity_needed__c, NSP_Who_receives_Insperity_Communication__c, NSP_Who_will_approve_the_payroll__c, NSP_Who_will_submit_payroll__c, NSP_collected_copies_of_state_WC_policy__c,NSP_current_waiting_period__c, NSP_how_future_payment_will_be_done__c, NSP_prior_medical_contributions__c, NSP_remote_EEs_not_working_physical_loc__c, NSP_separate_pay_document_specify__c, WC__c, received_introductory_email_frm_ORK_Team__c, remove_employee_directory_from_premier__c, NSP_AIMS_ClientNo_KDM__c, NSP_AIMS_ClientNo_OSS__c, NSP_AIMS_ClientNo_PC__c, NSP_AIMS_ClientNo_WC__c, NSP_Benefit_Notes__c, NSP_Commission_Provide_Details__c, NSP_DoYouPay_Other_Provide_details__c, NSP_Non_paid_users_Enter_User_Names__c, NSP_compensation_structu_Provide_Details__c, NSP_Govt_Type_Other_Provide_Details__c, NSP_employee_40_hour_work_Week_PDetails__c, NSP_Any_OT_Expections_Provide_Details__c, NSP_PD_different_contact_for_subaccount__c, NSP_Provide_Details_Relabeling_Needed__c, NSP_Any_special_pay_code_Provide_Details__c, Insperity_pay_frequency__c,
                                                                                              NSP_Payroll_Specialist__r.NSP_Work_email__c,NSP_Asset__r.AccountId, NSP_Payroll_Specialist__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__c,  NSP_Project_Manager__r.pse__Salesforce_User__r.Email,NSP_Urgent_Medical_Needs_Emp_Details__c, NSP_Employees_on_LOA__c,NSP_Employee_Details_On_LOA__c ,NSP_Old_Benefits_Package__c,NSP_Old_Effective_Date_EPLI__c,NSP_Old_Insperity_Ben_effective_date__c,NSP_OT_Representative__r.NSP_Work_email__c,Federal_Labor_Law_poster__c FROM Implementation_Profile__c WHERE recordType.Name= 'Middle Market' LIMIT 1 ]);

        for(Implementation_Profile__c ip: ipRecordMap.values()){
            ip.NSP_Form_Completed__c = true;
            ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.YES ;
            ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.PEOMULTIPLIER ;
            ip.Client_want_to_begin_401k_w_NSP_setup__c = 'NO';
        }
        update  ipRecordMap.values();

        NSP_Implementationprofile_ServiceHelper helper = new NSP_Implementationprofile_ServiceHelper(ipRecordMap, new Map<Id, Implementation_Profile__c>());
        helper.isRerun = True;
        helper.executeAutomation();
        system.assertEquals( ipRecordMap.values()[0].Client_has_existing_retirement_plan__c, NSP_ServiceConstants.YES);
        Test.StopTest();
    }

    @isTest
    private static void createCaseTest() {
        List <Implementation_Profile__c>updateIPList = new List<Implementation_Profile__c>();
        List<Implementation_Profile__c> getListFSA = [SELECT Id,Client_Profile_Information__c
                                                      FROM Implementation_Profile__c
                                                      WHERE Client_Profile_Information__c = 'Related Clients'
                                                      LIMIT 1];
        getListFSA[0].Client_Profile_Information__c = NSP_ServiceConstants.FORMERCLIENT;
        getListFSA[0].NSP_Form_Completed__c =TRUE;
        getListFSA[0].NSP_Urgent_Medical_Needs_Emp_Details__c = 'Test';
        getListFSA[0].NSP_BPA_BPC_Ids__c =userInfo.getUserId();
        database.update(getListFSA);

        Test.startTest();
        List<Implementation_Profile__c> getImpProfileList = [SELECT Id,Is_there_a_need_for_a_subaccount__c,Any_EEs_with_urgent_medical_needs__c,classing_req_a_new_download_for_Subacc__c,NSP_Form_Completed__c
                                                             FROM Implementation_Profile__c WHERE Id != null];
        getImpProfileList[0].Any_EEs_with_urgent_medical_needs__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Insperity_benefits_waiting_period__c = '90 Days';
        getImpProfileList[0].Client_s_previous_waiting_period__c = '0 Days';
        getImpProfileList[0].NSP_Immediate_need_for_Workers_Comp_Cert__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Does_the_client_offer_a_HSA__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Is_client_s_current_HSA_with_Optum_Bank__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Does_client_have_their_code_group_ID__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Are_there_any_EEs_on_Leave_of_Absence__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].NSP_List_Employee_Names__c = TEST_NAME;
        getImpProfileList[0].NSP_Urgent_Medical_Needs_Emp_Details__c = 'Test';
        getImpProfileList[0].NSP_BPA_BPC_Ids__c =userInfo.getUserId();
        getImpProfileList[0].NSP_Form_Completed__c = TRUE;
        getImpProfileList[0].Federal_Labor_Law_poster__c = NSP_ServiceConstants.NO;
        getImpProfileList[0].Would_the_client_like_a_FLSA_Exemption__c = NSP_ServiceConstants.YES;
        getImpProfileList[0].Is_the_client_Emerging_Growth__c = NSP_ServiceConstants.YES;
        update getImpProfileList[0];

        database.update(updateIPList);
        Test.stopTest();
        system.assertEquals( getImpProfileList[0].NSP_Immediate_need_for_Workers_Comp_Cert__c, NSP_ServiceConstants.YES);
    }

    @isTest
    private static void createCaseTest2() {
        Test.startTest();
        List<Implementation_Profile__c> getListCompCerts = [SELECT Id,NSP_Immediate_need_for_Workers_Comp_Cert__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getListCompCerts[0].NSP_Immediate_need_for_Workers_Comp_Cert__c = NSP_ServiceConstants.YES;
        database.update(getListCompCerts);
        Test.stopTest();
        system.assertEquals( getListCompCerts[0].NSP_Immediate_need_for_Workers_Comp_Cert__c, NSP_ServiceConstants.YES);
    }

    @isTest
    private static void createCaseTest3() {
        Test.startTest();
        List<Implementation_Profile__c> getListSeasonal = [SELECT Id,Client_have_will_have_any_Seasonal_EEs__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getListSeasonal[0].Client_have_will_have_any_Seasonal_EEs__c = NSP_ServiceConstants.YES;
        database.update(getListSeasonal);

        List<Implementation_Profile__c> getListRRP = [SELECT Id,NSP_Check_to_create_the_RRP_Case__c FROM Implementation_Profile__c WHERE Id != null LIMIT 1];
        getListRRP[0].NSP_Check_to_create_the_RRP_Case__c = NSP_ServiceConstants.VALUE_TRUE;
        database.update(getListRRP);
        Test.stopTest();
        NSP_Implementationprofile_ServiceHelper ip = new NSP_Implementationprofile_ServiceHelper(getListRRP[0].Id,'RRPCase');
        system.assertEquals( getListRRP[0].NSP_Check_to_create_the_RRP_Case__c , NSP_ServiceConstants.VALUE_TRUE);

    }

    @isTest
    private static void createCaseTest4() {
        Test.startTest();
        List<Implementation_Profile__c> getListOptum = [SELECT Id,Does_client_have_their_code_group_ID__c FROM Implementation_Profile__c WHERE Does_client_have_their_code_group_ID__c=:NSP_ServiceConstants.NO];
        getListOptum[0].RecordTypeId = fsoRecordTypeId;
        getListOptum[0].NSP_Form_Completed__c = True;
        database.update(getListOptum);

        List<Implementation_Profile__c> getListMMIps = [SELECT Id,How_are_empl_hrs_reported_to_Insperity__c FROM Implementation_Profile__c WHERE RecordTypeId=:ipMMRecordTypeId];
        getListMMIps[0].How_are_empl_hrs_reported_to_Insperity__c = NSP_ServiceConstants.XML;
        getListMMIps[0].Client_have_will_have_any_Seasonal_EEs__c = NSP_ServiceConstants.YES;
        getListMMIps[0].Are_there_any_EEs_on_Leave_of_Absence__c = NSP_ServiceConstants.YES;
        getListMMIps[0].NSP_Form_Completed__c = true;
        getListMMIps[0].Federal_Labor_Law_poster__c = NSP_ServiceConstants.NO;
        database.update(getListMMIps);
        Test.stopTest();
        system.assertEquals( getListMMIps[0].How_are_empl_hrs_reported_to_Insperity__c , NSP_ServiceConstants.XML);

    }

    @isTest
    private static void createEmailTest() {
        List<Implementation_Profile__c> getListIp = [SELECT Id,Form_8973_Contact__c
                                                     FROM Implementation_Profile__c
                                                     WHERE Form_8973_Contact__c = 'test'
                                                     LIMIT 1];
        Test.startTest();
        getListIp[0].NSP_Form_Completed__c = true;
        getListIp[0].Client_does_business_in_MA_NY_or_VA__c=NSP_ServiceConstants.YES;
        update getListIp;
        system.assertEquals( getListIp[0].NSP_Form_Completed__c ,true);

        List<Implementation_Profile__c> getList = [SELECT Id,EEO__c
                                                   FROM Implementation_Profile__c
                                                   WHERE NSP_Select_all_that_apply__c = 'IRR'
                                                   LIMIT 1];

        getList[0].NSP_Form_Completed__c = true;
        getList[0].Employees_work_in_the_following_states__c = 'DE';
        getList[0].Client_have_any_Commission_only_EEs__c=NSP_ServiceConstants.YES;
        getList[0].Has_FLSA_team_approved__c=NSP_ServiceConstants.NO;
        update getListIp;
        system.assertEquals( getList[0].NSP_Form_Completed__c ,true);
        Test.stopTest();


    }

    @isTest
    private static void createEmailTestEECommission() {

        Contact con=[SELECT Id,pse__Salesforce_User__c FROM Contact WHERE Id != null LIMIT 1];
        Test.startTest();
        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Client_have_any_Commission_only_EEs__c=NSP_ServiceConstants.YES;
        ip.Has_FLSA_team_approved__c=NSP_ServiceConstants.NO;
        ip.Employees_work_in_the_following_states__c='AK;AR;CT;IL';
        ip.Time_Entry_Method__c=NSP_ServiceConstants.XML;
        ip.Client_has_any_special_payroll_needs__c=NSP_ServiceConstants.YES;
        ip.Select_all_payroll_needs_that_apply__c='Departments';
        ip.NSP_Payroll_Specialist__c=con.id;
        ip.NSP_Project_Manager__c=con.id;
        ip.NSP_BPA_BPC_Ids__c = UserInfo.getUserId();
        ip.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        insert ip;
        Test.stopTest();
        system.assertEquals(ip.NSP_Onboarding_Specialist_Coordinator__c,con.id);
    }

    @isTest
    private static void createEmailTestStock() {

        Contact con=[SELECT Id,pse__Salesforce_User__c FROM Contact WHERE Id != null LIMIT 1];
        Test.startTest();
        NSP_Regulated_Area__c regulatedArea =new NSP_Regulated_Area__c  ();
        regulatedArea.NSP_State__c ='MN';
        regulatedArea.NSP_Regulation_Type__c ='State Retirement Plan';
        insert regulatedArea;

        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Employees_work_in_the_following_states__c='MN;TN;VT';
        ip.Does_the_client_offer_a_Stock_Purchase__c=NSP_ServiceConstants.YES;
        ip.NSP_Does_the_client_offer_Stock_Options__c=NSP_ServiceConstants.YES;
        ip.First_Pay_Date__c=system.today();
        ip.Num_of_Worksite_Employees_Full_Time__c=10;
        ip.NSP_Select_all_that_apply__c='IRR';
        ip.Client_have_any_EEs_on_F1_or_J1_Visa_s__c=NSP_ServiceConstants.YES;
        ip.NSP_Project_Manager__c=con.id;
        ip.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.NO;
        ip.Client_want_to_begin_401k_w_NSP_setup__c = NSP_ServiceConstants.NO;
        insert ip;
        NSP_Implementationprofile_ServiceHelper ipobject = new NSP_Implementationprofile_ServiceHelper(ip.Id,'NSP_New_401_k');
        Test.stopTest();
        system.assertEquals(ip.NSP_Select_all_that_apply__c,'IRR');
    }

    @isTest
    private static void createEmailTestStock2() {
        Contact con=[SELECT Id,pse__Salesforce_User__c FROM Contact WHERE Id != null LIMIT 1];
        Test.startTest();
        NSP_Regulated_Area__c regulatedArea = new NSP_Regulated_Area__c  ();
        regulatedArea.NSP_State__c ='MN';
        regulatedArea.NSP_Regulation_Type__c ='State Retirement Plan';
        insert regulatedArea;

        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = fsoRecordTypeId;
        ip.NSP_Form_Completed__c = true;
        ip.Employees_work_in_the_following_states__c='MN;TN;VT';
        ip.Does_the_client_offer_a_Stock_Purchase__c=NSP_ServiceConstants.YES;
        ip.NSP_Does_the_client_offer_Stock_Options__c=NSP_ServiceConstants.YES;
        ip.First_Pay_Date__c=system.today();
        ip.Num_of_Worksite_Employees_Full_Time__c=10;
        ip.NSP_Select_all_that_apply__c='IRR';
        ip.Client_have_any_EEs_on_F1_or_J1_Visa_s__c=NSP_ServiceConstants.YES;
        ip.NSP_Project_Manager__c=con.id;
        ip.NSP_Onboarding_Specialist_Coordinator__c=con.id;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.YES;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CSP401K;
        insert ip;
        NSP_Implementationprofile_ServiceHelper ipObject = new NSP_Implementationprofile_ServiceHelper(ip.Id,'NSP_New_401_k');
        Test.stopTest();
        system.assertEquals(ip.NSP_Select_all_that_apply__c,'IRR');
    }

    @isTest
    private static void createEmailTestStock3() {
        Test.startTest();
        List<Asset> assetRecord = [SELECT Id, Status FROM Asset WHERE Status =: NSP_ServiceConstants.AIMS_STATUS];
        List<Implementation_Profile__c> getListMMIps = [SELECT Id,Does_the_client_offer_a_Stock_Purchase__c,remove_employee_directory_from_premier__c FROM Implementation_Profile__c WHERE RecordTypeId=:ipMMRecordTypeId];
        getListMMIps[0].remove_employee_directory_from_premier__c=NSP_ServiceConstants.YES;
        getListMMIps[0].NSP_Form_Completed__c = true;
        getListMMIps[0].Does_the_client_offer_a_Stock_Purchase__c = NSP_ServiceConstants.YES;
        getListMMIps[0].NSP_Asset__c = assetRecord[0].Id;
        database.update(getListMMIps);
        Test.stopTest();
    }

    @isTest
    private static void createEmailTestStock4() {
        List<Asset> assetRecord = [SELECT Id, Status FROM Asset WHERE Status =: NSP_ServiceConstants.AIMS_STATUS];
        Implementation_Profile__c ip = new Implementation_Profile__c();
        ip.RecordTypeId = ipMMRecordTypeId;
        ip.remove_employee_directory_from_premier__c=NSP_ServiceConstants.YES;
        ip.Does_the_client_offer_a_Stock_Purchase__c = NSP_ServiceConstants.YES;
        ip.NSP_Asset__c = assetRecord[0].Id;
        insert ip;
        Test.startTest();
        NSP_Implementationprofile_ServiceHelper implService = new NSP_Implementationprofile_ServiceHelper(ip.Id, NSP_ServiceConstants.REMOVE_EMPLOYEE_DIR);
        implService.executeAutomation();
        Test.stopTest();
    }

}
//