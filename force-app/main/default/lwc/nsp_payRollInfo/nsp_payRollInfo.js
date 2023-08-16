import { LightningElement, api, wire, track } from 'lwc';
import * as labels from 'c/nsp_implementationLabels';
import { IP_FIELDS, YES_NO_OPTIONS } from './constants';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class Nsp_payRollInfo extends LightningElement {

    label = labels;
    @api recordId;
    @api objectApiName;
    @api objectInfo;
    @track fields = {};
    @api error;
    isLoading;
    isSubAccount = false;
    implementationProfileDetails;

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
            this.isSubAccount = this.fields?.Is_there_a_need_for_a_subaccount__c == YES_NO_OPTIONS.YES ? true : false;
        } else if (error) {
            this.error = error;
        }
    }

    handleLoad() {
        this.isLoading = false;
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
                    refreshApex(this.implementationProfileDetails);
                    this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
                    this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": oImpProfile.id } }));
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast(this.label.errorTitle, error.body.message, 'error');
                    this.dispatchEvent(new CustomEvent('error', { detail: { "error": error.body.message } }));
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
                    this.dispatchEvent(new CustomEvent('error', { detail: { "error": error.body.message } }));
                });
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
        } else if (detail.fieldType == "MultiPicklist") {
            this.fields[detail.fieldApiName] = detail.selectedValue?.join(";");
        }
    }

    handleSuccess(event) {
        //Id is event.detail.id
        this.isLoading = false;
        this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
        this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": event.detail.id } }));
    }

    handleError(event) {
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('error', { detail: { "error": error.body.message } }));
        this.showToast(this.label.errorTitle, event.detail.detail, 'error');
        // Maybe fire Error event for the Parent Component
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

    get isNonPaidUser() {
        return this.fields.Are_there_any_non_paid_users__c == YES_NO_OPTIONS.YES;
    }

    get isMultipleContacts() {
        return this.fields.Payroll_submitted_frm_multiple_contacts__c == YES_NO_OPTIONS.YES;
    }

    get isUserCannotSeeSalary() {
        return this.fields.Any_users_who_cannot_see_salary__c == YES_NO_OPTIONS.YES;
    }

    get isClientAutoApproval() {
        if (this.fields.NSP_ClientInterestedHavingAutoApproval__c == YES_NO_OPTIONS.NO) {
            this.fields.NSP_Has_the_addendum_been_collected__c = null
        }
        return this.fields.NSP_ClientInterestedHavingAutoApproval__c == YES_NO_OPTIONS.YES;
    }

    get isArrearageInComplianceWithEachState() {
        if (this.fields.NSP_ArrearageInComplianceWithEachState__c == YES_NO_OPTIONS.YES) {
            this.fields.Is_there_a_need_for_a_subaccount__c = null
        }
        return this.fields.NSP_ArrearageInComplianceWithEachState__c == YES_NO_OPTIONS.NO;
    }

    get isDifferentSubContacts() {
        return this.fields.NSP_Different_contact_for_subaccounts__c == YES_NO_OPTIONS.YES;
    }

    get isSubAccountNeeded() {
        return this.fields.Is_there_a_need_for_a_subaccount__c == YES_NO_OPTIONS.YES;
    }

    @api
    changeSubAccount(event) {
        if (event.detail?.field === 'Is_there_a_need_for_a_subaccount__c')
            this.isSubAccount = event.detail.value;
    }

    handleChange(event) {
        this.fields[event.target.dataset.id] = event.detail.value;
    }

}