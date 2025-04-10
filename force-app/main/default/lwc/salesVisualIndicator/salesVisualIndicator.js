import { api, track, LightningElement } from 'lwc';
import salesVisualResources from '@salesforce/resourceUrl/NSP_ReportingResource';
import getAccount from '@salesforce/apex/SalesVisualIndicatorHelper.getAccount';

export default class SalesVisualIndicator extends LightningElement {

    @api recordId;
    @track showWorkDayLogo = false;

    workdayLogo = salesVisualResources + '/nsp_ReportingResource/images/wday_logo.jpg';

    connectedCallback() {
        getAccount({ accId: this.recordId })
            .then((data) => {
                this.showWorkDayLogo = data.isWorkday;
            })
            .catch((e) => {
                console.error(e.body && e.body.message ?  e.body.message : "Server Error");
            });
    }

}