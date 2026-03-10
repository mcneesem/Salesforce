import { LightningElement , api } from 'lwc';

export default class PortalProjectTab extends LightningElement {
    @api record; // is-a Portal_Project__c

    get showMeetingCalendar() {
        return !this.showMeetingList;
    }

    get showMeetingList() {
        return true;
    }
}
//