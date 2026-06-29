import { LightningElement , api } from 'lwc';

export default class PortalProjectTab extends LightningElement {
    @api record; // is-a Portal_Project__c

    get columnSizeFull() {
        return 12;
    }

    get columnSizeLeft() {
        return 8;
    }

    get columnSizeRight() {
        return ( this.columnSizeFull - this.columnSizeLeft );
    }

    get recordId() {
        return this.record?.fields?.Id?.value;
    }

    get showMeetingCalendar() {
        return !this.showMeetingList;
    }

    get showMeetingList() {
        return true;
    }

}
//