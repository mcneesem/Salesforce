import { LightningElement , api , wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PORTAL_CLIENT_OBJECT from "@salesforce/schema/Portal_Client__c";
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Client__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Client__c.Name";
import BENEFITS_EFFECTIVE_DATE_FIELD from "@salesforce/schema/Portal_Client__c.Benefits_Effective_Date__c";
import BENEFITS_WAITING_PERIOD_FIELD from "@salesforce/schema/Portal_Client__c.Benefits_Waiting_Period__c";
import EFFECTIVE_DATE_FIELD from "@salesforce/schema/Portal_Client__c.Effective_Date__c";
import TIMEZONESIDKEY_FIELD from "@salesforce/schema/Portal_Client__c.TimeZoneSidKey__c";

export default class PortalClientImportantDates extends LightningElement {
    @api recordId;
    @api projectId;

    fields;
    @wire(getObjectInfo, {
        objectApiName: PORTAL_CLIENT_OBJECT
    })
    objectInfo({ error, data }) {
        if ( data ) {
            if ( data.fields ) {
                this.fields = data.fields;
            }
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.record = undefined;
        }
    }

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            BENEFITS_EFFECTIVE_DATE_FIELD ,
            BENEFITS_WAITING_PERIOD_FIELD ,
            EFFECTIVE_DATE_FIELD ,
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

    get leftColumnSize() {
        return "7";
    }
    get rightColumnSize() {
        return "5";
    }
}
//