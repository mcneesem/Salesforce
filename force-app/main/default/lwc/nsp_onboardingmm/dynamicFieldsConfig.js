const DYNAMIC_FIELDS = {
  'Review_Insperity_Online_Enrollment_Steps__c': [
      {
        expValue: ['Employee Enrollment'],
        dependentFields: ['Employee_Enrollment__c']
      },
    ],
    'Are_there_multiple_worksite_locations__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['Provide_multiple_worksite_details__c']
      },
    ],
    'Is_there_a_need_for_a_tech_package__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['NSP_When_where_and_quantity_needed__c']
      },
    ],
    'Is_the_client_coming_from_another_PEO__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['PEO_Name__c']
      },
    ],
    'EE_enrollments_outside_of_Insperity__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['Select_all_enrollments__c','How_will_enrollments_be_handled__c']
      },
    ],
    'NSP_remote_EEs_not_working_physical_loc__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['remoteI9Message']
      },
    ],
    'Client_does_business_in_MA_NY_or_VA__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['Client_business_in_MA_NY_or_VA__c']
      },
    ],
    'Have_EEs_been_notified_of_the_transition__c': [
      {
        expValue: ['Yes'],
        dependentFields: ['Client_provided_copy_of_communication__c']
      },
    ],
    'Is_there_a_separate_Vacation_policy__c':[
      {
      expValue: ['Yes'],
      dependentFields: ['Where_is_the_policy_located__c']
      },
    ],
    'NSP_Is_a_translator_needed__c':[
      {
        expValue: ['Yes'],
        dependentFields: ['Wht_language_whn_is_translator_needed__c']
      }
    ],
    'employee_states':[
      {
        expValue: ['CA'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_separate_pay_document_specify__c',
          'Written_doc_pay_plan_for_how_EE_is_paid__c',
          'Paid_Sick_Leave_Plan_Type__c',
          'San_Diego_Earned_Sick__c'
        ]
      },
      {
        expValue: ['NH'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_New_Hampshire__c', 
          'Is_there_a_separate_Vacation_policy__c']
      },
      {
        expValue: ['NY'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_New_York__c', 
          'Earned_Sick_Time_Start_Date__c']
      },
      {
        expValue: ['SC'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_South_Carolina__c', 
          'NSP_Standard_No_of_Hours_worked_for_EEs__c']
      },
      {
        expValue: ['DC'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_Washington_DC__c', 
          'Basis_of_wage_payment_options__c', 
          'Must_show_FLSA_EE_exemp_cat_for_all_EEs__c']
      },
      {
        expValue: ['WA'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_EarnedSick_Time_StartDate_Washington__c', 
          'Sick_Leave_balance_type__c']
      },
      {
        expValue: ['IL'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_Illinois__c', 
          'Checks_delivered__c']
      },
      {
        expValue: ['MD'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_Maryland__c']
      },
      {
        expValue: ['MN'],
        dependentFields: [
          'NSP_State_require_specific_priming_field__c',
          'NSP_Separate_pay_document_Minnesota__c',
          'Leave_Benefits__c',
          'Is_exempt_from_Minimum_Wage__c',
          'Is_exempt_from_MN_Statute_177__c',
          'Overtime_owed_after_how_many_hrs_worked__c',
          'NSP_FLSA_EE_exemption_category_provided__c'
        ]
      },
    ],
    'Written_doc_pay_plan_for_how_EE_is_paid__c':[
      {
        expValue: ['Yes'],
        dependentFields: ['Are_all_of_the_rates_in_agreement__c']
      },
    ],
    'NSP_Standard_No_of_Hours_worked_for_EEs__c':[
      {
        expValue:['Other'],
        dependentFields: ['NSP_No_of_Hours_worked_for_EEs_PD__c']
      }
    ],
};

export { DYNAMIC_FIELDS };