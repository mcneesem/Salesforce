import { LightningElement, wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord , getRecordNotifyChange } from 'lightning/uiRecordApi';
import getReportRequestList from '@salesforce/apex/NSP_ReportRequestWizardController.getReportRequestList';
import { NavigationMixin } from 'lightning/navigation';

export default class HandleDraftWizards extends NavigationMixin(LightningElement) {
    @api recordTypeIds
    reportRequest;
     error;
     recordId;
     repReqObj;
     wizardName='Edit Wizard';
     isDialogVisible = false;
     originalMessage;
     lastSavedPage ;
     openPrompt = false;
     urlStateParameters;
     sfdcBaseURL;
     openPageNumber ;
    /** Wired Apex result so it can be refreshed programmatically */
    wiredReportRequestResult;
    connectedCallback(){
        this.sfdcBaseURL = window.location.href;
        this.handleRelatedList();
    }

    get header() {
        if (this.wizardName.includes("Development")) {
            return "Request a WebFocus or Wire Report";
        }
        if (this.wizardName.includes("Survey")) {
            return "HR Survey Request";
        }
        if (this.wizardName.includes("Separation")) {
            return "Separation Agreement Request";
        }
        if (this.wizardName.includes("HRScale")) {
            return "Request an HRScale Report";
        }

        return 'Edit Wizard';
    }

    get showDevelopReport(){
        return  (
            this.wizardName.includes('Development') ||
            this.wizardName.includes("HRScale")
        );
    }
    get showSurvey(){
        return  this.wizardName.includes('Survey');
    }
    get showSeperation(){
        return  this.wizardName.includes('Separation');
    }


    @api refreshdraft(){
         refreshApex(this.handleRelatedList());
        this.navigateToWebPage();
      // return refreshApex(this.wiredReportRequestResult);
    }

    navigateToWebPage() {
        // Navigate to a URL
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: this.sfdcBaseURL
            }
        },
        true // Replaces the current page in your browser history with the URL
      );
    }

    handleRelatedList() {
        getReportRequestList({ recordTypeIds : this.recordTypeIds })
            .then((result) => {
                this.reportRequest = result.map(obj=> {
                    let date = new Date(obj.CreatedDate);
                    const day = date.toLocaleString('default', { day: '2-digit' });
                    const month = date.toLocaleString('default', { month: 'short' });
                    const year = date.toLocaleString('default', { year: 'numeric' });
                    let createDate = month + ' ' + day + ' ' + year;
                    if(obj.NSP_ClientName__c && obj.NSP_ClientName__r.Name != undefined){

                     return {...obj , AccountName : createDate+" - "+obj.NSP_ClientName__r.Name}

                    }else{
                     return {...obj, AccountName :  createDate+' - No Account Selected'}
                    }
                 });

                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.reportRequest  = undefined;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error!!',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }

    editReportRequest(event){
        let fullData = this.reportRequest;
        this.recordId = event.target.dataset.recordid;
        this.repReqObj = fullData.find(obj=>obj.Id == this.recordId);
        this.lastSavedPage = this.repReqObj.NSP_LastSavedPageNumber__c;
        this.wizardName = this.repReqObj.RecordType.DeveloperName;
        this.openPrompt = true;
        const modalPrompt = this.template.querySelector('c-wizard-resume-prompt');

        modalPrompt.show();
    }

    deleteReportRequest(event) {
        if(event.target.name === 'deleteRequest'){


        this.originalMessage = event.target.dataset.recordid ;
        //shows the component
        this.isDialogVisible = true;
      }else if(event.target.name === 'confirmModal'){

        //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
        if(event.detail !== 1){

            //you can do some custom logic here based on your scenario
            if(event.detail.status === 'confirm') {
                //do something
                const recordId =  event.detail.originalMessage;
                deleteRecord(recordId)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Report Request deleted',
                            variant: 'success'
                        })
                    );
                 return  this.handleRelatedList();
                    //return refreshApex(this.wiredReportRequestResult);
                })
                .catch((error) => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error deleting record',
                            message: error,
                            variant: 'error'
                        })
                    );
                });

            }else if(event.detail.status === 'cancel'){
                //do something else
            }
        }

        //hides the component
        this.isDialogVisible = false;
    }
  }


    handleShowModal() {
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleCancelModal() {
        const modal = this.template.querySelector('c-modal');
        modal.hide();
      return refreshApex(this.handleRelatedList());
    }

    handleCloseModal() {
        const modal = this.template.querySelector('c-modal');
        modal.hide();
         refreshApex(this.handleRelatedList());
         this.refreshdraft();
        // return refreshApex(this.wiredReportRequestResult);
    }

    handleResume(event){
        const modal = this.template.querySelector('c-modal[data-fname="OpenlastSavedPage"]');
        modal.show();
    }
    handleStartOver(event){
      const modal = this.template.querySelector('c-modal[data-fname="OpenFirstPage"]');
        modal.show();
    }

}
