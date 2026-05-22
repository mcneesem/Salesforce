import { LightningElement , api } from 'lwc';

export default class PortalEvent extends LightningElement {
    @api record; // is-a Portal_Event__c

    get name() {
        return ( this.record?.fields?.Name?.value );
    }

    get startDateTime() {
        return ( this.record?.fields?.StartDateTime__c?.value );
    }

    get endDateTime() {
        return ( this.record?.fields?.EndDateTime__c?.value );
    }

    get timeZoneSidKey() {
        return ( this.record?.fields?.TimeZoneSidKey__c?.value );
    }

}
//