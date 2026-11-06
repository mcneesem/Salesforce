import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalEventList extends LightningElement {
    @api recordId; // is-a Project_Project__c.Id

    // needs to show all events, event with no start date...
    // ~ sort null start dates last, then alphabetically by name...
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
            'Portal_Event__c.Is_Visible__c' ,
            'Portal_Event__c.Meeting_URL__c' ,
            'Portal_Event__c.Rank__c' ,
            'Portal_Event__c.Status__c' ,
            'Portal_Event__c.TimeZoneSidKey__c' ,
        ] ,
        sortBy: [ 'Portal_Event__c.StartDateTime__c' , 'Portal_Event__c.Rank__c' ]
    })
    listInfo({ error, data }) {
        if ( data ) {
            this.records = data.records;
            // only show visible tasks...
            this.records = data.records?.filter(
                ( record ) => {
                    return ( record?.fields?.Is_Visible__c?.value );
                }
            );
            // sort blank start dates to the end...
            this.records = this.records?.sort(
                ( a , b ) => {
                    const aValue = a?.fields?.StartDateTime__c?.value;
                    const bValue = b?.fields?.StartDateTime__c?.value;
                    let response = 0;
                    if ( aValue && bValue ) {
                        response = bValue - aValue;
                    } else if ( aValue ) {
                        response = -1;
                    } else if ( bValue ) {
                        response = 1;
                    }
                    return response;
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