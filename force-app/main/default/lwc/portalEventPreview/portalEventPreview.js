import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Event__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Event__c.Name";
import STARTDATETIME_FIELD from "@salesforce/schema/Portal_Event__c.StartDateTime__c";
import ENDDATETIME_FIELD from "@salesforce/schema/Portal_Event__c.EndDateTime__c";
import TIMEZONESIDKEY_FIELD from "@salesforce/schema/Portal_Event__c.TimeZoneSidKey__c";

export default class PortalEventPreview extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            STARTDATETIME_FIELD ,
            ENDDATETIME_FIELD ,
            TIMEZONESIDKEY_FIELD ,
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