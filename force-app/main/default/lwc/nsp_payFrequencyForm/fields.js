const SECTION_FIELDS = [
    'Client_number__c',
    'Frequency__c',
    'Insperity_first_day_of_1st_pay_period__c',
    'Insperity_last_day_of_1st_pay_period__c',
    'Insperity_1st_pay_date__c',
    'Insperity_first_day_of_2nd_pay_period__c',
    'Insperity_last_day_of_2nd_pay_period__c',
    'Insperity_2nd_pay_date__c',
    'Is_arrearage_7_days__c',
    'Have_credit_services_approved__c',
    'Provide_credit_services_detaIls__c',
    'Does_arrearage_comply_with_state_laws__c',
    'Provide_arrearage_details__c',
    'Does_the_client_have_prior_wages__c',
    'Final_pay_period_prior_to_Insperity__c',
    'Final_pay_date_prior_to_Insperity__c'
];

const PAY_FREQUENCY_FIELDS = [
    'Implementation_Pay_Period__c.Client_number__c',
    'Implementation_Pay_Period__c.Frequency__c',
    'Implementation_Pay_Period__c.Insperity_first_day_of_1st_pay_period__c',
    'Implementation_Pay_Period__c.Insperity_last_day_of_1st_pay_period__c',
    'Implementation_Pay_Period__c.Insperity_1st_pay_date__c',
    'Implementation_Pay_Period__c.Insperity_first_day_of_2nd_pay_period__c',
    'Implementation_Pay_Period__c.Insperity_last_day_of_2nd_pay_period__c',
    'Implementation_Pay_Period__c.Insperity_2nd_pay_date__c',
    'Implementation_Pay_Period__c.Is_arrearage_7_days__c',
    'Implementation_Pay_Period__c.Have_credit_services_approved__c',
    'Implementation_Pay_Period__c.Provide_credit_services_detaIls__c',
    'Implementation_Pay_Period__c.Does_arrearage_comply_with_state_laws__c',
    'Implementation_Pay_Period__c.Provide_arrearage_details__c',
    'Implementation_Pay_Period__c.Does_the_client_have_prior_wages__c',
    'Implementation_Pay_Period__c.Final_pay_period_prior_to_Insperity__c',
    'Implementation_Pay_Period__c.Final_pay_date_prior_to_Insperity__c'
]

const ERROR_TOAST_CONFIG = {
    title: 'Error',
    variant: 'error',
  };

export {
    SECTION_FIELDS,
    PAY_FREQUENCY_FIELDS,
    ERROR_TOAST_CONFIG
};