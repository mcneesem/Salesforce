import assignments from '@salesforce/label/c.NSP_Assignments';

const LABEL = { assignments };

const SPECIALFIELDS = [];
const SYNC_FIELDS = {
    NSP_BPA_BPC__c: 'NSP_BPA_BPC__c'
};

export { LABEL, SPECIALFIELDS,SYNC_FIELDS };