const actions = [
  { label: 'Edit', name: 'Edit' },
  { label: 'Delete', name: 'delete' },
];

const TABLE1 = [
  {
    label: 'Account Name',
    fieldName: 'memberAccountUrl',
    type: 'url',
    typeAttributes: {
      label: { fieldName: 'NSP_Account_Name__c' },
      target: '_self',
    },
  },
  {
    label: 'AIMS Client ID',
    fieldName: 'NSP_AIMS_Client_ID__c',
  },
  {
    label: 'Insperity Client',
    fieldName: 'NSP_Insperity_Client__c',
  },
  {
    label: 'Enter Date',
    fieldName: 'NSP_Enter_Date__c',
  },
  {
    label: 'HiComp EEs',
    fieldName: 'NSP_Hicomp_EEs__c',
  },
  {
    label: 'Total EEs',
    fieldName: 'NSP_Total_EEs__c',
  },
  {
    type: 'action',
    typeAttributes: { rowActions: actions },
  },
];

const TABLE2 = [
  {
    label: 'Account Group Member Name',
    fieldName: 'accountGroupMemberRecordUrl',
    type: 'url',
    typeAttributes: { label: { fieldName: 'Name' }, target: '_self' },
  },
  {
    label: 'Account Name',
    fieldName: 'memberAccountUrl',
    type: 'url',
    typeAttributes: {
      label: { fieldName: 'NSP_Account_Name__c' },
      target: '_self',
    },
  },
  {
    label: 'AIMS Client ID',
    fieldName: 'NSP_AIMS_Client_ID__c',
  },
  {
    label: 'Primary',
    fieldName: 'NSP_Primary__c',
    type: 'boolean',
  },
  {
    label: 'Type',
    fieldName: 'NSP_Type__c',
  },
  {
    label: 'Payroll Employees',
    fieldName: 'NSP_Payroll_Employees__c',
  },
  {
    type: 'action',
    typeAttributes: { rowActions: actions },
  },
];

const AURA_COMP = {
  Account_Group_Member: 'c__NSP_NewAccountGroupMember',
};

const ACCOUNT_GROUPS = ['Account Health','Renewal Probability', 'Growth Forecast']

export { TABLE1, TABLE2, AURA_COMP , ACCOUNT_GROUPS};
