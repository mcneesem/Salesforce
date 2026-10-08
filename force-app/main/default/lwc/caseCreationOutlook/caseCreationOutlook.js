import { LightningElement } from 'lwc';
import HAS_PERMISSION from '@salesforce/customPermission/Case_Creation_Outlook';

export default class CaseCreationOutlook extends LightningElement {
    get hasPermission() {
        return HAS_PERMISSION === true;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.dispatchEvent(new CustomEvent('flowfinished'));
        }
    }
}
