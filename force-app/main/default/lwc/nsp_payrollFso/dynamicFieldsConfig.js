const DYNAMIC_FIELDS = {
  Insperity_pay_frequency__c: [
    {
      expValue: ["Weekly"],
      dependentFields: [
        "NSP_Weekly_Pay_Period__c",
      ],
    },
    {
      expValue: ["Bi-Weekly"],
      dependentFields: [
        "NSP_Biweekly_Pay_Period__c",
      ],
    },
    {
      expValue: ["Semi-Monthly"],
      dependentFields: [
        "NSP_Semimonthly_Pay_Period__c",
        "Non_exempt_EEs_on_semi_monthly_pay_freq__c",
        "Semi_monthly_pay_freq_comply_w_state_law__c",
      ],
    },
    {
      expValue: ["Monthly"],
      dependentFields: [
        "Monthly_pay_freq_comply_w_state_laws__c",
        "NSP_Monthly_Pay_Period__c",
      ],
    },
  ],
  Non_exempt_EEs_on_semi_monthly_pay_freq__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "Current_hours_tracking_method_infolet__c",
        "Non_exempt_EE_pay_freq_provide_details__c",
      ],
    },
  ],
  Semi_monthly_pay_freq_comply_w_state_law__c: [
    {
      expValue: ["No"],
      dependentFields: ["Semi_monthly_pay_st_law_provide_details__c"],
    },
  ],
  Monthly_pay_freq_comply_w_state_laws__c: [
    {
      expValue: ["No"],
      dependentFields: ["NSP_Provide_Monthly_pay_frequency_detail__c"],
    },
  ],
  Is_there_a_need_for_a_subaccount__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "Why_is_subaccount_needed__c",
        "classing_req_a_new_download_for_Subacc__c",
      ],
    },
  ],
  NSP_Is_arrearage_7_days__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "NSP_Have_credit_services_approved__c",
        "NSP_Does_arrearage_comply_with_state_law__c",
      ],
    },
  ],
  NSP_Have_credit_services_approved__c: [
    {
      expValue: ["No"],
      dependentFields: ["Provide_credit_services_detaIls__c"],
    },
  ],
  Does_arrearage_comply_with_state_laws__c: [
    {
      expValue: ["No"],
      dependentFields: ["Provide_arrearage_details__c"],
    },
  ],
  NSP_Does_the_client_have_prior_wages__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "NSP_Final_pay_period_prior_to_Insperity__c",
        "NSP_Final_pay_date_prior_to_Insperity__c",
      ],
    },
  ],
  Where_to_mail_EE__c: [
    {
      expValue: ["Multiple locations"],
      dependentFields: ["Provide_live_check_details__c"],
    },
  ],
  NSP_non_Insperity_paid_emps_contractors__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Provide_non_insperity_worker_details__c"],
    },
  ],
  Client_have_any_EEs_on_F1_or_J1_Visa_s__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["NSP_EE_Name__c", "EE_Visa_Type__c"],
    },
  ],
  Client_have_any_Commission_only_EEs__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Has_FLSA_team_approved__c"],
    },
  ],
  Would_the_client_like_a_FLSA_Exemption__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Who_should_the_FLSA_team_reach_out_to__c','Is_the_client_Emerging_Growth__c'],
    },
  ],
  Does_client_employ_ministers_or_teachers__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Check_all_tht_apply_ministers_teachers__c"],
    },
  ],
  Does_the_client_have_any_union_EEs__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Client_union_EE_Check_all_that_Apply__c"],
    },
  ],
  Is_the_client_a_federal_contractor__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Client_has_Service_Contract_Act_SCA_EEs__c", "Is_the_client_required_to_track__c"],
    },
  ],
  Client_has_Service_Contract_Act_SCA_EEs__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "Have_the_SCA_EEs_been_approved__c",
        "SCA_EEs_get_wages_in_lieu_of_benefits__c",
      ],
    },
  ],
  Client_have_EEO_filing_under__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Can_client_provide_EEO_filing_address__c"],
    },
  ],
  Can_client_provide_EEO_filing_address__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["EEO__c", "Filing_address__c"],
    },
    {
      expValue: ["No"],
      dependentFields: ["EEO_name_phone_contact_email_for_info__c"],
    },
  ],
  Past_employees_crntly_getting_severance__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["NSP_how_future_payment_will_be_done__c"],
    },
  ],
  Has_expenses_allowances_through_payroll__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Client_runs_expenses_or_payroll__c"],
    },
  ],
  Client_runs_expenses_or_payroll__c: [
    {
      expValue: ["Allowances"],
      dependentFields: ["Allowances__c", "Provide_allowance_details__c"],
    },
    {
      expValue: ["Expenses"],
      dependentFields: ["NSP_How_will_client_reimburse_expenses__c"],
    },
  ],
  
  Client_has_any_post_tax_deductions__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Expenses__c","NSP_Payroll_notes__c"],
    },
  ],
  Expenses__c: [
    {
      expValue: ["Other"],
      dependentFields: ["Other_Post_Tax_Deduction_Details__c"],
    },
  ],
  Client_has_any_special_payroll_needs__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Select_all_payroll_needs_that_apply__c","Has_sample_payroll_report_been_requsted__c"],
    },
  ],
  Has_sample_payroll_report_been_requsted__c:[
    {
      expValue: ["Yes", "No", "Requested - Not collected"],
      dependentFields: ["NSP_Provide_details_around_reporting__c"],
    },
  ],
  Select_all_payroll_needs_that_apply__c:[
    {
      expValue: ["Job Costing"],
      dependentFields: ["NSP_Job_Costing__c"],
    },
    {
      expValue: ["Departments"],
      dependentFields: ["NSP_Departments_Status__c"],
    },
    {
      expValue: ["Locations"],
      dependentFields: ["NSP_Locations_Status__c"],
    },
    {
      expValue: ["IRR"],
      dependentFields: ["NSP_IRR_Status__c"],
    },
    {
      expValue: ["Billing Groups"],
      dependentFields: ["NSP_Billing_Groups_Status__c"],
    },
    {
      expValue: ["Other"],
      dependentFields: ["NSP_Provide_Details__c"],
    },
  ],
 
  What_accounting_software_do_you_use__c: [
    {
      expValue: ["QuickBooks"],
      dependentFields: ["Would_you_like_automation_general__c","Is_payroll_entry_itemized_or_simple__c"],
    },
    {
      expValue: ["Other"],
      dependentFields: ["Software_Used__c"],
    },
  ],
  
  Client_does_business_in_MA_NY_or_VA__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["NSP_Business_Meeting_States__c"],
    },
  ],
  Any_EEs_travel_internationally_for_work__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["internationalTravelNotify","Provide_EE_travel_details__c"],
    },
  ],
  Client_interested_in_NSP_tracking_PTO__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "NSP_Where_will_PTO_be_tracked__c",
        "NSP_Provide_Tracking_details__c",
      ],
    },
  ],
  NSP_Where_will_PTO_be_tracked__c: [
    {
      expValue: ["Track in NSP Time Attendance"],
      dependentFields: [
        "Client_interested_NSP_time_attendance__c",
      ],
    },
  ],
  Client_utilizing_Insperity_s_TimeStar__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "How_is_client_needing_to_implement_ITA__c",
        "Who_will_be_the_TimeStar_admin__c",
        "NSP_Who_will_be_the_backup_ITA_admin__c",
        "Does_client_want_NSP_to_track_hours_and__c",
        "Will_all_EEs_use_ITA__c",
        "Any_1099_international_or_other_users__c",
        "What_time_zone_do_EEs_work__c",
        "NSP_Client_s_holiday_calendar__c",
        "Does_client_offer_paid_holidays__c",
        "Does_client_offer_floating_holidays__c",
        "Does_client_have_premium_pay_needs__c",
        "EEs_to_punch_in_out_or_use_timesheet__c",
        "client_round_hours_or_other_spl_pay_rule__c",
        "Exempt_EEs_normal_of_hours_per_day__c",
        "NSP_Prepop_Timecards_w_Stndrd_hrs__c",
        "Does_client_require_job_costing__c",
        "Does_EDC_have_supervisors_and_work_email__c",
        "Day_one_start__c", 
      ],
    },
  ],
  Will_all_EEs_use_ITA__c: [
    {
      expValue: ["No"],
      dependentFields: [
        "Provide_details_if_all_EEs_are_not_using__c",
      ],
    },
  ],
  Any_1099_international_or_other_users__c:[
    {
      expValue: ["International"],
      dependentFields: ["List_Countries__c"],
    },
    {
      expValue: ["Other"],
      dependentFields: ["List_Other_Users__c"],
    },

  ],
  Does_client_offer_paid_holidays__c:[
    {
      expValue: ["Yes"],
      dependentFields: ["Are_all_EEs_eligible_for_paid_holidays__c","NSP_Any_EEs_work_on_holidays__c","NSP_If_EE_works_holiday_are_paid_prem__c"],
    },
  ],
  Does_client_have_premium_pay_needs__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Select_all_premium_pay_needs_that_apply__c"],
    },
  ],
  EEs_to_punch_in_out_or_use_timesheet__c: [
    {
      expValue: ["Punch in/out"],
      dependentFields: ["NSP_How_will_EEs_punch_in_out__c"],
    },
    {
      expValue: ["Timesheet"],
      dependentFields: ["Who_will_enter_time_worked__c"],
    },
  ],
  client_round_hours_or_other_spl_pay_rule__c: [
    {
      expValue: ["Other"],
      dependentFields: ["NSP_Provide_details_on_special_pay_rules__c"],
    },
  ],
  NSP_How_will_EEs_punch_in_out__c: [
    {
      expValue: ["Timeclock","Bluetooth Beach"],
      dependentFields: ["NSP_Has_hardware_been_ordered__c"],
    },
  ],

  Has_form_8973_been_discussed__c: [
    {
      expValue: ["Yes", "No"],
      dependentFields: [
        "Form_8973_Contact__c",
        "Contact_Information__c",
      ],
    },
  ],

  Does_this_client_have_an_AWW__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Is_client_CA_docs_submitted_for_approval__c"]
    }
  ],
  Client_have_will_have_any_Seasonal_EEs__c :[
    {
      expValue: ["Yes"],
      dependentFields:[
        "Do_the_employee_s_work_more_than_6__c",
        "What_months_client_increase_the_staff__c",
        "Is_the_work_performed_typically_the_same__c",
        "Work_performed_the_same_as_the_rest_year__c",
        "Is_the_Employee_an_Intern__c",
      ],
    },
  ],

  Work_performed_the_same_as_the_rest_year__c :[
    {
      expValue: ["Different"],
      dependentFields:[
        "Describe_the_type_of_work__c",        
      ],
    },
  ],

  Is_the_Employee_an_Intern__c :[
    {
      expValue: ["Yes"],
      dependentFields:[
        "What_months_is_the_Intern_working__c",
        "What_months_is_the_Intern_in_school__c", 
      ],
    },
  ],
};

export { DYNAMIC_FIELDS };