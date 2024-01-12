const DYNAMIC_FIELDS = {
    'Does_the_client_have_any_union_EEs__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Client_union_EE_Check_all_that_Apply__c']
        },
      ],
      'NSP_Any_employee_with_temporary_status__c':[
        {
          expValue: ['Yes'],
          dependentFields: ['empWithTempStatus' ],
        },
      ],
      'Does_client_employ_ministers_or_teachers__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Check_all_tht_apply_ministers_teachers__c']
        },
      ],
      'NSP_non_Insperity_paid_emps_contractors__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Provide_non_insperity_worker_details__c']
        },
      ],
      Any_EEs_travel_internationally_for_work__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["internationalTravelNotify","Provide_EE_travel_details__c"],
        },
      ],
      'Are_there_any_EEs_on_Leave_of_Absence__c':[
        {
          expValue: ['Yes'],
          dependentFields:['Do_you_have_the_LOA_information__c','Select_the_applicable_LOA_types__c','Told_EE_ineligble_for_active_at_work_ben__c','How_will_EE_complete_their_enrollment__c']
        },
      ],
      'NSP_Any_active_severance_agreement__c':[
        {
          expValue: ['Yes'],
          dependentFields:['NSP_how_future_payment_will_be_done__c']
        },
      ],
    
};

export { DYNAMIC_FIELDS };