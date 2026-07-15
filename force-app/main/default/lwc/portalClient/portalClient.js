import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalClient extends LightningElement {
    @api recordId; // is-a Portal_Client__c.Id

    error;
    bar; // is-a Portal_Project__c
    projects; // is-a Portal_Project__c[]
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Projects__r' ,
        fields: [
            'Portal_Project__c.Id' ,
            'Portal_Project__c.Name' ,
            'Portal_Project__c.Label__c' ,
            'Portal_Project__c.Portal_Client__c' ,
            'Portal_Project__c.Welcome_Guidance_Id__c' ,
        ] ,
        sortBy: [ 'Portal_Project__c.Id' ]
    })
    listInfo({ error, data }) {
        if ( data ) {
            this.projects = data.records;
            // for now...  only show the progress bar for the first "New Client" project...
            if ( this.projects?.length > 0 ) {
                let firstNewClientProject = this.projects.find( project => project.fields.Name.value.startsWith( 'New Client' ) );
                this.bar = firstNewClientProject;
                this.projects = [ firstNewClientProject ];
            }
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.projects = undefined;
            this.bar = undefined;
        }
    }

    get projectId() {
        return ( this.projects ? this.projects[0]?.fields?.Id?.value : undefined );
    }

    get guidanceId() {
        // change to generically pass Portal_Project__c.Portal_Guidance__c
        return ( this.projects ? this.projects[0]?.fields?.Welcome_Guidance_Id__c?.value : undefined );
    }

    get hasContent() {
        return ( this.recordId && this.projectId );
    }

}
//