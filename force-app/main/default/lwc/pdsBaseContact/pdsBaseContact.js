  import { LightningElement, api } from 'lwc';
  import { RefreshEvent } from 'lightning/refresh';
  import getSCCHRCount from '@salesforce/apex/PdsContactController.getSCCHRCount';
  import getSCCPCCount from '@salesforce/apex/PdsContactController.getSCCPCCount';

  /**
   * Base LWC to Apex wire result. Accepts two inputs:
   *  - flowApiName: Flow API name to render
   *  - apexMethodApiName: use to select Apex count method from getSCCHRCount or getSCCPCCount
   *  - recordId: the recordId of the context record
   */
  export default class PdsBaseContact extends LightningElement {
    // Public API
    @api flowApiName;
    @api apexMethodApiName;

    // Record context provided by the page
    @api recordId;

    wiredResult;
    showFlow = false;
    loading = true;

    // standard flow input variables (recordId only)
    get flowInputs() {
      return [{ name: 'recordId', type: 'String', value: this.recordId }];
    }

    connectedCallback() {
      // Automatically evaluate count when component is initialized
      if (this.apexMethodApiName && this.recordId) {
        this.evaluateCount();
      }
    }

    // Call this to load and compute showFlow
    @api
    async evaluateCount() {
      if (!this.apexMethodApiName || !this.recordId) {
        return;
      }
      this.loading = true;
      try {
        let count;
        if (this.apexMethodApiName === 'getSCCHRCount') {
          count = await getSCCHRCount({ recordId: this.recordId });
        } else if (this.apexMethodApiName === 'getSCCPCCount') {
          count = await getSCCPCCount({ recordId: this.recordId });
        }
        if (count !== undefined && count !== null) {
          this.showFlow = count > 1;
        } else {
          this.showFlow = false;
        }
      } catch (e) {
        console.error('Error fetching count:', e);
        this.showFlow = false;
      } finally {
        this.loading = false;
      }
    }

    handleFlowStatusChange(event) {
      const status = event?.detail?.status;
      if (
        status === 'FINISHED' ||
        status === 'FINISHED_SCREEN' ||
        status === 'FINISHED_SUCCESS' ||
        status === 'ERROR'
      ) {
        this.dispatchEvent(new RefreshEvent());
      }
    }
  }