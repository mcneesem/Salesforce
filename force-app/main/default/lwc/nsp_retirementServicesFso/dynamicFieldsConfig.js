const DYNAMIC_FIELDS = {
  Client_has_existing_retirement_plan__c: [
    {
      expValue: ["Yes"],
      dependentFields: [
        "Type_of_retirement_plan_client_has_today__c",
        "NSP_Is_the_client_working_an_NSP_RS_rep__c",
      ],
    },
    {
      expValue: ["No"],
      dependentFields: ["Client_want_to_begin_401k_w_NSP_setup__c"],
    },
  ],
  Type_of_retirement_plan_client_has_today__c: [
    {
      expValue: ["CSP 401K and wants to keep it", "Simple IRA", "403B"],
      dependentFields: ["Emp_deferral_loan_amount__c"],
    },
  ],
  Client_want_to_begin_401k_w_NSP_setup__c:[
    {
      expValue: ["Yes"],
      dependentFields: ["Client_working_with_an_NSP_RS_rep__c"],

    },
  ],
  Client_working_with_an_NSP_RS_rep__c: [
    {
      expValue: ["No"],
      dependentFields: ["NSP_RS_Doc_Contact_Info__c", "SHOW_Contact_Details"],
    },
  ],
  NSP_Is_the_client_working_an_NSP_RS_rep__c: [
    {
      expValue: ['No'],
      dependentFields: ['Contact_Details'],
    },
  ],
};

export { DYNAMIC_FIELDS };