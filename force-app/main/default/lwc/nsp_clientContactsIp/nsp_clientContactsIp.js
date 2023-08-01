import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as labels from 'c/nsp_implementationLabels';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';

export default class Nsp_clientContactsIp extends LightningElement {
    label = labels;
    @api
    recordId;
    @api
    objectApiName;
    isLoading = true;
    oOSSRecord = {};
    oWCRecord = {};
    oPCRecord = {};
    oBackupRecord = {};
    hrRecord={};
    
    @api backupFieldDisabled;
    reloadBackupFields = true;

    makeOSSSameasKDM(){
        let oOSSRecord = {};
        oOSSRecord.NSP_OSS_Client_Name__c = this.template.querySelector('.kdmClientName').value;
        oOSSRecord.NSP_OSS_Client_Office_Phone__c = this.template.querySelector('.kdmClientOfficePhone').value;
        oOSSRecord.NSP_OSS_Client_Cell_Phone__c = this.template.querySelector('.kdmClientCellPhone').value;
        oOSSRecord.NSP_OSS_Client_Email__c = this.template.querySelector('.kdmClientEmail').value;
        oOSSRecord.NSP_OSS_Client_Contact_Method__c = this.template.querySelector('.kdmClientContactMethod').value;
        this.oOSSRecord = oOSSRecord;
    }

    makeWCSameasOSS(){
        let oWCRecord = {};
        oWCRecord.NSP_WC_Client_Name__c = this.template.querySelector('.ossClientName').value;
        oWCRecord.NSP_WC_Client_Office_Phone__c = this.template.querySelector('.ossClientOfficePhone').value;
        oWCRecord.NSP_WC_Client_Cell_Phone__c = this.template.querySelector('.ossClientCellPhone').value;
        oWCRecord.NSP_WC_Client_Email__c = this.template.querySelector('.ossClientEmail').value;
        oWCRecord.NSP_WC_Client_Contact_Method__c = this.template.querySelector('.ossClientContactMethod').value;
        this.oWCRecord = oWCRecord;
    }
    
    makePCSameasOSS(){
        let oPCRecord = {};
        oPCRecord.NSP_PC_Client_Name__c = this.template.querySelector('.ossClientName').value;
        oPCRecord.NSP_PC_Client_Office_Phone__c = this.template.querySelector('.ossClientOfficePhone').value;
        oPCRecord.NSP_PC_Client_Cell_Phone__c = this.template.querySelector('.ossClientCellPhone').value;
        oPCRecord.NSP_PC_Client_Email__c = this.template.querySelector('.ossClientEmail').value;
        oPCRecord.PC_Client_Contact_Method__c = this.template.querySelector('.ossClientContactMethod').value;
        this.oPCRecord = oPCRecord;
    }
    
    makeHRSameasOSS(){
        let hrRecord = {};
        hrRecord.NSP_HR_Client_Name__c = this.template.querySelector('.ossClientName').value;
        hrRecord.HR_Contact_Office_Phone__c = this.template.querySelector('.ossClientOfficePhone').value;
        hrRecord.HR_Contact_Cell_Phone__c = this.template.querySelector('.ossClientCellPhone').value;
        hrRecord.NSP_HR_Client_Email__c = this.template.querySelector('.ossClientEmail').value;
        hrRecord.HR_Contact_Method__c = this.template.querySelector('.ossClientContactMethod').value;
        this.hrRecord = hrRecord;
    }

    get addBlackColor(){
        return this.backupFieldDisabled ? 'addBlackColor': 'addBlueColor';
    }
    
    makeBackupPCdisable(event){
        this.backupFieldDisabled = event.detail.checked;
        if(event.detail.checked){
            this.oBackupRecord = {
                NSP_AIMS_ClientNo_Backup_PC__c : null,
                NSP_Back_up_PC_Client_Name__c : null,
                NSP_Back_up_Client_Office_Phone__c : null,
                NSP_Back_up_Client_Cell_Phone__c : null,
                NSP_Back_up_Client_Email__c : null,
                NSP_Back_up_Client_Contact_Method__c : null,
            };
            this.reloadBackupFields = false;
           setTimeout( () => this.reloadBackupFields = true, 0);
        }
    }
    // RECORD EDIT FORM
    handleLoad(){
        this.isLoading = false;
        let noBackUpPCField = this.template.querySelector('.noBackUpPC');
        this.backupFieldDisabled = noBackUpPCField.value;
    }

    @api
    saveForm(newRecordId){
        const fields = {};

        this.isLoading = true;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });
        const existingRecordId = this.recordId || newRecordId;
        if (existingRecordId) {
            fields['Id'] = existingRecordId;
            updateRecord({ fields })
                .then((oImpProfile) => {
                    this.isLoading = false;
                    this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
                    this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": oImpProfile.id } }));
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast(this.label.errorTitle, error.body.message, 'error');
                    this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
                });
        } else {
            const recordInput = { apiName: this.objectApiName, fields };
            createRecord(recordInput)
                .then(oImpProfile => {
                    this.isLoading = false;
                    this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
                    this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": oImpProfile.id } }));
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast(this.label.errorTitle, error.body.message, 'error');
                    this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
                });
        }
    }

    handleSuccess(event){
        //Id is event.detail.id
        this.isLoading = false;
        this.showToast(this.label.successTitle, this.label.implementationSavedMessage,'success');
        this.dispatchEvent(new CustomEvent('success', {detail : { "recordId" : event.detail.id}}));
    }
    handleError(event){
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
        this.showToast(this.label.errorTitle,event.detail.detail,'error');
        // Maybe fire Error event for the Parent Component
    }
    showToast(title,message,type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: type,
            }),
        );
    }
}