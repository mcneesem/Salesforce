import { LightningElement , api , wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PORTAL_PROJECT_OBJECT from "@salesforce/schema/Portal_Project__c";
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Project__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Project__c.Name";
import BENEFITS_EFFECTIVE_DATE_FIELD from "@salesforce/schema/Portal_Project__c.Benefits_Effective_Date__c";
import BENEFITS_WAITING_PERIOD_FIELD from "@salesforce/schema/Portal_Project__c.Benefits_Waiting_Period__c";
import EFFECTIVE_DATE_FIELD from "@salesforce/schema/Portal_Project__c.Effective_Date__c";
import TIMEZONESIDKEY_FIELD from "@salesforce/schema/Portal_Project__c.TimeZoneSidKey__c";

export default class PortalClientImportantDates extends LightningElement {
    @api recordId; // is-a Portal_Client__c.Id
    @api projectId; // is-a Portal_Project__c.Id

    fields;
    @wire(getObjectInfo, {
        objectApiName: PORTAL_PROJECT_OBJECT
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
    record; // is-a Portal_Project__c
    @wire(getRecord, {
        recordId: "$projectId" ,
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

    get effectiveDateHelpText() {
        return ( this.fields?.Effective_Date__c?.inlineHelpText ? this.fields.Effective_Date__c.inlineHelpText : undefined );
    }

    get effectiveDate() {
        return ( this.record?.fields?.Effective_Date__c?.value ? this.record.fields.Effective_Date__c.value : undefined );
    }

    get benefitsEffectiveDate() {
        return ( this.record?.fields?.Benefits_Effective_Date__c?.value ? this.record.fields.Benefits_Effective_Date__c.value : undefined );
    }

    get benefitsWaitingPeriod() {
        let response = "";
        let period = this.record?.fields?.Benefits_Waiting_Period__c?.value;
        if ( period || ( period == 0 ) ) {
            // must render for non-null and "0 Days"...
            response = period + " Days";
        }
        return response;
    }

}
//