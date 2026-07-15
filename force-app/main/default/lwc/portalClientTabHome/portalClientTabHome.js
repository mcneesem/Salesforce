import { LightningElement , api } from 'lwc';

export default class PortalClientTabHome extends LightningElement {
    @api recordId; // is-a Portal_Client__c.Id
    @api projectId; // is-a Portal_Project__c.Id
    @api guidanceId; // is-a Portal_Guidance__c.Id

    get columnSizeFull() {
        return 12;
    }

    get columnSizeLeft() {
        return 7;
    }

    get columnSizeRight() {
        return ( this.columnSizeFull - this.columnSizeLeft );
    }

}
//