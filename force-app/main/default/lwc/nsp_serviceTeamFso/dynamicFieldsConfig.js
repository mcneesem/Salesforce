const DYNAMIC_FIELDS = {
  NSP_Immediate_need_for_Workers_Comp_Cert__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'When_are_certificates_needed__c',
        'List_of_certificates_requested__c',
        'Send_the_certificates_to__c',
      ],
    },
  ],
  Client_have_any_urgent_HR_needs__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Provide_Urgent_HR_Needs_details__c'],
    },
  ],
  Client_expect_chnges_in_the_organization__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Check_all_changes_that_apply__c', 'Provide_organization_change_details__c'],
    },
  ],
};

export { DYNAMIC_FIELDS };
