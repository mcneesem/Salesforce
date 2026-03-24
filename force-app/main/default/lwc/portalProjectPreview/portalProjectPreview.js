import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Project__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Project__c.Name";
import PORTAL_CLIENT_FIELD from "@salesforce/schema/Portal_Project__c.Portal_Client__c";

export default class PortalProjectPreview extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            PORTAL_CLIENT_FIELD ,
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