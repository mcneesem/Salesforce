import { LightningElement, api } from 'lwc';

export default class Nsp_cloneAccrualProfileRecordForm extends LightningElement {
    @api recordId;
    
    closeModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}