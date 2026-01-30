import { LightningElement , api } from 'lwc';

export default class PortalClientTabProgress extends LightningElement {
    @api recordId;
    get showMeetingCalendar() {
        return !this.showMeetingList;
    }
    get showMeetingList() {
        return true;
    }
}
//