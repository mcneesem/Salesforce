import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue, getRecordUi } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import TRANSITIONING_CLIENT from '@salesforce/schema/Account.Transitioning_Client__c';
import CASE_ACCOUNT from '@salesforce/schema/Case.AccountId';
import ASSET_ACCOUNT from '@salesforce/schema/Asset.AccountId';

export default class transitioningClientBannerr extends LightningElement {
    @api recordId;
    objectApiName;

    // Get objectApiName from getRecordUi
    @wire(getRecordUi, { recordIds: '$recordId'})
    wiredUi({ data, error }) {
        if (data && data.records && this.recordId) {
            const rec = data.records[this.recordId];
            this.objectApiName = rec?.apiName;
        } else {
            this.objectApiName = undefined;
        }
    }

    // Account page: read field directly on the same record
    @wire(getRecord, { recordId: '$recordId', fields: [TRANSITIONING_CLIENT] })
    record;

    // Case/Asset pages: read AccountId from the child, then read parent Account.Transitioning_Client__c
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CASE_ACCOUNT, ASSET_ACCOUNT]
    })
    parentRefs;

    get parentAccountId() {
        let accountId;
        if (this.objectApiName === 'Case') {
            accountId = CASE_ACCOUNT;
        } else if (this.objectApiName === 'Asset') {
            accountId = ASSET_ACCOUNT;
        }
        return accountId ? getFieldValue(this.parentRefs?.data, accountId) : undefined;
    }

    @wire(getRecord, {
        recordId: '$parentAccountId',
        fields: [TRANSITIONING_CLIENT]
    })
    parentAccount;

    // Value based on context
    get value() {
        let tc;
        if (this.objectApiName === 'Account') {
            tc = getFieldValue(this.record?.data, TRANSITIONING_CLIENT);
        } else if (this.objectApiName === 'Case' || this.objectApiName === 'Asset') {
            tc = getFieldValue(this.parentAccount?.data, TRANSITIONING_CLIENT);
        }
        return tc;
    }

    get hasValue() {
        return this.value ? true : false;
    }
}
