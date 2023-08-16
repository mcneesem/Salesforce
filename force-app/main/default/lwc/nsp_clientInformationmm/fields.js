const RL_FIELDS = [
  'Has_FEIN_documentation_been_collected__c',
  'Are_sample_intro_letters_being_provided__c',
];

const FIELD_CHANGE_HANDLER_MAPPING = {
  Client_FEIN__c: 'getClientFEINValue',
};

const SECTION_FIELDS = [
  'NSP_AIMS_ClientNo_KDM__c',
  'NSP_KDM_Client_Office_Phone__c',
  'NSP_KDM_Client_Email__c',
  'NSP_KDM_Client_Name__c',
  'NSP_KDM_Client_Cell_Phone__c',
  'NSP_KDM_Client_Contact_Method__c',
  'NSP_KDM_Job_Title__c',
  'NSP_AIMS_ClientNo_OSS__c',
  'NSP_OSS_Client_Office_Phone__c',
  'NSP_OSS_Client_Email__c',
  'NSP_OSS_contact_is_same_as_KDM__c',
  'NSP_OSS_Client_Name__c',
  'NSP_OSS_Client_Cell_Phone__c',
  'NSP_OSS_Client_Contact_Method__c',
  'NSP_OSS_Job_Title__c',
  'NSP_AIMS_ClientNo_WC__c',
  'NSP_WC_Client_Office_Phone__c',
  'NSP_WC_Client_Email__c',
  'NSP_WC_contact_is_same_as_OSS__c',
  'NSP_WC_Client_Name__c',
  'NSP_WC_Client_Cell_Phone__c',
  'NSP_WC_Client_Contact_Method__c',
  'NSP_WC_Job_Title__c',
  'NSP_AIMS_ClientNo_PC__c',
  'NSP_PC_Client_Office_Phone__c',
  'NSP_PC_Client_Email__c',
  'NSP_PC_is_same_as_OSS__c',
  'NSP_PC_Client_Name__c',
  'NSP_PC_Client_Cell_Phone__c',
  'PC_Client_Contact_Method__c',
  'NSP_PC_Job_Title__c',
  'NSP_No_back_up_PC__c',
  'NSP_AIMS_ClientNo_Backup_PC__c',
  'NSP_Back_up_PC_Client_Name__c',
  'NSP_Back_up_Client_Cell_Phone__c',
  'NSP_Back_up_Client_Contact_Method__c',
  'NSP_Back_up_Client_Office_Phone__c',
  'NSP_Back_up_Client_Email__c',
  'NSP_Back_up_PC_Job_Title__c',
  'NSP_HR_Client_Name__c',
  'HR_Contact_Cell_Phone__c',
  'HR_Contact_Method__c',
  'HR_contact_is_same_as_OSS__c',
  'HR_Contact_Office_Phone__c',
  'NSP_HR_Job_Title__c',
  'NSP_AIMS_ClientNo_HR__c',
  'Effective_Date_Payroll_Worker_comp_EPLI__c',
  'NSP_Service_Model__c',
  'Client_Profile_Information__c',
  'NSP_Related_Client__c',
  'Business_Inception_Date__c',
  'Client_FEIN__c',
  'All_EEs_paid_under_same_FEIN_currently__c',
  'List_additional_FEIN_s__c',
  'Has_FEIN_documentation_been_collected__c',
  'Has_form_8973_been_discussed__c',
  'Form_8973_Contact__c',
  'Contact_Information__c',
  'Arbitration_Agreement_been_discussed__c',
  'State_Unemployment_Insurance_SUI_Num__c',
  'Client_expect_chnges_in_the_organization__c',
  'Check_all_changes_that_apply__c',
  'List_change_s__c',
  'Is_the_client_a_federal_contractor__c',
  'Client_has_Service_Contract_Act_SCA_EEs__c',
  'Have_the_SCA_EEs_been_approved__c',
  'SCA_EEs_get_wages_in_lieu_of_benefits__c',
  'Is_the_client_required_to_track__c',
  'NSP_Are_Certified_Payroll_reports_needed__c',
  'Are_sample_intro_letters_being_provided__c',
  'Client_previously_filed_an_EEO_1_Report__c',
  'Client_needs_to_e_verify_all_employees__c',
  'NSP_How_e_verify_be_completed__c',
  'Client_have_EEO_filing_under__c',
  'Can_client_provide_EEO_filing_address__c',
  'EEO__c',
  'Filing_address__c',
  'EEO_name_phone_contact_email_for_info__c',
  'NSP_co_employ_100_of_client_workforce__c',
  'Client_part_of_entity_w_o_NSP__c',
  'NSP_Who_receives_Insperity_Communication__c',
  'Direct_deposit_offered_to_employees__c',
  'Client_Contact_Notes__c',
  'NSP_HR_Client_Email__c',
];
const SYNC_FIELDS = {
  Account__c: 'prefilledIpDetails',
};

const POST_SYNC_IP_FIELDS = { prefilledIpDetails: 'updatePrefilledIpValues' };
const PREFILLED_FIELDS = {
  All_EEs_paid_under_same_FEIN_currently__c:
    'All_EEs_paid_under_same_FEIN_currently__c',
  Client_FEIN__c: 'Client_FEIN__c',
  Client_Profile_Information__c: 'Client_Profile_Information__c',
  Effective_Date_Payroll_Worker_comp_EPLI__c:
    'Effective_Date_Payroll_Worker_comp_EPLI__c',
};

const BACKUP_PC_FIELDS = [
  'NSP_Back_up_PC_Client_Name__c',
  'NSP_Back_up_PC_Job_Title__c',
  'NSP_AIMS_ClientNo_Backup_PC__c',
  'NSP_Back_up_Client_Office_Phone__c',
  'NSP_Back_up_Client_Cell_Phone__c',
  'NSP_Back_up_Client_Email__c',
  'NSP_Back_up_Client_Contact_Method__c',
];

const PHONE_NUMBER_FIELDS = [
  'NSP_KDM_Client_Office_Phone__c',
  'NSP_KDM_Client_Cell_Phone__c',
  'NSP_OSS_Client_Office_Phone__c',
  'NSP_OSS_Client_Cell_Phone__c',
  'NSP_WC_Client_Office_Phone__c',
  'NSP_PC_Client_Office_Phone__c',
  'NSP_PC_Client_Cell_Phone__c',
  'NSP_Back_up_Client_Office_Phone__c',
  'NSP_Back_up_Client_Cell_Phone__c',
  'HR_Contact_Office_Phone__c',
  'HR_Contact_Cell_Phone__c',
  'NSP_WC_Client_Cell_Phone__c',
];

const OSS_KDM_MAPPING = {
  NSP_OSS_Client_Name__c : 'NSP_KDM_Client_Name__c',
  NSP_OSS_Client_Contact_Method__c : 'NSP_KDM_Client_Contact_Method__c',
  NSP_OSS_Job_Title__c : 'NSP_KDM_Job_Title__c',
  NSP_AIMS_ClientNo_OSS__c : 'NSP_AIMS_ClientNo_KDM__c',
  NSP_OSS_Client_Office_Phone__c : 'NSP_KDM_Client_Office_Phone__c',
  NSP_OSS_Client_Email__c : 'NSP_KDM_Client_Email__c',
  NSP_OSS_Client_Cell_Phone__c : 'NSP_KDM_Client_Cell_Phone__c',
};

const WC_OSS_MAPPING = {
  NSP_WC_Client_Name__c : 'NSP_OSS_Client_Name__c',
  NSP_WC_Client_Contact_Method__c : 'NSP_OSS_Client_Contact_Method__c',
  NSP_WC_Job_Title__c : 'NSP_OSS_Job_Title__c',
  NSP_AIMS_ClientNo_WC__c : 'NSP_AIMS_ClientNo_OSS__c',
  NSP_WC_Client_Office_Phone__c : 'NSP_OSS_Client_Office_Phone__c',
  NSP_WC_Client_Email__c : 'NSP_OSS_Client_Email__c',
  NSP_WC_Client_Cell_Phone__c : 'NSP_OSS_Client_Cell_Phone__c',
};

const PC_OSS_MAPPING = {
  NSP_PC_Client_Name__c : 'NSP_OSS_Client_Name__c',
  PC_Client_Contact_Method__c : 'NSP_OSS_Client_Contact_Method__c',
  NSP_PC_Job_Title__c : 'NSP_OSS_Job_Title__c',
  NSP_AIMS_ClientNo_PC__c : 'NSP_AIMS_ClientNo_OSS__c',
  NSP_PC_Client_Office_Phone__c : 'NSP_OSS_Client_Office_Phone__c',
  NSP_PC_Client_Email__c : 'NSP_OSS_Client_Email__c',
  NSP_PC_Client_Cell_Phone__c : 'NSP_OSS_Client_Cell_Phone__c',
};

const HR_OSS_MAPPING = {
  NSP_HR_Client_Name__c : 'NSP_OSS_Client_Name__c',
  HR_Contact_Method__c : 'NSP_OSS_Client_Contact_Method__c',
  NSP_HR_Job_Title__c : 'NSP_OSS_Job_Title__c',
  NSP_AIMS_ClientNo_HR__c : 'NSP_AIMS_ClientNo_OSS__c',
  HR_Contact_Office_Phone__c : 'NSP_OSS_Client_Office_Phone__c',
  NSP_HR_Client_Email__c : 'NSP_OSS_Client_Email__c',
  HR_Contact_Cell_Phone__c : 'NSP_OSS_Client_Cell_Phone__c',
};

const DEPENDENT_FIELDS_MAPPING = {
  NSP_OSS_contact_is_same_as_KDM__c: OSS_KDM_MAPPING,
  NSP_WC_contact_is_same_as_OSS__c: WC_OSS_MAPPING,
  NSP_PC_is_same_as_OSS__c: PC_OSS_MAPPING,
  HR_contact_is_same_as_OSS__c: HR_OSS_MAPPING, 
};

const IP_CLIENT_RELATED_CLIENT_FIELDS = [
  'NSP_Related_Client__c',
];

const ADDITIONAL_CLIENT_CONTACTS_FIELDS = [
  ['NSP_Contact_Type__c', 'Name'],
  ['NSP_AIMS_Client__c', 'NSP_Office_Phone__c'],
  ['NSP_Email_Address__c', 'NSP_Job_Title__c'],
  ['NSP_Cell_Phone__c', 'NSP_Contact_Method__c'],
];

export {
  RL_FIELDS,
  FIELD_CHANGE_HANDLER_MAPPING,
  PREFILLED_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
  BACKUP_PC_FIELDS,
  PHONE_NUMBER_FIELDS,
  IP_CLIENT_RELATED_CLIENT_FIELDS,
  DEPENDENT_FIELDS_MAPPING,
  ADDITIONAL_CLIENT_CONTACTS_FIELDS,
};