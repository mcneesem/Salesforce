import workersSafety from '@salesforce/label/c.NSP_Workers_Safety';

const LABEL = { workersSafety };

const CLASS_BY_ORDER = {
  1: 'level-1',
  2: 'level-2',
  3: 'level-3',
};

const SPECIALFIELDS = [
  'Received_Section_125_Questionnaire__c',
  'Has_FEIN_documentation_been_collected__c',
  'Are_sample_intro_letters_being_provided__c',
  'Client_provided_copy_of_communication__c',
  'Client_has_any_special_payroll_needs__c',
  'Do_any_EEs_have_garnishments__c',
  'Do_any_EEs_have_tax_levies__c',
  'Gave_copy_of_PTO_sick_leave_other_policy__c',
  'NSP_Chart_of_Accounts_GL_codes__c',
  'NSP_Sample_of_current_GL_report__c',
  'NSP_Client_s_holiday_calendar__c',
  'Recent_Payroll_Register_Collected__c',
  'Chngs_for_cafeteria_plan_questionnaire__c',
  'sample_new_empl_info_packet_collected__c',
  'NSP_collected_copies_of_state_WC_policy__c',
  'Gotten_Cvrg_Cert_Gen_Liability_Auto__c',
];
const SELECTEDVALUE = [
  'Requested',
  'Requested - Not Collected',
  'Requested - Not collected',
];

export { LABEL, CLASS_BY_ORDER, SPECIALFIELDS, SELECTEDVALUE };
