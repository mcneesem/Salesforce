import { LightningElement, api, wire } from 'lwc';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import EXISTING_RETIREMENT_PLAN from '@salesforce/schema/Implementation_Profile__c.Client_has_existing_retirement_plan__c';
import LIKE_TO_SETUP_WITH_NSP from '@salesforce/schema/Implementation_Profile__c.Client_want_to_begin_401k_w_NSP_setup__c';
import IS_CLIENT_WORKING_WITH_NSP from '@salesforce/schema/Implementation_Profile__c.Client_working_with_an_NSP_RS_rep__c';
import Type_of_retirement_plan from '@salesforce/schema/Implementation_Profile__c.Type_of_retirement_plan_client_has_today__c';
import deferralLoanAmount from '@salesforce/schema/Implementation_Profile__c.Emp_deferral_loan_amount__c';

import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_retirementServicesIp extends LightningElement {
    label = labels;
    @api
    recordId;
    @api
    objectApiName;
    @api error;
    fields = {};
    @api
    defaultRecordTypeId;
    isLoading = true;
    implemenatioProfileDetails;
    showSetupPlanQuestion = false;
    clientDoHaveRetirementPlan = false;
    showIsClientWorkingWithNSPQuestion = false;
    showIsClientWorkingWithNSPRep = false; // Added as part of DF-02101
    showNSPRSContact = false;
    isCSP401K = false;
    lBlueFieldscolor = ['NSP_RS_Contact__c'];
    validRetirementPlans = ['CSP 401K and wants to keep it', 'Simple IRA', '403B'];

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: EXISTING_RETIREMENT_PLAN })
    existingRetirementPlan;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: LIKE_TO_SETUP_WITH_NSP })
    likeToSetupWithNSP;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: IS_CLIENT_WORKING_WITH_NSP })
    isClientWorkingWithNSP;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: Type_of_retirement_plan })
    typeOfRetirementPlan;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: deferralLoanAmount })
    deferralLoanAmountOptions
    @wire(getRecord, {
        recordId: '$recordId', fields: [EXISTING_RETIREMENT_PLAN, LIKE_TO_SETUP_WITH_NSP,IS_CLIENT_WORKING_WITH_NSP]
    })
    getCaseDetails(value) {
        this.implemenatioProfileDetails = value;
        const { data, error } = value;
        if (data) {
            let fields = data.fields;
            let oImpProfileFields = {};
            for(let field in fields){
                oImpProfileFields[field] = fields[field].value;
                this.showDynamicFields(field,fields[field].value);
            }
            this.fields = oImpProfileFields;
        } else if (error) {
            this.error = error;
        }
    }

    // RECORD EDIT FORM
    handleLoad(){
        this.isLoading = false;
        this.fixLabelColor();
    }
    
    fixLabelColor(){
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        inputFields.forEach(field => {
            if(this.lBlueFieldscolor.includes(field.fieldName)){
                this.handleEmptyColor(field.fieldName,field.value);
            }
        });
    }

    handleChange(event) {
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value;
        this.showDynamicFields(field, value);
    }

    handleInputChange(event) {
        let value = Array.isArray(event.detail.value) ? event.detail.value[0] : event.detail.value;
        let field = event.currentTarget.fieldName;
        this.handleEmptyColor(field,value);
    }

    showDynamicFields(field, value) {
        if (field === 'Client_has_existing_retirement_plan__c') {
             /* added as part of DF-02101 */
             this.showSetupPlanQuestion = (value === this.label.NO_CONSTANT);
             if(value === this.label.YES_CONSTANT){
                 this.clientDoHaveRetirementPlan = true;
                 this.fields.Client_working_with_an_NSP_RS_rep__c = null;
                 this.showNSPRSContact = false;
             }
             if(value === this.label.NO_CONSTANT){
                 this.clientDoHaveRetirementPlan = false;
                 this.fields.Client_want_to_begin_401k_w_NSP_setup__c = null;
                 this.fields.Type_of_retirement_plan_client_has_today__c = null;
                 this.fields.Emp_deferral_loan_amount__c = null;
                 this.fields.Client_working_with_an_NSP_RS_rep__c = null;
                 this.fields.NSP_RS_Contact__c = '';
                 this.isCSP401K = false;
                 this.showNSPRSContact = false;
                 this.showSetupPlanQuestion = true;
                 this.showIsClientWorkingWithNSPRep = false;
             }
             /* added as part of DF-02101 */
             return;
         }
         if (field === 'Client_want_to_begin_401k_w_NSP_setup__c') {
             if (value === this.label.YES_CONSTANT) {
                 this.showIsClientWorkingWithNSPQuestion = true;
                  this.showIsClientWorkingWithNSPRep = true;
             } 
             if (value === this.label.NO_CONSTANT) {
                 this.fields.Client_working_with_an_NSP_RS_rep__c = null;
                 this.fields.NSP_RS_Contact__c = '';
                 this.showIsClientWorkingWithNSPQuestion = false;
                 this.showNSPRSContact = false;
                 this.showIsClientWorkingWithNSPRep = false;
             }
             return;
         }
         if (field === 'Client_working_with_an_NSP_RS_rep__c') {
             if (value === this.label.NO_CONSTANT) {
                 this.showNSPRSContact = true;
             } 
             if (value === this.label.YES_CONSTANT) {
                 this.fields.NSP_RS_Contact__c = '';
                 this.showNSPRSContact = false;
             }
             return;
         }
        if(field === 'Type_of_retirement_plan_client_has_today__c'){
            this.isCSP401K = this.validRetirementPlans.includes(value);
        }
    }

    handleEmptyColor(field,value) {
        if(this.lBlueFieldscolor.includes(field)){
            let eField = this.template.querySelector(`.${field}`);
            if(eField){
                if (value) {
//                    eField.classList.remove('emptyField');
                } else {
//                    eField.classList.add('emptyField');
                }
            }
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