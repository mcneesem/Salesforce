import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import hasFraudAlert from '@salesforce/apex/FraudAlertController.hasFraudAlert';
import CONTACT_FRAUD_ALERT from '@salesforce/schema/Contact.Fraud_Alert__c';

export default class FraudAlertBanner extends LightningElement {
    @api recordId;
    @api objectApiName;

    apexResult = false;
    contactFraudAlert = false;

    // Contact page — LDS reactive, updates on inline edit instantly
    @wire(getRecord, { recordId: '$contactRecordId', fields: [CONTACT_FRAUD_ALERT] })
    wiredContact({ data, error }) {
        if (data) {
            this.contactFraudAlert = getFieldValue(data, CONTACT_FRAUD_ALERT) === true;
        } else if (error) {
            console.error('Fraud Alert (Contact LDS) Error:', error);
            this.contactFraudAlert = false;
        }
    }

    // Account / Opportunity / Case — imperative call, bypasses LDS cache entirely
    connectedCallback() {
        if (this.objectApiName !== 'Contact') {
            hasFraudAlert({ recordId: this.recordId, objectApiName: this.objectApiName })
                .then(result => { this.apexResult = result === true; })
                .catch(error => {
                    console.error('Fraud Alert Error:', error);
                    this.apexResult = false;
                });
        }
    }

    get contactRecordId() {
        return this.objectApiName === 'Contact' ? this.recordId : undefined;
    }

    get showBanner() {
        return this.objectApiName === 'Contact'
            ? this.contactFraudAlert
            : this.apexResult;
    }
}
