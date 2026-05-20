import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Resource__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Resource__c.Name";
import PORTAL_LINK_URL_FIELD from "@salesforce/schema/Portal_Resource__c.Link_URL__c";
import PORTAL_PROJECT_FIELD from "@salesforce/schema/Portal_Resource__c.Portal_Project__c";

export default class PortalResourcePreview extends LightningElement {
    @api recordId; // is-a Portal_Resource__c.Id

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            PORTAL_LINK_URL_FIELD ,
            PORTAL_PROJECT_FIELD ,
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