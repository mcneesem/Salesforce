import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import * as labels from 'c/nsp_implementationLabels';
import { IP_FIELDS, TITLE } from './constants';
import getTeamMembers from '@salesforce/apex/NSP_ImplementationProfileController.getTeamMembers';

export default class Nsp_clientProjectDetailsIp extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api error;

    isLoading = true;
    bpo = null;

    @wire(getRecord, { recordId: '$recordId', fields: [ IP_FIELDS.account ] })
    getRecordCallback({data, error}){
        if(data){
            this.account = getFieldValue(data, IP_FIELDS.account);
            this.updateBPOValue({ value: [ this.account ] }, true);
        }
        if(error){
            this.showToast('Error', error.detail.message, 'error');
            this.dispatchEvent(new CustomEvent('error', error));
        }
    }

    @api saveForm(){
        this.isLoading = true;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handleLoad(){
        this.isLoading = false;
    }

    handleSuccess({ detail }){
        this.isLoading = false;
        this.showToast(this.label.successTitle, this.label.implementationSavedMessage,'success');
        this.dispatchEvent(new CustomEvent('success', { detail : { "recordId" : detail.id } }));
    }

    handleError({ detail }){
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('error', { detail }));
        this.showToast('Error', detail, 'error');
    }

    handleProjectChange({ detail }){
        if(!this.account){
            this.updateBPOValue(detail, false);
        }
    }

    handleAccountChange({ detail }){
        this.account = detail.value[0];
        this.updateBPOValue(detail, true);
    }

    showToast(title, message, variant){
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }

    updateBPOValue(detail, isAccountId){
        if(detail.value && detail.value.length > 0) {
            getTeamMembers({ recordId : detail.value[0], isAccountId })
            .then(response => {
                this.bpo = response || null;
            }).catch(error => {
                this.error = error;
            });
        } else {
            this.bpo = null;
        }
    }

    get label(){
        return labels;
    }

    get fields(){
        return IP_FIELDS;
    }

    get title(){
        return TITLE;
    }
}