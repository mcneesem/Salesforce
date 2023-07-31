import clientInformation from '@salesforce/label/c.NSP_Client_Information';

const LABEL = {clientInformation};

const CLASS_BY_ORDER = {
    1 : 'level-1',
    2 : 'level-2',
    3 : 'level-3',
}

const SPECIALFIELDS = [ 
            'Has_FEIN_documentation_been_collected__c',
            'Are_sample_intro_letters_being_provided__c',
            ];
const SELECTEDVALUE = ['Requested','Requested - Not Collected', 'Requested - Not collected'];

export { LABEL , CLASS_BY_ORDER, SPECIALFIELDS, SELECTEDVALUE};