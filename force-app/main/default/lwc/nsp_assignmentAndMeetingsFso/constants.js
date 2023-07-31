const SYNC_FIELDS = {
  Account__c: 'prefilledIpDetails',
  NSP_BPA_BPC__c: 'NSP_BPA_BPC__c'
};

const POST_SYNC_IP_FIELDS = { prefilledIpDetails: 'updatePrefilledIpValues' };
const PREFILLED_FIELDS = {
  Num_of_Worksite_Employees_Full_Time__c:
    'Num_of_Worksite_Employees_Full_Time__c',
  Num_of_Worksite_Employees_Part_Time__c:
    'Num_of_Worksite_Employees_Part_Time__c',
  DBA__c: 'DBA__c',
};

export { PREFILLED_FIELDS, SYNC_FIELDS, POST_SYNC_IP_FIELDS };
