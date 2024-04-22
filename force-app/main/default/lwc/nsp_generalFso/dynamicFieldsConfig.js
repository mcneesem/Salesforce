const DYNAMIC_FIELDS = {
  Is_the_client_coming_from_another_PEO__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["PEO_Name__c"],
    },
  ],
  Client_Implementing_Premier_Performance__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["When_Client_Wants_Solution_implemented__c"],
    },
  ],
  Select_BPSes__c: [
    {
      expValue: ["Organization Planning"],
      dependentFields: ["Organizational_Planning_Imp_Timeline__c"],
    },
    {
      expValue: ["Integra"],
      dependentFields: ["Integra_Implementation_Timeline__c"],
    },
    {
      expValue: ["Premier Performance"],
      dependentFields: ["Premier_Performance_Imp_Timeline__c"],
    },
  ],
  Implementing_biz_Performance_solutions__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Select_BPSes__c"],
    },
  ],
  Client_Profile_Information__c: [
    {
      expValue: ["National Account - No Hush Protocol"],
      dependentFields: ["NSP_Account_Executive__c","Hush_Protocol__c"],
    },
    {
      expValue: ["Related Clients"],
      dependentFields: ["Show_Related_Clients"],
    },
  ],
  All_EEs_paid_under_same_FEIN_currently__c: [
    {
      expValue: ["No"],
      dependentFields: ["List_additional_FEIN_s__c"],
    },
  ],
  Gotten_Cvrg_Cert_Gen_Liability_Auto__c: [
    {
      expValue: ["Received"],
      dependentFields: ["Gen_liability_auto_coverage_details__c"],
    },
    {
      expValue: ["Requested"],
      dependentFields: ["Gen_liability_auto_coverage_details__c"],
    },
  ],
  Will_the_owner_s_be_on_payroll__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Sole_Proprietorship_or_partnership__c"],
    },
    {
      expValue: ["No"],
      dependentFields: ["Owner_not_on_payroll_addendum_collected__c"],
    },
    {
      expValue: ["N/A"],
      dependentFields: ["Client_entity_owned_or_a_non_profit__c"],
    },
  ],
  Sole_Proprietorship_or_partnership__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["Owner_aware_they_will_not_get_W2_wages__c"],
    },
  ],
  Chngs_for_cafeteria_plan_questionnaire__c: [
    {
      expValue: ["Yes"],
      dependentFields: ["List_change_s__c"],
    },
  ],
  Employee_Data_Collection_EDC_collected__c: [
    {
      expValue: ["Requested - Not collected"],
      dependentFields: ["Provide_deadline_date__c"],
    },
  ],
};

export { DYNAMIC_FIELDS };