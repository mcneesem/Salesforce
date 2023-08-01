import { LightningElement,api } from 'lwc';
import releatedFiles from '@salesforce/apex/NSP_ReportRequestWizardController.releatedFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
export default class WizardFileUpload extends NavigationMixin(LightningElement){
    
    @api reReqId;
    @api showSpinner = false; //DF-02304 
    wiredRelatedFileResult;
    relatedfile;
    error;
    

    showToast(title,variant,message){
        const event = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
        });
        this.dispatchEvent(event);
 }

 getBaseUrl(){
    return 'https://'+location.host+'/';
}

    connectedCallback(){
        this.handleFilelist() ;
        this.baseUrl= this.getBaseUrl();
    }

    handleUploadFinished(event) {
        let strFileNames = '';
        const uploadedFiles = event.detail.files;
    
     if(uploadedFiles.length > 0){    
        for(let i = 0; i < uploadedFiles.length; i++) {
        strFileNames += uploadedFiles[i].name + ', ';
        }
        this.showToast('Success!!','success',strFileNames + ' Files uploaded Successfully!!!');
        this.handleFilelist();
    }

    }

    handleFilelist() {
        releatedFiles({ idParent : this.reReqId })
            .then((result) => {
                this.relatedfile = result;
                this.error = undefined;
            if(result != null && result.length !=null ){
                this.dispatchEvent(new CustomEvent('fileaction', { detail : { length :result.length } } ));
            }else{
                this.dispatchEvent(new CustomEvent('fileaction', { detail : { length : 0 } } ));
            }

            })
            .catch((error) => {
                this.error = error;
                this.relatedfile = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }

    downloadFile(event){
        const recordId = event.target.dataset.recordid;
        const downloadUrl = this.baseUrl+'sfc/servlet.shepherd/document/download/'+recordId;
            this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: downloadUrl
                    }
                }, false 
            );
        }

        deleteRelatedFile(event) {
            this.showSpinner = true;
            const recordId = event.target.dataset.recordid;
            this.template.querySelector("[data-id=spinner]").classList.remove('slds-hide');
            deleteRecord(recordId)
                .then(() => {
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'File deleted',
                            variant: 'success'
                        })
                    );
                    this.handleFilelist();
                    this.template.querySelector("[data-id=spinner]").classList.add('slds-hide');
                   
                    return refreshApex(this.relatedfile);
                   
                })
                .catch((error) => {
                    this.showSpinner = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: error,
                            variant: 'error'
                        })
                    );
                    this.template.querySelector("[data-id=spinner]").classList.add('slds-hide');
                });
        }

}