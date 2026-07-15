import { LightningElement , api , wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PORTAL_PAY_PERIOD_OBJECT from "@salesforce/schema/Portal_Pay_Period__c";

export default class PortalPayPeriod extends LightningElement {
    @api record; // is-a Portal_Pay_Period__c

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

    get columnSizeFull() {
        return 12;
    }

    get columnSizeLeft() {
        return 7;
    }

    get columnSizeRight() {
        return ( this.columnSizeFull - this.columnSizeLeft );
    }

    get hasFirstPayPeriod() {
        return ( this.record?.fields?.First_Pay_Period_Start__c?.value && this.record?.fields?.First_Pay_Period_End__c?.value );
    }

    get firstPayPeriodStart() {
        return this.record?.fields?.First_Pay_Period_Start__c?.value;
    }

    get firstPayPeriodEnd() {
        return this.record?.fields?.First_Pay_Period_End__c?.value;
    }

    get firstPayDate() {
        return this.record?.fields?.First_Pay_Date__c?.value;
    }

    get payFrequency() {
        return this.record?.fields?.Pay_Frequency__c?.value;
    }

}
//