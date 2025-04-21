import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrgSettings from '@salesforce/apex/SandboxManualStepsController.getOrgSettings';
import runManualSteps from '@salesforce/apex/SandboxManualStepsController.runManualSteps';
import runUserImport from '@salesforce/apex/SandboxManualStepsController.runUserImport';
import runManualSteps2 from '@salesforce/apex/SandboxManualStepsController.runManualSteps2';
import runE2CAddresses from '@salesforce/apex/SandboxManualStepsController.runE2CAddresses';

export default class PrepSandbox extends LightningElement {
    @track isLoading = false;
    @track message = '';
    postRefreshRun = false;
    postRefreshRun2 = false;
    postRefreshRun3 = false;
    postRefreshRun4 = false;

    @wire(getOrgSettings)  
    getCustomSettingValues({ error, data }) {
        if (data) {
            this.postRefreshRun = data.PostRefreshRun__c;
            this.postRefreshRun2 = data.PostRefreshRun2__c;
            this.postRefreshRun3 = data.PostRefreshRun3__c;
            this.postRefreshRun4 = data.PostRefreshRun4__c;
        }else if(error) {
            this.showToast('Error', error.message, 'error');
        }
    }

    // Handler for Post-Refresh Steps button
    async handlePostRefresh() {
        this.isLoading = true;
        this.message = 'Updating metadata...';

        try {
            await runManualSteps();
            this.showToast('Success', 'Post-refresh steps completed successfully.', 'success');
        } catch (error) {
            this.message = 'Failed to complete post-refresh steps...';
            this.showToast('Error', 'Failed to complete post-refresh steps.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Handler for Import Org Users button
    async handleImportUsers() {
        this.isLoading = true;
        this.message = 'Importing users...';

        try {
            await runUserImport();
            this.showToast('Success', 'Users imported successfully.', 'success');
        } catch (error) {
            this.message = 'Failed to import users...';
            this.showToast('Error', 'Failed to import users.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Handler for Post-Import Steps button
    async handlePostImport() {
        this.isLoading = true;
        this.message = 'Running post-import steps...';

        try {
            await runManualSteps2();
            this.showToast('Success', 'Post-import steps completed successfully.', 'success');
        } catch (error) {
            this.message = 'Failed to complete post-import steps...';
            this.showToast('Error', 'Failed to complete post-import steps.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Handler for E2C Addresses button
    async handleE2CAddresses() {
        this.isLoading = true;
        this.message = 'Updating E2C addresses...';

        try {
            await runE2CAddresses();
            this.showToast('Success', 'E2C addresses updated successfully.', 'success');
        } catch (error) {
            this.message = 'Failed to update E2C addresses...';
            this.showToast('Error', 'Failed to update E2C addresses.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Helper method to show * notifications
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
        }));
    }
}