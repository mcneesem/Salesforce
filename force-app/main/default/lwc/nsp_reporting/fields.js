const RL_FIELDS = [
  'NSP_Chart_of_Accounts_GL_codes__c',
  'NSP_Sample_of_current_GL_report__c',
];

const SECTION_FIELDS = [
  'NSP_Select_all_that_apply__c',
  'Implementation_Profile__c',
  'What_current_payroll_reports_being_used__c',
  'Is_there_a_need_for_a_GL_interface__c',
  'NSP_Chart_of_Accounts_GL_codes__c',
  'NSP_Sample_of_current_GL_report__c',
  'NSP_Name_of_accounting_software__c',
];

const SYNC_FIELDS = {
  Select_all_payroll_needs_that_apply__c: 'NSP_Select_all_that_apply__c',
  
}

const PRE_SYNC_IP_FIELDS = { Select_BPSes__c: 'Integra', 
                            Select_all_payroll_needs_that_apply__c: 'Integra' };
export { SECTION_FIELDS, RL_FIELDS,SYNC_FIELDS, PRE_SYNC_IP_FIELDS};