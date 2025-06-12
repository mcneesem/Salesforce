import { LightningElement, api ,wire} from 'lwc';
//importing the apex methods
import executeBatch from '@salesforce/apex/NSP_BatchProgressIndicatorController.executeBatch';
import getUserAccess from '@salesforce/apex/NSP_BatchProgressIndicatorController.getUserAccess';
import getDocuSignBatchSize from '@salesforce/apex/NSP_DocuSignInvoiceDocumentBatch.getBatchSize';
import getInvBatchSize from '@salesforce/apex/NSP_InvoiceBatch.getBatchSize';
import getBatchOptions from '@salesforce/apex/NSP_BatchProgressIndicatorController.getBatchOptions';

export default class NSP_BatchProgressIndicator extends LightningElement {
    @api recordId;
    batchClassName;
    batchSize;
    disableExecuteBatch = false;
    disableBatchSize = false;
    enableBatchUI = false;
    @wire(getInvBatchSize) invBatchSize;
    @wire(getDocuSignBatchSize) docuSignBatchSize;

    batchOptions = [];
    @wire(getBatchOptions)
        wireGetBatchOptions({ error , data }) {
            if ( error ) {
                this.batchOptions = [];
                this.showToast('Error', 'Failed to load batchable classes: ' + (error.body?.message || error.message), 'error');
            } else if ( data ) {
                this.batchOptions = data.map(option => ({
                    label: option.label,
                    value: option.value
                }));
            }
    }

    handleBatchChange(event) {
        this.batchClassName = event.detail.value;
        this.disableBatchSize = false;
        if (this.batchClassName == 'NSP_InvoiceBatch') {
            if (this.invBatchSize != null && this.invBatchSize != ''){
                this.batchSize = this.invBatchSize.data;
            }
            this.disableBatchSize = true;
        }
        if (this.batchClassName == 'NSP_DocuSignInvoiceDocumentBatch') {
            if (this.docuSignBatchSize != null && this.docuSignBatchSize != ''){
                this.batchSize = this.docuSignBatchSize.data;
            }
            this.disableBatchSize = true;
        }
    }

    handleBatchSizeChange(event) {
        this.batchSize = parseInt(event.currentTarget.value);
    }

    //execute the batch class
    handleExecuteBatch() {
        this.disableExecuteBatch = true;
        executeBatch({
            className: this.batchClassName,
            chunkSize: this.batchSize,
            recId : this.recordId
        }).then(res => {
            console.log('response => ', res);
        }).catch(err => {
            console.log('err ', err);

        })
    }

    validateUserAccess() {
        getUserAccess().then(res => {
            console.log('response => ', res);
            if(res) {
                this.enableBatchUI = true;
            }
        }).catch(err => {
            console.log('err ', err);

        })
    }
    connectedCallback(){
        this.validateUserAccess();
   }
}