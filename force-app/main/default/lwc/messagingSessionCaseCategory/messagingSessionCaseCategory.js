import { LightningElement , api , wire } from 'lwc';
import { getRecord , getFieldValue } from "lightning/uiRecordApi";
import CASEID_FIELD from "@salesforce/schema/MessagingSession.CaseId";

export default class MessagingSessionCaseCategory extends LightningElement {
    @api recordId;

    @wire(
        getRecord ,
        {
            recordId : "$recordId" ,
            fields : [ CASEID_FIELD ]
        }
    )
    record;

    get caseId() {
        let response = null;
        if ( this.record && this.record.data ) {
            response = getFieldValue(
                this.record.data ,
                CASEID_FIELD
            );
        }
        return response;
    }

}