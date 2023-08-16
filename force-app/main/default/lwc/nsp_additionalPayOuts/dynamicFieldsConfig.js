const DYNAMIC_FIELDS = {
    'NSP_Do_you_pay__c': [
        {
            expValue: ['Non-Discretionary Bonus', 'Discretionary Bonus', 'Commission', 'Other'],
            dependentFields: ['Do_you_pay_non_exempt_employees__c', 'NSP_NonDiscretionaryDiscretionaryPayCode__c'],
        },
        {
            expValue: ['Non-Discretionary Bonus'],
            dependentFields: ['NSP_Non_Discretionary_Bonus__c', 'Non_Discretionary_Bonus_Input_frequency__c'],
        },
        {
            expValue: ['Discretionary Bonus'],
            dependentFields: ['NSP_Discretionary_Bonus__c', 'NSP_Discretionary_Bonus_Input_Frequency__c'],
        },
        {
            expValue: ['Commission',],
            dependentFields: ['NSP_Commission_Frequency__c', 'NSP_Commission_Type__c'],
        },
        {
            expValue: ['Other',],
            dependentFields: ['NSP_DoYouPay_Other_Provide_details__c'],
        },
    ],
    'NSP_Commission_Frequency__c': [
        {
            expValue: ['Other'],
            dependentFields: ['NSP_Commission_Provide_Details__c'],
        },
    ],
    'NSP_Any_special_pay_codes_Needed__c': [
        {
            expValue: ['Yes'],
            dependentFields: ['NSP_Any_special_pay_code_Provide_Details__c'],
        },
    ],
};

export { DYNAMIC_FIELDS };