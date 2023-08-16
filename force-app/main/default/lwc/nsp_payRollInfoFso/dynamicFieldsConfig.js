const DYNAMIC_FIELDS = {
    Are_there_any_non_paid_users__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["NSP_Non_paid_users_Enter_User_Names__c"],
        },
      ],
      Payroll_submitted_frm_multiple_contacts__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["Provide_multiple_contact_details__c"],
        },
      ],
      Any_users_who_cannot_see_salary__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["Enter_user_names_that_can_t_see_salary__c"],
        },
      ],
      NSP_Different_contact_for_subaccounts__c:[
        {
          expValue: ["Yes"],
          dependentFields: ["NSP_PD_different_contact_for_subaccount__c"],
        },
      ],
      NSP_ArrearageInComplianceWithEachState__c: [
        {
          expValue: ["No"],
          dependentFields: ["NSP_SubaccountNeededDifferentPayPeriod__c"],
        },
      ],
      NSP_ClientInterestedHavingAutoApproval__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["NSP_Has_the_addendum_been_collected__c"],
        },
      ],
      need_for_a_subaccount__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["NSP_Enter_Time_Entry_for_all_subaccounts__c"],
        },
      ],
}
 export { DYNAMIC_FIELDS };