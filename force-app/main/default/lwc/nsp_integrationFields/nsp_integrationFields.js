import { LightningElement, wire, api} from 'lwc';
import getIntegrationFieldsBasedOnObject from '@salesforce/apex/NSP_IntegrationFieldsController.getIntegrationFieldsBasedOnObject';
import getContact from '@salesforce/apex/NSP_IntegrationFieldsController.getContact';
export default class Nsp_integrationFields extends LightningElement {
    integrationFields = [];

    contactFields = {};

    isReadOnly = true;
    showSave = false;
    perIdChanged = false;
    editOrView='view';

    @api recordId;
    @api objectApiName;    
    
    connectedCallback() {
        let tempFields = [];
        getIntegrationFieldsBasedOnObject({recordId: this.recordId})
        .then((result) => {
            result.forEach(eachField => {
                tempFields.push({fieldApiName : eachField, objectApiName:this.objectApiName})
            });
            this.integrationFields = tempFields;

        })
        .catch((error) => {
        });
    if(this.objectApiName === 'Contact') {
        getContact({recordId: this.recordId})
        .then((result) => {
            this.contactFields = result;
            this.isReadOnly = false;
            if (this.contactFields.CreatedBy.NSP_Profile_Name__c === 'Integration User' || this.contactFields.NSP_Per_ID__c !== undefined) {
                this.editOrView = 'readonly';
            }   
        })      
        .catch((error) => {
        });

    }
        
    }

    handleSubmit(event) {
        event.preventDefault(); // stop the form from submitting
        const fields = event.detail.fields;
        if(fields.NSP_Per_ID__c !== null && fields.NSP_Per_ID__c !== undefined) {
            this.editOrView = 'readonly';
        }
        this.template.querySelector('lightning-record-form').submit(fields);
    }     
}