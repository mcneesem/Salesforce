const DYNAMIC_FIELDS = {
  Insperity_pay_frequency__c: [
    {
      expValue: ['Weekly'],
      dependentFields: ['NSP_Weekly_Pay_Period__c'],
    },
    {
      expValue: ['Bi-Weekly'],
      dependentFields: ['NSP_Biweekly_Pay_Period__c'],
    },
    {
      expValue: ['Semi-Monthly'],
      dependentFields: [
        'NSP_Semimonthly_Pay_Period__c',
        'Non_exempt_EEs_on_semi_monthly_pay_freq__c',
        'Semi_monthly_pay_freq_comply_w_state_law__c',
      ],
    },
    {
      expValue: ['Monthly'],
      dependentFields: [
        'Monthly_pay_freq_comply_w_state_laws__c',
        'NSP_Monthly_Pay_Period__c',
      ],
    },
  ],
  Non_exempt_EEs_on_semi_monthly_pay_freq__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Non_exempt_EE_pay_freq_provide_details__c'],
    },
  ],
  Semi_monthly_pay_freq_comply_w_state_law__c: [
    {
      expValue: ['No'],
      dependentFields: ['Semi_monthly_pay_st_law_provide_details__c'],
    },
  ],
  Monthly_pay_freq_comply_w_state_laws__c: [
    {
      expValue: ['No'],
      dependentFields: ['NSP_Provide_Monthly_pay_frequency_detail__c'],
    },
  ],
  NSP_Is_arrearage_7_days__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_Have_credit_services_approved__c',
        'NSP_Does_arrearage_comply_with_state_law__c',
      ],
    },
  ],
  NSP_DoTheEmployeeWorkA40HourWorkWeek__c: [
    {
      expValue: ['No'],
      dependentFields: ['NSP_Work_Hours__c'],
    },
  ],
  Is_there_a_need_for_a_subaccount__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Why_is_subaccount_needed__c',
        'classing_req_a_new_download_for_Subacc__c',
      ],
    },
  ],
  Payroll_submitted_frm_multiple_contacts__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Provide_multiple_contact_details__c'],
    },
  ],
  Where_to_mail_EE__c: [
    {
      expValue: ['Multiple locations'],
      dependentFields: ['Provide_live_check_details__c'],
    },
  ],
  Client_has_any_special_payroll_needs__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Select_all_payroll_needs_that_apply__c'],
    },
  ],
  Select_all_payroll_needs_that_apply__c: [
    {
      expValue: ['Job Costing'],
      dependentFields: ['NSP_Job_Costing__c'],
    },
    {
      expValue: ['Departments'],
      dependentFields: ['NSP_Departments_Status__c'],
    },
    {
      expValue: ['Locations'],
      dependentFields: ['NSP_Locations_Status__c'],
    },
    {
      expValue: ['IRR'],
      dependentFields: ['NSP_IRR_Status__c'],
    },
    {
      expValue: ['Billing Groups'],
      dependentFields: ['NSP_Billing_Groups_Status__c'],
    },
    {
      expValue: ['Other'],
      dependentFields: ['NSP_Provide_Details__c'],
    },
  ],
  Labor_Dist_Job_Costing_or_cert_payroll__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['What_type_and_how_many_splits__c'],
    },
  ],
  Client_have_any_Commission_only_EEs__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Has_FLSA_team_approved__c'],
    },
  ],
  NSP_Do_you_pay__c: [
    {
      expValue: ['Non-Discretionary Bonus'],
      dependentFields: [
        'NSP_Non_Discretionary_Bonus__c',
        'Non_Discretionary_Bonus_Input_frequency__c',
      ],
    },
    {
      expValue: ['Discretionary Bonus'],
      dependentFields: [
        'NSP_Discretionary_Bonus__c',
        'NSP_Discretionary_Bonus_Input_Frequency__c',
      ],
    },
    {
      expValue: ['Commission'],
      dependentFields: [
        'NSP_Commission_Frequency__c',
        'NSP_Commission_Type__c',
      ],
    },
    {
      expValue: ['Other'],
      dependentFields: [
        'NSP_DoYouPay_Other_Provide_details__c',
        'Do_you_pay_non_exempt_employees__c',
        'NSP_NonDiscretionaryDiscretionaryPayCode__c',
      ],
    },
  ],
  NSP_Commission_Frequency__c: [
    {
      expValue: ['Other'],
      dependentFields: ['NSP_Commission_Provide_Details__c'],
    },
  ],
  NSP_Employees_with_multiple_types_of_pay__c: [
    {
      expValue: ['Multiple Pay Rates'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['Shift Differentials'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['Piece Rate'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
        'messageAppletForPieceRateAndCA',
      ],
    },
    {
      expValue: ['Car Allowance'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
        'messageAppletForPieceRateAndCA',
      ],
    },
    {
      expValue: ['Housing Allowance'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['Per Diem'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['Fee Based'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['Phone Allowance'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['On-Call'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
    {
      expValue: ['Daily Rate'],
      dependentFields: [
        'NSP_Daily_Rate_approval_status__c',
        'NSP_Payroll_Specialist_to_confirm__c',
      ],
    },
  ],
  Do_any_EEs_have_garnishments__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Documentation_Status__c',
        'NSP_EEs_garnishments_details__c',
      ],
    },
  ],
  Do_any_EEs_have_tax_levies__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_Documents_Collected_Leviesd__c',
        'NSP_Provide_EEs_tax_levies_details__c',
      ],
    },
  ],
  Has_expenses_allowances_through_payroll__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Client_runs_expenses_or_payroll__c',
      ],
    },
  ],
  Client_runs_expenses_or_payroll__c: [
    {
      expValue: ["Allowances"],
      dependentFields: ["Allowances__c", "Provide_allowance_details__c"],
    },
    {
      expValue: ["Expenses"],
      dependentFields: ["Provide_expense_details__c"],
    },
  ],
  Employees_work_in_more_than_one_state__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['stateGuidelines'],
    },
  ],
  Are_there_employes_working_in__c: [
    {
      expValue: ['Seattle, WA'],
      dependentFields: ['Paid_Sick_Leave_requirement__c'],
    },
    {
      expValue: ['Tacoma, WA'],
      dependentFields: ['Paid_Sick_Leave_requirement__c'],
    },
    {
      expValue: ['California'],
      dependentFields: ['Paid_Sick_Leave_requirement__c'],
    },
    {
      expValue: ['Oregon'],
      dependentFields: ['Paid_Sick_Leave_requirement__c'],
    },
    {
      expValue: ['Morristown, NJ'],
      dependentFields: ['Paid_Sick_Leave_requirement__c'],
    },
  ],
  Client_interested_in_NSP_tracking_PTO__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['PTO_Types__c', 'NSP_Provide_Tracking_details__c'],
    },
  ],
  PTO_Types__c: [
    {
      expValue: ['Track in NSP Time & Attendance'],
      dependentFields: [
        'Does_client_want_NSP_to_track_hours_and__c',
      ],
    },
  ],
  Is_there_a_need_for_a_GL_interface__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_Chart_of_Accounts_GL_codes__c',
        'NSP_Sample_of_current_GL_report__c',
        'NSP_Name_of_accounting_software__c',
      ],
    },
  ],
  Client_utilizing_Insperity_s_TimeStar__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Day_one_start__c',
        'What_time_zone_do_EEs_work__c',
        'Exempt_EEs_normal_of_hours_per_day__c',
        'Does_client_require_job_costing__c',
        'Who_will_enter_time_worked__c',
        'EEs_to_punch_in_out_or_use_timesheet__c',
        'NSP_Prepop_Timecards_w_Stndrd_hrs__c',
        'Who_will_be_the_TimeStar_admin__c',
        'NSP_Client_s_holiday_calendar__c',
      ],
    },
  ],
  Client_have_any_EEs_on_F1_or_J1_Visa_s__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_EE_Name__c', 'EE_Visa_Type__c'],
    },
  ],
  NSP_Any_special_pay_codes_Needed__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Any_special_pay_code_Provide_Details__c'],
    },
  ],
  Client_has_any_post_tax_deductions__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Expenses__c'],
    },
  ],
  Expenses__c: [
    {
      expValue: ['Other'],
      dependentFields: ['Other_Post_Tax_Deduction_Details__c'],
    },
  ],
  Paid_Sick_Leave_requirement__c: [
    {
      expValue: ['Exempt'],
      dependentFields: ['Paid_sick_leave_exemption_reason__c'],
    },
  ],
};

export { DYNAMIC_FIELDS };