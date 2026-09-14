import { LightningElement, api } from 'lwc';

export default class ScheduleSellerFormattedDateTime extends LightningElement {
    @api startDateTime;   // DateTime from the picked slot
    @api endDateTime;     // DateTime from the picked slot
    @api timeZoneSidKey;        // e.g. "America/Los_Angeles"

    get hasStart() {
        return Boolean(this.startDateTime);
    }

    get hasEnd() {
        return Boolean(this.endDateTime);
    }
}