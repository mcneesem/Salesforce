import { LightningElement, api, track } from 'lwc';
import isContactHasMultipleACRs from '@salesforce/apex/NSP_CustomCaseCreationPageController.isContactHasMultipleACRs';
import getRelatedContacts from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedContacts';
import getRelatedAccounts from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedAccounts';
import getContactParent from '@salesforce/apex/NSP_CustomCaseCreationPageController.getContactParent';
import MULTIPLE_ACCOUNTS_LABEL from '@salesforce/label/c.NSP_MultipleAccountsAssociatedWithContact';

export default class CaseAccountContactLookup extends LightningElement {
    @api selectedAccountId = null;
    @api selectedContactId = null;
    @api contextAccountId;
    @api contextContactId;

    @track showAccountWarning = false;
    @track accountFilterId = '';
    @track contactFilterId = '';
    @track isContactPath = false;
    multipleAccountsLabel = MULTIPLE_ACCOUNTS_LABEL;

    connectedCallback() {
        this.initializeFromContext();
    }

    get isAccountPath() {
        return !this.isContactPath;
    }

    async initializeFromContext() {
        if (this.contextAccountId && this.contextAccountId !== 'null') {
            this.selectedAccountId = this.contextAccountId;
            this.contactFilterId = this.contextAccountId;
            this.isContactPath = false;
            await this.setDefaultContact();
        } else if (this.contextContactId && this.contextContactId !== 'null') {
            this.selectedContactId = this.contextContactId;
            this.accountFilterId = this.selectedContactId;
            this.isContactPath = true;
            await this.setDefaultAccountFromContact();
            await this.handleMultipleACRs();
        }
    }

    async handleAccountLookup(event) {
        const newAccountId = event?.detail?.recId;
        this.selectedAccountId = newAccountId;
        this.contactFilterId = this.selectedAccountId || '';
        this.accountFilterId = this.contextContactId || this.selectedContactId || '';
        this.showAccountWarning = false;
        this.dispatchFlowEvent('accountIdChange', this.selectedAccountId);
        if (newAccountId && !this.selectedContactId) {
            await this.setDefaultContact();
        }
    }

    async handleContactLookup(event) {
        const newContactId = event.detail.recId;
        if (newContactId !== this.selectedContactId) {
            this.selectedContactId = newContactId;
            this.accountFilterId = this.contextContactId || this.selectedContactId || '';
            this.contactFilterId = this.selectedAccountId || '';
            this.showAccountWarning = false;
            this.dispatchFlowEvent('contactIdChange', this.selectedContactId);
            await this.handleMultipleACRs();
            if (!this.selectedAccountId) {
                await this.setDefaultAccountFromContact();
            }
        }
    }

    async handleMultipleACRs() {
        if (!this.selectedContactId) {
            this.showAccountWarning = false;
            return;
        }
        try {
            this.showAccountWarning = await isContactHasMultipleACRs({ contId: this.selectedContactId });
        } catch (error) {
            this.dispatchFlowEvent('error', 'Error checking multiple ACRs: ' + (error.body?.message || error.message));
        }
    }

    async setDefaultContact() {
        if (!this.selectedAccountId || this.selectedContactId) return;
        try {
            const contacts = await getRelatedContacts({ accountId: this.selectedAccountId });
            if (contacts?.length === 1) {
                this.selectedContactId = contacts[0].Id;
                this.accountFilterId = this.selectedContactId;
                this.dispatchFlowEvent('contactIdChange', this.selectedContactId);
                await this.handleMultipleACRs();
                const contactLookup = this.template.querySelector('c-nsp_case-custom-look-up[s-object-api-name="Contact"]');
                if (contactLookup) {
                    contactLookup.getDefaultRecord(this.selectedContactId, 'Contact', this.selectedAccountId);
                }
            }
        } catch (error) {
            this.dispatchFlowEvent('error', 'Error setting default Contact: ' + (error.body?.message || error.message));
        }
    }

    // response from getContactParent is a List<Contact>...
    // response from getRelatedAccounts is a List<AccountContactRelation>...
    // both sObjectTypes have the same AccountId field...
    handleImperativeResponse( response ) {
        let accountId = null;
        if ( response
            && Array.isArray( response )
            && ( response.length > 0 )
            && response[0]
            )
        {
            accountId = response[0].AccountId;
        }
        return accountId;
    }

    async setDefaultAccountFromContact() {
        if (!this.selectedContactId) return;
        try {
            const getContactParentResponse = await getContactParent({ contactId: this.selectedContactId });
            let defaultAccountId = this.handleImperativeResponse( getContactParentResponse );
            if ( !defaultAccountId ) {
                const getRelatedAccountsResponse = await getRelatedAccounts({ contactId: this.selectedContactId });
                defaultAccountId = this.handleImperativeResponse( getRelatedAccountsResponse );
            }
            if (defaultAccountId && !this.selectedAccountId) {
                this.selectedAccountId = defaultAccountId;
                this.contactFilterId = this.selectedAccountId;
                this.dispatchFlowEvent('accountIdChange', this.selectedAccountId);
                const accountLookup = this.template.querySelector('c-nsp_case-custom-look-up[s-object-api-name="Account"]');
                if (accountLookup) {
                    accountLookup.getDefaultRecord(this.selectedAccountId, 'Account', this.selectedContactId);
                }
            }
        } catch (error) {
            this.dispatchFlowEvent('error', 'Error setting default Account: ' + (error.body?.message || error.message));
        }
    }

    dispatchFlowEvent(eventName, value) {
        this.dispatchEvent(new CustomEvent(eventName, { detail: value, bubbles: true, composed: true }));
    }

    @api
    validate() {
        return {
            isValid: !!this.selectedAccountId,
            errorMessage: this.selectedAccountId ? '' : 'Please select an Account.'
        };
    }
}