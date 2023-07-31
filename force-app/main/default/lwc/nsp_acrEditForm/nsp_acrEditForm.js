import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import UPDATED_INTEGRATION_FIELD from '@salesforce/schema/AccountContactRelation.NSP_Updated_By_Integration__c';
import isFieldAccessible from '@salesforce/apex/NSP_Utilities.isFieldAccessible';


export default class Nsp_acrEditForm extends LightningElement {

    @api recordId;
    @api error;
    isReadOnly = false;
    isRoleReadOnly = false;
    isRelStrengthReadOnly = false;

    activeSections = ['A', 'G', 'B', 'C', 'D', 'E', 'F'];

    @wire(getRecord, { recordId: '$recordId', fields: UPDATED_INTEGRATION_FIELD })
    loadFields({ error, data }) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.isReadOnly = getFieldValue(data, UPDATED_INTEGRATION_FIELD);
        }
    }


    handleCancel() {
        window.history.back();
    }

    hideSuccess() {
        window.location.assign('/lightning/r/AccountContactRelation/' + this.recordId + '/view');
    }

    connectedCallback() {
        this.getFieldAccessiability()
    }

    getFieldAccessiability() {
        isFieldAccessible({fieldName : 'Roles'})
            .then(result => {
                if (result === true) {
                    this.isRoleReadOnly = true;
                }
            })
            .catch(error => {
                this.error = error;
            })

            isFieldAccessible({fieldName : 'Relationship_Strength__c'})
            .then(result => {
                if (result === true) {
                    this.isRelStrengthReadOnly = true;
                }
            })
            .catch(error => {
                this.error = error;
        })

    }
}