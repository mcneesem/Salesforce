const FIELD_VISIBILITY_CONFIG = {
  NSP_clientHaveAnInternationalPresence__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_ClientWorkedWithInternationalSupport__c',
        'NSP_Which_vendor_used__c',
        'NSP_What_countries__c',
        'NSP_Number_of_WSEE_s_in_each_country__c',
      ],
    },
  ],
  NSP_Company_Recognition_and_Rewards__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_PD_Company_Recognition_Rewards__c'],
    },
  ],
  NSP_Do_they_have_SEOs__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Who_are_they__c'],
    },
  ],
  NSP_Do_they_have_an_HSA_match__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_How_much_and_when_did_it_begin__c',
        'NSP_Contribution_management__c',
      ],
    },
  ],
  NSP_Does_the_client_have_classing__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_What_are_they__c', 'NSP_Exceptions__c'],
    },
  ],
  NSP_usng_third_pary_timekeeping_system__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Which_software_are_they_using__c'],
    },
  ],
  NSP_Do_they_have_a_GL_interface__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Wht_financial_sftwre_does_clnt_use__c'],
    },
  ],
  NSP_Added_custom_forms_into_Onboarding__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_What_forms__c'],
    },
  ],
  NSP_Any_client_specific_links__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_PD_client_specific_links__c'],
    },
  ],
  NSP_Are_they_part_any_technology_pilots__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_PD_part_of_any_technology_pilots__c'],
    },
  ],
  NSP_Are_thy_usng_Client_Docs_EE_Folder__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Hv_thy_signed_Client_Doc_addendum__c'],
    },
  ],
  NSP_clint_usng_Custom_Hostng_fr_Training__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Which_vendor__c'],
    },
  ],
  NSP_Do_they_offer_training__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_PD_indstrySpcificTraining_i_e_wt_req__c',
        'NSP_Is_there_an_onsite_trainer__c',
      ],
    },
  ],
  NSP_PTO_Tracking_in_AIMS_Y_N__c: [
    {
      expValue: ['No'],
      dependentFields: [
        'NSP_Client_hv_PTO_Tracking_in_pastAIMS__c'
      ],
    }, 
  ],
  NSP_Client_hv_PTO_Tracking_in_pastAIMS__c: [
    {
      expValue: ['Yes'],
      dependentFields: [
        'NSP_When_was_it_disabled__c'
      ],
    },
  ],
  NSP_PremierEmployeeDirectoryViewSetup__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['NSP_Select_View__c'],
    },
  ],
};

export { FIELD_VISIBILITY_CONFIG };
