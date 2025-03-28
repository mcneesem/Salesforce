import { LightningElement, api, track } from 'lwc';
import isContactHasMultipleACRs from '@salesforce/apex/NSP_CustomCaseCreationPageController.isContactHasMultipleACRs';
import getRelatedContacts from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedContacts';
import getRelatedAccounts from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedAccounts';
import MULTIPLE_ACCOUNTS_LABEL from '@salesforce/label/c.NSP_MultipleAccountsAssociatedWithContact';

export default class CaseAccountContactLookup extends LightningElement {
    @api selectedAccountId = null;
    @api selectedContactId = null;
    @api contextAccountId; 
    @api contextContactId;

    @track showAccountWarning = false;
    @track isAccountDisabled = false;
    @track isContactDisabled = false;
    multipleAccountsLabel = MULTIPLE_ACCOUNTS_LABEL;

    connectedCallback() {
        this.initializeFromContext();
    }

    async initializeFromContext() {
        if (this.contextAccountId && this.contextAccountId !== 'null') {
            this.selectedAccountId = this.contextAccountId;
            this.isAccountDisabled = true; 
            await this.setDefaultContact();
        } else if (this.contextContactId && this.contextContactId !== 'null') {
            this.selectedContactId = this.contextContactId;
            this.isContactDisabled = false;
            await this.setAccountFromContact(true);
            await this.handleMultipleACRs();
        }
    }

    async handleAccountLookup(event) {
        const newAccountId = event.detail.recId;
        if (newAccountId !== this.selectedAccountId) {
            this.selectedAccountId = newAccountId;
            if (!this.contextContactId || !this.selectedContactId) {
                this.selectedContactId = null;
            }
            this.showAccountWarning = false;
            this.isAccountDisabled = false;
            this.dispatchFlowEvent('accountIdChange', this.selectedAccountId);
            await this.setDefaultContact();
        }
    }

    async handleContactLookup(event) {
        const newContactId = event.detail.recId;
        if (newContactId !== this.selectedContactId) {
            this.selectedContactId = newContactId;
            this.showAccountWarning = false;
            this.isContactDisabled = false;
            this.dispatchFlowEvent('contactIdChange', this.selectedContactId);
            await this.handleMultipleACRs();
            if (!this.selectedAccountId) {
                await this.setAccountFromContact(false);
            }
        }
    }

    async handleMultipleACRs() {
        if (!this.selectedContactId) {
            this.showAccountWarning = false;
            return;
        }
        try {
            const hasMultipleACRs = await isContactHasMultipleACRs({ contId: this.selectedContactId });
            this.showAccountWarning = hasMultipleACRs;
        } catch (error) {
            this.dispatchFlowEvent('error', 'Error checking multiple ACRs: ' + (error.body?.message || error.message || 'Unknown error'));
        }
    }

    async setDefaultContact() {
        if (!this.selectedAccountId || this.selectedContactId) return;
        try {
            const contacts = await getRelatedContacts({ accountId: this.selectedAccountId });
            if (contacts?.length === 1) {
                this.selectedContactId = contacts[0].Id;
                this.isContactDisabled = true;
                this.dispatchFlowEvent('contactIdChange', this.selectedContactId);
                await this.handleMultipleACRs();
                const contactLookup = this.template.querySelector('c-nsp_case-custom-look-up[s-object-api-name="Contact"]');
                if (contactLookup) {
                    contactLookup.getDefaultRecord(this.selectedContactId, 'Contact', this.selectedAccountId);
                }
            }
        } catch (error) {
            this.dispatchFlowEvent('error', 'Error setting default Contact: ' + (error.body?.message || error.message || 'Unknown error'));
        }
    }

    async setAccountFromContact(isInitialSetup) {
        if (!this.contextContactId || (this.selectedAccountId && !isInitialSetup)) return;
        try {
            const accounts = await getRelatedAccounts({ contactId: this.contextContactId });
            if (accounts?.length > 0) {
                const primaryAccount = accounts.find(a => a.NSP_Is_Primary__c);
                if (primaryAccount) {
                    this.selectedAccountId = primaryAccount.AccountId;
                    this.isAccountDisabled = isInitialSetup;
                } else if (accounts.length === 1) {
                    this.selectedAccountId = accounts[0].AccountId;
                    this.isAccountDisabled = isInitialSetup;
                }
                if (this.selectedAccountId) {
                    this.dispatchFlowEvent('accountIdChange', this.selectedAccountId);
                }
            }
        } catch (error) {
            this.dispatchFlowEvent('error', 'Error setting Account from Contact: ' + (error.body?.message || error.message || 'Unknown error'));
        }
    }

    dispatchFlowEvent(eventName, value) {
        const flowEvent = new CustomEvent(eventName, {
            detail: value,
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(flowEvent);
    }

    @api
    validate() { 
        let response = {
            isValid: true,
            errorMessage: ''
        };
        if (!this.selectedAccountId) {
            response.isValid = false;
            response.errorMessage = 'Please select an Account.';
        }
        return response;
    }
}