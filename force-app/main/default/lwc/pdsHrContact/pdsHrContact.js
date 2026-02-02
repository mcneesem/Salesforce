import { LightningElement, api, track } from 'lwc';

export default class PdsHrContact extends LightningElement {
    // Record Page context Id (NSP_Payroll__c Id)
    @api recordId;

    @track showFlow = false;
    @track loading = false;

    // Provide Flow input variables: pass only recordId
    get flowInputs() {
        return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

}