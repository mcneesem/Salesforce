import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalTeamMemberList extends LightningElement {
    @api recordId;

    error;
    records;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Team_Members__r' ,
        fields: [
            'Portal_Team_Member__c.Id' ,
            'Portal_Team_Member__c.Name' ,
            'Portal_Team_Member__c.Contact__c' ,
            'Portal_Team_Member__c.Contact_Name__c' ,
            'Portal_Team_Member__c.Position__c' ,
        ] ,
        sortBy: [ 'Portal_Team_Member__c.Rank__c' ]
    })
    listInfo({ error, data }) {
        if ( data ) {
            this.records = data.records;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.records = undefined;
        }
    }

    get title() {
        return "Insperity Contacts (" + this.total + ")";
    }

    get total() {
        return ( this.records ? this.records.length : 0 );
    }

    get hasData() {
        return ( this.total > 0 );
    }

}
//