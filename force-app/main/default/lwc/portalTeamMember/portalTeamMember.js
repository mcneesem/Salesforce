import { LightningElement , api } from 'lwc';

export default class PortalTeamMember extends LightningElement {
    @api record; // is-a Portal_Team_Member__c

    get columnSizeFull() {
        return 12;
    }

    get columnSizeLeft() {
        return 7;
    }

    get columnSizeRight() {
        return ( this.columnSizeFull - this.columnSizeLeft );
    }

    get position() {
        return this.record?.fields?.Position__c?.value;
    }

    get guidanceId() {
        return this.record?.fields?.Portal_Guidance__c?.value;
    }

    get name() {
        return this.record?.fields?.Contact_Name__c?.value;
    }

    get email() {
        return this.record?.fields?.Contact_Email__c?.value;
    }

    get phone() {
        return this.record?.fields?.Contact_Phone__c?.value;
    }

}
//