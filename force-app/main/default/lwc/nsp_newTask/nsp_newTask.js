import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAllRecordTypes from '@salesforce/apex/NSP_GetTaskRecordTypesWrapper.getRecordTypes';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class Nsp_newTask extends NavigationMixin(LightningElement) {
    @api objectApiName
    @api recordId;
    value = '';
    recordTypes = [];
    @wire(getAllRecordTypes)    
    wiredRecordTypes({ data}) {
        if (data) {
            this.recordTypes = data;
            this.value = data?.filter(record => record.isdefault)[0]?.value;
        }
    }

    handleNext() {
        let defaultValue = {};
        if(this.objectApiName == 'Contact'){
            defaultValue['WhoId'] = this.recordId
        }
        else{
            defaultValue['WhatId'] = this.recordId
        }
        try{
            const defaultValues = encodeDefaultFieldValues(
                defaultValue
            );
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Task',
                    actionName: 'new'
                },
                state: {
                    recordTypeId: this.value,
                    defaultFieldValues: defaultValues
                }
            });
        }catch(error){
        }
    }

    handleChange(event){
        this.value = event.detail.value;
    }

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('close'));
    }
}