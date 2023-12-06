import { LightningElement, api } from 'lwc';
import getPDSRecordsForSubClient from '@salesforce/apex/NSP_PDSRecordManagerController.getPDSRecordsForSubClient';
import getUpdatedSubClient from '@salesforce/apex/NSP_PDSRecordManagerController.getUpdatedSubClient';
import ExistingPDSMessageLabel from '@salesforce/label/c.ExistingPDSMessage';
import PDSSyncedMessageLabel from '@salesforce/label/c.PDSSyncedMessage';
import IntegrationUserLabel from '@salesforce/label/c.Integration_User';
import PDSCreateErrorLabel from '@salesforce/label/c.NSP_PDS_Create_Validation';

export default class Nsp_pdsRecordManager extends LightningElement {
    @api recordId;
    @api navigateToList;
    label = {ExistingPDSMessageLabel, PDSSyncedMessageLabel, IntegrationUserLabel,PDSCreateErrorLabel};
    recordMessage = '';
    newPDSId = '';
    showError = false;
 
    connectedCallback() {
       this.fetchPDSRecordsForSubClient();
    }

    fetchPDSRecordsForSubClient() {
        try {
            this.showError = false;
            getPDSRecordsForSubClient({recordId : this.recordId}).then((result)=>{
                if(result === 'PDS Exists') {
                    this.showError = true;
                    this.recordMessage = this.label.ExistingPDSMessageLabel;
                }else {
                    this.newPDSId = result;
                    if(this.newPDSId==null || this.newPDSId=='' ){
                        this.recordMessage = this.label.PDSCreateErrorLabel;
                    }
                    else{
                        this.recordMessage = this.label.PDSSyncedMessageLabel;
                        setTimeout(() => {
                            this.fetchUpdatedSubClient();
                        }, 5000);
                    }
                }
            })
            
        } catch (error) {
        }
       
    }

    fetchUpdatedSubClient() {
        getUpdatedSubClient({recordId : this.recordId}).then((eachSubClient)=>{
            if ( eachSubClient === this.label.IntegrationUserLabel ) {
                this.navigateToList('/'+this.newPDSId);
            } else {
                this.fetchUpdatedSubClient();
            }
        })
    }

    handleClose(){
        history.back();
    }
}