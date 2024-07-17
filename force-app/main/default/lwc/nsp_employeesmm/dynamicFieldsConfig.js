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
      'Client_have_will_have_any_Seasonal_EEs__c':[
        {
          expValue: ['Yes'],
          dependentFields:['Do_the_employee_s_work_more_than_6__c','What_months_client_increase_the_staff__c','Is_the_work_performed_typically_the_same__c','work_performed_the_same_as_the_rest_year__c','Is_the_Employee_an_Intern__c']
        },
      ],
      'Work_performed_the_same_as_the_rest_year__c':[
        {
          expValue: ['Different'],
          dependentFields:['Describe_the_type_of_work__c']
        },
      ],
      'Is_the_Employee_an_Intern__c':[
        {
          expValue: ['Yes'],
          dependentFields:['What_months_is_the_Intern_working__c','What_months_is_the_Intern_in_school__c']
        },
      ],
    
};

export { DYNAMIC_FIELDS };