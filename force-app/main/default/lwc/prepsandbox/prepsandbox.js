import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import isCurrentUserAllowedE2C from '@salesforce/apex/NSP_PrepSandbox.isCurrentUserAllowedE2C';
import getOrgSettings from '@salesforce/apex/NSP_PrepSandbox.getOrgSettings';
import runManualSteps from '@salesforce/apex/NSP_PrepSandbox.runManualSteps';
import runUserImport from '@salesforce/apex/NSP_PrepSandbox.runUserImport';
import runManualSteps2 from '@salesforce/apex/NSP_PrepSandbox.runManualSteps2';
import runE2CAddresses from '@salesforce/apex/NSP_PrepSandbox.runE2CAddresses';
import { refreshApex } from '@salesforce/apex';

export default class PrepSandbox extends LightningElement {
    @track isLoading = false;
    @track message = '';
    postRefreshRun = false;
    postRefreshRun2 = false;
    postRefreshRun3 = false;
    postRefreshRun4 = false;
    sandboxApiName = '';
    wiredCustomSettingResult;
    isUserAllowedE2C = false;

    // Computed flag: show Import Users button only when sandboxApiName starts with "dev"
    get showImportUsers() {
        const name = this.sandboxApiName;
        return name.startsWith('dev');
    }

    connectedCallback() {
        this.checkUserAccessE2C();
    }

    async checkUserAccessE2C() {
        try {
            this.isUserAllowedE2C = await isCurrentUserAllowedE2C();
        } catch (error) {
            console.error('Error checking user access:', error);
            this.isUserAllowedE2C = false;
        }
    }

    @wire(getOrgSettings)
    wiredCustomSetting(result) {
        this.wiredCustomSettingResult = result;
        if (result.data) {
            this.postRefreshRun = result.data.PostRefreshRun__c;
            this.postRefreshRun2 = result.data.PostRefreshRun2__c;
            this.postRefreshRun3 = result.data.PostRefreshRun3__c;
            this.postRefreshRun4 = result.data.PostRefreshRun4__c;
            this.sandboxApiName = result.data.SandboxApiName__c;
        } else if (result.error) {
            this.showToast('Error', result.error.message, 'error');
        }
    }

    refreshCustomSetting() {
        refreshApex(this.wiredCustomSettingResult);
    }

    // Handler for Post-Refresh Steps button
    async handlePostRefresh() {
        this.isLoading = true;
        this.message = 'Updating metadata...';

        try {
            await runManualSteps();
            this.showToast('Success', 'Post-refresh steps completed successfully.', 'success');
            this.postRefreshRun = true;
        } catch (error) {
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
            this.postRefreshRun2 = true;
        } catch (error) {
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
            this.postRefreshRun3 = true;
        } catch (error) {
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
            this.postRefreshRun4 = true;
        } catch (error) {
            this.showToast('Error', 'Failed to update E2C addresses.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Helper method to show * notifications
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        });
        this.dispatchEvent(toastEvent);
    }
}
