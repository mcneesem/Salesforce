const SYNC_FIELDS = {
  Provide_PEO_Name__c: 'PEO_Name__c',
  Account__c: 'prefilledIpDetails',
};

const POST_SYNC_IP_FIELDS = { prefilledIpDetails: 'updatePrefilledIpValues' };
const PREFILLED_FIELDS = {
  All_EEs_paid_under_same_FEIN_currently__c:
    'All_EEs_paid_under_same_FEIN_currently__c',
  Client_FEIN__c: 'Client_FEIN__c',
  Client_Profile_Information__c: 'Client_Profile_Information__c',
  Client_s_previous_payroll_provider__c:
    'Client_s_previous_payroll_provider__c',
};

const RL_FIELDS = [
  'NSP_Has_the_client_s_logo_been_collected__c',
  'Has_FEIN_documentation_been_collected__c',
  'SUI_Tax_rate_notice_s_collected__c',
  'Gotten_Cvrg_Cert_Gen_Liability_Auto__c',
  'Recent_Payroll_Register_Collected__c',
  'Employee_Data_Collection_EDC_collected__c',
  'Owner_not_on_payroll_addendum_collected__c',
];

const FIELD_CHANGE_HANDLER_MAPPING = {
  Client_FEIN__c: 'getClientFEINValue',
};

const SECTION_FIELDS = [
  'Brief_description_of_client__c',
  'Why_did_the_client_join_Insperity__c',
  'Is_the_client_coming_from_another_PEO__c',
  'Implementation_Profile__c',
  'PEO_Name__c',
  'Client_s_previous_payroll_provider__c',
  'Client_Implementing_Premier_Performance__c',
  'When_Client_Wants_Solution_implemented__c',
  'Implementing_biz_Performance_solutions__c',
  'Select_BPSes__c',
  'Time_Entry_Method__c',
  'Client_Profile_Information__c',
  'NSP_Related_Client__c',
  'NSP_Account_Executive__c',
  'Hush_Protocol__c',
  'Will_the_BPA_s_Be_attending_the_SKO__c',
  'NSP_Has_the_client_s_logo_been_collected__c',
  'Business_Inception_Date__c',
  'Client_FEIN__c',
  'Has_FEIN_documentation_been_collected__c',
  'All_EEs_paid_under_same_FEIN_currently__c',
  'List_additional_FEIN_s__c',
  'State_Unemployment_Insurance_SUI_Num__c',
  'SUI_Tax_rate_notice_s_collected__c',
  'Gotten_Cvrg_Cert_Gen_Liability_Auto__c',
  'Gen_liability_auto_coverage_details__c',
  'Recent_Payroll_Register_Collected__c',
  'Employee_Data_Collection_EDC_collected__c',
  'Provide_deadline_date__c',
  'Will_the_owner_s_be_on_payroll__c',
  'Sole_Proprietorship_or_partnership__c',
  'Owner_aware_they_will_not_get_W2_wages__c',
  'Owner_not_on_payroll_addendum_collected__c',
  'Client_entity_owned_or_a_non_profit__c',
  'NSP_How_will_the_payroll_be_funded__c',
  'Chngs_for_cafeteria_plan_questionnaire__c',
  'List_change_s__c',
  'Client_part_of_entity_w_o_NSP__c',
  'Payroll_general_notes__c',
  'remove_employee_directory_from_premier__c',
];

const IP_CLIENT_RELATED_CLIENT_FIELDS = [
  'NSP_Related_Client__c',
];

export {
  SYNC_FIELDS,
  RL_FIELDS,
  FIELD_CHANGE_HANDLER_MAPPING,
  PREFILLED_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
  IP_CLIENT_RELATED_CLIENT_FIELDS,
};