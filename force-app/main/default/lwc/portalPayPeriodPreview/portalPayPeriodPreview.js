import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Name";
import FIRST_PAY_DATE_FIELD from "@salesforce/schema/Portal_Pay_Period__c.First_Pay_Date__c";
import FIRST_PAY_PERIOD_FIELD from "@salesforce/schema/Portal_Pay_Period__c.First_Pay_Period__c";
import FIRST_PAY_PERIOD_END_FIELD from "@salesforce/schema/Portal_Pay_Period__c.First_Pay_Period_End__c";
import FIRST_PAY_PERIOD_START_FIELD from "@salesforce/schema/Portal_Pay_Period__c.First_Pay_Period_Start__c";
import IMPLEMENTATION_PAY_PERIOD_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Implementation_Pay_Period__c";
import PAY_FREQUENCY_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Pay_Frequency__c";
import PORTAL_CLIENT_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Portal_Client__c";
import PORTAL_PROJECT_FIELD from "@salesforce/schema/Portal_Pay_Period__c.Portal_Project__c";

export default class PortalPayPeriodPreview extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            FIRST_PAY_DATE_FIELD ,
            FIRST_PAY_PERIOD_FIELD ,
            FIRST_PAY_PERIOD_END_FIELD ,
            FIRST_PAY_PERIOD_START_FIELD ,
            IMPLEMENTATION_PAY_PERIOD_FIELD ,
            PAY_FREQUENCY_FIELD ,
            PORTAL_CLIENT_FIELD ,
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