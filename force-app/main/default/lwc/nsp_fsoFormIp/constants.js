import { SECTION_LABELS } from './labels';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import ID_FIELD from '@salesforce/schema/Implementation_Profile__c.Id';
import IP_EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';
import PAY_PERIOD_OBJECT from '@salesforce/schema/Implementation_Pay_Period__c';
import EMPLOYEE_ORIENTATION from '@salesforce/schema/Employee_Orientation__c';
import ADDITIONAL_CLIENT_CONTACTS from '@salesforce/schema/NSP_IP_Additional_Client_Contact__c';
import IP_RELATED_CLIENT from '@salesforce/schema/NSP_IP_Related_Client__c';
import IP_COPY_DATA_OBJECT from '@salesforce/schema/NSP_Implementation_Profile_Copy_Data__c';
import yesButton from '@salesforce/label/c.NSP_Yes';
import noButton from '@salesforce/label/c.NSP_No';

const SECTION = {
  clientProject: SECTION_LABELS.clientProject,
  assignmentMeetings: SECTION_LABELS.assignmentMeetings,
  clientContacts: SECTION_LABELS.clientContacts,
  general: SECTION_LABELS.general,
  payroll: SECTION_LABELS.payroll,
  retirementServices: SECTION_LABELS.retirmentServices,
  serviceTeam: SECTION_LABELS.serviceTeam,
  benefits: SECTION_LABELS.benefits,
  orientation: SECTION_LABELS.orientation,

  payRollInfo: SECTION_LABELS.payRollInfo,
  generalPayInfo: SECTION_LABELS.generalPayInfo,
  additionalPayCodes: SECTION_LABELS.additionalPayCodes,
  additionalPayOuts: SECTION_LABELS.additionalPayOuts,
  deductions: SECTION_LABELS.deductions,
  checkDelivery: SECTION_LABELS.checkDelivery,
  reporting: SECTION_LABELS.reporting,
  miscellaneous: SECTION_LABELS.miscellaneous,
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
  'clientProject',
];

const COPY_ABLE_IP_CHILD_OBJECTS = [
  IP_RELATED_CLIENT.objectApiName,
  PAY_PERIOD_OBJECT.objectApiName,
  ADDITIONAL_CLIENT_CONTACTS.objectApiName,
  EMPLOYEE_ORIENTATION.objectApiName,
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
  'List_additional_FEIN_s__c',
  'Have_name_s_of_COBRA_takeovr_employees__c'
];

const CLASS_BY_ORDER = {
  1: 'level-1',
  2: 'level-2',
  3: 'level-3',
};

const SCROLL_DELAY_MS = 50;
const SECTION_MARGIN = 10;
const VERTICAL_SPACE = 60;
const SUCCESS_TOAST_CONFIG = {
  title: 'Success',
  variant: 'success',
};
const ERROR_TOAST_CONFIG = {
  title: 'Error',
  variant: 'error',
};

const SUCCESS_MESSAGE = {
  edit: 'IP record has been updated successfully.',
  create: 'IP record has been created successfully.',
  employeeData: 'Employee Data records have been saved.',
};

const ERROR_MESSAGE = {
  save: 'Error occured while saving IP record.',
};

const BUTTON_HANDLER_MAPPING = {
  saveAndExit: 'handleSaveAndExit',
  exit: 'handleExit',
  copy: 'handleCopyHBClick',
};

const sOBJECT_NAME = {
  ip: IP_OBJECT.objectApiName,
};

const POST_UPSERT_ACTION_MAPPING = {
  [IP_EMP_DATA_OBJECT.objectApiName]: 'saveEmpDataRecords',
  [PAY_PERIOD_OBJECT.objectApiName]: 'saveRelatedRecords',
  [EMPLOYEE_ORIENTATION.objectApiName]: 'saveRelatedRecords',
  [ADDITIONAL_CLIENT_CONTACTS.objectApiName]: 'saveRelatedRecords',
  [IP_RELATED_CLIENT.objectApiName]: 'saveRelatedRecords',
  [IP_COPY_DATA_OBJECT.objectApiName]: 'saveRelatedRecords',
};

const RELATED_FIELD_NAME = {
  [EMPLOYEE_ORIENTATION.objectApiName]: 'NSP_Implementation_Profile__c',
  [PAY_PERIOD_OBJECT.objectApiName]: 'NSP_Implementation_Profile__c',
  [ADDITIONAL_CLIENT_CONTACTS.objectApiName]: 'NSP_Implementation_Profile__c',
  [IP_RELATED_CLIENT.objectApiName]: 'NSP_Implementation_Profile__c',
  [IP_COPY_DATA_OBJECT.objectApiName]: 'NSP_Source_Record__c'
}

const PREVIOUS_VALUE_FIELDS_MAPPING = {
  Benefits_Package__c: 'NSP_Old_Benefits_Package__c',
  Effective_Date_Payroll_Worker_comp_EPLI__c: 'NSP_Old_Effective_Date_EPLI__c',
  Insperity_benefits_effective_date__c: 'NSP_Old_Insperity_Ben_effective_date__c'
}

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

export {
  SECTION,
  SCROLL_DELAY_MS,
  SECTION_MARGIN,
  CLASS_BY_ORDER,
  SUCCESS_TOAST_CONFIG,
  SUCCESS_MESSAGE,
  VERTICAL_SPACE,
  ERROR_TOAST_CONFIG,
  ERROR_MESSAGE,
  BUTTON_HANDLER_MAPPING,
  POST_UPSERT_ACTION_MAPPING,
  sOBJECT_NAME,
  ID_FIELD,
  SAVE_AND_EXIT_DIALOG_BUTTON_CONFIG,
  NON_COPY_ABLE_SECTIONS,
  NON_COPY_ABLE_FIELDS,
  RELATED_FIELD_NAME,
  PREVIOUS_VALUE_FIELDS_MAPPING,
  COPY_ABLE_IP_CHILD_OBJECTS
};