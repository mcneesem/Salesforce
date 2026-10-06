import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Task__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Task__c.Name";
import ACTION_FIELD from "@salesforce/schema/Portal_Task__c.Action__c";
import DUE_DATE_FIELD from "@salesforce/schema/Portal_Task__c.Due_Date__c";
import IS_EDITABLE_FIELD from "@salesforce/schema/Portal_Task__c.Is_Editable__c";
import HAS_PROJECT_TASK_FIELD from "@salesforce/schema/Portal_Task__c.Has_Project_Task__c";
import PARENT_PORTAL_TASK_FIELD from "@salesforce/schema/Portal_Task__c.Parent_Portal_Task__c";
import PORTAL_GUIDANCE_FIELD from "@salesforce/schema/Portal_Task__c.Portal_Guidance__c";
import PORTAL_PROJECT_FIELD from "@salesforce/schema/Portal_Task__c.Portal_Project__c";
import STATUS_FIELD from "@salesforce/schema/Portal_Task__c.Status__c";
import TYPE_FIELD from "@salesforce/schema/Portal_Task__c.Type__c";
import VALUE_CHECKBOX_FIELD from "@salesforce/schema/Portal_Task__c.Value_Checkbox__c";
import VALUE_DATE_FIELD from "@salesforce/schema/Portal_Task__c.Value_Date__c";
import VALUE_DATETIME_FIELD from "@salesforce/schema/Portal_Task__c.Value_DateTime__c";
import VALUE_INTEGER_FIELD from "@salesforce/schema/Portal_Task__c.Value_Integer__c";
import VALUE_TEXT_FIELD from "@salesforce/schema/Portal_Task__c.Value_Text__c";

export default class PortalTaskPreview extends LightningElement {
    @api recordId; // is-a Portal_Task__c.Id

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            ACTION_FIELD ,
            DUE_DATE_FIELD ,
            IS_EDITABLE_FIELD ,
            HAS_PROJECT_TASK_FIELD ,
            PARENT_PORTAL_TASK_FIELD ,
            PORTAL_GUIDANCE_FIELD ,
            PORTAL_PROJECT_FIELD ,
            STATUS_FIELD ,
            TYPE_FIELD ,
            VALUE_CHECKBOX_FIELD ,
            VALUE_DATE_FIELD ,
            VALUE_DATETIME_FIELD ,
            VALUE_INTEGER_FIELD ,
            VALUE_TEXT_FIELD ,
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