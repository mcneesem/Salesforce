import { LightningElement, api, wire } from 'lwc';
import { getRecord, createRecord ,updateRecord } from 'lightning/uiRecordApi';
import PIN_LOG_OBJECT from '@salesforce/schema/NSP_Verification_Log__c';
import CONTACT_FIELD from '@salesforce/schema/NSP_Verification_Log__c.NSP_Contact__c';
import VERIFIED_FIELD from '@salesforce/schema/NSP_Verification_Log__c.NSP_PIN_Verified__c';
import NOTE_FIELD from '@salesforce/schema/NSP_Verification_Log__c.NSP_Verification_Note__c';
import NAME_FIELD from '@salesforce/schema/Contact.Name';
import PIN_FIELD from '@salesforce/schema/Contact.NSP_Contact_Pin__c';
import PIN_VALIDATED from '@salesforce/schema/Contact.NSP_Pin_Validated__c';
import SERVICE_REQUEST_CHANNEL from '@salesforce/schema/Contact.NSP_Service_Request_Channel__c';
import ACCOUNT_FIELD from '@salesforce/schema/Contact.AccountId';
import CONTACT_ID from '@salesforce/schema/Contact.Id';

export default class VerifyContactPin extends LightningElement {

    @api recordId;
    @api acctId;
    @api contactId;
    // @api serviceChannel;
    contact;
    name;
    contactPin;
    pin
    showErr;
    verified = false;
    note;
    submitLabel = 'Validate PIN';
    showDismissNote = false;
    showContractExceptions = false;
    showCancel = false;
    showPinModal = false;
    pinValidated;
    serviceChannel;
    createLogRecord(){
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

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, PIN_FIELD, ACCOUNT_FIELD, CONTACT_ID,PIN_VALIDATED,SERVICE_REQUEST_CHANNEL] })
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
            this.name = this.contact.fields.Name.value;
            this.contactPin = this.contact.fields.NSP_Contact_Pin__c.value;
            this.acctId = this.contact.fields.AccountId.value;
            this.contactId = this.contact.fields.Id.value;
            this.pinValidated = this.contact.fields.NSP_Pin_Validated__c.value;
            this.serviceChannel = this.contact.fields.NSP_Service_Request_Channel__c.value;

            if (this.contactPin != null && ((!this.pinValidated && this.serviceChannel == 'Phone')||this.serviceChannel != 'Chat')){
                this.showPinModal = true;
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
       this.submitLabel = 'Dismiss';
       this.showContractExceptions = true;
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.showPinModal = false;
    }
    setNote(event){
        this.note = event.target.value;
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        if ((this.pin == this.contactPin) ){ 
            this.verified = true;
          
            if(this.serviceChannel == 'Phone'){
                this.updateContactRecord();
                this.pinValidated = true;
            }
            
        } else {
            this.errMsg = 'No Match';
            this.showErr = true;
            this.verified = false;
            var inp=this.template.querySelector('lightning-textarea');
            this.note=inp.value;
        }
        this.createLogRecord();
        this.showPinModal = false;
        this.showContractExceptions = true;
    }

    createPin() {
        this.verified = false;
        this.note = 'User has already authenticated through the Portal';
        this.createLogRecord();
        this.showPinModal = false;
        this.showContractExceptions = true;
    }

    handleChange(event){
        this.showErr = false;
        this.pin = event.target.value;
    }

    updateContactRecord() {
       
        const fields = {};
        if(this.contactId != null &&  this.serviceChannel!= null ){
            fields[CONTACT_ID.fieldApiName] = this.contactId;
            fields[PIN_VALIDATED.fieldApiName] = true;
            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                    
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