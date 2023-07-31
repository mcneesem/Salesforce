const DYNAMIC_FIELDS = {
  Are_there_multiple_worksite_locations__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Provide_multiple_worksite_details__c"],
    },
  ],
  NSP_Is_a_translator_needed__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Wht_language_whn_is_translator_needed__c"],
    },
  ],
  Is_there_a_need_for_a_tech_package__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Tech_pack_when_where_quantity_needed__c"],
    },
  ],
};

export { DYNAMIC_FIELDS };
