import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalClientResources extends LightningElement {
    @api recordId; // is-a Project_Project__c.Id

    error;
    records;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Resources__r' ,
        fields: [
            'Portal_Resource__c.Id' ,
            'Portal_Resource__c.Name' ,
            'Portal_Resource__c.Link_URL__c' ,
        ] ,
        sortBy: [ 'Portal_Resource__c.Name' ]
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