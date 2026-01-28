import { LightningElement , api , wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PORTAL_PAY_PERIOD_OBJECT from "@salesforce/schema/Portal_Pay_Period__c";

export default class PortalPayPeriod extends LightningElement {
    @api record;
    error;

    fields;
    @wire(getObjectInfo, {
        objectApiName: PORTAL_PAY_PERIOD_OBJECT
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

    get leftColumnSize() {
        return "7";
    }
    get rightColumnSize() {
        return "5";
    }

}
//