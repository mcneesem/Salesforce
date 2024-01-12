import aimsClientNoKDM from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo_KDM__c';
import clientNameKDM from '@salesforce/schema/Implementation_Profile__c.NSP_KDM_Client_Name__c';
import clientOfficePhoneKDM from '@salesforce/schema/Implementation_Profile__c.NSP_KDM_Client_Office_Phone__c';
import clientCellPhoneKDM from '@salesforce/schema/Implementation_Profile__c.NSP_KDM_Client_Cell_Phone__c';
import clientEmailKDM from '@salesforce/schema/Implementation_Profile__c.NSP_KDM_Client_Email__c';
import clientContactMethodKDM from '@salesforce/schema/Implementation_Profile__c.NSP_KDM_Client_Contact_Method__c';
import clientJobTitleKDM from '@salesforce/schema/Implementation_Profile__c.NSP_KDM_Job_Title__c';

import aimsClientNoOSS from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo_OSS__c';
import clientNameOSS from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_Client_Name__c';
import clientOfficePhoneOSS from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_Client_Office_Phone__c';
import clientCellPhoneOSS from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_Client_Cell_Phone__c';
import clientEmailOSS from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_Client_Email__c';
import clientContactMethodOSS from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_Client_Contact_Method__c';
import clientJobTitleOSS from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_Job_Title__c';

import aimsClientNoWC from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo_WC__c';
import clientNameWC from '@salesforce/schema/Implementation_Profile__c.NSP_WC_Client_Name__c';
import clientOfficePhoneWC from '@salesforce/schema/Implementation_Profile__c.NSP_WC_Client_Office_Phone__c';
import clientCellPhoneWC from '@salesforce/schema/Implementation_Profile__c.NSP_WC_Client_Cell_Phone__c';
import clientEmailWC from '@salesforce/schema/Implementation_Profile__c.NSP_WC_Client_Email__c';
import clientContactMethodWC from '@salesforce/schema/Implementation_Profile__c.NSP_WC_Client_Contact_Method__c';
import clientJobTitleWC from '@salesforce/schema/Implementation_Profile__c.NSP_WC_Job_Title__c';

import aimsClientNoPC from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo_PC__c';
import clientNamePC from '@salesforce/schema/Implementation_Profile__c.NSP_PC_Client_Name__c';
import clientOfficePhonePC from '@salesforce/schema/Implementation_Profile__c.NSP_PC_Client_Office_Phone__c';
import clientCellPhonePC from '@salesforce/schema/Implementation_Profile__c.NSP_PC_Client_Cell_Phone__c';
import clientEmailPC from '@salesforce/schema/Implementation_Profile__c.NSP_PC_Client_Email__c';
import clientContactMethodPC from '@salesforce/schema/Implementation_Profile__c.PC_Client_Contact_Method__c';
import clientJobTitlePC from '@salesforce/schema/Implementation_Profile__c.NSP_PC_Job_Title__c';

import aimsClientNoBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo_Backup_PC__c';
import clientNameBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_Back_up_PC_Client_Name__c';
import clientOfficePhoneBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_Back_up_Client_Office_Phone__c';
import clientCellPhoneBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_Back_up_Client_Cell_Phone__c';
import clientEmailBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_Back_up_Client_Email__c';
import clientContactMethodBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_Back_up_Client_Contact_Method__c';
import clientJobTitleBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_Back_up_PC_Job_Title__c';

import aimsClientNoHR from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo_HR__c';
import clientNameHR from '@salesforce/schema/Implementation_Profile__c.NSP_HR_Client_Name__c';
import clientOfficePhoneHR from '@salesforce/schema/Implementation_Profile__c.HR_Contact_Office_Phone__c';
import clientCellPhoneHR from '@salesforce/schema/Implementation_Profile__c.HR_Contact_Cell_Phone__c';
import clientEmailHR from '@salesforce/schema/Implementation_Profile__c.NSP_HR_Client_Email__c';
import clientContactMethodHR from '@salesforce/schema/Implementation_Profile__c.HR_Contact_Method__c';
import clientJobTitleHR from '@salesforce/schema/Implementation_Profile__c.NSP_HR_Job_Title__c';

import clientContactNotes from '@salesforce/schema/Implementation_Profile__c.Client_Contact_Notes__c';
import addnClientContactFields from '@salesforce/schema/NSP_IP_Additional_Client_Contact__c';

import ossSameAsKDM from '@salesforce/schema/Implementation_Profile__c.NSP_OSS_contact_is_same_as_KDM__c';
import wcSameAsOSS from '@salesforce/schema/Implementation_Profile__c.NSP_WC_contact_is_same_as_OSS__c';
import pcSameAsOSS from '@salesforce/schema/Implementation_Profile__c.NSP_PC_is_same_as_OSS__c';
import noBackUpPC from '@salesforce/schema/Implementation_Profile__c.NSP_No_back_up_PC__c';
import hrSameAsOSS from '@salesforce/schema/Implementation_Profile__c.HR_contact_is_same_as_OSS__c';

const SECTION_FIELDS = {
  aimsClientNoKDM,
  clientNameKDM,
  clientOfficePhoneKDM,
  clientCellPhoneKDM,
  clientEmailKDM,
  clientContactMethodKDM,
  aimsClientNoOSS,
  clientNameOSS,
  clientOfficePhoneOSS,
  clientCellPhoneOSS,
  clientEmailOSS,
  clientContactMethodOSS,
  aimsClientNoWC,
  clientNameWC,
  clientOfficePhoneWC,
  clientCellPhoneWC,
  clientEmailWC,
  clientContactMethodWC,
  aimsClientNoPC,
  clientNamePC,
  clientOfficePhonePC,
  clientCellPhonePC,
  clientEmailPC,
  clientContactMethodPC,
  aimsClientNoBackUpPC,
  clientNameBackUpPC,
  clientOfficePhoneBackUpPC,
  clientCellPhoneBackUpPC,
  clientEmailBackUpPC,
  clientContactMethodBackUpPC,
  aimsClientNoHR,
  clientNameHR,
  clientOfficePhoneHR,
  clientCellPhoneHR,
  clientEmailHR,
  clientContactMethodHR,
  clientContactNotes,
  clientJobTitleKDM,
  clientJobTitleOSS,
  clientJobTitleWC,
  clientJobTitlePC,
  clientJobTitleBackUpPC,
  clientJobTitleHR,
  addnClientContactFields,
  ossSameAsKDM,
  wcSameAsOSS,
  pcSameAsOSS,
  noBackUpPC,
  hrSameAsOSS,
};

const BACKUP_PC_FIELDS = [
  'NSP_Back_up_PC_Client_Name__c',
  'NSP_Back_up_PC_Job_Title__c',
  'NSP_AIMS_ClientNo_Backup_PC__c',
  'NSP_Back_up_Client_Office_Phone__c',
  'NSP_Back_up_Client_Cell_Phone__c',
  'NSP_Back_up_Client_Email__c',
  'NSP_Back_up_Client_Contact_Method__c',
];

const PHONE_NUMBER_FIELDS = [
  'NSP_KDM_Client_Office_Phone__c',
  'NSP_KDM_Client_Cell_Phone__c',
  'NSP_OSS_Client_Office_Phone__c',
  'NSP_OSS_Client_Cell_Phone__c',
  'NSP_WC_Client_Office_Phone__c',
  'NSP_PC_Client_Office_Phone__c',
  'NSP_PC_Client_Cell_Phone__c',
  'NSP_Back_up_Client_Office_Phone__c',
  'NSP_Back_up_Client_Cell_Phone__c',
  'HR_Contact_Office_Phone__c',
  'HR_Contact_Cell_Phone__c',
  'NSP_WC_Client_Cell_Phone__c',
];

const ADDITIONAL_CLIENT_CONTACTS_FIELDS = [
  ['NSP_Contact_Type__c', 'Name'],
  ['NSP_AIMS_Client__c', 'NSP_Office_Phone__c'],
  ['NSP_Email_Address__c', 'NSP_Job_Title__c'],
  ['NSP_Cell_Phone__c', 'NSP_Contact_Method__c'],
];

const OSS_KDM_MAPPING = {
  NSP_OSS_Client_Name__c : 'NSP_KDM_Client_Name__c',
  NSP_OSS_Client_Contact_Method__c : 'NSP_KDM_Client_Contact_Method__c',
  NSP_OSS_Job_Title__c : 'NSP_KDM_Job_Title__c',
  NSP_AIMS_ClientNo_OSS__c : 'NSP_AIMS_ClientNo_KDM__c',
  NSP_OSS_Client_Office_Phone__c : 'NSP_KDM_Client_Office_Phone__c',
  NSP_OSS_Client_Email__c : 'NSP_KDM_Client_Email__c',
  NSP_OSS_Client_Cell_Phone__c : 'NSP_KDM_Client_Cell_Phone__c',
};

const WC_OSS_MAPPING = {
  NSP_WC_Client_Name__c : 'NSP_OSS_Client_Name__c',
  NSP_WC_Client_Contact_Method__c : 'NSP_OSS_Client_Contact_Method__c',
  NSP_WC_Job_Title__c : 'NSP_OSS_Job_Title__c',
  NSP_AIMS_ClientNo_WC__c : 'NSP_AIMS_ClientNo_OSS__c',
  NSP_WC_Client_Office_Phone__c : 'NSP_OSS_Client_Office_Phone__c',
  NSP_WC_Client_Email__c : 'NSP_OSS_Client_Email__c',
  NSP_WC_Client_Cell_Phone__c : 'NSP_OSS_Client_Cell_Phone__c',
};

const PC_OSS_MAPPING = {
  NSP_PC_Client_Name__c : 'NSP_OSS_Client_Name__c',
  PC_Client_Contact_Method__c : 'NSP_OSS_Client_Contact_Method__c',
  NSP_PC_Job_Title__c : 'NSP_OSS_Job_Title__c',
  NSP_AIMS_ClientNo_PC__c : 'NSP_AIMS_ClientNo_OSS__c',
  NSP_PC_Client_Office_Phone__c : 'NSP_OSS_Client_Office_Phone__c',
  NSP_PC_Client_Email__c : 'NSP_OSS_Client_Email__c',
  NSP_PC_Client_Cell_Phone__c : 'NSP_OSS_Client_Cell_Phone__c',
};

const HR_OSS_MAPPING = {
  NSP_HR_Client_Name__c : 'NSP_OSS_Client_Name__c',
  HR_Contact_Method__c : 'NSP_OSS_Client_Contact_Method__c',
  NSP_HR_Job_Title__c : 'NSP_OSS_Job_Title__c',
  NSP_AIMS_ClientNo_HR__c : 'NSP_AIMS_ClientNo_OSS__c',
  HR_Contact_Office_Phone__c : 'NSP_OSS_Client_Office_Phone__c',
  NSP_HR_Client_Email__c : 'NSP_OSS_Client_Email__c',
  HR_Contact_Cell_Phone__c : 'NSP_OSS_Client_Cell_Phone__c',
};

const DEPENDENT_FIELDS_MAPPING = {
  NSP_OSS_contact_is_same_as_KDM__c: OSS_KDM_MAPPING,
  NSP_WC_contact_is_same_as_OSS__c: WC_OSS_MAPPING,
  NSP_PC_is_same_as_OSS__c: PC_OSS_MAPPING,
  HR_contact_is_same_as_OSS__c: HR_OSS_MAPPING, 
};

export {
  SECTION_FIELDS,
  BACKUP_PC_FIELDS,
  PHONE_NUMBER_FIELDS,
  ADDITIONAL_CLIENT_CONTACTS_FIELDS,
  DEPENDENT_FIELDS_MAPPING,
};