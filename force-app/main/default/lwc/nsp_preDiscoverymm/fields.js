const RL_FIELDS = [
  'Received_Section_125_Questionnaire__c',
  'Gotten_Cvrg_Cert_Gen_Liability_Auto__c',
];

const SECTION_FIELDS = [
  'Num_of_Worksite_Employees_Full_Time__c',
  'Num_of_Worksite_Employees_Part_Time__c',
  'Num_of_Worksite_Employees_Seasonal__c',
  'Any_Special_Agreements_Addendum_in_CSA__c',
  'Special_Agreement_Addendum_details__c',
  'Insperity_Empl_contrib_rate_determined__c',
  'Received_Section_125_Questionnaire__c',
  'Gotten_Cvrg_Cert_Gen_Liability_Auto__c',
  'Gen_liability_auto_coverage_details__c',
  'Received_Enrollment_Fee__c',
  'Employees_work_in_the_following_states__c',
  'Will_there_be_benefits_classing__c',
  'Pre_Discovery_Notes__c',
];
const SYNC_FIELDS = {
  Account__c: 'prefilledIpDetails',
  'wcPolicy': 'Employees_work_in_the_following_states__c',
};

const POST_SYNC_IP_FIELDS = { prefilledIpDetails: 'updatePrefilledIpValues' };
const PREFILLED_FIELDS = {
  Will_there_be_benefits_classing__c: 'Will_there_be_benefits_classing__c',
  Num_of_Worksite_Employees_Full_Time__c:
    'Num_of_Worksite_Employees_Full_Time__c',
  Num_of_Worksite_Employees_Part_Time__c:
    'Num_of_Worksite_Employees_Part_Time__c',
};

export {
  RL_FIELDS,
  PREFILLED_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
};
