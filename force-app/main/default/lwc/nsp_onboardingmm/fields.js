const RL_FIELDS = [
    'Client_provided_copy_of_communication__c',
];

const SECTION_FIELDS = [
     'Review_Insperity_Online_Enrollment_Steps__c',
     'Employee_Enrollment__c',
     'NSP_Review_Cigna_Enrollment_Process__c',
     'Review_Employee_Orientations__c',
     'Client_Address__c',
     'Are_there_multiple_worksite_locations__c',
     'Provide_multiple_worksite_details__c',
     'NSP_Is_a_translator_needed__c',
     'Wht_language_whn_is_translator_needed__c',
     'Is_there_a_need_for_a_tech_package__c',
     'NSP_When_where_and_quantity_needed__c',
     'Any_special_needs_for_EE_orientation__c',
     'Client_internal_deadline_for_OEE_OBE__c',
     'Is_the_client_coming_from_another_PEO__c',
     'PEO_Name__c',
     'Client_s_previous_payroll_provider__c',
     'EE_enrollments_outside_of_Insperity__c',
     'Select_all_enrollments__c',
     'How_will_enrollments_be_handled__c',
     'NSP_remote_EEs_not_working_physical_loc__c',
     'Client_does_business_in_MA_NY_or_VA__c',
     'Client_business_in_MA_NY_or_VA__c',
     'NSP_State_require_specific_priming_field__c',
     'NSP_separate_pay_document_specify__c',
     'Written_doc_pay_plan_for_how_EE_is_paid__c',
     'Are_all_of_the_rates_in_agreement__c',
     'Paid_Sick_Leave_Plan_Type__c',
     'San_Diego_Earned_Sick__c',
     'Checks_delivered__c',
     'Leave_Benefits__c',
     'Is_exempt_from_Minimum_Wage__c',
     'Is_exempt_from_MN_Statute_177__c',
     'Overtime_owed_after_how_many_hrs_worked__c',
     'NSP_FLSA_EE_exemption_category_provided__c',
     'Is_there_a_separate_Vacation_policy__c',
     'Where_is_the_policy_located__c',
     'Earned_Sick_Time_Start_Date__c',
     'NSP_Standard_No_of_Hours_worked_for_EEs__c',
     'NSP_Provide_Details__c',
     'Basis_of_wage_payment_options__c',
     'Sick_Leave_balance_type__c',
     'Have_EEs_been_notified_of_the_transition__c',
     'Client_provided_copy_of_communication__c',
     'Onboarding_Notes__c',
     'NSP_No_of_Hours_worked_for_EEs_PD__c',
     'NSP_Separate_pay_document_New_Hampshire__c',
     'NSP_Separate_pay_document_New_York__c',
     'NSP_Separate_pay_document_South_Carolina__c',
     'NSP_Separate_pay_document_Washington_DC__c',
     'NSP_Separate_pay_document_Illinois__c',
     'NSP_Separate_pay_document_Maryland__c',
     'NSP_Separate_pay_document_Minnesota__c',
     'NSP_EarnedSick_Time_StartDate_Washington__c',
     'Must_show_FLSA_EE_exemp_cat_for_all_EEs__c'
];
const SYNC_FIELDS = {
  Provide_PEO_Name__c: 'PEO_Name__c',
  Account__c:"prefilledIpDetails",
  Employees_work_in_the_following_states__c: 'employee_states',
};

const POST_SYNC_IP_FIELDS={"prefilledIpDetails":"updatePrefilledIpValues"}

const PREFILLED_FIELDS={
    Client_s_previous_payroll_provider__c:"Client_s_previous_payroll_provider__c",
}

export {RL_FIELDS,PREFILLED_FIELDS,SYNC_FIELDS,POST_SYNC_IP_FIELDS, SECTION_FIELDS };