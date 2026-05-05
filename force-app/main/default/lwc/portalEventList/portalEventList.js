import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalEventList extends LightningElement {
    @api recordId; // is-a Project_Project__c.Id

    error;
    records;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Events__r' ,
        fields: [
            'Portal_Event__c.Id' ,
            'Portal_Event__c.Name' ,
            'Portal_Event__c.StartDateTime__c' ,
            'Portal_Event__c.EndDateTime__c' ,
            'Portal_Event__c.TimeZoneSidKey__c' ,
        ] ,
        sortBy: [ 'Portal_Event__c.StartDateTime__c' ]
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

}
//