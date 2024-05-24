const DYNAMIC_FIELDS = {
  Is_there_a_need_for_a_GL_interface__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_Chart_of_Accounts_GL_codes__c',
        'NSP_Sample_of_current_GL_report__c',
      ],
    },
  ],
  NSP_Select_all_that_apply__c: [
    {
      expValue: ['Integra'],
      dependentFields: ['showIntegraMessage'],
    },
  ],
  Select_BPSes__c: [
    {
      expValue: ['Integra'],
      dependentFields: ['showIntegraMessage'],
    },
    {
      expValue: ['Integra'],
      dependentFields:[
        'What_QuickBooks_version_do_you_use__c',
        'Needed_payroll_entry_allocation__c',
        'Do_you_need_to_allocate_costs__c',
        'Do_you_require_more_than_3_job_cost__c',
        'Do_you_have_a_recent_journal_entry__c',
        ],
    },
  ],
  Select_all_payroll_needs_that_apply__c: [
    {
      expValue: ['Integra'],
      dependentFields: ['showIntegraMessage'],
    },
  ],
  Is_there_a_need_for_Integra__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
      'What_QuickBooks_version_do_you_use__c',
      'Needed_payroll_entry_allocation__c',
      'Do_you_need_to_allocate_costs__c',
      'Do_you_require_more_than_3_job_cost__c',
      'Do_you_have_a_recent_journal_entry__c',
      ],
    },
  ],
  Do_you_have_a_recent_journal_entry__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['showJournalMessage'],
    },
  ],
  Do_you_require_more_than_3_job_cost__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['showJobCostMessage'],
    },
  ],
};

export { DYNAMIC_FIELDS };
