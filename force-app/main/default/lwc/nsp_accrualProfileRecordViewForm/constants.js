const ERROR_TOAST_CONFIG = {
  title: 'Error',
  variant: 'error',
};

const ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CALENDAR_YEAR = {
  'First of Quarter: Accrual is added on the first day of each quarter': [
    'Beginning of the Quarter that contains the Anniversary Date',
    'Beginning of the Quarter following the Anniversary Date',
  ],
  'Last of Pay Period: Accrual is added on the last day of each pay period': [
    'Beginning of the Pay Period that contains the Anniversary Date',
  ],
  'Calendar Year Frontload: Full benefit year amount provided on 1/1 each year':
    [
      'Calendar Year: Accrual rate increases on 1/1 prior to the designated anniversary',
      'Calendar Year: Accrual rate increases on 1/1/ after the designated anniversary',
    ],
  'Hours Worked: Accrual is added based on actual hours worked': [
    'Beginning of the Pay Period that contains the Anniversary Date',
  ],
  'First of Month: Accrual is added on the first day of each month': [
    'Beginning of the Month that contains the Anniversary Date',
    'Beginning of the Month following the Anniversary Date',
  ],
};

const ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_ANNIVERSARY_YEAR = {
  'First of Quarter: Accrual is added on the hire date at the beginning of each quarter': [
    'Beginning of the Quarter that contains the Anniversary Date',
    'Beginning of the Quarter following the Anniversary Date',
  ],
  'Last of Pay Period: Accrual is added on the last day of each pay period': [
    'Beginning of the Pay Period that contains the Anniversary Date',
  ],
  'Anniversary Year Frontload: Full benefit year amount provided anniversary date each year':
    [
      'Anniversary Date: Accrual rate increases on anniversary date',
    ],
  'Hours Worked: Accrual is added based on actual hours worked': [
    'Beginning of the Pay Period that contains the Anniversary Date',
  ],
  'Monthly: Accrual is added on the hire date of each month': [
    'Anniversary Date: Accrual rate increases on anniversary date',
  ],
};

const ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CLIENT_FISCAL_YEAR = {
  'First of Quarter: Accrual is added on the first day of each quarter': [
    'Beginning of the Quarter that contains the Anniversary Date',
    'Beginning of the Quarter following the Anniversary Date',
  ],
  'Last of Pay Period: Accrual is added on the last day of each pay period': [
    'Beginning of the Pay Period that contains the Anniversary Date',
  ],
  'Fiscal Year Frontload: Full benefit year amount provided on day 1 of the Fiscal year':
    [
      'Fiscal Year: Accrual rate increases on the start of the fiscal year prior to the designated anniversary',
      'Fiscal Year: Accrual rate increases at the end of the fiscal year after the designated anniversary',
    ],
  'First of Month: Accrual is added on the first day of each month': [
    'Beginning of the Month that contains the Anniversary Date',
    'Beginning of the Month following the Anniversary Date',
  ],
  'Hours Worked: Accrual is added based on actual hours worked': [
    'Beginning of the Pay Period that contains the Anniversary Date',
  ],
};

const ACCRUAL_LEVEL_CHANGES_FISCAL_YEAR_AIMS = [
  'Fiscal Year: Accrual rate increases on the first day of the designated fiscal year',
  'Anniversary Date: Accrual rate increase on each employee’s anniversary date',
  'Anniversary Month: Accrual rate increase on the first day of each employee’s anniversary month',
]

const ACCRUAL_LEVEL_CHANGES_CALENDAR_YEAR_AIMS = [
  'Anniversary Date: Accrual rate increase on each employee’s anniversary date',
  'Anniversary Month: Accrual rate increase on the first day of each employee’s anniversary month',
  'Calendar Year: Accrual rate increases on 1/1 prior to the designated anniversary',
  'Calendar Year: Accrual rate increases on 1/1 after the designated anniversary',
]

const ACCRUAL_LEVEL_CHANGES_ANNIVERSARY_YEAR_AIMS = [
  'Anniversary Date: Accrual rate increase on each employee’s anniversary date',
  'Anniversary Month: Accrual rate increase on the first day of each employee’s anniversary month',
]

const LABEL = {
  NSP_Do_balances_carry_over_into_next_yer__c:
    'Do balances carry over into the next <placeholder> plan year?',
  NSP_Hours_paid_for_earning_accruals__c:
    'Accrual rates are based on every <placeholder> hours worked. Check each earning category that is considered hours worked/hours paid for the purpose of earning accruals',
  NSP_Once_limit_is_hit_they_do_not_accrue__c:
    'Is there an Annual Accrual Limit? (Maximum number of hours accrued within a <placeholder> year not including carryover). Once this limit is hit, they do not accrue any more hours during the plan year.',
};

const INFO_MESSAGE = {
  NSP_Do_balances_carry_over_into_next_yer_info_msg:
    'Would it carry over into the same plan or into a separate bucket? If separate bucket, please provide name in the additional information section below.',
  NSP_Add_info_not_already_listed_on_form_info_msg:
    'Additional information not already listed on the form',
};


const APG_FIELDS = [
  'NSP_Accrual_Profile_Grid__c.Id',
  'NSP_Accrual_Profile_Grid__c.NSP_Index__c', 
  'NSP_Accrual_Profile_Grid__c.NSP_Completed_Months_of_Service__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Accrual_Rate__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Carryover_Expires_on_of_days_or_date__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Accrual_Profile__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Annual_Accrual_Limit_Cap_Hours__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Maximum_Balance_Cap_Hours__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Accrual_Period_limits_Hours__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Max_Carryoverhours__c',
  'NSP_Accrual_Profile_Grid__c.NSP_From__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Max_Amount_Expires_days_or_hours__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Max_in_Lieu_of_Payout_Hours__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Through__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Unit__c',
  'NSP_Accrual_Profile_Grid__c.NSP_Completed_Months_of_Service__c'

];

const APAR_FIELDS = [
  'NSP_Accrual_Profile_Account_Relationship__c.Id',
  'NSP_Accrual_Profile_Account_Relationship__c.NSP_Account__c',
  'NSP_Accrual_Profile_Account_Relationship__c.NSP_Account__r.Name',
];

const APSR_FIELDS = [
  'NSP_Accrual_Profile_Subclient_Relation__c.Id',
  'NSP_Accrual_Profile_Subclient_Relation__c.NSP_Sub_Client__c',
  'NSP_Accrual_Profile_Subclient_Relation__c.NSP_Sub_Client__r.Name',
];

const APG_ROW_ACTIONS = [
  { label: 'Delete', name: 'delete' },
  { label: 'Add Row', name: 'addRow' },
];

const STATUS_OPTIONS = ['Draft', 'Inactive', 'Cancelled'];
const STATUS_OPTIONS_AIMS = ['Draft', 'Inactive'];

const ACCRUAL_PROFILE_FIELDS = [
  'NSP_Accrual_Profile__c.NSP_Employee_Status_check_all_that_apply__c',
  'NSP_Accrual_Profile__c.NSP_Status__c',
];

const APG_COLUMNS = {
  completedMonthsService: {
    label: 'Completed Months of Service',
    fieldName: 'NSP_Completed_Months_of_Service__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  accrualRate: {
    label: 'Accrual Rate',
    fieldName: 'NSP_Accrual_Rate__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  annualAccrualLimit: {
    label: 'Annual Accrual limit/Cap(hours)',
    fieldName: 'NSP_Annual_Accrual_Limit_Cap_Hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maximumBalanceCapHours: {
    label: 'Maximum Balance Cap(hours)',
    fieldName: 'NSP_Maximum_Balance_Cap_Hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  accrualPeriodLimitsHours: {
    label: 'Accrual Period limits(hours)',
    fieldName: 'NSP_Accrual_Period_limits_Hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maxCarryOverHours: {
    label: 'Max Carryover Amount Hours',
    fieldName: 'NSP_Max_Carryoverhours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maxCarryOverPercent: {
    label: 'Max Carryover Amount %',
    fieldName: 'NSP_Max_Carryoverhours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  carryoverExpiresDaysDate: {
    label: 'Carryover Expires on (# of days or date)',
    fieldName: 'NSP_Carryover_Expires_on_of_days_or_date__c',
    type: 'text',
    cellAttributes: { alignment: 'left' },
  }, 
};

const APG_COLUMNS_AIMS = {
  from: {
    label: 'From',
    fieldName: 'NSP_From__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  through: {
    label: 'Through',
    fieldName: 'NSP_Through__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  unit: {
    label: 'Unit',
    fieldName: 'NSP_Unit__c',
    type: 'text',
    cellAttributes: { alignment: 'left' },
  },
  accrualRate: {
    label: 'Accrual Rate',
    fieldName: 'NSP_Accrual_Rate__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maximumBalanceCapHours: {
    label: 'Max Balance Cap(days or hours)',
    fieldName: 'NSP_Maximum_Balance_Cap_Hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maxCarryOverHours: {
    label: 'Max Carry Over Amount Hours',
    fieldName: 'NSP_Max_Carryoverhours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maxCarryOverPercent: {
    label: 'Max Carry Over Amount %',
    fieldName: 'NSP_Max_Carryoverhours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  }, 
  maxInLieuOfPayoutHours: {
    label: 'Max in Lieu of Payout Hours',
    fieldName: 'NSP_Max_in_Lieu_of_Payout_Hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maxInLieuOfPayoutPercent: {
    label: 'Max in Lieu of Payout %',
    fieldName: 'NSP_Max_in_Lieu_of_Payout_Hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },    
    typeAttributes: { maximumFractionDigits: '5' }
  },
  carryoverExpiresDaysDate: {
    label: 'Carryover Expires on (Number of days or date)',
    fieldName: 'NSP_Carryover_Expires_on_of_days_or_date__c',
    type: 'text',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  },
  maxAmountThatExpires: {
    label: 'Max Amount that Expires (days or hours)',
    fieldName: 'NSP_Max_Amount_Expires_days_or_hours__c',
    type: 'number',
    cellAttributes: { alignment: 'left' },
    typeAttributes: { maximumFractionDigits: '5' }
  }
};

const ACTIVE_SECTIONS = [
  'ClientInformation', 'PolicyInformation' , 'PolicyDetails'
]

const YES = 'Yes';

const EXISTING_FIELD_API_VALUE = {
  NSP_List_pay_codes__c_ITA_FISCAL: 'NSP_List_pay_codes__c',
  NSP_List_pay_codes__c_ITA_ANNIVERSARY: 'NSP_List_pay_codes__c',
  NSP_List_pay_codes__c_ITA_CALENDER: 'NSP_List_pay_codes__c',
  NSP_List_pay_codes__c_AIMS_CALENDAR: 'NSP_List_pay_codes__c',
  NSP_List_pay_codes__c_AIMS_ANNIVERSARY: 'NSP_List_pay_codes__c',
  NSP_List_pay_codes__c_AIMS_FISCAL: 'NSP_List_pay_codes__c',
  NSP_Hours_paid_for_earning_accruals__c_ITA_CALENDER: 'NSP_Hours_paid_for_earning_accruals__c',
  NSP_Hours_paid_for_earning_accruals__c_ITA_ANNIVERSARY: 'NSP_Hours_paid_for_earning_accruals__c',
  NSP_Hours_paid_for_earning_accruals__c_ITA_FISCAL: 'NSP_Hours_paid_for_earning_accruals__c',
  NSP_Hours_paid_for_earning_accruals__c_AIMS_FISCAL: 'NSP_Hours_paid_for_earning_accruals__c',
  NSP_Hours_paid_for_earning_accruals__c_AIMS_CALENDAR: 'NSP_Hours_paid_for_earning_accruals__c',
  NSP_Hours_paid_for_earning_accruals__c_AIMS_ANNIVERSARY: 'NSP_Hours_paid_for_earning_accruals__c',
  NSP_If_hired_midway_through_pay_period__c_ITA_CALENDAR: 'NSP_If_hired_midway_through_pay_period__c',
  NSP_Is_there_a_frontloaded_proration__c_ITA_CALENDAR: 'NSP_Is_there_a_frontloaded_proration__c',
  NSP_Select_Pay_Frequency__c_ITA_CALENDAR: 'NSP_Select_Pay_Frequency__c',
  NSP_Accrual_Period_Limit__c_ITA_CALENDAR: 'NSP_Accrual_Period_Limit__c',
  NSP_If_hired_midway_through_pay_period__c_AIMS_FISCALYEAR: 'NSP_If_hired_midway_through_pay_period__c',
  NSP_If_hired_midway_through_pay_period__c_AIMS_CALENDAR: 'NSP_If_hired_midway_through_pay_period__c',
  NSP_If_hired_midway_through_pay_period__c_ITA_FISCAL: 'NSP_If_hired_midway_through_pay_period__c',
  NSP_Is_there_a_frontloaded_proration__c_ITA_FISCAL: 'NSP_Is_there_a_frontloaded_proration__c',
  NSP_Select_Pay_Frequency__c_ITA_FISCAL: 'NSP_Select_Pay_Frequency__c',
  NSP_Select_Pay_Frequency__c_ITA_ANNIVERSARY: 'NSP_Select_Pay_Frequency__c',
  NSP_Accrual_Period_Limit__c_ITA_ANNIVERSARY: 'NSP_Accrual_Period_Limit__c',
  NSP_Accrual_Period_Limit__c_ITA_FISCAL: 'NSP_Accrual_Period_Limit__c',
  NSP_If_hired_midway_through_pay_period__c_ITA_ANNIVERSARY: 'NSP_If_hired_midway_through_pay_period__c',
  Accrual_rates_are_based_Input_Number__c_ITA_CALENDER: 'Accrual_rates_are_based_Input_Number__c',
  Accrual_rates_are_based_Input_Number__c_ITA_ANNIVERSARY: 'Accrual_rates_are_based_Input_Number__c',
  Accrual_rates_are_based_Input_Number__c_ITA_FISCAL : 'Accrual_rates_are_based_Input_Number__c',
  Accrual_rates_are_based_Input_Number__c_AIMS_CALENDAR : 'Accrual_rates_are_based_Input_Number__c',
  Accrual_rates_are_based_Input_Number__c_AIMS_ANNIVERSARY : 'Accrual_rates_are_based_Input_Number__c',
  Accrual_rates_are_based_Input_Number__c_AIMS_FISCAL : 'Accrual_rates_are_based_Input_Number__c',
  NSP_When_do_accrual_level_changes_happen__c_ITA_FISCAL: 'NSP_When_do_accrual_level_changes_happen__c',
  NSP_When_do_accrual_level_changes_happen__c_ITA_CALENDAR: 'NSP_When_do_accrual_level_changes_happen__c',
  NSP_When_do_accrual_level_changes_happen__c_ITA_ANNIVERSARY : 'NSP_When_do_accrual_level_changes_happen__c',
  NSP_When_do_accrual_level_changes_happen__c_AIMS_CALENDAR: 'NSP_When_do_accrual_level_changes_happen__c',
  NSP_When_do_accrual_level_changes_happen__c_AIMS_ANNIVERSARY : 'NSP_When_do_accrual_level_changes_happen__c',
  NSP_When_do_accrual_level_changes_happen__c_AIMS_FISCAL : 'NSP_When_do_accrual_level_changes_happen__c',
}

export {
  ERROR_TOAST_CONFIG,
  ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CALENDAR_YEAR,
  ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_ANNIVERSARY_YEAR,
  ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CLIENT_FISCAL_YEAR,
  ACCRUAL_LEVEL_CHANGES_FISCAL_YEAR_AIMS,
  ACCRUAL_LEVEL_CHANGES_CALENDAR_YEAR_AIMS,
  ACCRUAL_LEVEL_CHANGES_ANNIVERSARY_YEAR_AIMS,
  LABEL,
  INFO_MESSAGE,
  APG_FIELDS,
  APAR_FIELDS,
  APSR_FIELDS,
  STATUS_OPTIONS,
  STATUS_OPTIONS_AIMS,
  ACCRUAL_PROFILE_FIELDS,
  APG_COLUMNS,
  APG_COLUMNS_AIMS,
  YES,
  ACTIVE_SECTIONS,
  EXISTING_FIELD_API_VALUE
};