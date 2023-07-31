import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import cloneRelatedRecords from'@salesforce/apex/NSP_PayrollTriggerHelper.deepCloneRec';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Nsp_cloneRelatedRecord extends NavigationMixin(LightningElement) {
 
    @api recordId;
    selectedLookupId;
    isCloningInProgress = false;
    @api error;
    selectedLookupId;
    isCloningInProgress = false;
    retrievedRecordId = false;
    disableSubmit = true;
    disableCancel = false;

    handleChange(event) {
        this.selectedLookupId = event.detail.value[0];
        if(this.selectedLookupId != null || this.selectedLookupId != undefined) {
            this.disableSubmit = false;
        }
        else if(this.selectedLookupId == null || this.selectedLookupId == undefined) {
            this.disableSubmit = true;
        }
        console.log('selectedLookupId : ',JSON.stringify(this.selectedLookupId));
    }

    handleSubmit(event) {
        this.isCloningInProgress = true;
        if (!this.retrievedRecordId && this.recordId && this.isCloningInProgress) {
            
            this.retrievedRecordId = true; // Escape case from recursion
            this.initiateClone(); 
        }
        
        if(this.isCloningInProgress) {
           this.disableCancel = true;
           this.disableSubmit = true;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }      

    showToast() {
        const event = new ShowToastEvent({
            title: 'Error',
            message: 'You may not have more than 1 Payroll Data Sheet per Sub Client',
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

   initiateClone() {    
    cloneRelatedRecords({recordId : this.recordId, subClientId : this.selectedLookupId}).then((eachResult)=>{        
        try {
            if(eachResult) {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: eachResult,
                        objectApiName: 'NSP_Payroll__c',
                        actionName: 'view'
                    },
                });
            }
            else if(eachResult == null || eachResult == '') {
                this.showToast();
                this.handleCancel();
            }
        } catch (error) {
            console.error('error occured: ',JSON.stringify(error));
        }        
    })
   }
}