import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Task__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Task__c.Name";
import ACTION_FIELD from "@salesforce/schema/Portal_Task__c.Action__c";
import DUE_DATE_FIELD from "@salesforce/schema/Portal_Task__c.Due_Date__c";
import PARENT_PORTAL_TASK_FIELD from "@salesforce/schema/Portal_Task__c.Parent_Portal_Task__c";
import PORTAL_GUIDANCE_FIELD from "@salesforce/schema/Portal_Task__c.Portal_Guidance__c";
import PORTAL_PROJECT_FIELD from "@salesforce/schema/Portal_Task__c.Portal_Project__c";
import STATUS_FIELD from "@salesforce/schema/Portal_Task__c.Status__c";
import TYPE_FIELD from "@salesforce/schema/Portal_Task__c.Type__c";
import VALUE_DATE_FIELD from "@salesforce/schema/Portal_Task__c.Value_Date__c";
import VALUE_DATETIME_FIELD from "@salesforce/schema/Portal_Task__c.Value_DateTime__c";
import VALUE_INTEGER_FIELD from "@salesforce/schema/Portal_Task__c.Value_Integer__c";

export default class PortalTaskPreview extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            ACTION_FIELD ,
            DUE_DATE_FIELD ,
            PARENT_PORTAL_TASK_FIELD ,
            PORTAL_GUIDANCE_FIELD ,
            PORTAL_PROJECT_FIELD ,
            STATUS_FIELD ,
            TYPE_FIELD ,
            VALUE_DATE_FIELD ,
            VALUE_DATETIME_FIELD ,
            VALUE_INTEGER_FIELD ,
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
    get variant() {
        return ( ( this.record?.fields?.Parent_Portal_Task__c?.value ) ? "child" : "parent" );
    }

}
//