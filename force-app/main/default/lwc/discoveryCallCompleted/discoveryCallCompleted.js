import { LightningElement, api } from 'lwc';
import { subscribe, onError } from 'lightning/empApi';
import { NavigationMixin } from 'lightning/navigation';
import Id from '@salesforce/user/Id'; // Import the user ID

export default class EventFlowLauncher extends NavigationMixin(LightningElement) {
    @api recordId;
    eventId;
    whatId;
    isModalOpen = false;
    inputVariables = [];
    flowName = 'Event_Screen_Discovery_Call_Completed';
    channelName = '/event/DiscoveryCallCompletedEvent__e';
    currentUserId = Id;
    isSubscribed = false;

    connectedCallback() {
        if( !this.isSubscribed ) {
            this.handleSubscribe();
        }
    }

    handleSubscribe() {
        const callback = (response) => {
            const updateUserId = response.data.payload.UserId__c;
            this.eventId = response.data.payload.Id__c;
            this.whatId = response.data.payload.WhatId__c;
            this.updateInputVariables();

            if ( ( this.currentUserId == updateUserId )
                 && ( this.recordId == this.eventId
                   || this.recordId == this.whatId )
               )
            {
                this.openModal();
            }
        };

        subscribe(this.channelName, -1, callback).then(response => {
            this.isSubscribed = true;
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
        this.navigateToOpportunity();
    }
    
    navigateToOpportunity() {
    this[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.whatId,
            objectApiName: 'Opportunity', // Specify the object API name
            actionName: 'view'
        }
    });
}

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.closeModal();
        }
    }
}