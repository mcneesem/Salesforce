import { LightningElement , api , wire } from 'lwc';
import { getRecord , getFieldValue } from "lightning/uiRecordApi";
import CONTACTID_FIELD from "@salesforce/schema/VoiceCall.ContactId__c";

export default class verifyContactPinVoice extends LightningElement {
    @api recordId;

    @wire(
        getRecord ,
        {
            recordId : "$recordId" ,
            fields : [ CONTACTID_FIELD ]
        }
    )
    record;

    get contactId() {
        let response = null;
        if ( this.record && this.record.data ) {
            response = getFieldValue(
                this.record.data ,
                CONTACTID_FIELD
            );
        }
        return response;
    }

}