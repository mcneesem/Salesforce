import { LightningElement } from 'lwc';

export default class GenerateRenewalOpportunities extends LightningElement {
    showFlow = false;
        handleClick() {
        this.showFlow = true;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showFlow = false;
        }
    }
}