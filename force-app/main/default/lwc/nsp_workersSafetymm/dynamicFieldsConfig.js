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
    
};

export { DYNAMIC_FIELDS };