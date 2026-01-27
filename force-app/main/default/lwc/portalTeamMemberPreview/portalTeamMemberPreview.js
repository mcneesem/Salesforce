import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Team_Member__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Team_Member__c.Name";
import PORTAL_CLIENT_FIELD from "@salesforce/schema/Portal_Team_Member__c.Portal_Client__c";
import CONTACT_FIELD from "@salesforce/schema/Portal_Team_Member__c.Contact__c";
import CONTACT_NAME_FIELD from "@salesforce/schema/Portal_Team_Member__c.Contact_Name__c";
import POSITION_FIELD from "@salesforce/schema/Portal_Team_Member__c.Position__c";

export default class PortalTeamMemberPreview extends LightningElement {
    @api recordId;

    error;
    record;
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            PORTAL_CLIENT_FIELD ,
            CONTACT_FIELD ,
            CONTACT_NAME_FIELD ,
            POSITION_FIELD ,
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