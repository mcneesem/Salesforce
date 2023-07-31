import { api, LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import MULTIPLE_WORKSITE_FIELD from '@salesforce/schema/Implementation_Profile__c.Are_there_multiple_worksite_locations__c';
import TRANSLATOR_QUESTION_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Is_a_translator_needed__c';
import TECHPACK_QUESTION_FIELD from '@salesforce/schema/Implementation_Profile__c.Is_there_a_need_for_a_tech_package__c';
import EE_ORIENTATION_FIELD from '@salesforce/schema/Implementation_Profile__c.Any_special_needs_for_EE_orientation__c';

import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_orientationIp extends LightningElement {
    label = labels;
    @api error;
    @api
    recordId;
    @api
    objectApiName;
    fields = {
        Any_special_needs_for_EE_orientation__c: []
    };
    @api
    defaultRecordTypeId;
    isLoading = true;
    showWorksiteDetails = false;
    showTranslatorFields = false;
    showTechpackField = false;
    multiSelectFields = ['Any_special_needs_for_EE_orientation__c'];

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: MULTIPLE_WORKSITE_FIELD })
    multipleWorksiteFieldQuestion;

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: EE_ORIENTATION_FIELD })
    eeOrientationOptions;

    @wire(getRecord, {
        recordId: '$recordId', fields: [MULTIPLE_WORKSITE_FIELD,TRANSLATOR_QUESTION_FIELD,TECHPACK_QUESTION_FIELD, EE_ORIENTATION_FIELD]
    })
    getImplementationDetails(value) {
        this.implementationDetails = value;
        const { data, error } = value;
        if (data) {
            let fields = data.fields;
            let oImpProfileFields = {};
            for(let field in fields){
                const val = fields[field].value;
                oImpProfileFields[field] = this.multiSelectFields.includes(field) ? (val || '').split(';') : val;
                this.showDynamicFields(field, val);
            }
            this.fields = oImpProfileFields;
        } else if (error) {
            this.error = error;
        }
    }

    // RECORD EDIT FORM
    handleLoad(){
        this.isLoading = false;
    }
    handleChange(event) {
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value;
        this.showDynamicFields(field, value);
    }

    handleCheckboxChange(event){
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value.join(';');
        this.showDynamicFields(field, value);
    }

    showDynamicFields(field, value) {
        if (field === 'Are_there_multiple_worksite_locations__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showWorksiteDetails = true;
            } else {
                this.showWorksiteDetails = false;
            }
            return;
        }

        if (field === 'NSP_Is_a_translator_needed__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showTranslatorFields = true;
            } else {
                this.showTranslatorFields = false;
            }
            return;
        }

        if (field === 'Is_there_a_need_for_a_tech_package__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showTechpackField = true;
            } else {
                this.showTechpackField = false;
            }
            return;
        }
    }

    @api
    saveForm(newRecordId){
        this.isLoading = true;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        let fields = JSON.parse(JSON.stringify(this.fields));
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
    showToast(title, message, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: type,
            }),
        );
    }
}