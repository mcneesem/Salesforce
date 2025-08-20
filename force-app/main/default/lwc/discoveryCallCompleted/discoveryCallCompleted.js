import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

const EVENTFIELDS = [
    'Event.NSP_Status__c',
    'Event.WhatId',
    'Event.NSP_Event_Subtype__c'
];
 
export default class EventFlowLauncher extends LightningElement {
    @api recordId; // Event record Id
    @track whatId;
 
    @wire(getRecord, { recordId: '$recordId', fields: EVENTFIELDS })
    wiredEvent({ error, data }) {
        if (data) {
            const status = data.fields.NSP_Status__c.value;
            const subType = data.fields.NSP_Event_Subtype__c.value;
            this.whatId = data.fields.WhatId.value;

            if (this.previousStatus && this.previousStatus !== status) {
                console.log('Status changed:', status);
                if (status === 'Completed' && subType === 'Discovery Call') {
                    this.launchFlow();
                }
            }
            this.previousStatus = status;

            console.log('NSP_Status__c: ', status);
 
            
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }
    
    launchFlow() {
        const flowEvent = new FlowNavigationNextEvent();
        flowEvent.detail = {
            flowName: 'NSP_Opportunity_Team_Member_Creation', // Event_Screen_Discovery_Call_Completed
            inputVariables: [
                { name: 'whatId', type: 'String', value: this.whatId } // Pass whatId as an input variable
            ]
        };
        this.dispatchEvent(flowEvent);
    }
}