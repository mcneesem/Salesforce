import { LightningElement, api, wire, track } from 'lwc';
import * as labels from 'c/nsp_implementationLabels';
import { IP_FIELDS } from './constants';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class Nsp_miscellaneous extends LightningElement {

    label = labels;
    @api recordId;
    @api objectApiName;
    @api objectInfo;
    @api error;
    @track fields = {};
    implementationProfileDetails;
    isLoading = false;
    
    @wire(getRecord, {
        recordId: '$recordId', fields: IP_FIELDS
    })
    getImplementationProfileDetails(value) {
        this.implementationProfileDetails = value;
        const { data, error } = value;
        if (data) {
            let fields = data.fields;
            let oImpProfileFields = {};
            for (let field in fields) {
                oImpProfileFields[field] = fields[field].value;
            }
            this.fields = oImpProfileFields;
        } else if (error) {
            this.error = error;
        }
    }

    get recordTypeId() {
        // Returns a map of record type Ids 
        if (this.objectInfo && this.objectInfo.recordTypeInfos) {
            const rtis = this.objectInfo.recordTypeInfos;
            return Object.keys(rtis).find(rti => rtis[rti].name === this.label.FSO);
        }
    }

    handleselected(event) {
        let detail = event.detail;
        let target = this.template.querySelector(`[data-id="${detail.fieldApiName}"]`);
        if (detail.fieldType == "Picklist") {
            target.value = detail.selectedValue;
            this.fields[detail.fieldApiName] = detail.selectedValue;
        }
    }

    @api
    saveForm(newRecordId) {
        const fields = this.fields;
        
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
                    refreshApex(this.implementationProfileDetails)
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

    handleLoad() {
        this.isLoading = false;
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

    get isEnrollmentfee() {
        if(this.fields.NSP_Is_there_an_Enrollment_fee__c === 'No'){
            this.fields['NSP_Provide_Details_Enrollment_fee__c'] = null;
        }
        return (this.fields.NSP_Is_there_an_Enrollment_fee__c === 'Yes')
    }

}