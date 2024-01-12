const DYNAMIC_FIELDS = {
    'Any_Special_Agreements_Addendum_in_CSA__c': [
        {
          expValue: ['Yes'],
          dependentFields: ['Special_Agreement_Addendum_details__c']
        }
      ],
      'Gotten_Cvrg_Cert_Gen_Liability_Auto__c': [
        {
          expValue: ['Received', 'Requested'],
          dependentFields: ['Gen_liability_auto_coverage_details__c']
        },
      ],
      'Employees_work_in_the_following_states__c': [
        {
          expValue: ['NH'],
          dependentFields: ['newHampshire']
        },
      ],
};

export { DYNAMIC_FIELDS };