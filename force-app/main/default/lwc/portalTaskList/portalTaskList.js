import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalTaskList extends LightningElement {
    @api parentRecordId; // is-a Portal_Project__c.Id OR Portal_Task__c.Id
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

    //
    //
    //

    get columnSizeFull() {
        return 12;
    }

    get columnSizeTitle() {
        return ( this.isChild ? 7 : 5 );
    }

    get columnSizeDueDate() {
        return (
            this.columnSizeFull
            - this.columnSizeTitle
            - this.columnSizeAction
            - this.columnSizeUploads
            - this.columnSizeStatus
        );
    }

    get columnSizeAction() {
        return 3;
    }

    get columnSizeUploads() {
        return 1;
    }

    get columnSizeStatus() {
        return 1;
    }

    //
    //
    //

    error;
    records;
    @wire(getRelatedListRecords, {
        parentRecordId: '$parentRecordId' ,
        relatedListId: '$relatedListId' ,
        fields: [
            'Portal_Task__c.Id' ,
            'Portal_Task__c.Name' ,
            'Portal_Task__c.Action__c' ,
            'Portal_Task__c.Due_Date__c' ,
            'Portal_Task__c.Is_Editable__c' ,
            'Portal_Task__c.Has_Project_Task__c' ,
            'Portal_Task__c.Parent_Portal_Task__c' ,
            'Portal_Task__c.Portal_Guidance__c' ,
            'Portal_Task__c.Portal_Project__c' ,
            'Portal_Task__c.Status__c' ,
            'Portal_Task__c.Type__c' ,
            'Portal_Task__c.Value_Date__c' ,
            'Portal_Task__c.Value_DateTime__c' ,
            'Portal_Task__c.Value_Integer__c' ,
            'Portal_Task__c.Value_Text__c' ,
        ] ,
        where: '$where' ,
        sortBy: [ 'Portal_Task__c.Rank__c' ]
    })
    listInfo({ error, data }) {
        if ( data ) {
            this.records = data.records;
            // only show visible tasks...
            // ~ ignore tasks with a "Hidden" status...
            this.records = data.records?.filter(
                ( record ) => {
                    return ( record?.fields?.Status__c?.value != "Hidden" );
                }
            );
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