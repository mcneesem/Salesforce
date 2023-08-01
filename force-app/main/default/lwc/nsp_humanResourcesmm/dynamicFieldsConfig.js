const DYNAMIC_FIELDS = {
  Client_have_any_urgent_HR_needs__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Select_client_urgent_HR_needs__c'],
    },
  ],
  Select_client_urgent_HR_needs__c: [
    {
      expValue: ['Other'],
      dependentFields: ['Other_urgent_HR_needs_provide_details__c'],
    },
  ],
  Are_there_any_DOL_audits__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['DOL_Audit_Provide_Details__c'],
    },
  ],
  Client_has_any_of_the_following__c: [
    {
      expValue: ['Handbook'],
      dependentFields: ['When_was_the_handbook_last_updated__c'],
    },
  ],
  Does_client_perform_background_checks__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Who_is_the_provider__c'],
    },
  ],
  Client_does_pre_employment_drug_screen__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Wh_is_the_provider__c'],
    },
  ],
};

export { DYNAMIC_FIELDS };
