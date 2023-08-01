const DYNAMIC_FIELDS = {
  Is_arrearage_7_days__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Have_credit_services_approved__c',
        'Does_arrearage_comply_with_state_laws__c',
      ],
    },
  ],
  Have_credit_services_approved__c: [
    {
      expValue: ['No'],
      dependentFields: ['Provide_credit_services_detaIls__c'],
    },
  ],
  Does_arrearage_comply_with_state_laws__c: [
    {
      expValue: ['No'],
      dependentFields: ['Provide_arrearage_details__c'],
    },
  ],
  Frequency__c: [
    {
      expValue: ['Semi-Monthly'],
      dependentFields: [
        'Non_exempt_EEs_on_semi_monthly_pay_freq__c',
        'Semi_monthly_pay_freq_comply_w_state_law__c',
      ],
    },
  ],
  Does_the_client_have_prior_wages__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Final_pay_period_prior_to_Insperity__c',
        'Final_pay_date_prior_to_Insperity__c',
      ],
    },
  ],
};

export { DYNAMIC_FIELDS };