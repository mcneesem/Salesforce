import { LightningElement, api } from 'lwc';

export default class CaseAccountContactLookup extends LightningElement {
    // Public properties for Flow to get/set Account and Contact IDs
    @api selectedAccountId;
    @api selectedContactId;

    // Fields to display in the lookup
    accountFields = ['Name'];
    contactFields = ['Name'];

    // Optional filters for lookups
    accountFilters = [
        { field: 'Name', operator: 'like', value: '' } 
    ];

    contactFilters = [
        { field: 'Name', operator: 'like', value: '' } 
    ];

    // Handle Account selection
    handleAccountChange(event) {
        this.selectedAccountId = event.detail.recordId || null;
        this.dispatchFlowEvent('accountIdChange', this.selectedAccountId);
    }

    // Handle Contact selection
    handleContactChange(event) {
        this.selectedContactId = event.detail.recordId || null;
        this.dispatchFlowEvent('contactIdChange', this.selectedContactId);
    }

    // Dispatch event to Flow
    dispatchFlowEvent(eventName, value) {
        const flowEvent = new CustomEvent(eventName, {
            detail: value,
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(flowEvent);
    }
}