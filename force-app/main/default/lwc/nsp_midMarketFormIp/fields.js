import RECEIVED_ENROLLMENT_FEE from '@salesforce/schema/Implementation_Profile__c.Received_Enrollment_Fee__c';
import PROJECT_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_Project__c';
import ASSET_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_Asset__c';
import ACCOUNT_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.Account__c';
import AIMS_CLIENT_NAME_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_Client_Name__c';
import AIMS_CLIENT_NUM_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo__c';

const FIELDS = {
  receivedEnrollmentFee: RECEIVED_ENROLLMENT_FEE,
  project: PROJECT_FIELD_IP,
  asset: ASSET_FIELD_IP,
  account: ACCOUNT_FIELD_IP,
  clientName: AIMS_CLIENT_NAME_FIELD_IP,
  clientNumber: AIMS_CLIENT_NUM_FIELD_IP,
};

const PREVIOUS_VALUE_FIELDS_MAPPING = {
  Benefits_Package__c: 'NSP_Old_Benefits_Package__c',
  Effective_Date_Payroll_Worker_comp_EPLI__c: 'NSP_Old_Effective_Date_EPLI__c',
  Insperity_benefits_effective_date__c: 'NSP_Old_Insperity_Ben_effective_date__c'
}

export { FIELDS, PREVIOUS_VALUE_FIELDS_MAPPING };
