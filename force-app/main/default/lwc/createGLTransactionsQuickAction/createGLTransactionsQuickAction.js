import { LightningElement, api } from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import createGLRecords from '@salesforce/apex/CreateGLTransactionsController.createGLTransactions';

export default class CreateGLTransactionsQuickAction extends LightningElement {
    @api recordId;
    isExecuting = false;    

    @api
    async invoke() {
        if ( !this.isExecuting ) {
            createGLRecords({glPeriodId : this.recordId}).then(() => {
                this.showToast("Success","Creating GL Transaction Records..","success");
            }).catch(error => {
                this.showToast("Error",error.body.message,"error");
            });
            this.isExecuting = true;
        }
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