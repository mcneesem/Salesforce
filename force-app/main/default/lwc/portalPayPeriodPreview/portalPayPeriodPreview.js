import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Name";

export default class PortalPayPeriodPreview extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
        ] ,
    })
    recordInfo({ error, data }) {
        if ( data ) {
            this.record = data;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.record = undefined;
        }
    }

}
//