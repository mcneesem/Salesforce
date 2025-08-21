import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

const FIELDS = ['Opportunity.Type'];

export default class EventFlowLauncher extends NavigationMixin(LightningElement) {
    @api recordId; // Event record Id
    @track previousType = null;
    @track isModalOpen = false; // Track modal state
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredEvent({ error, data }) {
        if (data) {
            const type = data.fields.Type.value;

        console.log('MATT    this.previousType :', this.previousType);
        console.log('MATT    type :', type);

            if (this.previousType && this.previousType !== type) {
                console.log('MATT    this.recordId :' + this.recordId);
                inputVariables = [
                    { name: 'opportunityRecordId', type: 'String', value: this.recordId }
                ];
                this.openModal(); // Open modal when type changes
            }
            this.previousType = type;
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    openModal() {
        this.isModalOpen = true; // Set modal to open
        console.log('MATT    this.isModalOpen :', this.isModalOpen);
    }

    closeModal() {
        this.isModalOpen = false; // Set modal to close
        console.log('MATT    this.isModalOpen :', this.isModalOpen);
    }

    handleStatusChange(event) {
        // Handle flow status changes if needed
        console.log('MATT    event.detail.status :', event.detail.status);
        if (event.detail.status === 'FINISHED') {
            this.closeModal(); // Close modal when flow is finished
        }
    }
}