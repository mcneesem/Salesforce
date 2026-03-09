import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Project__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Project__c.Name";
import COMPLETED_PORTAL_TASKS_FIELD from "@salesforce/schema/Portal_Project__c.Completed_Portal_Tasks__c";
import TOTAL_PORTAL_TASKS_FIELD from "@salesforce/schema/Portal_Project__c.Total_Portal_Tasks__c";

export default class PortalProjectProgressBar extends LightningElement {
    @api recordId; // is-a Portal_Project__c.Id

    error;
    record; // is-a Portal_Project__c
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            COMPLETED_PORTAL_TASKS_FIELD ,
            TOTAL_PORTAL_TASKS_FIELD ,
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

    get progress() {
        let response = 0;
        if ( this.record?.fields?.Completed_Portal_Tasks__c?.value
            && this.record?.fields?.Total_Portal_Tasks__c?.value
            )
        {
            response = parseInt( 100 * ( this.record.fields.Completed_Portal_Tasks__c.value / this.record.fields.Total_Portal_Tasks__c.value ) );
        }
        return response;
    }

}
//