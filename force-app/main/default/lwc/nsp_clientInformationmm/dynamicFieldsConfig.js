const DYNAMIC_FIELDS = {
    'All_EEs_paid_under_same_FEIN_currently__c': [
        {
          expValue: ['No'],
          dependentFields: ['List_additional_FEIN_s__c']
        },
      ],
      'Has_form_8973_been_discussed__c':[
        {
          expValue: ['Yes', 'No'],
          dependentFields: ['Form_8973_Contact__c','Contact_Information__c'],
        },
      ],
      'Client_expect_chnges_in_the_organization__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Check_all_changes_that_apply__c','List_change_s__c']
        },
      ],
      'Is_the_client_a_federal_contractor__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Client_has_Service_Contract_Act_SCA_EEs__c','Is_the_client_required_to_track__c','NSP_Are_Certified_Payroll_reports_needed__c']
        },
      ],
      'Client_has_Service_Contract_Act_SCA_EEs__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Have_the_SCA_EEs_been_approved__c','SCA_EEs_get_wages_in_lieu_of_benefits__c']
        },
      ],
      'Client_needs_to_e_verify_all_employees__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['NSP_How_e_verify_be_completed__c']
        },
      ],
      'Client_have_EEO_filing_under__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Can_client_provide_EEO_filing_address__c']
        },
      ],
      'Can_client_provide_EEO_filing_address__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['EEO__c', 'Filing_address__c']
        },
        {
          expValue: ['No'],
          dependentFields: ['EEO_name_phone_contact_email_for_info__c']
        },
      ],
      'Client_Profile_Information__c': [
        {
          expValue: ["Related Clients"],
          dependentFields: ["Show_Related_Clients"],
        },
      ],
    
};

export { DYNAMIC_FIELDS };