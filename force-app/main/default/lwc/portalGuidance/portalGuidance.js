import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Guidance__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Guidance__c.Name";
import HELP_TEXT_FIELD from "@salesforce/schema/Portal_Guidance__c.Help_Text__c";
import RICH_TEXT_FIELD from "@salesforce/schema/Portal_Guidance__c.Rich_Text__c";

export default class PortalGuidance extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            HELP_TEXT_FIELD ,
            RICH_TEXT_FIELD ,
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

    @api variant;

    get isDetect() {
        return ( !this.variant || ( this.variant === "detect" ) );
    }

    get isHelpText() {
        return ( ( this.isDetect || ( this.variant === "helptext" ) ) && this.helpText );
    }

    get helpText() {
        return this.record?.fields?.Help_Text__c?.value;
    }

    get isRichText() {
        return ( ( this.isDetect || ( this.variant === "richtext" ) ) && this.richText );
    }

    get richText() {
        return this.record?.fields?.Rich_Text__c?.value;
    }

}
//