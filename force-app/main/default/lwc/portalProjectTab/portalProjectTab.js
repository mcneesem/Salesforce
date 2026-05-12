import { LightningElement , api } from 'lwc';

export default class PortalProjectTab extends LightningElement {
    @api record; // is-a Portal_Project__c

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