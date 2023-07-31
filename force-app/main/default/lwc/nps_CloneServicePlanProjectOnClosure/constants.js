import PROJ_STATUS from '@salesforce/schema/pse__Proj__c.pse__Project_Status__c';
import USED_TEMPLATE from '@salesforce/schema/pse__Proj__c.Templates_Used__c';

const MESSAGE = {
  unselectedOpenTaskAvailableWarning:
    'The task that is not selected will be cancelled.',
  projectAccHelpText:
    'Select any Accounts you want to include on the new Engagement Plan project',
  openTaskErrorMessage:
    'Open tasks must be closed/cancelled before the project can be marked Complete.',
};

const PROJECT_ACCOUNT_COLUMNS = [
  { label: 'Account Name', fieldName: 'Account__r.Name' },
];

const PROJECT_TASK_COLUMNS = [
  { label: 'Name', fieldName: 'Name', type: 'text' },
  { label: 'Status', fieldName: 'pse__Status__c', type: 'text' },
  {
    label: 'Start Date & Time',
    fieldName: 'pse__Start_Date_Time__c',
    type: 'date',
    typeAttributes: {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true,
    },
  },
  {
    label: 'End Date & Time',
    fieldName: 'pse__End_Date_Time__c',
    type: 'date',
    typeAttributes: {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true,
    },
  },
];

const PROJECT_OBJ_FIELDS = [
  PROJ_STATUS,
  USED_TEMPLATE,
  { fieldApiName: 'pse__Account__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'pse__Parent_Project__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'pse__Start_Date__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'pse__End_Date__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'NSP_RET_Client_ID__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'pse__Is_Active__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'pse__Project_Type__c', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'RecordType.Name', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'RecordTypeId', objectApiName: 'pse__Proj__c' },
  { fieldApiName: 'Name', objectApiName: 'pse__Proj__c' },
];

export { MESSAGE, PROJECT_ACCOUNT_COLUMNS, PROJECT_TASK_COLUMNS, PROJECT_OBJ_FIELDS };
