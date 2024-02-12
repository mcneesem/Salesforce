import {
    LightningElement,
    api,
    wire
} from 'lwc';
import {
    getRecord,
    createRecord,
    updateRecord
} from 'lightning/uiRecordApi';
import PIN_LOG_OBJECT from '@salesforce/schema/NSP_Verification_Log__c';
import CONTACT_FIELD from '@salesforce/schema/NSP_Verification_Log__c.NSP_Contact__c';
import VERIFIED_FIELD from '@salesforce/schema/NSP_Verification_Log__c.NSP_PIN_Verified__c';
import NOTE_FIELD from '@salesforce/schema/NSP_Verification_Log__c.NSP_Verification_Note__c';
import PIN_FIELD from '@salesforce/schema/Contact.NSP_Contact_Pin__c';
import CONTACT_ID from '@salesforce/schema/Contact.Id';
import CONTACT_NOTES from '@salesforce/schema/Contact.Pin_Dismiss_Notes__c';

export default class VerifyContactPin extends LightningElement {

    @api recordId;
    @api contactId;
    contact;
    contactPin;
    pin
    showErr;
    showErrNote;
    verified = false;
    note;
    submitLabel = 'Validate PIN';
    showDismissNote = false;
    showContractExceptions = false;
    showCancel = false;
    showPinModal = false;
    createLogRecord() {
        const fields = {};
        fields[CONTACT_FIELD.fieldApiName] = this.recordId;
        fields[VERIFIED_FIELD.fieldApiName] = this.verified;
        fields[NOTE_FIELD.fieldApiName] = this.note;
        const recordInput = { apiName: PIN_LOG_OBJECT.objectApiName, fields };
        createRecord(recordInput)
            .then(plo => {
            })
            .catch(error => {
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: [PIN_FIELD,CONTACT_ID] })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        } else if (data) {
            this.contact = data;
            this.contactPin = this.contact.fields.NSP_Contact_Pin__c.value;
            this.contactId = this.contact.fields.Id.value;
            if (!this.showDismissNote && this.contactPin != null) {
                this.showPinModal = true;
                this.showContractExceptions = false;
                this.showCancel = true;
            }
            else {
                this.showPinModal = false;
                this.showContractExceptions = true;
            }
        }
    }

    handleDismiss(event) {
        //present note
        this.showDismissNote = true;
        this.showCancel = false;
        this.showErr = false;
    }

    get hideDismissNote() {
        return !this.showDismissNote;
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.showPinModal = false;
    }
    
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        if ((this.pin == this.contactPin)) {
            this.showPinModal = false;
            this.showContractExceptions = true;
        } else {
            this.showErr = true;
        }
    }

    SubmitNotes() {
        if ( this.refs.reason ) {
            this.note = this.refs.reason.value;
        }
        if (!this.note || this.note.trim() === '') {
            this.showErrNote = true;
        } else {
            this.showPinModal = false;
            this.showContractExceptions = true;
            this.updateContactPinDismissDetails();
        }
    }

    createPin() {
        this.verified = false;
        this.note = 'User has already authenticated through the Portal';
        this.createLogRecord();
        this.showPinModal = false;
    }

    handleChange(event){
        this.showErr = false;
        this.pin = event.target.value;
    }

    updateContactPinDismissDetails() {
        const fields = {};
        if (this.contactId != null) {
            fields[CONTACT_ID.fieldApiName] = this.contactId;
            fields[CONTACT_NOTES.fieldApiName] = this.note;
            const recordInput = {
                fields
            };
            updateRecord(recordInput)
                .then(() => {
                    this.showPinModal = false;
                    this.showContractExceptions = true;
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error Updating Record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });
        }
    }
}