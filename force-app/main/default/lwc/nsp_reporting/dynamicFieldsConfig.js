const DYNAMIC_FIELDS = {
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
  NSP_Select_all_that_apply__c: [
    {
      expValue: ['Integra'],
      dependentFields: ['showIntegraMessage'],
    },
  ],
};

export { DYNAMIC_FIELDS };
