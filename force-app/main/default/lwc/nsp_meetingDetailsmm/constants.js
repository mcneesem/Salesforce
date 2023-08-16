import meetingDetails from '@salesforce/label/c.NSP_Meeting_Details';
import LEGAL_NAME_IP from '@salesforce/schema/Implementation_Profile__c.Legal_Name__c';
const CLASS_BY_ORDER = {
    1 : 'level-1',
    2 : 'level-2',
    3 : 'level-3',
}
const HELP_TEXT = {
    newHampshire : 'For New Hampshire, send Schedule A to Andrea Slayden',
}
const SPECIALFIELDS = [];
const LABEL = { meetingDetails };

const SYNC_FIELDS = {
    Account__c:"prefilledIpDetails"
  };
  
  const POST_SYNC_IP_FIELDS={"prefilledIpDetails":"updatePrefilledIpValues"}
const PREFILLED_FIELDS={
    DBA__c:"DBA__c"
    

  }

export { LABEL, SPECIALFIELDS, HELP_TEXT, LEGAL_NAME_IP,PREFILLED_FIELDS,SYNC_FIELDS,POST_SYNC_IP_FIELDS };