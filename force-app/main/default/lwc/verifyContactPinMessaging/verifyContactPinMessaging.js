import { LightningElement , api , wire } from 'lwc';
import { getRecord , getFieldValue } from "lightning/uiRecordApi";
import ENDUSERCONTACTID_FIELD from "@salesforce/schema/MessagingSession.EndUserContactId";

export default class verifyContactPinVoice extends LightningElement {
    @api recordId;

    @wire(
        getRecord ,
        {
            recordId : "$recordId" ,
            fields : [ ENDUSERCONTACTID_FIELD ]
        }
    )
    record;

    get contactId() {
        let response = null;
        if ( this.record && this.record.data ) {
            response = getFieldValue(
                this.record.data ,
                ENDUSERCONTACTID_FIELD
            );
        }
        return response;
    }

}