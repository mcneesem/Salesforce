import payroll from '@salesforce/label/c.NSP_Payroll';

const LABEL = { payroll };
const HELP_TEXT = {
  stateGuidelines:
    'Assist the client in reviewing the Unemployment State Guidelines, located in the “Insperity Client – Payroll Tax Guidelines” located on Premier, to determine which work circumstance applies and have the client complete the State Unemployment Add/Change Multi-State worker form and return to Payroll for entry into AIMS.',
};

const CLASS_BY_ORDER = {
  1: 'level-1',
  2: 'level-2',
  3: 'level-3',
};

const SPECIALFIELDS = [
  'Client_has_any_special_payroll_needs__c',
  'Do_any_EEs_have_garnishments__c',
  'Do_any_EEs_have_tax_levies__c',
  'Gave_copy_of_PTO_sick_leave_other_policy__c',
  'NSP_Chart_of_Accounts_GL_codes__c',
  'NSP_Sample_of_current_GL_report__c',
  'NSP_Client_s_holiday_calendar__c',
  'Recent_Payroll_Register_Collected__c',
];
const SELECTEDVALUE = [
  'Requested',
  'Requested - Not Collected',
  'Requested - Not collected',
];

export { LABEL, CLASS_BY_ORDER, SPECIALFIELDS, SELECTEDVALUE, HELP_TEXT };
