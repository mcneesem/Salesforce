import { SECTION_LABELS } from './labels';
import IP_EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';
import PAY_PERIOD_OBJECT from '@salesforce/schema/Implementation_Pay_Period__c';
import IP_RELATED_CLIENT from '@salesforce/schema/NSP_IP_Related_Client__c'
import IP_COPY_DATA_OBJECT from '@salesforce/schema/NSP_Implementation_Profile_Copy_Data__c';
import ADDITIONAL_CLIENT_CONTACTS from '@salesforce/schema/NSP_IP_Additional_Client_Contact__c';

import yesButton from '@salesforce/label/c.NSP_Yes';
import noButton from '@salesforce/label/c.NSP_No';

const SECTION = {
  clientProjectInfo: SECTION_LABELS.clientProject,
  meetingDetails: SECTION_LABELS.meetingDetails,
  assignments: SECTION_LABELS.assignments,
  preDiscovery: SECTION_LABELS.preDiscovery,
  clientInformation: SECTION_LABELS.clientInfo,
  onBoarding: SECTION_LABELS.onBoarding,
  employees: SECTION_LABELS.employees,
  payroll: SECTION_LABELS.payroll,
  benefits: SECTION_LABELS.benefits,
  retirementServices: SECTION_LABELS.retirementServices,
  humanResources: SECTION_LABELS.humanResources,
  workersCompSafety: SECTION_LABELS.workersSafety,
  businessPerformanceSolutions: SECTION_LABELS.businessPerformance,
  attachments: SECTION_LABELS.attachments,
  automation: SECTION_LABELS.automation,
  auditLog: SECTION_LABELS.auditLog,
  systemInfo: SECTION_LABELS.systemInfo,
};

const NON_COPY_ABLE_SECTIONS = [
  'attachments',
  'automation',
  'auditLog',
  'systemInfo',
  'clientProjectInfo',
];

const NON_COPY_ABLE_FIELDS = [
  'NSP_BPA_BPC__c',
  'NSP_Legal_Name__c',
  'Sales_Office__c',
  'DBA__c',
  'Business_Inception_Date__c',
  'State_Unemployment_Insurance_SUI_Num__c',
  'Client_FEIN__c',
  'Has_FEIN_documentation_been_collected__c',
  'NSP_Does_the_client_more_FEIN__c',
  'Client_have_EEO_filing_under__c',
  'Can_client_provide_EEO_filing_address__c',
  'EEO__c',
  'Filing_address__c',
  'EEO_name_phone_contact_email_for_info__c',
  'Schedule_B_version__c',
  'Num_of_Worksite_Employees_Full_Time__c',
  'Num_of_Worksite_Employees_Part_Time__c',
  'Num_of_Worksite_Employees_Seasonal__c',
  'Client_have_any_EEs_on_F1_or_J1_Visa_s__c',
  'Any_EEs_with_urgent_medical_needs__c',
  'Participants_on_COBRA_eligibility_period__c',
  'Do_any_EEs_have_garnishments__c',
  'Do_any_EEs_have_tax_levies__c',
  'All_EEs_paid_under_same_FEIN_currently__c',
  'List_additional_FEIN_s__c'
];

const HELP_TEXT = {
  clientLocationMessage: 'Discuss the remote I-9 process',
  empWithTempStatus:
    'Collect ee name/projected assignment end date. Explain benefits eligibility and Insperity Temp Policy. Cannot have temp to perm scenario - violation of the group health plan. All temp ees must be assigned to a project with a designated end date. NOTE: Classification for Benefits eligibility is ONLY – Full-time or Part-Time.',
  travelInternationallyForWork:
    'The International Travel Notification form will need to be completed prior to each trip regardless of duration.',
  newHamshire: 'For New Hampshire, send Schedule A to Andrea Slayden',
  stateGuidelines:
    'Assist the client in reviewing the Unemployment State Guidelines, located in the “Insperity Client – Payroll Tax Guidelines” located on Premier, to determine which work circumstance applies and have the client complete the State Unemployment Add/Change Multi-State worker form and return to Payroll for entry into AIMS.',
};
const BUTTON_HANDLER_MAPPING = {
  saveAndExit: 'handleSaveAndExit',
  exit: 'handleExit',
  copy: 'handleCopyHBClick',
};
const CLASS_BY_ORDER = {
  1: 'level-1',
  2: 'level-2',
  3: 'level-3',
};

const SUCCESS_MESSAGE = {
  edit: 'Record has been updated successfully.',
  create: 'Record has been created successfully.',
  employeeData: 'Employee Data records have been saved.',
};

const SUCCESS_TOAST_CONFIG = {
  title: 'Success',
  variant: 'success',
};

const ERROR_TOAST_CONFIG = {
  title: 'Error',
  variant: 'error',
};

const SCROLL_DELAY_MS = 50;
const SECTION_MARGIN = 10;
const VERTICAL_SPACE = 60;

/* added as part of STY-03065 */
const SPECIALFIELDS = [
  'Received_Section_125_Questionnaire__c',
  'Has_FEIN_documentation_been_collected__c',
  'Are_sample_intro_letters_being_provided__c',
  'Client_provided_copy_of_communication__c',
  'Client_has_any_special_payroll_needs__c',
  'Do_any_EEs_have_garnishments__c',
  'Do_any_EEs_have_tax_levies__c',
  'Gave_copy_of_PTO_sick_leave_other_policy__c',
  'NSP_Chart_of_Accounts_GL_codes__c',
  'NSP_Sample_of_current_GL_report__c',
  'NSP_Client_s_holiday_calendar__c',
  'Recent_Payroll_Register_Collected__c',
  'Chngs_for_cafeteria_plan_questionnaire__c',
  'sample_new_empl_info_packet_collected__c',
  'NSP_collected_copies_of_state_WC_policy__c',
  'Gotten_Cvrg_Cert_Gen_Liability_Auto__c',
];
const SELECTEDVALUE = [
  'Requested',
  'Requested - Not Collected',
  'Requested - Not collected',
];
const POST_UPSERT_ACTION_MAPPING = {
  [IP_EMP_DATA_OBJECT.objectApiName]: 'saveEmpDataRecords',
  [PAY_PERIOD_OBJECT.objectApiName]: 'saveRelatedRecords',
  [IP_RELATED_CLIENT.objectApiName] : 'saveRelatedRecords',
  [IP_COPY_DATA_OBJECT.objectApiName] : 'saveRelatedRecords',
  [ADDITIONAL_CLIENT_CONTACTS.objectApiName] : 'saveRelatedRecords'
};

const SAVE_AND_EXIT_DIALOG_BUTTON_CONFIG = [
  {
    name: 'No',
    label: noButton,
  },
  {
    name: 'Yes',
    label: yesButton,
    variant: 'brand',
  },
];

const RELATED_FIELD_NAME = {
  [PAY_PERIOD_OBJECT.objectApiName]: 'NSP_Implementation_Profile__c',
  [IP_RELATED_CLIENT.objectApiName] : 'NSP_Implementation_Profile__c',
  [IP_COPY_DATA_OBJECT.objectApiName] : 'NSP_Source_Record__c',
  [ADDITIONAL_CLIENT_CONTACTS.objectApiName] : 'NSP_Implementation_Profile__c'
};

export {
  BUTTON_HANDLER_MAPPING,
  SECTION,
  VERTICAL_SPACE,
  SCROLL_DELAY_MS,
  SECTION_MARGIN,
  HELP_TEXT,
  CLASS_BY_ORDER,
  SPECIALFIELDS,
  SELECTEDVALUE,
  SUCCESS_MESSAGE,
  SUCCESS_TOAST_CONFIG,
  POST_UPSERT_ACTION_MAPPING,
  SAVE_AND_EXIT_DIALOG_BUTTON_CONFIG,
  NON_COPY_ABLE_SECTIONS,
  NON_COPY_ABLE_FIELDS,
  RELATED_FIELD_NAME,
  ERROR_TOAST_CONFIG,
};