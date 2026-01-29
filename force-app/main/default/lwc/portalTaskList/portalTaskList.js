import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalTaskList extends LightningElement {
    @api recordId;
    @api type;
    @api variant;

    get layoutClass() {
        return ( this.isChild ? "slds-p-top_medium" : "" );
    }
    get titleSize() {
        return ( this.isChild ? "7" : "5" );
    }
    get isParent() {
        return !this.isChild;
    }
    get isChild() {
        return ( this.variant === "child" );
    }
    get relatedListId() {
        return ( this.isChild ? 'Child_Portal_Tasks__r' : 'Portal_Tasks__r' );
    }
    get where() {
        return ( this.isChild ? '' : '{ and: [ { Type__c: { eq: "' + this.type + '" }} , { Parent_Portal_Task__c: { eq: "" }} ] }' );
    }

    error;
    records;
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: '$relatedListId' ,
        fields: [
            'Portal_Task__c.Id' ,
            'Portal_Task__c.Name' ,
            'Portal_Task__c.Action__c' ,
            'Portal_Task__c.Due_Date__c' ,
            'Portal_Task__c.Parent_Portal_Task__c' ,
            'Portal_Task__c.Portal_Client__c' ,
            'Portal_Task__c.Status__c' ,
            'Portal_Task__c.Type__c' ,
        ] ,
        where: '$where' ,
        sortBy: [ 'Portal_Task__c.Id' ]
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
    get hasRecords() {
        return ( this.records?.length > 0 );
    }

}
//