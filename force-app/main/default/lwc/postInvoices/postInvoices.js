import { LightningElement, api } from 'lwc';
import postInvoices from '@salesforce/apex/PostInvoicesController.PostInvoices';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

export default class PostInvoices extends LightningElement {

    @api reactiveValue
    @api recordId;
    isButtonDisabled = false;

    handleClick(){
        this.isButtonDisabled = true;
        postInvoices({invoiceRunId : this.reactiveValue}).then(() => {
            this.showToast("Success","Reverted records","success");
        }).catch(error => {
            this.showToast("Error",error.body.message,"error");
        });
    }

    showToast(theTitle, theMessage, theVariant) {
        const event = new ShowToastEvent({
            title: theTitle,
            message: theMessage,
            variant: theVariant
        });
        this.dispatchEvent(event);
    }
}