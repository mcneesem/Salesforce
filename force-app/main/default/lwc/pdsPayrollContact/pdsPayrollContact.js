import { LightningElement, api, track, wire } from 'lwc';
import getSCCPCCount from '@salesforce/apex/PdsContactController.getSCCPCCount';
import { NavigationMixin } from 'lightning/navigation';
import { RefreshEvent } from "lightning/refresh";


export default class PdsPayrollContact extends NavigationMixin(LightningElement) {
    // Record Page context Id (NSP_Payroll__c Id)
    @api recordId;

    // Store the wired result for refresh purposes
    wiredResult;

    @track showFlow = false;
    @track loading = true;

    // Provide Flow input variables: pass only recordId
    get flowInputs() {
        return [
            { name: 'recordId', type: 'String', value: this.recordId }
        ];
    }

    // Wire to Apex with recordId only
    @wire(getSCCPCCount, { recordId: '$recordId' })
    wiredSCCHandler({ error, data }) {
        this.wiredResult = { error, data }; // Store for refresh
        this.loading = false;
        if (data !== undefined && data !== null) {
            // data is Integer count now
            this.showFlow = data > 1;
        } else if (error) {
            console.error('Error fetching data:', error);
            this.showFlow = false;
        }
    }

    // Handle flow status change - refresh on FINISHED, FINISHED_SCREEN, FINISHED_SUCCESS, ERROR
    handleFlowStatusChange(event) {
        const status = event?.detail?.status;
        if (status === 'FINISHED'
            || status === 'FINISHED_SCREEN'
            || status === 'FINISHED_SUCCESS'
            || status === 'ERROR'
        ) {                  
            this.dispatchEvent(new RefreshEvent());        
        }
    }
}