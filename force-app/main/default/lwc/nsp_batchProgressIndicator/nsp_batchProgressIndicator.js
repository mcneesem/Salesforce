import { LightningElement, api } from 'lwc';
//importing the apex methods
import getJobDetails from '@salesforce/apex/NSP_BatchProgressIndicatorController.getJobDetails';
import executeBatch from '@salesforce/apex/NSP_BatchProgressIndicatorController.executeBatch';
import getUserAccess from '@salesforce/apex/NSP_BatchProgressIndicatorController.getUserAccess';

export default class NSP_BatchProgressIndicator extends LightningElement {
    @api recordId;
    batchJobId;
    batchClassName;
    batchSize;
    disableExecuteBatch = false;
    disableBatchSize = false;
    enableBatchUI = false;
    showList = false;
    jobsList = [];

    get batchOptions() {
        return [
            { label: 'Invoice Post Batch', value: 'NSP_InvoiceBatch' }
           // { label: 'DocuSign Document Generation Batch', value: 'NSP_DocuSignInvoiceDocumentBatch' },
           // { label: 'Invoice Email Batch', value: 'TBD' }
        ];
    }

    handleBatchChange(event) {
        this.batchClassName = event.detail.value;
        this.disableBatchSize = false;
        if (this.batchClassName == 'NSP_InvoiceBatch') {
            this.batchSize = 1;
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
            if (res) {
                this.batchJobId = res;
                this.getBatchStatus();
            }
        }).catch(err => {
            console.log('err ', err);

        })
    }
    
    //get the batch status
    getBatchStatus() {
        getJobDetails().then(res => {
            console.log('response => ', res);
            let tempjobsList = [];
            this.showList = false;
            if (res.length > 0) {
                res.forEach(element => {
                let batchObj={};
                batchObj.batchJobId = element.Id;
                //batchObj.batchJobName = element.ApexClass.Name;
                batchObj.totalBatch = element.TotalJobItems;
                if (element.TotalJobItems == element.JobItemsProcessed) {
                    batchObj.isBatchCompleted = true;
                }
                batchObj.executedPercentage = ((element.JobItemsProcessed / element.TotalJobItems) * 100).toFixed(2);
                batchObj.executedBatch = element.JobItemsProcessed;
                var executedNumber = Number(batchObj.executedPercentage);
                batchObj.executedIndicator = Math.floor(executedNumber);
                //var classObj = element.ApexClass;
                batchObj.batchClassName = element.ApexClass.Name;
                tempjobsList.push(batchObj);
                });
                this.jobsList = tempjobsList;
                this.showList = true;
                this.disableExecuteBatch = true;

                //this.totalBatch = res[0].TotalJobItems;
                //if (res[0].TotalJobItems == res[0].JobItemsProcessed) {
                //    this.isBatchCompleted = true;
                //}
                //this.executedPercentage = ((res[0].JobItemsProcessed / res[0].TotalJobItems) * 100).toFixed(2);
                //this.executedBatch = res[0].JobItemsProcessed;
                //var executedNumber = Number(this.executedPercentage);
                //this.executedIndicator = Math.floor(executedNumber);
                 this.refreshBatchOnInterval();  //enable this if you want to refresh on interval
            }
        }).catch(err => {
            console.log('err ', err);

        })
    }

    handleRefreshView() {
        this.getBatchStatus();
    }

    refreshBatchOnInterval() {
        this._interval = setInterval(() => {
            if (!this.showList) {
                clearInterval(this._interval);
            } else {
                this.getBatchStatus();
            }
        }, 10000); //refresh view every time
    }

    validateUserAccess() {
        getUserAccess().then(res => {
            console.log('response => ', res);
            if(res) {
                this.enableBatchUI = true;
                this.handleRefreshView();
            }
        }).catch(err => {
            console.log('err ', err);

        })
    }
    connectedCallback(){
        this.validateUserAccess();
   } 
}