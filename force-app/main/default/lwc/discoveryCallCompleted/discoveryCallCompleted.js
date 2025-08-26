import { LightningElement, api, track } from 'lwc';
import { subscribe, onError } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';

export default class EventFlowLauncher extends NavigationMixin(LightningElement) {
    @api recordId;
    @track previousStatus = null;
    @track whatId;
    @track isModalOpen = false;
    inputVariables = [];
    flowName = 'Event_Screen_Discovery_Call_Completed';
    channelName = '/event/DiscoveryCallCompletedEvent__e';

    connectedCallback() {
        this.handleSubscribe();
    }

    handleSubscribe() {
        const callback = (response) => {
            const eventId = response.data.payload.Id__c;
            this.whatId = response.data.payload.WhatId__c;
            this.updateInputVariables();

            if ( this.recordId == eventId || this.recordId == this.whatId ) {
                this.openModal();
            }
        };

        subscribe(this.channelName, -1, callback).then(response => {
            console.log('Subscribed to channel:', response.channel);
        });

        onError(error => {
            console.error('Error in EMP API: ', error);
        });
    }

    updateInputVariables() {
        this.inputVariables = [
            { name: 'recordId', type: 'String', value: this.whatId }
        ];
    }

    openModal() {
        this.isModalOpen = true;
    }

    closeModal() {
        this.isModalOpen = false;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }
}