import { LightningElement , api } from 'lwc';

export default class PortalTeamMember extends LightningElement {
    @api record; // is-a Portal_Team_Member__c

    get position() {
        return this.record?.fields?.Position__c?.value;
    }

    get name() {
        return this.record?.fields?.Contact_Name__c?.value;
    }

}
//