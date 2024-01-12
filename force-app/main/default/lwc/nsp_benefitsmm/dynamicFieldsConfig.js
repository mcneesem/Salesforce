const DYNAMIC_FIELDS = {
  Any_EEs_in_clients_waiting_period__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Client_s_previous_waiting_period__c'],
    },
  ],
  Part_time_employees_enrolled_in_benefits__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Reason_for_eligibility__c'],
    },
  ],
  client_terminated_old_benefit_coverage__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Prior_Benefits_Termination_Date__c'],
    },
  ],
  Is_current_medical_provider_UHC__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['memberIDMessage'],
    },
  ],
  Previous_challenges_w_current_provider__c: [
    {
      expValue: ['Other'],
      dependentFields: ['Previous_challenge_provide_details__c'],
    },
  ],
  Insperity_grp_hlth_plan_replacing_prior__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Previous_group_plan_is_terminating__c',
        'Old_grp_health_plan_coverage_period_was__c',
        'Previous_group_health_plan_administrator__c',
        'Previous_group_health_plan_carrier_s__c',
        'Carrier_notified_of_termination__c',
        'Previous_group_health_plan_coverage_type__c',
      ],
    },
  ],
  Old_grp_health_plan_coverage_period_was__c: [
    {
      expValue: ['Other Plan Year'],
      dependentFields: ['Provide_start_end_dates_of_plan_year__c'],
    },
  ],
  Previous_group_health_plan_administrator__c: [
    {
      expValue: ['Other Administrator'],
      dependentFields: ['Old_plan_administrator_was_another_PEO__c'],
    },
  ],
  Old_plan_administrator_was_another_PEO__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Provide_PEO_Name__c'],
    },
  ],
  Previous_group_health_plan_coverage_type__c: [
    {
      expValue: ['Other'],
      dependentFields: ['Other_Health_Plan_Coverage_Type__c'],
    },
  ],
  Does_the_client_currently_offer_a_FSA__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Employees_currently_enrolled_in_FSA__c',
        'What_are_the_FSA_plan_dates__c',
        'Client_maintain_own_FSA__c',
      ],
    },
  ],
  Does_the_client_offer_a_HSA__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'Any_employees_currently_enrolled__c',
        'Is_client_s_current_HSA_with_Optum_Bank__c',
        'Client_is_making_employer_contributions__c',
      ],
    },
  ],
  Is_client_s_current_HSA_with_Optum_Bank__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Does_client_have_their_code_group_ID__c'],
    },
    {
      expValue: ['No'],
      dependentFields: ['Who_is_the_current_custodian_bank__c'],
    },
  ],
  Does_client_have_their_code_group_ID__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Optum_Bank_HSA_Code__c', 'Optum_Bank_HSA_Group__c'],
    },
  ],
  Any_employer_contributions_to_EE_HSA__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Provide_Details__c'],
    },
  ],
  NSP_Client_Sponsored_Plan__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Sponsored_plan_contribution_type__c'],
    },
  ],
  Sponsored_plan_contribution_type__c: [
    {
      expValue: ['Pre-Tax'],
      dependentFields: ['Pre_tax_Client_Sponsored_Plan_CSP_Type__c'],
    },
    {
      expValue: ['Post-Tax'],
      dependentFields: ['Post_tax_suppl_insurance_provide_details__c'],
    },
  ],
  Pre_tax_Client_Sponsored_Plan_CSP_Type__c: [
    {
      expValue: ['Health Care Flexible Spending Account (HCFSA)'],
      dependentFields: ['NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c', 'NSP_HCFSA_Delayed_Start_Date__c'],
    },
    {
      expValue: ['Health Savings Account'],
      dependentFields: ['NSP_HSA_Ongoing_CSP_cafeteria_document__c', 'NSP_Health_Savings_Account_Delayed_Start__c'],
    },
    {
      expValue: ['Dependent Care Flexible Spending Account (DCFSA)'],
      dependentFields: ['NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c'],
    },
    {
      expValue: ['Medical (Pretax)'],
      dependentFields: ['NSP_Medical_Ongoing_CSP_cafeteria_Doc__c', 'NSP_Medical_Pretax_Delayed_Start__c'],
    },
    {
      expValue: ['Dental (Pretax)'],
      dependentFields: ['NSP_Dental_Ongoing_CSP_cafeteria_Doc__c', 'NSP_Dental_Pretax_Delayed_Start__c'],
    },
    {
      expValue: ['Vision (Pretax)'],
      dependentFields: ['NSP_Vision_Ongoing_CSP_cafeteria_Doc__c', 'NSP_Vision_Pretax_Delayed_Start__c'],
    },
  ],
  NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c: [
    {
      expValue: ['NA'],
      dependentFields: ['NSP_HCFSA_Provide_Details__c'],
    },
  ],
  NSP_HSA_Ongoing_CSP_cafeteria_document__c: [
    {
      expValue: ['NA'],
      dependentFields: ['NSP_HSA_Provide_Details__c'],
    },
  ],
  NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c: [
    {
      expValue: ['NA'],
      dependentFields: ['NSP_DCFSA_Provide_details__c'],
    },
  ],
  NSP_Medical_Ongoing_CSP_cafeteria_Doc__c: [
    {
      expValue: ['NA'],
      dependentFields: ['NSP_Medical_Pretax_Provide_details__c'],
    },
  ],
  NSP_Dental_Ongoing_CSP_cafeteria_Doc__c: [
    {
      expValue: ['NA'],
      dependentFields: ['NSP_Dental_Pretax_Provide_Details__c'],
    },
  ],
  NSP_Vision_Ongoing_CSP_cafeteria_Doc__c: [
    {
      expValue: ['NA'],
      dependentFields: ['NSP_Vision_Pretax_Provide_Details__c'],
    },
  ],
  NSP_Client_retaining_benefit_plan__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['benefitPlanMesssage'],
    },
  ],
  Client_covering_addl_paid_life_insurance__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['lifeInsuranceMessage'],
    },
  ],
  Uses_WageWorks_for_commuter_benefit_plan__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['wageWorkPlanMessage'],
    },
  ],
  Non_active_non_paid_empl_w_benefits_cov__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['benefitCoverageMessage'],
    },
  ],
};

export { DYNAMIC_FIELDS };
