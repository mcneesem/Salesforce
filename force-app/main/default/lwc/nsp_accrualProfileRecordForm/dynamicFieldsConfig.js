import { YES } from './constants';

const DYNAMIC_FIELDS = {
   Is_this_a_new_client_implementation__c: [
    {
      expValue: [YES],
      dependentFields: [
        'X2nd_Pay_Date__c',
      ],
    },
  ],
  Is_Client_MM_or_MM_Enterprise__c:[
    {
      expValue: [
        'N/A'
      ],
      dependentFields: ['Enter_Case_number__c'],
    },
  ],
  NSP_NewExisting_Client_or_Change_order__c:[
    {
      expValue: [
        'Existing Client/New ITA Implementation',
        'Existing Client/Change Orders (changes to current ITA plan)',
      ],
      dependentFields: ['Enter_Case_number__c'],
    },
  ],
  NSP_Type_of_Policy__c: [
    {
      expValue: ['Other'],
      dependentFields: [
        'NSP_Policy_Type_Provide_Details__c',
        'NSP_Type_of_Policy_info_msg',
      ],
    },
    {
      expValue: ['Floating Holiday'],
      dependentFields: ['NSP_Type_of_Policy_info_msg'],
    },
  ],
  NSP_Does_this_plan_replace_other_plans__c: [
    {
      expValue: [YES],
      dependentFields: ['NSP_Accrual_Profile__c'],
    },
  ],
  NSP_Accrue_under_plan_cal_year__c: [
    {
      expValue: [
        'First of Quarter: Accrual is added on the first day of each quarter',
        'Last of Pay Period: Accrual is added on the last day of each pay period',
      ],
      dependentFields: [
        'NSP_If_hired_midway_through_pay_period__c_ITA_CALENDAR',
      ],
    },
    {
      expValue: [
        'Calendar Year Frontload: Full benefit year amount provided on 1/1 each year',
      ],
      dependentFields: ['NSP_Is_there_a_frontloaded_proration__c_ITA_CALENDAR'],
    },
    {
      expValue: [
        'Last of Pay Period: Accrual is added on the last day of each pay period',
      ],
      dependentFields: ['NSP_Select_Pay_Frequency__c_ITA_CALENDAR'],
    },
    {
      expValue: ['Hours Worked: Accrual is added based on actual hours worked'],
      dependentFields: [
        'NSP_Hours_paid_for_earning_accruals__c_ITA_CALENDER',
        'NSP_Accrual_Period_Limit__c_ITA_CALENDAR',
        'Accrual_rates_are_based_Input_Number__c_ITA_CALENDER'
      ],
    },
    {
      expValue: [
        'Hours Worked: Accrual is added based on actual hours worked or hours worked and hours paid',
      ],
      dependentFields: ['NSP_Hours_paid_for_earning_accruals__c_ITA_CALENDER'],
    },
  ],
  NSP_Is_there_a_frontloaded_proration__c_ITA_CALENDAR: [
    {
      expValue: [YES],
      dependentFields: ['frontLoadITACalendar'],
    }
  ],
  NSP_time_accrue_under_plan_anniv_year__c: [
    {
      expValue: [
        'First of Quarter: Accrual is added on the hire date at the beginning of each quarter',
        'Last of Pay Period: Accrual is added on the last day of each pay period',
      ],
      dependentFields: [
        'NSP_If_hired_midway_through_pay_period__c_ITA_ANNIVERSARY',
      ],
    },
    {
      expValue: [
        'Last of Pay Period: Accrual is added on the last day of each pay period',
      ],
      dependentFields: ['NSP_Select_Pay_Frequency__c_ITA_ANNIVERSARY'],
    },
    {
      expValue: ['Hours Worked: Accrual is added based on actual hours worked'],
      dependentFields: [
        'NSP_Hours_paid_for_earning_accruals__c_ITA_ANNIVERSARY',
        'NSP_Accrual_Period_Limit__c_ITA_ANNIVERSARY',
        'Accrual_rates_are_based_Input_Number__c_ITA_ANNIVERSARY'
      ],
    },
  ],
  NSP_Howdoestimeaccrueunder_the_plan_AIMS__c: [
    {
      expValue: [
        'Fiscal Year Frontload: Full accrual is granted each year on the first day the Fiscal year',
        'First of Month: Accrual is added on the first day of each month',
        'Pay Period: Accrual is added on each pay date',
      ],
      dependentFields: [
        'NSP_If_hired_midway_through_pay_period__c_AIMS_FISCALYEAR',
      ],
    },
    {
      expValue: [
        'Hours Worked: Accrual is added based on actual hours worked or hours worked and hours paid',
      ],
      dependentFields: [
        'NSP_Hours_paid_for_earning_accruals__c_AIMS_FISCAL',
        'Accrual_rates_are_based_Input_Number__c_AIMS_FISCAL'
      ],
    },
  ],
  NSP_time_accrue_under_plan_aims_calendar__c: [
    {
      expValue: [
        'Calendar Year Frontload: Full accrual is granted on 1/1 each year',
        'First of Quarter: Accrual is added on the first day of each quarter in a calendar year',
        'First of Month: Accrual is added on the first day of each month',
        'Pay Period: Accrual is added on each pay date',
      ],
      dependentFields: [
        'NSP_If_hired_midway_through_pay_period__c_AIMS_CALENDAR',
      ],
    },
    {
      expValue: [
        'Hours Worked: Accrual is added based on actual hours worked or hours worked and hours paid',
      ],
      dependentFields: [
        'Accrual_rates_are_based_Input_Number__c_AIMS_CALENDAR',
        'NSP_Hours_paid_for_earning_accruals__c_AIMS_CALENDAR',
        
      ],
    },
  ],
  NSP_timeaccrue_underplan_aimsanniversary__c: [
    {
      expValue: [
        'Hours Worked: Accrual is added based on actual hours worked or hours worked and hours paid',
      ],
      dependentFields: [
        'NSP_Hours_paid_for_earning_accruals__c_AIMS_ANNIVERSARY',
        'Accrual_rates_are_based_Input_Number__c_AIMS_ANNIVERSARY'
      ],
    },
  ],
  NSP_Is_there_a_frontloaded_proration__c_ITA_FISCAL: [
    {
      expValue: [YES],
      dependentFields: ['frontLoad'],
    },
  ],
  NSP_Submitted_to_satisfy_compliance_need__c: [
    {
      expValue: [YES],
      dependentFields: ['NSP_Compliance_Location__c'],
    },
  ],
  NSP_Hours_paid_for_earning_accruals__c_ITA_ANNIVERSARY: [
    {
      expValue: ['Client Specific Pay Codes'],
      dependentFields: ['NSP_List_pay_codes__c_ITA_ANNIVERSARY'],
    },
  ],
  NSP_Hours_paid_for_earning_accruals__c_ITA_FISCAL: [
    {
      expValue: ['Client Specific Pay Codes'],
      dependentFields: ['NSP_List_pay_codes__c_ITA_FISCAL'],
    },
  ],
  NSP_Hours_paid_for_earning_accruals__c_ITA_CALENDER: [
    {
      expValue: ['Client Specific Pay Codes'],
      dependentFields: ['NSP_List_pay_codes__c_ITA_CALENDER'],
    },
  ],
  NSP_Hours_paid_for_earning_accruals__c_AIMS_CALENDAR:[
    {
      expValue: ['Client Specific Pay Codes'],
      dependentFields: ['NSP_List_pay_codes__c_AIMS_CALENDAR'],
    },
  ],
  NSP_Hours_paid_for_earning_accruals__c_AIMS_ANNIVERSARY:[
    {
      expValue: ['Client Specific Pay Codes'],
      dependentFields: ['NSP_List_pay_codes__c_AIMS_ANNIVERSARY'],
    },
  ],
  NSP_Hours_paid_for_earning_accruals__c_AIMS_FISCAL:[
    {
      expValue: ['Client Specific Pay Codes'],
      dependentFields: ['NSP_List_pay_codes__c_AIMS_FISCAL'],
    },
  ],
  NSP_What_is_the_plan_year__c: [
    {
      expValue: ['Calendar Year (1/1 to 12/31)'],
      dependentFields: [
        'isCalendarYear',
        'NSP_When_do_accrual_level_changes_happen__c_ITA_CALENDAR',
        'NSP_time_accrue_under_plan_aims_calendar__c',
        'NSP_When_do_accrual_level_changes_happen__c_AIMS_CALENDAR',
        'NSP_Accrue_under_plan_cal_year__c',
      ],
    },
    {
      expValue: ['Anniversary Year'],
      dependentFields: [
        'isAnniversaryYear',
        'NSP_When_do_accrual_level_changes_happen__c_ITA_ANNIVERSARY',
        'NSP_When_do_accrual_level_changes_happen__c_AIMS_ANNIVERSARY',
        'NSP_timeaccrue_underplan_aimsanniversary__c',
        'NSP_time_accrue_under_plan_anniv_year__c',
      ],
    },
    {
      expValue: ['Clients Fiscal Year'],
      dependentFields: [
        'isClientFiscalYear',
        'NSP_Month__c',
        'NSP_Day__c',
        'NSP_When_do_accrual_level_changes_happen__c_ITA_FISCAL',
        'NSP_When_do_accrual_level_changes_happen__c_AIMS_FISCAL',
        'NSP_Howdoestimeaccrueunder_the_plan_AIMS__c',
        'NSP_Is_there_a_frontloaded_proration__c',
        'NSP_time_accrue_under_plan_fiscal_year__c',
      ],
    },
  ],
  NSP_Do_balances_carry_over_into_next_yer__c: [
    {
      expValue: [YES],
      dependentFields: [
        'NSP_Do_balances_carry_over_into_next_yer_info_msg',
        'NSP_Carryover_in_Hours_or_percentage__c',
        'NSP_Does_carryover_expire__c',
      ],
    },
  ],
  NSP_Does_carryover_expire__c: [
    {
      expValue: [YES],
      dependentFields: ['NSP_Days_Date_after_carryover_balance_ex__c'],
    },
  ],
  NSP_Accrual_waiting_period__c: [
    {
      expValue: ['Accrual', 'Eligibility'],
      dependentFields: ['NSP_Length_of_period__c', 'NSP_Select__c'],
    },
  ],
  NSP_balances_paid_in_lieu_of_carryover__c: [
    {
      expValue: [YES],
      dependentFields: ['NSP_Carryover_in_Hours_or_paid_in_lieu__c'],
    },
  ],
  NSP_Accrual_Profile__c: [
    {
      expValue: ['other'],
      dependentFields: ['NSP_Other_Plan__c'],
    },
  ],
  NSP_Employee_Status_check_all_that_apply__c: [
    {
      expValue: ['Others'],
      dependentFields: ['Other_Status__c'],
    },
  ],
  NSP_time_accrue_under_plan_fiscal_year__c: [
    {
      expValue: [
        'First of Quarter: Accrual is added on the first day of each quarter',
        'Last of Pay Period: Accrual is added on the last day of each pay period',
      ],
      dependentFields: ['NSP_If_hired_midway_through_pay_period__c_ITA_FISCAL'],
    },
    {
      expValue: [
        'Fiscal Year Frontload: Full benefit year amount provided on day 1 of the Fiscal year',
      ],
      dependentFields: ['NSP_Is_there_a_frontloaded_proration__c_ITA_FISCAL'],
    },
    {
      expValue: [
        'Last of Pay Period: Accrual is added on the last day of each pay period',
      ],
      dependentFields: ['NSP_Select_Pay_Frequency__c_ITA_FISCAL'],
    },
    {
      expValue: ['Hours Worked: Accrual is added based on actual hours worked'],
      dependentFields: [
        'NSP_Hours_paid_for_earning_accruals__c_ITA_FISCAL',
        'NSP_Accrual_Period_Limit__c_ITA_FISCAL',
        'Accrual_rates_are_based_Input_Number__c_ITA_FISCAL'
      ],
    },
  ],
  Annual_Usage_Limit__c: [
    {
      expValue: ['Yes'],
      dependentFields: ['Accrual_Usage_Hours__c'],
    }
  ]
};

const MULTIPLE_DEPENDENT_FIELDS = {
  Enter_Case_number__c:[
    'Is_Client_MM_or_MM_Enterprise__c',
    'NSP_NewExisting_Client_or_Change_order__c'
  ],
};

export { DYNAMIC_FIELDS, MULTIPLE_DEPENDENT_FIELDS };