const DYNAMIC_FIELDS = {
    'NSP_Immediateworkerscomporsafety_concern__c':[
        {
          expValue: ['Yes'],
          dependentFields: ['NSP_workers_comp_or_safety_concerns_PD__c'],
        },
      ],
      'Regulatory_accreditation_inspections__c':[
        {
          expValue: ['Yes'],
          dependentFields: ['Inspection_details__c'],
        },
      ],
      'NSP_Immediate_need_for_Workers_Comp_Cert__c':[
        {
          expValue: ['Yes'],
          dependentFields: ['When_are_certificates_needed__c'],
        },
      ],
      Employees_work_in_the_following_states__c: [
        {
          expValue: ['CA'],
          dependentFields: ['Are_you_a_licensed_Contractor__c'],
        },
      ],
      Are_you_a_licensed_Contractor__c: [
        {
          expValue: ['Yes'],
          dependentFields: ['Are_you_registered_with_the_CSLB__c', 'Contractor_s_License__c'],
        },
      ],
    
};

export { DYNAMIC_FIELDS };