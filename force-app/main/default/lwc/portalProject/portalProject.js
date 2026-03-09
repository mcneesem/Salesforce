import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalProject extends LightningElement {
    @api record; // is-a Portal_Project__c

    get recordId() {
        return ( this.record ? this.record.fields.Id.value : undefined );
    }

    error;
    types; // is-a String[]
    tasks; // is-a Portal_Task__c[]
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Tasks__r' ,
        fields: [
            'Portal_Task__c.Id' ,
            'Portal_Task__c.Name' ,
            'Portal_Task__c.Type__c' ,
        ] ,
        sortBy: [ 'Portal_Task__c.Rank__c' ]
    })
    taskInfo({ error, data }) {
        if ( data ) {
            this.tasks = data.records;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.tasks = undefined;
        }
        this.types = undefined;
        if ( this.tasks ) {
            this.types = [
                ...new Set(
                    this.tasks.map(
                        task => task.fields.Type__c.value
                    )
                )
            ];
        }
    }

}
//