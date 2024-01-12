import { api, LightningElement, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import IMMEDIATE_NEED_WORKERS from '@salesforce/schema/Implementation_Profile__c.NSP_Immediate_need_for_Workers_Comp_Cert__c';
import CLIENT_HAVE_URGENT_NEED_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_any_urgent_HR_needs__c';
import CLIENT_HAVE_GROWTH_PLANS from '@salesforce/schema/Implementation_Profile__c.NSP_Does_Client_have_Growth_Plans__c';
import CHECK_ALL_THAT_APPLY from '@salesforce/schema/Implementation_Profile__c.Check_all_changes_that_apply__c';
import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_serviceTeamIp extends LightningElement {
    label = labels;
    @api error;
    @api
    recordId;
    @api
    objectApiName;
    fields = {
        Check_all_changes_that_apply__c : []
    };
    @api
    defaultRecordTypeId;
    isLoading = true;
    showCertificationFields = false;
    showHRNeedField = false;
    showAnticipatedPlanDetailsField = false;
    multiSelectFields = ['Check_all_changes_that_apply__c'];

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: IMMEDIATE_NEED_WORKERS })
    immediateNeedForWorkersValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_HAVE_URGENT_NEED_FIELD })
    clientHaveUrgentHRNeeds;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_HAVE_GROWTH_PLANS })
    anticipatedGrowthPlans;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CHECK_ALL_THAT_APPLY })
    checAllThatApplyOptions;

    @wire(getRecord, {
        recordId: '$recordId', fields: [IMMEDIATE_NEED_WORKERS, CLIENT_HAVE_URGENT_NEED_FIELD,CLIENT_HAVE_GROWTH_PLANS, CHECK_ALL_THAT_APPLY]
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

        this.fields[field] = this.multiSelectFields.includes(field) ? value.join(';') : value;
        this.showDynamicFields(field, value);
    }
    showDynamicFields(field, value) {
        if (field === 'NSP_Immediate_need_for_Workers_Comp_Cert__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showCertificationFields = true;
            } else {
                this.showCertificationFields = false;
                this.fields.When_are_certificates_needed__c = null;
                this.fields.List_of_certificates_requested__c = null;
                this.fields.Send_the_certificates_to__c = null;
            }
            return;
        }
        if (field === 'Client_have_any_urgent_HR_needs__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showHRNeedField = true;
            } else {
                this.showHRNeedField = false;
                this.fields.Provide_Urgent_HR_Needs_details__c = null;
            }
            return;
        }
        if (field === 'NSP_Does_Client_have_Growth_Plans__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showAnticipatedPlanDetailsField = true;
            } else {
                this.showAnticipatedPlanDetailsField = false;
                this.fields.NSP_Anticipated_Growth_Plans_details__c = null;
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