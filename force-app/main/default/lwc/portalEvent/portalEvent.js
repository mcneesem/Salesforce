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

    get isVisible() {
        return ( this.record?.fields?.Is_Visible__c?.value );
    }

    get meetingUrl() {
        return ( this.record?.fields?.Meeting_URL__c?.value );
    }

    get rank() {
        return ( this.record?.fields?.Rank__c?.value );
    }

    get status() {
        return ( this.record?.fields?.Status__c?.value );
    }

    get timeZoneSidKey() {
        return ( this.record?.fields?.TimeZoneSidKey__c?.value );
    }

}
//