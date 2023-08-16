const EMP_TABLE_FIELDS = {
    Client_working_with_an_NSP_RS_rep__c: [
      "NSP_RS_Contact_Name__c",
      "NSP_RS_Work_Phone__c",
      "NSP_RS_Email_Address__c",
    ],
    NSP_Is_the_client_working_an_NSP_RS_rep__c: [
      "NSP_RS_Contact_Name__c",
      "NSP_RS_Work_Phone__c",
      "NSP_RS_Email_Address__c",
    ],
  };

const SECTION_FIELDS = [
  'Client_has_existing_retirement_plan__c',
  'Implementation_Profile__c',
  'Type_of_retirement_plan_client_has_today__c',
  'Emp_deferral_loan_amount__c',
  'Client_working_with_an_NSP_RS_rep__c',
  'Client_want_to_begin_401k_w_NSP_setup__c',
  'NSP_RS_Contact__c',
  'NSP_RS_Doc_Contact_Info__c',
  'Retirement_services_notes__c',
  'NSP_Is_the_client_working_an_NSP_RS_rep__c'
];

export { EMP_TABLE_FIELDS, SECTION_FIELDS };