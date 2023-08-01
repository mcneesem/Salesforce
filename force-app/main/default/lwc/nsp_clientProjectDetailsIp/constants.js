// Project Object Fields
import ACCOUNT_FIELD_PROJECT from '@salesforce/schema/pse__Proj__c';
import ASSET_FIELD_PROJECT from '@salesforce/schema/pse__Proj__c';

// IP Object Fields
import PROJECT_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_Project__c';
import ASSET_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_Asset__c';
import ACCOUNT_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.Account__c';
import AIMS_CLIENT_NAME_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_Client_Name__c';
import AIMS_CLIENT_NUM_FIELD_IP from '@salesforce/schema/Implementation_Profile__c.NSP_AIMS_ClientNo__c';

import TITLE from '@salesforce/label/c.NSP_ClientProjectInformationSection';

const IP_FIELDS = {
    project : PROJECT_FIELD_IP,
    asset : ASSET_FIELD_IP,
    account : ACCOUNT_FIELD_IP,
    clientName : AIMS_CLIENT_NAME_FIELD_IP,
    clientNumber : AIMS_CLIENT_NUM_FIELD_IP
}

const PROJECT_FIELDS = {
    account : ACCOUNT_FIELD_PROJECT,
    asset : ASSET_FIELD_PROJECT
}

export { IP_FIELDS, PROJECT_FIELDS, TITLE };