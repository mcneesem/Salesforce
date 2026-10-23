import { LightningElement , api , wire } from 'lwc';
import { getRecord } from "lightning/uiRecordApi";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import ID_FIELD from "@salesforce/schema/Portal_Project__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Project__c.Name";
import COMPLETED_PORTAL_TASKS_FIELD from "@salesforce/schema/Portal_Project__c.Completed_Portal_Tasks__c";
import TOTAL_PORTAL_TASKS_FIELD from "@salesforce/schema/Portal_Project__c.Total_Portal_Tasks__c";

export default class PortalProjectProgressBar extends LightningElement {
    @api recordId; // is-a Portal_Project__c.Id
    @api title;

    error;
    record; // is-a Portal_Project__c
    @wire(getRecord, {
        recordId: "$recordId" ,
        fields: [
            ID_FIELD ,
            NAME_FIELD ,
            COMPLETED_PORTAL_TASKS_FIELD ,
            TOTAL_PORTAL_TASKS_FIELD ,
        ] ,
    })
    recordInfo({ error, data }) {
        if ( data ) {
            this.record = data;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.record = undefined;
        }
    }

    get progress() {
        let response = 0;
        if ( this.hasTasks ) {
            response = Number.parseInt( 100 * ( this.tasksCompleted?.length / this.tasksTotal?.length ) );
        }
        return response;
    }

    get message() {
        let response = "";
        if ( this.hasTasks ) {
            response = "" + this.tasksCompleted?.length + " out of " + this.tasksTotal?.length + " items completed";
        }
        return response;
    }

    get hasTasks() {
        return ( this.tasksCompleted && this.tasksTotal );
    }

    tasksCompleted; // is-a Portal_Task__c[]
    tasksTotal; // is-a Portal_Task__c[]
    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId' ,
        relatedListId: 'Portal_Tasks__r' ,
        fields: [
            'Portal_Task__c.Id' ,
            'Portal_Task__c.Name' ,
            'Portal_Task__c.Is_Visible__c' ,
            'Portal_Task__c.Status__c' ,
        ] ,
        where: '{ and: [ { Is_Visible__c: { eq: true }} , { Status__c: { ne: "Summary" }} ] }' ,
        sortBy: [ 'Portal_Task__c.Rank__c' ]
    })
    taskInfo({ error, data }) {
        if ( data ) {
            this.tasksTotal = data.records;
            this.tasksCompleted = this.tasksTotal?.filter(
                ( record ) => {
                    return ( record?.fields?.Status__c?.value === "Completed" );
                }
            );
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.tasksCompleted = undefined;
            this.tasksTotal = undefined;
        }
    }

}
//