const RL_FIELDS = ['NSP_collected_copies_of_state_WC_policy__c'];

const SECTION_FIELDS = [
  'NSP_Immediate_need_for_Workers_Comp_Cert__c',
  'NSP_collected_copies_of_state_WC_policy__c',
  'Regulatory_accreditation_inspections__c',
  'NSP_workers_comp_or_safety_concerns_PD__c',
  'Inspection_details__c',
  'Interested_in_on_site_safety_inspections__c',
  'NSP_Immediateworkerscomporsafety_concern__c',
  'When_are_certificates_needed__c',
  'Workers_Comp_Safety_Notes__c',
];

const SYNC_FIELDS = {
  Employees_work_in_the_following_states__c: 'employeesWorkStates',
};

const POST_SYNC_IP_FIELDS = {
  employeesWorkStates: 'updateEmployeesWorkStates',
};

const UNEMPLOYMENT_STATES = ['WY', 'ND', 'WA', 'OH'];

export {
  RL_FIELDS,
  SECTION_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
  UNEMPLOYMENT_STATES,
};